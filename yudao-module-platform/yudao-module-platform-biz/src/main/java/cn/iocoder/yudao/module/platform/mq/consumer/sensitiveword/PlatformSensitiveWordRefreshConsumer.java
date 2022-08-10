package cn.iocoder.yudao.module.platform.mq.consumer.sensitiveword;

import cn.iocoder.yudao.framework.mq.core.pubsub.AbstractChannelMessageListener;
import cn.iocoder.yudao.module.platform.mq.message.sensitiveword.SensitiveWordRefreshMessage;
import cn.iocoder.yudao.module.platform.service.sensitiveword.PlatformSensitiveWordService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;

/**
 * 针对 {@link SensitiveWordRefreshMessage} 的消费者
 *
 * @author 芋道源码
 */
@Component
@Slf4j
public class PlatformSensitiveWordRefreshConsumer extends AbstractChannelMessageListener<SensitiveWordRefreshMessage> {

    @Resource
    private PlatformSensitiveWordService platformSensitiveWordService;

    @Override
    public void onMessage(SensitiveWordRefreshMessage message) {
        log.info("[onMessage][收到 SensitiveWord 刷新消息]");
        platformSensitiveWordService.initLocalCache();
    }

}
