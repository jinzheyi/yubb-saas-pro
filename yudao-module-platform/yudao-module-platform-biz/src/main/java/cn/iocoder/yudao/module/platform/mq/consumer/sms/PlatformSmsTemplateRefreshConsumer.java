package cn.iocoder.yudao.module.platform.mq.consumer.sms;

import cn.iocoder.yudao.module.platform.mq.message.sms.SmsTemplateRefreshMessage;
import cn.iocoder.yudao.framework.mq.core.pubsub.AbstractChannelMessageListener;
import cn.iocoder.yudao.module.platform.service.sms.PlatformSmsTemplateService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;

/**
 * 针对 {@link SmsTemplateRefreshMessage} 的消费者
 *
 * @author 芋道源码
 */
@Component
@Slf4j
public class PlatformSmsTemplateRefreshConsumer extends AbstractChannelMessageListener<SmsTemplateRefreshMessage> {

    @Resource
    private PlatformSmsTemplateService platformSmsTemplateService;

    @Override
    public void onMessage(SmsTemplateRefreshMessage message) {
        log.info("[onMessage][收到 SmsTemplate 刷新消息]");
        platformSmsTemplateService.initLocalCache();
    }

}
