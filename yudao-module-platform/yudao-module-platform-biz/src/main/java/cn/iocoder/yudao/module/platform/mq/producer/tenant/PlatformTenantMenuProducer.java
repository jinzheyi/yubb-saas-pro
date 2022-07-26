package cn.iocoder.yudao.module.platform.mq.producer.tenant;

import cn.iocoder.yudao.framework.mq.core.RedisMQTemplate;
import cn.iocoder.yudao.module.platform.mq.message.tenant.PlatformTenantMenuRefreshMessage;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;

/**
 * Menu 菜单相关消息的 Producer
 */
@Component
public class PlatformTenantMenuProducer {

    @Resource
    private RedisMQTemplate redisMQTemplate;

    /**
     * 发送 {@link PlatformTenantMenuRefreshMessage} 消息
     */
    public void sendMenuRefreshMessage() {
        PlatformTenantMenuRefreshMessage message = new PlatformTenantMenuRefreshMessage();
        redisMQTemplate.send(message);
    }

}
