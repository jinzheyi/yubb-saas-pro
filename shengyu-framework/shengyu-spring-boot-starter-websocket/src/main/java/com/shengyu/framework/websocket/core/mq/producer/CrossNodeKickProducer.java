package com.shengyu.framework.websocket.core.mq.producer;

import com.shengyu.framework.mq.redis.core.RedisMQTemplate;
import com.shengyu.framework.websocket.core.mq.message.CrossNodeKickMessage;
import com.shengyu.framework.websocket.core.session.CrossNodeKickPublisher;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;

/**
 * 跨节点互踢消息生产者（Redis Pub/Sub）
 *
 * 用途：当新设备在节点 B 登录时，广播互踢消息，
 * 让节点 A 上的同类型旧设备被踢掉。
 *
 * @author 圣钰科技
 */
@Slf4j
@Component
public class CrossNodeKickProducer implements CrossNodeKickPublisher {

    @Resource
    private RedisMQTemplate redisMQTemplate;

    @Override
    public void publishKickMessage(Long userId, Integer deviceType, String byDevice) {
        if (userId == null || deviceType == null) {
            return;
        }

        CrossNodeKickMessage message = new CrossNodeKickMessage()
                .setUserId(userId)
                .setDeviceType(deviceType)
                .setByDevice(byDevice);

        log.info("[CrossNodeKickProducer] 发送跨节点互踢消息, userId: {}, deviceType: {}, byDevice: {}",
                userId, deviceType, byDevice);

        redisMQTemplate.send(message);
    }

}
