package com.shengyu.framework.websocket.core.processor.impl;

import com.google.protobuf.InvalidProtocolBufferException;
import com.shengyu.framework.websocket.core.processor.MessageProcessor;
import com.shengyu.framework.websocket.core.protocol.ImMessage;
import com.shengyu.framework.websocket.core.protocol.MessageHeader;
import com.shengyu.framework.websocket.core.protocol.QuoteReplyMessage;
import com.shengyu.framework.websocket.core.sender.NettyMessageSender;
import com.shengyu.framework.websocket.core.service.MessageStorageService;
import com.shengyu.framework.websocket.core.service.dto.MessageSaveResult;
import com.shengyu.framework.websocket.core.session.NettySession;
import com.shengyu.framework.websocket.core.session.NettySessionManager;
import io.netty.channel.ChannelHandlerContext;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * 引用回复消息处理器
 *
 * 功能：
 * 1. 解析引用回复消息
 * 2. 存储消息到数据库
 * 3. 回推给发送者（用于端侧把 SENDING -> SENT）
 * 4. 单聊转发给接收者
 *
 * 说明：
 * - 群聊转发由业务侧（SystemMessageStorageServiceImpl/消息总线）处理。
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class QuoteReplyMessageProcessor implements MessageProcessor {

    private final NettySessionManager sessionManager;
    private final MessageStorageService messageStorageService;
    private final NettyMessageSender messageSender;

    @Override
    public void process(ChannelHandlerContext ctx, ImMessage message) {
        try {
            MessageHeader inHeader = message.getHeader();
            if (ctx == null || ctx.channel() == null) {
                log.warn("[QuoteReplyMessage] ctx/channel is null, skip process. messageId={}", inHeader != null ? inHeader.getMessageId() : null);
                return;
            }

            // 解析引用回复消息
            QuoteReplyMessage quoteMessage = QuoteReplyMessage.parseFrom(message.getBody());

            // 获取发送者会话
            NettySession senderSession = sessionManager.getSession(ctx.channel());
            if (senderSession == null) {
                log.warn("[QuoteReplyMessage] 发送者会话不存在");
                return;
            }

            if (log.isInfoEnabled()) {
                log.info("[QuoteReplyMessage] 收到引用回复, messageId={}, from={}, to={}, groupId={}, quotedMessageId={}, replyContent={}",
                        inHeader.getMessageId(),
                        inHeader.getSenderId(),
                        inHeader.getReceiverId(),
                        inHeader.getGroupId(),
                        quoteMessage.getQuoteMessageId(),
                        quoteMessage.getReplyContent());
            }

            // 存储消息到数据库
            MessageSaveResult saveResult = messageStorageService.saveMessageWithResult(message);
            if (saveResult == null || saveResult.getMessageId() == null || saveResult.getChatId() == null) {
                log.error("[QuoteReplyMessage] 消息未持久化，跳过回推。messageId={}, saveResult={}", inHeader.getMessageId(), saveResult);
                return;
            }

            // 回推给发送者（用于端侧更新状态）
            messageSender.sendToUser(
                    inHeader.getSenderId(),
                    inHeader.getMessageType(),
                    quoteMessage,
                    inHeader.getSenderId(),
                    inHeader.getReceiverId(),
                    inHeader.getGroupId() > 0 ? inHeader.getGroupId() : null,
                    inHeader.getTenantId(),
                    inHeader.getMessageId(),
                    saveResult != null ? saveResult.getSequence() : null,
                    saveResult != null ? saveResult.getChatId() : null
            );

            // 转发消息（单聊）
            Long receiverId = inHeader.getReceiverId();
            Long groupId = inHeader.getGroupId();
            if (receiverId != null && receiverId > 0) {
                messageSender.sendToUser(
                        receiverId,
                        inHeader.getMessageType(),
                        quoteMessage,
                        inHeader.getSenderId(),
                        receiverId,
                        groupId != null && groupId > 0 ? groupId : null,
                        inHeader.getTenantId(),
                        inHeader.getMessageId(),
                        saveResult != null ? saveResult.getSequence() : null,
                        saveResult != null ? saveResult.getChatId() : null
                );
            } else if (groupId != null && groupId > 0) {
                log.debug("[QuoteReplyMessage] 群聊消息，groupId: {}, 由消息总线处理转发", groupId);
            } else {
                log.warn("[QuoteReplyMessage] no forward target: messageId={}, receiverId={}, groupId={}",
                        inHeader.getMessageId(), receiverId, groupId);
            }

        } catch (InvalidProtocolBufferException e) {
            log.error("[QuoteReplyMessage] 解析消息失败", e);
        } catch (Exception e) {
            log.error("[QuoteReplyMessage] 处理消息异常", e);
            throw new RuntimeException(e);
        }
    }
}
