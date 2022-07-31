package cn.iocoder.yudao.module.platform.mq.consumer.sms;

import cn.iocoder.yudao.framework.mq.core.pubsub.AbstractChannelMessageListener;
import cn.iocoder.yudao.module.platform.mq.message.sms.PlatformSmsTemplateRefreshMessage;
import cn.iocoder.yudao.module.platform.service.sms.PlatformSmsTemplateService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;

/**
 * 针对 {@link PlatformSmsTemplateRefreshMessage} 的消费者
 *
 * @author 芋道源码
 */
@Component
@Slf4j
public class PlatformSmsTemplateRefreshConsumer extends AbstractChannelMessageListener<PlatformSmsTemplateRefreshMessage> {

    @Resource
    private PlatformSmsTemplateService platformsmsTemplateService;

    @Override
    public void onMessage(PlatformSmsTemplateRefreshMessage message) {
        log.info("[onMessage][收到 PlatformSmsTemplate 刷新消息]");
        platformsmsTemplateService.initLocalCache();
    }

}
