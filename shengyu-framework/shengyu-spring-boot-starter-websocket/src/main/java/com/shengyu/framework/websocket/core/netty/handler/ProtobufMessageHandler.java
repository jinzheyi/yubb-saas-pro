package com.shengyu.framework.websocket.core.netty.handler;

import com.shengyu.framework.websocket.core.protocol.ImMessage;
import com.shengyu.framework.websocket.core.protocol.MessageType;
import com.shengyu.framework.websocket.core.processor.MessageProcessor;
import com.shengyu.framework.websocket.core.processor.MessageProcessorFactory;
import com.shengyu.framework.tenant.core.util.TenantUtils;
import com.shengyu.framework.websocket.core.session.NettySessionManager;
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
        }
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) {
        log.error("[Protobuf] 异常: {}", ctx.channel().id().asShortText(), cause);
        ctx.close();
    }
}
