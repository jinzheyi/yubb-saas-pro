package cn.iocoder.yudao.module.platform.mq.consumer.tenant;

import cn.iocoder.yudao.framework.mq.core.pubsub.AbstractChannelMessageListener;
import cn.iocoder.yudao.module.platform.mq.message.tenant.PlatformTenantMenuRefreshMessage;
import cn.iocoder.yudao.module.platform.service.tenant.PlatformTenantMenuService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;

/**
 * 针对 {@link PlatformTenantMenuRefreshMessage} 的消费者
 *
 * @author 芋道源码
 */
@Component
@Slf4j
public class PlatformTenantMenuRefreshConsumer extends AbstractChannelMessageListener<PlatformTenantMenuRefreshMessage> {

    @Resource
    private PlatformTenantMenuService menuService;

    @Override
    public void onMessage(PlatformTenantMenuRefreshMessage message) {
        log.info("[onMessage][收到 Menu 刷新消息]");
        menuService.initLocalCache();
    }

}
