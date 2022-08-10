package cn.iocoder.yudao.module.platform.mq.consumer.auth;

import cn.iocoder.yudao.framework.mq.core.pubsub.AbstractChannelMessageListener;
import cn.iocoder.yudao.module.platform.mq.message.auth.OAuth2ClientRefreshMessage;
import cn.iocoder.yudao.module.platform.service.oauth2.PlatformOAuth2ClientService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;

/**
 * 针对 {@link OAuth2ClientRefreshMessage} 的消费者
 *
 * @author 芋道源码
 */
@Component
@Slf4j
public class PlatformOAuth2ClientRefreshConsumer extends AbstractChannelMessageListener<OAuth2ClientRefreshMessage> {

    @Resource
    private PlatformOAuth2ClientService oauth2ClientServicePlatform;

    @Override
    public void onMessage(OAuth2ClientRefreshMessage message) {
        log.info("[onMessage][收到 OAuth2Client 刷新消息]");
        oauth2ClientServicePlatform.initLocalCache();
    }

}
