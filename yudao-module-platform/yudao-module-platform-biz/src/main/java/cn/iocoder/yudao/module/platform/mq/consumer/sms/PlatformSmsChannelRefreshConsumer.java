package cn.iocoder.yudao.module.platform.mq.consumer.sms;

import cn.iocoder.yudao.framework.mq.core.pubsub.AbstractChannelMessageListener;
import cn.iocoder.yudao.module.platform.mq.message.sms.SmsChannelRefreshMessage;
import cn.iocoder.yudao.module.platform.service.sms.PlatformSmsChannelService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;

/**
 * 针对 {@link SmsChannelRefreshMessage} 的消费者
 *
 * @author 芋道源码
 */
@Component
@Slf4j
public class PlatformSmsChannelRefreshConsumer extends AbstractChannelMessageListener<SmsChannelRefreshMessage> {

    @Resource
    private PlatformSmsChannelService platformSmsChannelService;

    @Override
    public void onMessage(SmsChannelRefreshMessage message) {
        log.info("[onMessage][收到 SmsChannel 刷新消息]");
        platformSmsChannelService.initSmsClients();
    }

}
