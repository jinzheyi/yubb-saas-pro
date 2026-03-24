package com.shengyu.framework.websocket.core.processor.impl;

import com.shengyu.framework.websocket.core.processor.MessageProcessor;
import com.shengyu.framework.websocket.core.protocol.ImMessage;
import com.shengyu.framework.websocket.core.protocol.MessageHeader;
import com.shengyu.framework.websocket.core.protocol.TextMessage;
import com.shengyu.framework.websocket.core.sender.NettyMessageSender;
import com.shengyu.framework.websocket.core.service.MessageStorageService;
import com.shengyu.framework.websocket.core.service.dto.MessageSaveResult;
import com.shengyu.framework.websocket.core.service.SensitiveWordFilterService;
import com.shengyu.framework.websocket.core.session.NettySession;
import com.shengyu.framework.websocket.core.session.NettySessionManager;
import com.google.protobuf.InvalidProtocolBufferException;
import io.netty.channel.ChannelHandlerContext;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

/**
 * 文本消息处理器
 * 
 * 功能：
 * 1. 解析文本消息
 * 2. 敏感词过滤（可选）
 * 3. 存储消息到数据库
 * 4. 转发消息到接收者
 *
 * @author 圣钰科技
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class TextMessageProcessor implements MessageProcessor {

    private final NettySessionManager sessionManager;
    private final MessageStorageService messageStorageService;
    private final NettyMessageSender messageSender;
    private SensitiveWordFilterService sensitiveWordFilterService;

    @Autowired(required = false)
    public void setSensitiveWordFilterService(SensitiveWordFilterService sensitiveWordFilterService) {
        this.sensitiveWordFilterService = sensitiveWordFilterService;
    }

    @Override
    public void process(ChannelHandlerContext ctx, ImMessage message) {
        try {
            MessageHeader inHeader = message.getHeader();
            if (log.isInfoEnabled()) {
                log.info("[TextMessage] process enter: messageId={}, messageType={}, senderId={}, receiverId={}, groupId={}, tenantId={}, channelId={}",
                        inHeader.getMessageId(), inHeader.getMessageType(), inHeader.getSenderId(), inHeader.getReceiverId(), inHeader.getGroupId(), inHeader.getTenantId(),
                        ctx != null && ctx.channel() != null ? ctx.channel().id() : null);
            }

            if (ctx == null || ctx.channel() == null) {
                log.warn("[TextMessage] ctx/channel is null, skip process. messageId={}", inHeader.getMessageId());
                return;
            }

            // 解析文本消息
            TextMessage textMessage = TextMessage.parseFrom(message.getBody());
            String originalContent = textMessage.getContent();
            
            // 获取发送者会话
            NettySession senderSession = sessionManager.getSession(ctx.channel());
            if (senderSession == null) {
                log.warn("[TextMessage] 发送者会话不存在");
                return;
            }

            if (log.isInfoEnabled()) {
                log.info("[TextMessage] senderSession: userId={}, deviceType={}, active={}",
                        senderSession.getUserId(), senderSession.getDeviceType(), senderSession.isActive());
            }

            log.info("[TextMessage] 收到文本消息, from: {}, to: {}, group: {}, content: {}", 
                message.getHeader().getSenderId(),
                message.getHeader().getReceiverId(),
                message.getHeader().getGroupId(),
                originalContent);

            // 1. 敏感词过滤（如果服务可用）
            String filteredContent = originalContent;
            if (sensitiveWordFilterService != null) {
                filteredContent = sensitiveWordFilterService.filter(originalContent);
                if (!filteredContent.equals(originalContent)) {
                    log.info("[TextMessage] 敏感词过滤: userId={}, 原内容长度={}, 过滤后长度={}", 
                        message.getHeader().getSenderId(), 
                        originalContent.length(), 
                        filteredContent.length());
                    
                    // 重新构建消息（使用过滤后的内容）
                    TextMessage filteredTextMessage = TextMessage.newBuilder()
                        .setContent(filteredContent)
                        .addAllAtUserIds(textMessage.getAtUserIdsList())
                        .addAllMentions(textMessage.getMentionsList())
                        .build();
                    
                    message = ImMessage.newBuilder()
                        .setHeader(message.getHeader())
                        .setBody(filteredTextMessage.toByteString())
                        .build();

                    // ensure ack/forward use the final body
                    textMessage = filteredTextMessage;
                }
            }

            // 2. 存储消息到数据库
            if (log.isInfoEnabled()) {
                MessageHeader h = message.getHeader();
                log.info("[TextMessage] saveMessage begin: messageId={}, senderId={}, receiverId={}, groupId={}, tenantId={}",
                        h.getMessageId(), h.getSenderId(), h.getReceiverId(), h.getGroupId(), h.getTenantId());
            }
            MessageSaveResult saveResult = messageStorageService.saveMessageWithResult(message);
            if (log.isInfoEnabled()) {
                log.info("[TextMessage] saveMessage done: messageId={}", message.getHeader().getMessageId());
            }
            if (saveResult == null || saveResult.getMessageId() == null || saveResult.getChatId() == null) {
                log.error("[TextMessage] 消息未持久化，跳过回推与转发。messageId={}, saveResult={}",
                        message.getHeader().getMessageId(), saveResult);
                return;
            }

            // 2.1 回推给发送者（用于端侧把 SENDING -> SENT，避免仅本地乐观渲染）
            MessageHeader ackHeader = message.getHeader();
            messageSender.sendToUser(
                    ackHeader.getSenderId(),
                    ackHeader.getMessageType(),
                    textMessage,
                    ackHeader.getSenderId(),
                    ackHeader.getReceiverId(),
                    ackHeader.getGroupId() > 0 ? ackHeader.getGroupId() : null,
                    ackHeader.getTenantId(),
                    ackHeader.getMessageId(),
                    saveResult != null ? saveResult.getSequence() : null,
                    saveResult != null ? saveResult.getChatId() : null
            );

            // 3. 转发消息
            Long receiverId = message.getHeader().getReceiverId();
            Long groupId = message.getHeader().getGroupId();

            if (receiverId != null && receiverId > 0) {
                // 单聊：转发给接收者的所有在线设备
                MessageHeader header = message.getHeader();

                if (log.isInfoEnabled()) {
                    log.info("[TextMessage] forward(single) begin: messageId={}, from={}, to={}, groupId={}, tenantId={}",
                            header.getMessageId(), header.getSenderId(), receiverId, groupId, header.getTenantId());
                }
                messageSender.sendToUser(
                        receiverId,
                        header.getMessageType(),
                        textMessage,
                        header.getSenderId(),
                        receiverId,
                        groupId != null && groupId > 0 ? groupId : null,
                        header.getTenantId(),
                        header.getMessageId(),
                        saveResult != null ? saveResult.getSequence() : null,
                        saveResult != null ? saveResult.getChatId() : null
                );

                if (log.isInfoEnabled()) {
                    log.info("[TextMessage] forward(single) called sender: messageId={}, to={}", header.getMessageId(), receiverId);
                }
            } else if (groupId != null && groupId > 0) {
                // 群聊：转发给群成员的所有在线设备（由中间件的消息总线处理）
                // 注意：这里只是示例，实际群聊需要查询群成员列表
                // 在分布式环境下，消息总线会自动转发到其他节点
                log.debug("[TextMessage] 群聊消息，groupId: {}, 由消息总线处理转发", groupId);
                // TODO: 查询群成员列表并转发（可选，也可以在 SystemMessageStorageServiceImpl 中处理）
            } else {
                MessageHeader header = message.getHeader();
                log.warn("[TextMessage] no forward target: messageId={}, receiverId={}, groupId={}, senderId={}, tenantId={}",
                        header.getMessageId(), receiverId, groupId, header.getSenderId(), header.getTenantId());
            }

            // 4. 如果接收者离线，推送离线通知
            // TODO: 实现离线推送逻辑

        } catch (InvalidProtocolBufferException e) {
            log.error("[TextMessage] 解析消息失败", e);
        }
    }

    /**
     * 转发消息给指定用户的所有在线设备
     */
    private void forwardToUser(Long userId, ImMessage message) {
        sessionManager.getSessionsByUserId(userId).forEach(session -> {
            if (session.isActive()) {
                session.getChannel().writeAndFlush(message);
                session.updateLastActiveTime();
                log.debug("[TextMessage] 转发消息给用户: {}, 设备类型: {}", 
                    userId, session.getDeviceType());
            }
        });
    }
}
