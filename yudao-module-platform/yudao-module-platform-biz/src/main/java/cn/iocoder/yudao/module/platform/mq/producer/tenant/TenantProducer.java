package cn.iocoder.yudao.module.platform.mq.producer.tenant;

import cn.iocoder.yudao.framework.mq.core.RedisMQTemplate;
import cn.iocoder.yudao.module.platform.mq.message.tenant.TenantRefreshMessage;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;

/**
 * Tenant 租户相关消息的 Producer
 *
 * @author 芋道源码
 */
@Component
public class TenantProducer {

    @Resource
    private RedisMQTemplate redisMQTemplate;

    /**
     * 发送 {@link TenantRefreshMessage} 消息
     */
    public void sendTenantRefreshMessage() {
        TenantRefreshMessage message = new TenantRefreshMessage();
        redisMQTemplate.send(message);
    }

}
