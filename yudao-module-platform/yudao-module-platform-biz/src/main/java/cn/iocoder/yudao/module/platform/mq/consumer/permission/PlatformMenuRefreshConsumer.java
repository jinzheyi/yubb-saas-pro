package cn.iocoder.yudao.module.platform.mq.consumer.permission;

import cn.iocoder.yudao.framework.mq.core.pubsub.AbstractChannelMessageListener;
import cn.iocoder.yudao.module.platform.mq.message.permission.PlatformMenuRefreshMessage;
import cn.iocoder.yudao.module.platform.service.permission.PlatformMenuService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;

/**
 * 针对 {@link PlatformMenuRefreshMessage} 的消费者
 *
 * @author 芋道源码
 */
@Component
@Slf4j
public class PlatformMenuRefreshConsumer extends AbstractChannelMessageListener<PlatformMenuRefreshMessage> {

    @Resource
    private PlatformMenuService menuService;

    @Override
    public void onMessage(PlatformMenuRefreshMessage message) {
        log.info("[onMessage][收到 Menu 刷新消息]");
        menuService.initLocalCache();
    }

}
