package com.shengyu.framework.websocket.core.service.impl;

import com.shengyu.framework.websocket.core.protocol.ImMessage;
import com.shengyu.framework.websocket.core.service.MessageStorageService;
import lombok.extern.slf4j.Slf4j;

/**
 * 消息存储服务空实现（NoOp）
 * 
 * 说明：
 * 1. 这是一个默认的空实现，不做任何实际存储操作
 * 2. 当业务模块没有提供实现时，使用此默认实现
 * 3. 只打印日志，不会影响中间件的核心功能（连接管理、消息路由）
 * 4. 业务模块应该提供自己的实现来替换此默认实现
 * 
 * 使用场景：
 * - 开发测试阶段，业务模块还未实现存储逻辑
 * - 某些场景不需要持久化消息（如纯实时通讯）
 *
 * @author 圣钰科技
 */
@Slf4j
public class NoOpMessageStorageServiceImpl implements MessageStorageService {

    @Override
    public void saveMessage(ImMessage message) {
        log.debug("[NoOpMessageStorage] 消息未持久化（使用空实现）: messageId={}, type={}, senderId={}, receiverId={}",
            message.getHeader().getMessageId(),
            message.getHeader().getMessageType(),
            message.getHeader().getSenderId(),
            message.getHeader().getReceiverId());
    }

    @Override
    public Long saveMessageWithId(ImMessage message) {
        saveMessage(message);
        return message.getHeader().getMessageId();
    }
}
