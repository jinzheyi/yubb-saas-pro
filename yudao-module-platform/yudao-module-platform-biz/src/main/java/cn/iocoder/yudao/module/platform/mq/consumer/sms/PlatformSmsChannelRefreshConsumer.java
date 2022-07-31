package cn.iocoder.yudao.module.platform.mq.consumer.sms;

import cn.iocoder.yudao.framework.mq.core.pubsub.AbstractChannelMessageListener;
import cn.iocoder.yudao.module.platform.mq.message.sms.PlatformSmsChannelRefreshMessage;
import cn.iocoder.yudao.module.platform.service.sms.PlatformSmsChannelService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;

/**
 * 针对 {@link PlatformSmsChannelRefreshMessage} 的消费者
 *
 * @author 芋道源码
 */
@Component
@Slf4j
public class PlatformSmsChannelRefreshConsumer extends AbstractChannelMessageListener<PlatformSmsChannelRefreshMessage> {

    @Resource
    private PlatformSmsChannelService platformsmsChannelService;

    @Override
    public void onMessage(PlatformSmsChannelRefreshMessage message) {
        log.info("[onMessage][收到 PlatformSmsChannel 刷新消息]");
        platformsmsChannelService.initSmsClients();
    }

}
