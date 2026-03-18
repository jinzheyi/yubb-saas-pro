package com.shengyu.module.system.mq.producer.im;

import com.shengyu.framework.mq.redis.core.RedisMQTemplate;
import com.shengyu.module.system.mq.message.im.ImGroupConversationRefreshMessage;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import javax.annotation.Resource;

@Slf4j
@Component
public class ImGroupConversationRefreshProducer {

    @Resource
    private RedisMQTemplate redisMQTemplate;

    public void sendAfterCommit(ImGroupConversationRefreshMessage message) {
        if (message == null) {
            return;
        }
        if (!TransactionSynchronizationManager.isActualTransactionActive()) {
            redisMQTemplate.send(message);
            return;
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                try {
                    redisMQTemplate.send(message);
                } catch (Exception e) {
                    log.error("[ImGroupConversationRefreshProducer] send message afterCommit failed, action={}, groupId={}, error={}"
                            , message.getAction(), message.getGroupId(), e.getMessage(), e);
                }
            }
        });
    }

}
