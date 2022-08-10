package cn.iocoder.yudao.module.platform.mq.consumer.permission;

import cn.iocoder.yudao.framework.mq.core.pubsub.AbstractChannelMessageListener;
import cn.iocoder.yudao.module.platform.mq.message.permission.RoleRefreshMessage;
import cn.iocoder.yudao.module.platform.service.permission.PlatformRoleService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;

/**
 * 针对 {@link RoleRefreshMessage} 的消费者
 *
 * @author 芋道源码
 */
@Component
@Slf4j
public class PlatformRoleRefreshConsumer extends AbstractChannelMessageListener<RoleRefreshMessage> {

    @Resource
    private PlatformRoleService platformRoleService;

    @Override
    public void onMessage(RoleRefreshMessage message) {
        log.info("[onMessage][收到 Role 刷新消息]");
        platformRoleService.initLocalCache();
    }

}
