package com.shengyu.framework.websocket.core.mq.consumer;

import com.shengyu.framework.mq.redis.core.pubsub.AbstractRedisChannelMessageListener;
import com.shengyu.framework.websocket.core.mq.message.CrossNodeKickMessage;
import com.shengyu.framework.websocket.core.session.NettySession;
import com.shengyu.framework.websocket.core.session.NettySessionManager;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;

/**
 * 跨节点互踢消息消费者（Redis Pub/Sub）
 *
 * 用途：当新设备在节点 B 登录时，广播互踢消息，
 * 让节点 A 上的同类型旧设备被踢掉。
 *
 * @author 圣钰科技
 */
@Slf4j
@Component
public class CrossNodeKickConsumer extends AbstractRedisChannelMessageListener<CrossNodeKickMessage> {

    @Resource
    private NettySessionManager sessionManager;

    @Override
    public void onMessage(CrossNodeKickMessage message) {
        if (message == null || message.getUserId() == null || message.getDeviceType() == null) {
            return;
        }

        Long userId = message.getUserId();
        Integer deviceType = message.getDeviceType();
        String byDevice = message.getByDevice();

        log.info("[CrossNodeKickConsumer] 收到跨节点互踢消息, userId: {}, deviceType: {}, byDevice: {}",
                userId, deviceType, byDevice);

        // 检查本节点是否有该用户同类型设备
        NettySession oldSession = sessionManager.getSessionByUserIdAndDeviceType(userId, deviceType);
        if (oldSession == null || !oldSession.isActive()) {
            log.debug("[CrossNodeKickConsumer] 本节点没有该用户同类型设备, userId: {}, deviceType: {}",
                    userId, deviceType);
            return;
        }

        // 踢掉旧设备
        log.info("[CrossNodeKickConsumer] 踢掉旧设备, userId: {}, deviceType: {}, byDevice: {}",
                userId, deviceType, byDevice);
        sessionManager.kickDevice(userId, deviceType, byDevice);
    }

}
