package cn.iocoder.yudao.module.platform.mq.consumer.permission;

import cn.iocoder.yudao.framework.mq.core.pubsub.AbstractChannelMessageListener;
import cn.iocoder.yudao.module.platform.mq.message.permission.PlatformRoleMenuRefreshMessage;
import cn.iocoder.yudao.module.platform.service.permission.PlatformPermissionService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;

/**
 * 针对 {@link PlatformRoleMenuRefreshMessage} 的消费者
 *
 * @author 芋道源码
 */
@Component
@Slf4j
public class PlatformRoleMenuRefreshConsumer extends AbstractChannelMessageListener<PlatformRoleMenuRefreshMessage> {

    @Resource
    private PlatformPermissionService permissionService;

    @Override
    public void onMessage(PlatformRoleMenuRefreshMessage message) {
        log.info("[onMessage][收到 Role 与 Menu 的关联刷新消息]");
        permissionService.initLocalCache();
    }

}
