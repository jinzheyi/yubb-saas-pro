package com.shengyu.framework.websocket.core.processor.impl;

import com.shengyu.framework.websocket.core.processor.MessageProcessor;
import com.shengyu.framework.websocket.core.protocol.ImMessage;
import com.shengyu.framework.websocket.core.session.NettySession;
import com.shengyu.framework.websocket.core.session.NettySessionManager;
import io.netty.channel.ChannelHandlerContext;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * 角标更新消息处理器
 * 
 * 功能：
 * 1. 接收角标更新消息（messageType = 204）
 * 2. 转发角标更新到目标用户的所有在线设备
 * 3. 不存储到数据库（角标数据由 ImBadgeService 管理）
 * 
 * 【消息流程】
 * 1. ImBadgeService.pushBadgeUpdate() 发送角标更新消息
 * 2. BadgeUpdateMessageProcessor 接收并转发到用户所有设备
 * 3. 前端 BadgeService 接收并更新本地角标显示
 * 
 * 【角标更新消息格式】
 * {
 *   "userId": 123,
 *   "totalUnread": 10,
 *   "conversationBadges": [
 *     {"conversationId": 1, "unreadCount": 5},
 *     {"conversationId": 2, "unreadCount": 5}
 *   ],
 *   "menuBadges": [
 *     {"menuId": "todo", "count": 3}
 *   ]
 * }
 *
 * @author 圣钰科技
 */
@Component
@Slf4j
@RequiredArgsConstructor
public class BadgeUpdateMessageProcessor implements MessageProcessor {

    private final NettySessionManager sessionManager;

    @Override
    public void process(ChannelHandlerContext ctx, ImMessage message) {
        try {
            Long userId = message.getHeader().getReceiverId();
            
            if (userId == null || userId <= 0) {
                log.warn("[BadgeUpdateProcessor] 角标更新消息缺少接收者ID");
                return;
            }

            // 转发角标更新消息到目标用户的所有在线设备
            List<NettySession> sessions = sessionManager.getSessionsByUserId(userId);
            if (sessions.isEmpty()) {
                log.debug("[BadgeUpdateProcessor] 用户不在线, userId: {}", userId);
                return;
            }

            int successCount = 0;
            for (NettySession targetSession : sessions) {
                if (targetSession.isActive()) {
                    targetSession.getChannel().writeAndFlush(message);
                    targetSession.updateLastActiveTime();
                    successCount++;
                }
            }
            
            log.debug("[BadgeUpdateProcessor] 角标更新消息已转发, userId: {}, success: {}", 
                userId, successCount);

        } catch (Exception e) {
            log.error("[BadgeUpdateProcessor] 处理角标更新消息失败", e);
        }
    }
}
