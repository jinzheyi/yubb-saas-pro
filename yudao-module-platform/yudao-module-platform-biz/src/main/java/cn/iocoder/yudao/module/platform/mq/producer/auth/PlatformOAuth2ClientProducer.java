package cn.iocoder.yudao.module.platform.mq.producer.auth;

import cn.iocoder.yudao.framework.mq.core.RedisMQTemplate;
import cn.iocoder.yudao.module.platform.mq.message.auth.PlatformOAuth2ClientRefreshMessage;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;

/**
 * OAuth 2.0 客户端相关消息的 Producer
 */
@Component
public class PlatformOAuth2ClientProducer {

    @Resource
    private RedisMQTemplate redisMQTemplate;

    /**
     * 发送 {@link PlatformOAuth2ClientRefreshMessage} 消息
     */
    public void sendOAuth2ClientRefreshMessage() {
        PlatformOAuth2ClientRefreshMessage message = new PlatformOAuth2ClientRefreshMessage();
        redisMQTemplate.send(message);
    }

}
