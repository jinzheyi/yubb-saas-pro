package com.shengyu.module.system.mq.producer.im;

import com.shengyu.framework.mq.redis.core.RedisMQTemplate;
import com.shengyu.framework.websocket.core.mq.message.ImSessionRevokeMessage;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;

/**
 * IM 会话撤销 Producer（Redis Pub/Sub）
 */
@Slf4j
@Component
public class ImSessionRevokeProducer {

    @Resource
    private RedisMQTemplate redisMQTemplate;

    public void send(ImSessionRevokeMessage message) {
        if (message == null) {
            return;
        }
        redisMQTemplate.send(message);
        log.info("[ImSessionRevokeProducer] send revoke message, userId={}, action={}, reason={}",
            message.getUserId(), message.getAction(), message.getReason());
    }
}
