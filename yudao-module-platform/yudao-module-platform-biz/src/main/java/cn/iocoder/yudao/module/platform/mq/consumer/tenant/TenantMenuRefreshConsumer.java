package cn.iocoder.yudao.module.platform.mq.consumer.tenant;

import cn.iocoder.yudao.framework.mq.core.pubsub.AbstractChannelMessageListener;
import cn.iocoder.yudao.module.platform.mq.message.tenant.TenantMenuRefreshMessage;
import cn.iocoder.yudao.module.platform.service.tenant.TenantMenuService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;

/**
 * 针对 {@link TenantMenuRefreshMessage} 的消费者
 *
 * @author 芋道源码
 */
@Component
@Slf4j
public class TenantMenuRefreshConsumer extends AbstractChannelMessageListener<TenantMenuRefreshMessage> {

    @Resource
    private TenantMenuService tenantMenuService;

    @Override
    public void onMessage(TenantMenuRefreshMessage message) {
        log.info("[onMessage][收到 Menu 刷新消息]");
        tenantMenuService.initLocalCache();
    }

}
