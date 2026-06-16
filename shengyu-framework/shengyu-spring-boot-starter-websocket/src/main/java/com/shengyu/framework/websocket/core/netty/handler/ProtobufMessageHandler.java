package com.shengyu.framework.websocket.core.netty.handler;

import cn.hutool.json.JSONUtil;
import com.shengyu.framework.common.exception.ServiceException;
import com.shengyu.framework.common.exception.util.ServiceExceptionUtil;
import com.shengyu.framework.websocket.core.protocol.ImMessage;
import com.shengyu.framework.websocket.core.protocol.MessageHeader;
import com.shengyu.framework.websocket.core.protocol.MessageType;
import com.shengyu.framework.websocket.core.protocol.TextMessage;
import com.shengyu.framework.websocket.core.protocol.VoiceMessage;
import com.shengyu.framework.websocket.core.processor.MessageProcessor;
import com.shengyu.framework.websocket.core.processor.MessageProcessorFactory;
import com.shengyu.framework.tenant.core.util.TenantUtils;
import com.shengyu.framework.websocket.core.session.NettySessionManager;
import com.shengyu.framework.websocket.core.security.MessageSignature;
import com.google.protobuf.InvalidProtocolBufferException;
import io.netty.channel.ChannelHandler;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.SimpleChannelInboundHandler;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * Protobuf 消息处理器
 * 根据消息类型分发到不同的业务处理器
 *
 * @author 圣钰科技
 */
@Slf4j
@Component
@RequiredArgsConstructor
@ChannelHandler.Sharable  // 标记为可共享的Handler
public class ProtobufMessageHandler extends SimpleChannelInboundHandler<ImMessage> {

    private final MessageProcessorFactory processorFactory;

    private final NettySessionManager sessionManager;

    private final com.shengyu.framework.websocket.config.NettyProperties nettyProperties;

    @Override
    protected void channelRead0(ChannelHandlerContext ctx, ImMessage msg) {
        try {
            MessageType messageType = msg.getHeader().getMessageType();
            log.debug("[Protobuf] 收到消息, type: {}, messageId: {}, channel: {}", 
                messageType, msg.getHeader().getMessageId(), ctx.channel().id().asShortText());

            // 更新业务活跃时间：任何非系统消息都视为业务活跃
            if (messageType != null && messageType.getNumber() >= MessageType.TEXT_VALUE) {
                sessionManager.updateLastBizActiveTime(ctx.channel());
            }

            if (messageType == MessageType.VOICE) {
                String voiceError = validateVoiceEnvelope(msg);
                if (voiceError != null) {
                    log.warn("[Protobuf] reject invalid voice message, messageId={}, error={}",
                            msg.getHeader() != null ? msg.getHeader().getMessageId() : null, voiceError);
                    sendPbClose(ctx, "VOICE_INVALID", 400, voiceError);
                    ctx.close();
                    return;
                }
            }

            // 等保三级：消息签名验证（可配置，开发环境默认关闭）
            if (Boolean.TRUE.equals(nettyProperties.getMessageSignatureEnabled())) {
                String sessionKey = AuthHandler.getSessionKey(ctx);
                if (sessionKey != null) {
                    if (!verifyProtobufSignature(ctx, msg, sessionKey)) {
                        return;
                    }
                }
            }

            // 获取对应的消息处理器
            MessageProcessor processor = processorFactory.getProcessor(messageType);
            if (processor == null) {
                log.warn("[Protobuf] 未找到消息处理器, type: {}", messageType);
                return;
            }

            // 安全与一致性：Protobuf 入站 header 以认证会话为准，禁止端侧伪造 senderId/tenantId。
            // 典型症状：tenantId 不一致导致群成员查询为空，最终无法 fanout。
            Long authedUserId = null;
            Long authedTenantId = null;
            try {
                authedUserId = AuthHandler.getUserId(ctx);
            } catch (Exception ignore) {
                authedUserId = null;
            }
            try {
                authedTenantId = AuthHandler.getTenantId(ctx);
            } catch (Exception ignore) {
                authedTenantId = null;
            }

            ImMessage actualMsg = msg;
            boolean overridden = false;
            try {
                if (msg.getHeader() != null) {
                    long incomingSenderId = msg.getHeader().getSenderId();
                    long incomingTenantId = msg.getHeader().getTenantId();
                    long fixedSenderId = authedUserId != null && authedUserId > 0 ? authedUserId : incomingSenderId;
                    long fixedTenantId = authedTenantId != null && authedTenantId > 0 ? authedTenantId : incomingTenantId;

                    if (fixedSenderId != incomingSenderId || fixedTenantId != incomingTenantId) {
                        actualMsg = ImMessage.newBuilder(msg)
                                .setHeader(msg.getHeader().toBuilder()
                                        .setSenderId(fixedSenderId)
                                        .setTenantId(fixedTenantId)
                                        .build())
                                .build();
                        overridden = true;
                    }
                }
            } catch (Exception ignore) {
                actualMsg = msg;
                overridden = false;
            }

            Long tenantId = null;
            try {
                tenantId = actualMsg.getHeader().getTenantId();
                if (tenantId != null && tenantId <= 0) {
                    tenantId = null;
                }
            } catch (Exception ignore) {
                tenantId = null;
            }
            if (tenantId == null) {
                tenantId = authedTenantId;
            }

            if (overridden && log.isInfoEnabled()) {
                log.info("[Protobuf] override inbound header by auth: messageId={}, type={}, incomingSenderId={}, authedUserId={}, incomingTenantId={}, authedTenantId={}, channel={}",
                        msg.getHeader() != null ? msg.getHeader().getMessageId() : null,
                        messageType,
                        msg.getHeader() != null ? msg.getHeader().getSenderId() : null,
                        authedUserId,
                        msg.getHeader() != null ? msg.getHeader().getTenantId() : null,
                        authedTenantId,
                        ctx.channel().id().asShortText());
            }

            // 处理消息（在 Netty 线程中显式绑定 TenantContextHolder，避免 MyBatis 租户拦截器 NPE）
            final Long finalTenantId = tenantId;
            final ImMessage finalMsg = actualMsg;
            TenantUtils.execute(finalTenantId, () -> processor.process(ctx, finalMsg));
            
        } catch (Exception e) {
            log.error("[Protobuf] 消息处理异常", e);
            sendPbBusinessError(ctx, msg, e);
        }
    }

    private void sendPbBusinessError(ChannelHandlerContext ctx, ImMessage inbound, Exception e) {
        try {
            MessageHeader inboundHeader = inbound != null ? inbound.getHeader() : null;
            long senderId = AuthHandler.getUserId(ctx) != null
                    ? AuthHandler.getUserId(ctx)
                    : (inboundHeader != null ? inboundHeader.getSenderId() : 0L);
            long receiverId = inboundHeader != null ? inboundHeader.getReceiverId() : 0L;
            long groupId = inboundHeader != null ? inboundHeader.getGroupId() : 0L;
            long tenantId = AuthHandler.getTenantId(ctx) != null
                    ? AuthHandler.getTenantId(ctx)
                    : (inboundHeader != null ? inboundHeader.getTenantId() : 0L);
            long messageId = inboundHeader != null ? inboundHeader.getMessageId() : System.currentTimeMillis();

            String action = "message_send_failed";
            String reasonMessage = "消息发送失败";
            Integer reasonCode = null;
            if (e instanceof ServiceException) {
                ServiceException se = (ServiceException) e;
                action = "message_send_denied";
                reasonCode = se.getCode();
                reasonMessage = se.getMessage();
            }

            MessageHeader header = MessageHeader.newBuilder()
                    .setMessageId(System.currentTimeMillis())
                    .setMessageType(MessageType.SYSTEM_NOTIFY)
                    .setSenderId(0L)
                    .setReceiverId(senderId)
                    .setGroupId(groupId)
                    .setTenantId(tenantId)
                    .setTimestamp(System.currentTimeMillis())
                    .setExtra(JSONUtil.createObj()
                            .set("action", action)
                            .set("messageId", String.valueOf(messageId))
                            .set("code", reasonCode)
                            .set("message", reasonMessage)
                            .toString())
                    .build();
            TextMessage body = TextMessage.newBuilder().setContent("MESSAGE_SEND_DENIED").build();
            ImMessage notify = ImMessage.newBuilder()
                    .setHeader(header)
                    .setBody(body.toByteString())
                    .build();
            ctx.writeAndFlush(notify);
        } catch (Exception notifyEx) {
            log.warn("[Protobuf] send business error notify failed", notifyEx);
        }
    }

    private String validateVoiceEnvelope(ImMessage msg) {
        if (msg == null || msg.getHeader() == null) {
            return i18n("ws.biz.voice_header_missing", "Invalid request format: missing VOICE.header");
        }
        try {
            VoiceMessage voiceMessage = VoiceMessage.parseFrom(msg.getBody());
            return VoiceMessageValidationSupport.validate(
                    msg.getHeader().getExtra(),
                    voiceMessage.getDuration(),
                    voiceMessage.getSize()
            );
        } catch (InvalidProtocolBufferException ex) {
            return i18n("ws.biz.voice_body_invalid", "Invalid request format: failed to parse VOICE.body");
        }
    }

    private void sendPbClose(ChannelHandlerContext ctx, String action, int code, String message) {
        try {
            MessageHeader header = MessageHeader.newBuilder()
                    .setMessageId(System.currentTimeMillis())
                    .setMessageType(MessageType.CLOSE)
                    .setTimestamp(System.currentTimeMillis())
                    .setExtra(JSONUtil.createObj()
                            .set("code", code)
                            .set("message", message)
                            .set("action", action)
                            .toString())
                    .build();
            ImMessage close = ImMessage.newBuilder().setHeader(header).build();
            ctx.writeAndFlush(close);
        } catch (Exception ignore) {
        }
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) {
        log.error("[Protobuf] 异常: {}", ctx.channel().id().asShortText(), cause);
        ctx.close();
    }

    private String i18n(String key, String defaultMessage, Object... args) {
        return ServiceExceptionUtil.getOrDefault(key, defaultMessage, args);
    }

    /**
     * 验证 Protobuf 消息签名（等保三级数据完整性要求）
     * 客户端需在 header.extra 中添加 JSON 格式的 signature 字段
     *
     * @param ctx        通道上下文
     * @param msg        Protobuf 消息
     * @param sessionKey 会话密钥
     * @return 签名是否有效
     */
    private boolean verifyProtobufSignature(ChannelHandlerContext ctx, ImMessage msg, String sessionKey) {
        MessageHeader header = msg.getHeader();
        if (header == null) {
            log.warn("[MessageSignature] MISSING header from userId={}", AuthHandler.getUserId(ctx));
            sendPbClose(ctx, "SIGNATURE_MISSING", 401,
                    i18n("ws.signature.missing", "Message signature is required"));
            ctx.close();
            return false;
        }

        String extra = header.getExtra();
        if (extra == null || extra.isEmpty()) {
            log.warn("[MessageSignature] MISSING signature (extra empty) from userId={}", AuthHandler.getUserId(ctx));
            sendPbClose(ctx, "SIGNATURE_MISSING", 401,
                    i18n("ws.signature.missing", "Message signature is required"));
            ctx.close();
            return false;
        }

        try {
            cn.hutool.json.JSONObject extraJson = JSONUtil.parseObj(extra);
            String signatureBase64 = extraJson.getStr("signature");
            if (signatureBase64 == null || signatureBase64.isEmpty()) {
                log.warn("[MessageSignature] MISSING signature field in extra from userId={}",
                        AuthHandler.getUserId(ctx));
                sendPbClose(ctx, "SIGNATURE_MISSING", 401,
                        i18n("ws.signature.missing", "Message signature is required"));
                ctx.close();
                return false;
            }

            // 提取签名数据：header（不含 signature）+ body
            MessageHeader signableHeader = header.toBuilder().clearExtra().build();
            byte[] headerBytes = signableHeader.toByteArray();
            byte[] bodyBytes = msg.getBody().toByteArray();
            byte[] data = new byte[headerBytes.length + bodyBytes.length];
            System.arraycopy(headerBytes, 0, data, 0, headerBytes.length);
            System.arraycopy(bodyBytes, 0, data, headerBytes.length, bodyBytes.length);

            byte[] expectedSignature = java.util.Base64.getDecoder().decode(signatureBase64);

            if (!MessageSignature.verify(data, sessionKey, expectedSignature)) {
                log.warn("[MessageSignature] INVALID signature from userId={}, message dropped!",
                        AuthHandler.getUserId(ctx));
                sendPbClose(ctx, "SIGNATURE_INVALID", 401,
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
            sendPbClose(ctx, "SIGNATURE_ERROR", 401,
                    i18n("ws.signature.error", "Message signature verification error"));
            ctx.close();
            return false;
        }
    }
}
