package cn.iocoder.yudao.module.platform.mq.consumer.tenant;

import cn.iocoder.yudao.framework.mq.core.pubsub.AbstractChannelMessageListener;
import cn.iocoder.yudao.module.platform.mq.message.tenant.TenantRefreshMessage;
import cn.iocoder.yudao.module.platform.service.tenant.TenantService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;

/**
 * 针对 {@link TenantRefreshMessage} 的消费者
 *
 * @author 芋道源码
 */
@Component
@Slf4j
public class TenantRefreshConsumer extends AbstractChannelMessageListener<TenantRefreshMessage> {

    @Resource
    private TenantService tenantService;

    @Override
    public void onMessage(TenantRefreshMessage message) {
        log.info("[onMessage][收到 Tenant 刷新消息]");
        tenantService.initLocalCache();
    }

}
