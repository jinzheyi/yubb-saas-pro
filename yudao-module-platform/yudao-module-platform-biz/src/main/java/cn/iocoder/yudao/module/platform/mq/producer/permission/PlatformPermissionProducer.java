package cn.iocoder.yudao.module.platform.mq.producer.permission;

import cn.iocoder.yudao.framework.mq.core.RedisMQTemplate;
import cn.iocoder.yudao.module.platform.mq.message.permission.PlatformRoleMenuRefreshMessage;
import cn.iocoder.yudao.module.platform.mq.message.permission.PlatformUserRoleRefreshMessage;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;

/**
 * Permission 权限相关消息的 Producer
 */
@Component
public class PlatformPermissionProducer {

    @Resource
    private RedisMQTemplate redisMQTemplate;

    /**
     * 发送 {@link PlatformRoleMenuRefreshMessage} 消息
     */
    public void sendRoleMenuRefreshMessage() {
        PlatformRoleMenuRefreshMessage message = new PlatformRoleMenuRefreshMessage();
        redisMQTemplate.send(message);
    }

    /**
     * 发送 {@link PlatformUserRoleRefreshMessage} 消息
     */
    public void sendUserRoleRefreshMessage() {
        PlatformUserRoleRefreshMessage message = new PlatformUserRoleRefreshMessage();
        redisMQTemplate.send(message);
    }

}
