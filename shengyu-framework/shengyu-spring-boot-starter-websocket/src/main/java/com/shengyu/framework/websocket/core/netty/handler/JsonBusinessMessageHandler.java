package com.shengyu.framework.websocket.core.netty.handler;

import cn.hutool.json.JSONArray;
import cn.hutool.json.JSONObject;
import cn.hutool.json.JSONUtil;
import com.shengyu.framework.websocket.core.processor.MessageProcessor;
import com.shengyu.framework.websocket.core.processor.MessageProcessorFactory;
import com.shengyu.framework.tenant.core.util.TenantUtils;
import com.shengyu.framework.websocket.core.protocol.FileMessage;
import com.shengyu.framework.websocket.core.protocol.ImageMessage;
import com.shengyu.framework.websocket.core.protocol.ImMessage;
import com.shengyu.framework.websocket.core.protocol.LocationMessage;
import com.shengyu.framework.websocket.core.protocol.MessageHeader;
import com.shengyu.framework.websocket.core.protocol.MessageType;
import com.shengyu.framework.websocket.core.protocol.AckMessage;
import com.shengyu.framework.websocket.core.protocol.QuoteReplyMessage;
import com.shengyu.framework.websocket.core.protocol.ReadReceiptMessage;
import com.shengyu.framework.websocket.core.protocol.RecallMessage;
import com.shengyu.framework.websocket.core.protocol.TextMessage;
import com.shengyu.framework.websocket.core.protocol.TypingMessage;
import com.shengyu.framework.websocket.core.protocol.VideoMessage;
import com.shengyu.framework.websocket.core.protocol.VoiceMessage;
import com.shengyu.framework.websocket.core.session.NettySessionManager;
import io.netty.channel.ChannelHandler;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInboundHandlerAdapter;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;

/**
 * WebSocket(JSON) 业务消息处理器
 *
 * 负责将前端发送的 JSON 格式 { header, body } 消息转换为 Protobuf {@link ImMessage}，
 * 并复用现有 {@link MessageProcessorFactory} 进行分发处理（存储/转发等）。
 */
@Slf4j
@Component
@RequiredArgsConstructor
@ChannelHandler.Sharable
public class JsonBusinessMessageHandler extends ChannelInboundHandlerAdapter {

    private final MessageProcessorFactory processorFactory;

    private final NettySessionManager sessionManager;

    @Override
    public void channelRead(ChannelHandlerContext ctx, Object msg) throws Exception {
        // 只处理 WebSocket 文本帧转发出来的 String
        if (!(msg instanceof String)) {
            super.channelRead(ctx, msg);
            return;
        }

        final String text = (String) msg;
        JSONObject json;
        try {
            json = JSONUtil.parseObj(text);
        } catch (Exception e) {
            // 非 JSON，交给后续处理（例如 ping/pong 或其他协议）
            super.channelRead(ctx, msg);
            return;
        }

        JSONObject headerJson = json.getJSONObject("header");
        if (headerJson == null) {
            super.channelRead(ctx, msg);
            return;
        }

        Integer messageTypeValue = headerJson.getInt("messageType");
        if (messageTypeValue == null) {
            super.channelRead(ctx, msg);
            return;
        }

        if (log.isInfoEnabled()) {
            Object rawMessageId = headerJson.get("messageId");
            Object rawSenderId = headerJson.get("senderId");
            Object rawReceiverId = headerJson.get("receiverId");
            Object rawGroupId = headerJson.get("groupId");
            Object rawTenantId = headerJson.get("tenantId");
            Object rawTimestamp = headerJson.get("timestamp");
            Object rawSequence = headerJson.get("sequence");
            log.info("[JsonBusiness] inbound header raw types: type={}, messageId={}({}), senderId={}({}), receiverId={}({}), groupId={}({}), tenantId={}({}), timestamp={}({}), sequence={}({})",
                    messageTypeValue,
                    rawMessageId, rawMessageId == null ? "null" : rawMessageId.getClass().getSimpleName(),
                    rawSenderId, rawSenderId == null ? "null" : rawSenderId.getClass().getSimpleName(),
                    rawReceiverId, rawReceiverId == null ? "null" : rawReceiverId.getClass().getSimpleName(),
                    rawGroupId, rawGroupId == null ? "null" : rawGroupId.getClass().getSimpleName(),
                    rawTenantId, rawTenantId == null ? "null" : rawTenantId.getClass().getSimpleName(),
                    rawTimestamp, rawTimestamp == null ? "null" : rawTimestamp.getClass().getSimpleName(),
                    rawSequence, rawSequence == null ? "null" : rawSequence.getClass().getSimpleName());
        }

        // 系统消息在 HeartbeatHandler/AuthHandler 已处理，这里只处理业务消息（>=100）
        // 但 ACK 是协议级回执，需要在这里进入 processorFactory 统一处理
        // 注意：ACK=8 是新协议类型；在 protobuf 生成代码尚未更新时避免直接引用 MessageType.ACK_VALUE
        if (messageTypeValue < MessageType.TEXT_VALUE && messageTypeValue != 8) {
            super.channelRead(ctx, msg);
            return;
        }

        // 业务消息视为业务活跃
        sessionManager.updateLastBizActiveTime(ctx.channel());

        try {
            ImMessage imMessage = buildImMessageFromJson(ctx, headerJson, json.get("body"));
            MessageType messageType = imMessage.getHeader().getMessageType();

            if (log.isInfoEnabled()) {
                MessageHeader h = imMessage.getHeader();
                log.info("[JsonBusiness] parsed header: messageType={}, messageId={}, senderId={}, receiverId={}, groupId={}, tenantId={}, timestamp={}, sequence={}",
                        h.getMessageType(), h.getMessageId(), h.getSenderId(), h.getReceiverId(), h.getGroupId(), h.getTenantId(), h.getTimestamp(), h.getSequence());
            }

            MessageProcessor processor = processorFactory.getProcessor(messageType);
            if (processor == null) {
                log.warn("[JsonBusiness] 未找到消息处理器, type: {}", messageType);
                return;
            }

            if (log.isInfoEnabled()) {
                log.info("[JsonBusiness] dispatch to processor: type={}, processor={} ", messageType, processor.getClass().getSimpleName());
            }

            Long tenantId = imMessage.getHeader().getTenantId();
            if (log.isInfoEnabled()) {
                log.info("[JsonBusiness] execute with tenantId={}, type={}, messageId={}", tenantId, messageType, imMessage.getHeader().getMessageId());
            }
            TenantUtils.execute(tenantId, () -> processor.process(ctx, imMessage));
        } catch (Exception e) {
            log.error("[JsonBusiness] 处理业务 JSON 消息异常, payload: {}", text, e);
        }
    }

    private ImMessage buildImMessageFromJson(ChannelHandlerContext ctx, JSONObject headerJson, Object bodyObj) {
        // 1) header
        MessageHeader.Builder headerBuilder = MessageHeader.newBuilder();

        Long authedUserId = AuthHandler.getUserId(ctx);
        Long authedTenantId = AuthHandler.getTenantId(ctx);

        Long messageId = readLong(headerJson, "messageId", System.currentTimeMillis());
        headerBuilder.setMessageId(messageId);

        Integer messageTypeValue = headerJson.getInt("messageType");
        MessageType resolvedType = MessageType.forNumber(messageTypeValue);
        headerBuilder.setMessageType(resolvedType != null ? resolvedType : MessageType.UNKNOWN);

        // senderId：优先使用认证用户，避免前端伪造
        Long senderId = authedUserId != null ? authedUserId : headerJson.getLong("senderId", 0L);
        headerBuilder.setSenderId(senderId != null ? senderId : 0L);

        Long receiverId = readLong(headerJson, "receiverId", 0L);
        headerBuilder.setReceiverId(receiverId);

        Long groupId = readLong(headerJson, "groupId", 0L);
        headerBuilder.setGroupId(groupId);

        Long tenantId = authedTenantId != null ? authedTenantId : readLong(headerJson, "tenantId", 0L);
        headerBuilder.setTenantId(tenantId != null ? tenantId : 0L);

        Long timestamp = readLong(headerJson, "timestamp", System.currentTimeMillis());
        headerBuilder.setTimestamp(timestamp);

        Long sequence = readLong(headerJson, "sequence", 0L);
        headerBuilder.setSequence(sequence);

        String extra = headerJson.getStr("extra", "");
        headerBuilder.setExtra(extra != null ? extra : "");

        // 2) body（将 JSON body 转为对应 Protobuf message bytes）
        byte[] bodyBytes = buildBodyBytes(headerBuilder.getMessageType(), bodyObj);

        return ImMessage.newBuilder()
                .setHeader(headerBuilder.build())
                .setBody(com.google.protobuf.ByteString.copyFrom(bodyBytes))
                .build();
    }

    private long readLong(JSONObject obj, String key, long defaultValue) {
        if (obj == null || key == null) {
            return defaultValue;
        }
        try {
            Object raw = obj.get(key);
            if (raw == null) {
                return defaultValue;
            }
            if (raw instanceof Number) {
                return ((Number) raw).longValue();
            }
            String s = String.valueOf(raw);
            if (s.isEmpty() || "null".equalsIgnoreCase(s)) {
                return defaultValue;
            }
            return Long.parseLong(s);
        } catch (Exception ignore) {
            return defaultValue;
        }
    }

    private byte[] buildBodyBytes(MessageType messageType, Object bodyObj) {
        JSONObject bodyJson = null;
        if (bodyObj instanceof JSONObject) {
            bodyJson = (JSONObject) bodyObj;
        } else if (bodyObj != null) {
            try {
                bodyJson = JSONUtil.parseObj(bodyObj);
            } catch (Exception ignore) {
            }
        }

        switch (messageType) {
            case ACK: {
                if (bodyJson == null) {
                    return AckMessage.getDefaultInstance().toByteArray();
                }
                AckMessage.Builder builder = AckMessage.newBuilder()
                        .setMessageId(bodyJson.getLong("messageId", 0L))
                        .setChatId(bodyJson.getLong("chatId", 0L))
                        .setSequence(bodyJson.getLong("sequence", 0L))
                        .setAckType(bodyJson.getStr("ackType", ""))
                        .setClientReceivedAt(bodyJson.getLong("clientReceivedAt", 0L))
                        .setOriginalTimestamp(bodyJson.getLong("originalTimestamp", 0L));
                return builder.build().toByteArray();
            }
            case TEXT: {
                String content = bodyJson != null ? bodyJson.getStr("content", "") : "";
                List<Long> atUserIds = new ArrayList<>();
                if (bodyJson != null) {
                    Object atObj = bodyJson.get("atUserIds");
                    if (atObj instanceof JSONArray) {
                        JSONArray arr = (JSONArray) atObj;
                        for (int i = 0; i < arr.size(); i++) {
                            Long v = arr.getLong(i);
                            if (v != null) {
                                atUserIds.add(v);
                            }
                        }
                    }
                }
                TextMessage.Builder builder = TextMessage.newBuilder().setContent(content);
                if (!atUserIds.isEmpty()) {
                    builder.addAllAtUserIds(atUserIds);
                }
                return builder.build().toByteArray();
            }
            case IMAGE: {
                if (bodyJson == null) {
                    return ImageMessage.getDefaultInstance().toByteArray();
                }
                ImageMessage.Builder builder = ImageMessage.newBuilder()
                        .setUrl(bodyJson.getStr("url", ""))
                        .setThumbnailUrl(bodyJson.getStr("thumbnailUrl", ""))
                        .setWidth(bodyJson.getInt("width", 0))
                        .setHeight(bodyJson.getInt("height", 0))
                        .setSize(bodyJson.getLong("size", 0L));
                return builder.build().toByteArray();
            }
            case VOICE: {
                if (bodyJson == null) {
                    return VoiceMessage.getDefaultInstance().toByteArray();
                }
                VoiceMessage.Builder builder = VoiceMessage.newBuilder()
                        .setUrl(bodyJson.getStr("url", ""))
                        .setDuration(bodyJson.getInt("duration", 0))
                        .setSize(bodyJson.getLong("size", 0L));
                return builder.build().toByteArray();
            }
            case VIDEO: {
                if (bodyJson == null) {
                    return VideoMessage.getDefaultInstance().toByteArray();
                }
                VideoMessage.Builder builder = VideoMessage.newBuilder()
                        .setUrl(bodyJson.getStr("url", ""))
                        .setCoverUrl(bodyJson.getStr("coverUrl", ""))
                        .setDuration(bodyJson.getInt("duration", 0))
                        .setWidth(bodyJson.getInt("width", 0))
                        .setHeight(bodyJson.getInt("height", 0))
                        .setSize(bodyJson.getLong("size", 0L));
                return builder.build().toByteArray();
            }
            case FILE: {
                if (bodyJson == null) {
                    return FileMessage.getDefaultInstance().toByteArray();
                }
                FileMessage.Builder builder = FileMessage.newBuilder()
                        .setUrl(bodyJson.getStr("url", ""))
                        .setFileName(bodyJson.getStr("fileName", ""))
                        .setSize(bodyJson.getLong("size", 0L))
                        .setFileType(bodyJson.getStr("fileType", ""));
                return builder.build().toByteArray();
            }
            case LOCATION: {
                if (bodyJson == null) {
                    return LocationMessage.getDefaultInstance().toByteArray();
                }
                LocationMessage.Builder builder = LocationMessage.newBuilder()
                        .setLatitude(bodyJson.getDouble("latitude", 0D))
                        .setLongitude(bodyJson.getDouble("longitude", 0D))
                        .setAddress(bodyJson.getStr("address", ""));
                return builder.build().toByteArray();
            }
            case READ_RECEIPT: {
                if (bodyJson == null) {
                    return ReadReceiptMessage.getDefaultInstance().toByteArray();
                }
                ReadReceiptMessage.Builder builder = ReadReceiptMessage.newBuilder();
                Object idsObj = bodyJson.get("messageIds");
                if (idsObj instanceof JSONArray) {
                    JSONArray arr = (JSONArray) idsObj;
                    List<Long> ids = new ArrayList<>();
                    for (int i = 0; i < arr.size(); i++) {
                        Long v = arr.getLong(i);
                        if (v != null) {
                            ids.add(v);
                        }
                    }
                    builder.addAllMessageIds(ids);
                }
                return builder.build().toByteArray();
            }
            case RECALL: {
                if (bodyJson == null) {
                    return RecallMessage.getDefaultInstance().toByteArray();
                }
                RecallMessage.Builder builder = RecallMessage.newBuilder().setMessageId(bodyJson.getLong("messageId", 0L));
                return builder.build().toByteArray();
            }
            case TYPING: {
                if (bodyJson == null) {
                    return TypingMessage.getDefaultInstance().toByteArray();
                }
                TypingMessage.Builder builder = TypingMessage.newBuilder()
                        .setTargetUserId(bodyJson.getLong("targetUserId", 0L))
                        .setGroupId(bodyJson.getLong("groupId", 0L))
                        .setIsTyping(bodyJson.getBool("isTyping", false));
                return builder.build().toByteArray();
            }
            case QUOTE_REPLY: {
                if (bodyJson == null) {
                    return QuoteReplyMessage.getDefaultInstance().toByteArray();
                }
                QuoteReplyMessage.Builder builder = QuoteReplyMessage.newBuilder()
                        .setQuoteMessageId(bodyJson.getLong("quoteMessageId", 0L))
                        .setQuoteContent(bodyJson.getStr("quoteContent", ""))
                        .setQuoteSenderId(bodyJson.getLong("quoteSenderId", 0L))
                        .setQuoteSenderName(bodyJson.getStr("quoteSenderName", ""))
                        .setReplyContent(bodyJson.getStr("replyContent", ""));

                Object atObj = bodyJson.get("atUserIds");
                if (atObj instanceof JSONArray) {
                    JSONArray arr = (JSONArray) atObj;
                    List<Long> ids = new ArrayList<>();
                    for (int i = 0; i < arr.size(); i++) {
                        Long v = arr.getLong(i);
                        if (v != null) {
                            ids.add(v);
                        }
                    }
                    builder.addAllAtUserIds(ids);
                }

                return builder.build().toByteArray();
            }
            default:
                // 未覆盖的类型，尽量透传 JSON 字符串（便于排查）
                return bodyObj != null ? bodyObj.toString().getBytes() : new byte[0];
        }
    }
}
