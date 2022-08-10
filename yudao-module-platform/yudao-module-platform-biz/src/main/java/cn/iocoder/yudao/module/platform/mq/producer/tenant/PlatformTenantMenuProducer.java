package cn.iocoder.yudao.module.platform.mq.producer.tenant;

import cn.iocoder.yudao.framework.mq.core.RedisMQTemplate;
import cn.iocoder.yudao.module.platform.mq.message.tenant.TenantMenuRefreshMessage;
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
     * 发送 {@link TenantMenuRefreshMessage} 消息
     */
    public void sendMenuRefreshMessage() {
        TenantMenuRefreshMessage message = new TenantMenuRefreshMessage();
        redisMQTemplate.send(message);
    }

}
