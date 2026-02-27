package com.shengyu.framework.websocket.core.processor.impl;

import com.shengyu.framework.websocket.core.message.ImMessage;
import com.shengyu.framework.websocket.core.processor.MessageProcessor;
import com.shengyu.framework.websocket.core.sender.WebSocketMessageSender;
import com.shengyu.framework.websocket.core.session.WebSocketSession;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;

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
public class BadgeUpdateMessageProcessor implements MessageProcessor {

    @Resource
    private WebSocketMessageSender messageSender;

    /**
     * 消息类型：角标更新消息
     */
    private static final int MESSAGE_TYPE = 204;

    @Override
    public int getMessageType() {
        return MESSAGE_TYPE;
    }

    @Override
    public void process(WebSocketSession session, ImMessage message) {
        try {
            Long userId = message.getHeader().getReceiverId();
            
            if (userId == null || userId <= 0) {
                log.warn("[BadgeUpdateProcessor] 角标更新消息缺少接收者ID");
                return;
            }

            // 转发角标更新消息到目标用户的所有在线设备
            messageSender.sendToUser(userId, message);
            
            log.debug("[BadgeUpdateProcessor] 角标更新消息已转发, userId: {}", userId);

        } catch (Exception e) {
            log.error("[BadgeUpdateProcessor] 处理角标更新消息失败", e);
        }
    }

    @Override
    public boolean needStore() {
        // 角标更新消息不需要存储到数据库
        return false;
    }

    @Override
    public boolean needForward() {
        // 需要转发到接收者
        return true;
    }
}
