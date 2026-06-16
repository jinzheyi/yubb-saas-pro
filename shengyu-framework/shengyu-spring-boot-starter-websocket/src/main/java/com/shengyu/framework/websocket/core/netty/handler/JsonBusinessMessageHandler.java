package com.shengyu.framework.websocket.core.netty.handler;

import cn.hutool.core.util.StrUtil;
import cn.hutool.json.JSONArray;
import cn.hutool.json.JSONObject;
import cn.hutool.json.JSONUtil;
import com.shengyu.framework.common.exception.ServiceException;
import com.shengyu.framework.common.exception.util.ServiceExceptionUtil;
import com.shengyu.framework.websocket.core.processor.MessageProcessor;
import com.shengyu.framework.websocket.core.processor.MessageProcessorFactory;
import com.shengyu.framework.tenant.core.util.TenantUtils;
import com.shengyu.framework.websocket.core.protocol.FileMessage;
import com.shengyu.framework.websocket.core.protocol.ImageMessage;
import com.shengyu.framework.websocket.core.protocol.ImMessage;
import com.shengyu.framework.websocket.core.protocol.LocationMessage;
import com.shengyu.framework.websocket.core.protocol.MentionUser;
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
import com.shengyu.framework.websocket.config.NettyProperties;
import com.shengyu.framework.websocket.core.security.MessageSignature;
import io.netty.channel.ChannelHandler;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInboundHandlerAdapter;
import io.netty.handler.codec.http.websocketx.TextWebSocketFrame;
import lombok.extern.slf4j.Slf4j;

import java.util.ArrayList;
import java.util.List;

/**
 * WebSocket(JSON) 业务消息处理器
 *
 * 负责将前端发送的 JSON 格式 { header, body } 消息转换为 Protobuf {@link ImMessage}，
 * 并复用现有 {@link MessageProcessorFactory} 进行分发处理（存储/转发等）。
 */
@Slf4j
@ChannelHandler.Sharable
public class JsonBusinessMessageHandler extends ChannelInboundHandlerAdapter {

    private final MessageProcessorFactory processorFactory;

    private final NettySessionManager sessionManager;

    private final NettyProperties nettyProperties;

    public JsonBusinessMessageHandler(MessageProcessorFactory processorFactory,
                                      NettySessionManager sessionManager,
                                      NettyProperties nettyProperties) {
        this.processorFactory = processorFactory;
        this.sessionManager = sessionManager;
        this.nettyProperties = nettyProperties;
    }

    @Override
    public void channelRead(ChannelHandlerContext ctx, Object msg) throws Exception {
        // 只处理 WebSocket 文本帧转发出来的 String
        if (!(msg instanceof String)) {
            super.channelRead(ctx, msg);
            return;
        }

        final String text = (String) msg;
        // 企业级：限制 JSON 消息最大长度，防止超大 payload 导致 GC 压力
        int maxLen = nettyProperties != null ? nettyProperties.getMaxJsonMessageLength() : 256 * 1024;
        if (text.length() > maxLen) {
            sendJsonClose(ctx, "PAYLOAD_TOO_LARGE", 413,
                i18n("ws.biz.payload_too_large", "Message payload exceeds maximum size ({0} bytes)", maxLen));
            ctx.close();
            return;
        }

        JSONObject json;
        try {
            json = JSONUtil.parseObj(text);
        } catch (Exception e) {
            sendJsonClose(ctx, "JSON_PARSE_ERROR", 400,
                i18n("ws.biz.json_parse_error", "Invalid request format: unable to parse JSON"));
            ctx.close();
            return;
        }

        JSONObject headerJson = json.getJSONObject("header");
        if (headerJson == null) {
            sendJsonClose(ctx, "ENVELOPE_INVALID", 400, i18n("ws.biz.header_missing", "Invalid request format: missing header"));
            ctx.close();
            return;
        }

        Integer messageTypeValue = headerJson.getInt("messageType");
        if (messageTypeValue == null) {
            sendJsonClose(ctx, "ENVELOPE_INVALID", 400,
                i18n("ws.biz.header_message_type_missing", "Invalid request format: missing header.messageType"));
            ctx.close();
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
        if (messageTypeValue < MessageType.TEXT_VALUE) {
            super.channelRead(ctx, msg);
            return;
        }

        if (headerJson.get("messageId") == null) {
            sendJsonClose(ctx, "ENVELOPE_INVALID", 400,
                i18n("ws.biz.header_message_id_missing", "Invalid request format: missing header.messageId"));
            ctx.close();
            return;
        }
        long messageIdParsed = readLong(headerJson, "messageId", -1L);
        if (messageIdParsed <= 0L) {
            sendJsonClose(ctx, "ENVELOPE_INVALID", 400,
                i18n("ws.biz.header_message_id_invalid", "Invalid request format: header.messageId is invalid"));
            ctx.close();
            return;
        }

        if (headerJson.get("timestamp") == null) {
            sendJsonClose(ctx, "ENVELOPE_INVALID", 400,
                i18n("ws.biz.header_timestamp_missing", "Invalid request format: missing header.timestamp"));
            ctx.close();
            return;
        }
        long ts = readLong(headerJson, "timestamp", -1L);
        if (ts <= 0L) {
            sendJsonClose(ctx, "ENVELOPE_INVALID", 400,
                i18n("ws.biz.header_timestamp_invalid", "Invalid request format: header.timestamp is invalid"));
            ctx.close();
            return;
        }

        // 业务消息视为业务活跃
        sessionManager.updateLastBizActiveTime(ctx.channel());

        // 等保三级：消息签名验证（可配置，开发环境默认关闭）
        if (Boolean.TRUE.equals(nettyProperties.getMessageSignatureEnabled())) {
            String sessionKey = AuthHandler.getSessionKey(ctx);
            if (sessionKey != null) {
                // JSON 消息签名验证：对原始 JSON 文本进行签名校验
                // 客户端需要在消息末尾附加 32 字节签名（Base64 编码，64 字符）
                // 格式: {"header":...,"body":...,"signature":"<base64_signature>"}
                if (!verifyJsonSignature(ctx, json, sessionKey)) {
                    return;
                }
            }
        }

        try {
            Object bodyObj = json.get("body");
            if (messageTypeValue == MessageType.TEXT_VALUE) {
                JSONObject bodyJson = null;
                if (bodyObj instanceof JSONObject) {
                    bodyJson = (JSONObject) bodyObj;
                } else if (bodyObj != null) {
                    try {
                        bodyJson = JSONUtil.parseObj(bodyObj);
                    } catch (Exception ignore) {
                    }
                }
                String content = bodyJson != null ? bodyJson.getStr("content", "") : "";
                if (content == null || content.trim().isEmpty()) {
                    sendJsonClose(ctx, "ENVELOPE_INVALID", 400,
                        i18n("ws.biz.text_content_required", "Invalid request format: TEXT.content must not be empty"));
                    ctx.close();
                    return;
                }
            }
            if (messageTypeValue == MessageType.VOICE_VALUE) {
                JSONObject bodyJson = null;
                if (bodyObj instanceof JSONObject) {
                    bodyJson = (JSONObject) bodyObj;
                } else if (bodyObj != null) {
                    try {
                        bodyJson = JSONUtil.parseObj(bodyObj);
                    } catch (Exception ignore) {
                        bodyJson = null;
                    }
                }
                String voiceError = VoiceMessageValidationSupport.validate(
                        headerJson.getStr("extra", ""),
                        bodyJson != null ? bodyJson.getInt("duration", 0) : 0,
                        bodyJson != null ? bodyJson.getLong("size", 0L) : 0L
                );
                if (voiceError != null) {
                    sendJsonClose(ctx, "VOICE_INVALID", 400, voiceError);
                    ctx.close();
                    return;
                }
            }

            ImMessage imMessage = buildImMessageFromJson(ctx, headerJson, bodyObj);
            MessageType messageType = imMessage.getHeader().getMessageType();

            if (messageType == null || messageType == MessageType.UNKNOWN) {
                sendJsonClose(ctx, "UNSUPPORTED_MESSAGE_TYPE", 400,
                    i18n("ws.biz.unsupported_message_type", "Unsupported messageType: {0}", messageTypeValue));
                ctx.close();
                return;
            }

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
            sendJsonBusinessError(ctx, headerJson, e);
        }
    }

    private void sendJsonBusinessError(ChannelHandlerContext ctx, JSONObject headerJson, Exception e) {
        try {
            long senderId = AuthHandler.getUserId(ctx) != null ? AuthHandler.getUserId(ctx) : readLong(headerJson, "senderId", 0L);
            long receiverId = readLong(headerJson, "receiverId", 0L);
            long groupId = readLong(headerJson, "groupId", 0L);
            long tenantId = AuthHandler.getTenantId(ctx) != null ? AuthHandler.getTenantId(ctx) : readLong(headerJson, "tenantId", 0L);
            long messageId = readLong(headerJson, "messageId", System.currentTimeMillis());
            String reasonType = "message_send_failed";
            String reasonMessage = i18n("error.code.1002030101", "Message send failed");
            Integer reasonCode = null;
            if (e instanceof ServiceException) {
                ServiceException se = (ServiceException) e;
                reasonCode = se.getCode();
                reasonMessage = StrUtil.blankToDefault(se.getMessage(), reasonMessage);
                reasonType = "message_send_denied";
            }
            JSONObject extra = JSONUtil.createObj()
                    .set("action", reasonType)
                    .set("messageId", String.valueOf(messageId))
                    .set("code", reasonCode)
                    .set("message", reasonMessage);
            JSONObject payload = JSONUtil.createObj()
                    .set("header", JSONUtil.createObj()
                            .set("messageId", System.currentTimeMillis())
                            .set("messageType", MessageType.SYSTEM_NOTIFY_VALUE)
                            .set("senderId", 0L)
                            .set("receiverId", senderId)
                            .set("groupId", groupId)
                            .set("tenantId", tenantId)
                            .set("timestamp", System.currentTimeMillis())
                            .set("sequence", 0L)
                            .set("extra", extra.toString()))
                    .set("body", JSONUtil.createObj().set("content", "MESSAGE_SEND_DENIED"));
            ctx.writeAndFlush(new TextWebSocketFrame(payload.toString()));
        } catch (Exception notifyEx) {
            log.warn("[JsonBusiness] send business error notify failed", notifyEx);
        }
    }

    private void sendJsonClose(ChannelHandlerContext ctx, String action, int code, String message) {
        try {
            JSONObject payload = JSONUtil.createObj()
                .set("header", JSONUtil.createObj()
                    .set("messageId", System.currentTimeMillis())
                    .set("messageType", MessageType.CLOSE_VALUE)
                    .set("timestamp", System.currentTimeMillis()))
                .set("body", JSONUtil.createObj()
                    .set("action", action)
                    .set("code", code)
                    .set("message", message));
            ctx.writeAndFlush(new TextWebSocketFrame(payload.toString()));
        } catch (Exception ignore) {
        }
    }

    private String i18n(String key, String defaultMessage, Object... args) {
        return ServiceExceptionUtil.getOrDefault(key, defaultMessage, args);
    }

    /**
     * 验证 JSON 消息签名（等保三级数据完整性要求）
     * 客户端需在消息中添加 "signature" 字段（Base64 编码的 HMAC 签名）
     *
     * @param ctx        通道上下文
     * @param json       完整的 JSON 消息
     * @param sessionKey 会话密钥
     * @return 签名是否有效
     */
    private boolean verifyJsonSignature(ChannelHandlerContext ctx, JSONObject json, String sessionKey) {
        String signatureBase64 = json.getStr("signature");
        if (signatureBase64 == null || signatureBase64.isEmpty()) {
            log.warn("[MessageSignature] MISSING signature from userId={}, message dropped!",
                    AuthHandler.getUserId(ctx));
            sendJsonClose(ctx, "SIGNATURE_MISSING", 401,
                    i18n("ws.signature.missing", "Message signature is required"));
            ctx.close();
            return false;
        }

        try {
            // 提取签名前的原始数据：移除 signature 字段后的 JSON
            JSONObject dataJson = json.clone();
            dataJson.remove("signature");
            byte[] data = dataJson.toString().getBytes(java.nio.charset.StandardCharsets.UTF_8);
            byte[] expectedSignature = java.util.Base64.getDecoder().decode(signatureBase64);

            if (!MessageSignature.verify(data, sessionKey, expectedSignature)) {
                log.warn("[MessageSignature] INVALID signature from userId={}, message dropped!",
                        AuthHandler.getUserId(ctx));
                sendJsonClose(ctx, "SIGNATURE_INVALID", 401,
                        i18n("ws.signature.invalid", "Message signature verification failed"));
                ctx.close();
                return false;
            }

            if (log.isDebugEnabled()) {
                log.debug("[MessageSignature] signature verified for userId={}", AuthHandler.getUserId(ctx));
            }
            return true;
        } catch (Exception e) {
            log.warn("[MessageSignature] signature verification failed for userId={}",
                    AuthHandler.getUserId(ctx), e);
            sendJsonClose(ctx, "SIGNATURE_ERROR", 401,
                    i18n("ws.signature.error", "Message signature verification error"));
            ctx.close();
            return false;
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
                List<MentionUser> mentionUsers = new ArrayList<>();
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

					Object mentionsObj = bodyJson.get("mentions");
					if (mentionsObj instanceof JSONArray) {
						JSONArray arr = (JSONArray) mentionsObj;
						for (int i = 0; i < arr.size(); i++) {
							Object item = arr.get(i);
							if (item == null) {
								continue;
							}
							JSONObject m;
							try {
								m = item instanceof JSONObject ? (JSONObject) item : JSONUtil.parseObj(item);
							} catch (Exception ignore) {
								m = null;
							}
							if (m == null) {
								continue;
							}
							long userId = readLong(m, "userId", 0L);
							String nickname = m.getStr("nickname", "");
							int startIndex = m.getInt("startIndex", 0);
							int endIndex = m.getInt("endIndex", 0);
							MentionUser mu = MentionUser.newBuilder()
									.setUserId(userId)
									.setNickname(nickname != null ? nickname : "")
									.setStartIndex(startIndex)
									.setEndIndex(endIndex)
									.build();
							mentionUsers.add(mu);
						}
					}
                }
                TextMessage.Builder builder = TextMessage.newBuilder().setContent(content);
                if (!atUserIds.isEmpty()) {
                    builder.addAllAtUserIds(atUserIds);
                }
				if (!mentionUsers.isEmpty()) {
					builder.addAllMentions(mentionUsers);
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
                long quoteMessageId = readLong(bodyJson, "quoteMessageId", 0L);
                if (quoteMessageId <= 0L) {
                    quoteMessageId = readLong(bodyJson, "quotedMessageId", 0L);
                }
                String quoteContent = bodyJson.getStr("quoteContent", "");
                if (StrUtil.isBlank(quoteContent)) {
                    quoteContent = bodyJson.getStr("quotedContent", "");
                }
                long quoteSenderId = readLong(bodyJson, "quoteSenderId", 0L);
                String quoteSenderName = bodyJson.getStr("quoteSenderName", "");
                if (StrUtil.isBlank(quoteSenderName)) {
                    quoteSenderName = bodyJson.getStr("quotedSenderName", "");
                }
                String replyContent = bodyJson.getStr("replyContent", "");
                if (StrUtil.isBlank(replyContent)) {
                    replyContent = bodyJson.getStr("content", "");
                }
                QuoteReplyMessage.Builder builder = QuoteReplyMessage.newBuilder()
                        .setQuoteMessageId(quoteMessageId)
                        .setQuoteContent(quoteContent)
                        .setQuoteSenderId(quoteSenderId)
                        .setQuoteSenderName(quoteSenderName)
                        .setReplyContent(replyContent);

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

				Object mentionsObj = bodyJson.get("mentions");
				if (mentionsObj instanceof JSONArray) {
					JSONArray arr = (JSONArray) mentionsObj;
					List<MentionUser> mentionUsers = new ArrayList<>();
					for (int i = 0; i < arr.size(); i++) {
						Object item = arr.get(i);
						if (item == null) {
							continue;
						}
						JSONObject m;
						try {
							m = item instanceof JSONObject ? (JSONObject) item : JSONUtil.parseObj(item);
						} catch (Exception ignore) {
							m = null;
						}
						if (m == null) {
							continue;
						}
						long userId = readLong(m, "userId", 0L);
						String nickname = m.getStr("nickname", "");
						int startIndex = m.getInt("startIndex", 0);
						int endIndex = m.getInt("endIndex", 0);
						MentionUser mu = MentionUser.newBuilder()
								.setUserId(userId)
								.setNickname(nickname != null ? nickname : "")
								.setStartIndex(startIndex)
								.setEndIndex(endIndex)
								.build();
						mentionUsers.add(mu);
					}
					if (!mentionUsers.isEmpty()) {
						builder.addAllMentions(mentionUsers);
					}
				}

                return builder.build().toByteArray();
            }
            default:
                // 未覆盖的类型，尽量透传 JSON 字符串（便于排查）
                return bodyObj != null ? bodyObj.toString().getBytes() : new byte[0];
        }
    }
}
