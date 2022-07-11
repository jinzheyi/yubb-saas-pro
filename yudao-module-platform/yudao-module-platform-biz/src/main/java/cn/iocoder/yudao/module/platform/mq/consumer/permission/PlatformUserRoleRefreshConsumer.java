package cn.iocoder.yudao.module.platform.mq.consumer.permission;

import cn.iocoder.yudao.framework.mq.core.pubsub.AbstractChannelMessageListener;
import cn.iocoder.yudao.module.platform.mq.message.permission.PlatformUserRoleRefreshMessage;
import cn.iocoder.yudao.module.platform.service.permission.PlatformPermissionService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;

/**
 * 针对 {@link PlatformUserRoleRefreshMessage} 的消费者
 *
 * @author 芋道源码
 */
@Component
@Slf4j
public class PlatformUserRoleRefreshConsumer extends AbstractChannelMessageListener<PlatformUserRoleRefreshMessage> {

    @Resource
    private PlatformPermissionService permissionService;

    @Override
    public void onMessage(PlatformUserRoleRefreshMessage message) {
        log.info("[onMessage][收到 User 与 Role 的关联刷新消息]");
        permissionService.initLocalCache();
    }

}
