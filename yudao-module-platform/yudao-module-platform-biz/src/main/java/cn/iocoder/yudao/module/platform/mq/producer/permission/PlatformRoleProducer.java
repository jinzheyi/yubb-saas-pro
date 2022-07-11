package cn.iocoder.yudao.module.platform.mq.producer.permission;

import cn.iocoder.yudao.framework.mq.core.RedisMQTemplate;
import cn.iocoder.yudao.module.platform.mq.message.permission.PlatformRoleRefreshMessage;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;

/**
 * Role 角色相关消息的 Producer
 *
 * @author 芋道源码
 */
@Component
public class PlatformRoleProducer {

    @Resource
    private RedisMQTemplate redisMQTemplate;

    /**
     * 发送 {@link PlatformRoleRefreshMessage} 消息
     */
    public void sendRoleRefreshMessage() {
        PlatformRoleRefreshMessage message = new PlatformRoleRefreshMessage();
        redisMQTemplate.send(message);
    }

}
