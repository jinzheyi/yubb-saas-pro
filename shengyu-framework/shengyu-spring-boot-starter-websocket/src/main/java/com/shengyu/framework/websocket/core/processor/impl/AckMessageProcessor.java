package com.shengyu.framework.websocket.core.processor.impl;

import com.google.common.cache.Cache;
import com.google.common.cache.CacheBuilder;
import com.shengyu.framework.websocket.core.processor.MessageProcessor;
import com.shengyu.framework.websocket.core.protocol.AckMessage;
import com.shengyu.framework.websocket.core.protocol.ImMessage;
import com.shengyu.framework.websocket.core.protocol.MessageHeader;
import com.shengyu.framework.websocket.core.protocol.MessageType;
import com.shengyu.framework.websocket.core.session.NettySession;
import com.shengyu.framework.websocket.core.session.NettySessionManager;
import io.netty.channel.ChannelHandlerContext;
import java.util.concurrent.TimeUnit;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@RequiredArgsConstructor
public class AckMessageProcessor implements MessageProcessor {

    private final NettySessionManager sessionManager;

    private final Cache<String, Boolean> dedupCache = CacheBuilder.newBuilder()
            .expireAfterWrite(10, TimeUnit.MINUTES)
            .maximumSize(1_000_000)
            .build();

    @Override
    public void process(ChannelHandlerContext ctx, ImMessage message) {
        try {
            if (ctx == null || ctx.channel() == null) {
                return;
            }

            MessageHeader header = message.getHeader();
            if (header == null || header.getMessageType() != MessageType.ACK) {
                return;
            }

            NettySession session = sessionManager.getSession(ctx.channel());
            Long userId = session != null ? session.getUserId() : null;
            Long tenantId = session != null ? session.getTenantId() : null;

            AckMessage ack;
            try {
                ack = AckMessage.parseFrom(message.getBody());
            } catch (Exception e) {
                log.warn("[ACK] parse body failed, channel={}, err={}", ctx.channel().id().asShortText(), e.toString());
                return;
            }

            String ackType = ack.getAckType();
            long ackMessageId = ack.getMessageId();
            String dedupKey = String.valueOf(tenantId) + ":" + String.valueOf(userId) + ":" + ackType + ":" + ackMessageId;

            if (dedupCache.getIfPresent(dedupKey) != null) {
                if (log.isDebugEnabled()) {
                    log.debug("[ACK] dedup hit: key={}, channel={}", dedupKey, ctx.channel().id().asShortText());
                }
                return;
            }
            dedupCache.put(dedupKey, Boolean.TRUE);

            if (log.isInfoEnabled()) {
                log.info("[ACK] received: tenantId={}, userId={}, ackType={}, messageId={}, chatId={}, sequence={}, clientReceivedAt={}, originalTimestamp={}",
                        tenantId,
                        userId,
                        ackType,
                        ackMessageId,
                        ack.getChatId(),
                        ack.getSequence(),
                        ack.getClientReceivedAt(),
                        ack.getOriginalTimestamp());
            }

        } catch (Exception e) {
            log.error("[ACK] process failed", e);
        }
    }
}
