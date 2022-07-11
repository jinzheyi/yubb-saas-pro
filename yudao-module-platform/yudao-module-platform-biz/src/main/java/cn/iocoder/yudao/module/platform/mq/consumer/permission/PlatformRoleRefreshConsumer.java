package cn.iocoder.yudao.module.platform.mq.consumer.permission;

import cn.iocoder.yudao.framework.mq.core.pubsub.AbstractChannelMessageListener;
import cn.iocoder.yudao.module.platform.mq.message.permission.PlatformRoleRefreshMessage;
import cn.iocoder.yudao.module.platform.service.permission.PlatformRoleService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;

/**
 * 针对 {@link PlatformRoleRefreshMessage} 的消费者
 *
 * @author 芋道源码
 */
@Component
@Slf4j
public class PlatformRoleRefreshConsumer extends AbstractChannelMessageListener<PlatformRoleRefreshMessage> {

    @Resource
    private PlatformRoleService roleService;

    @Override
    public void onMessage(PlatformRoleRefreshMessage message) {
        log.info("[onMessage][收到 Role 刷新消息]");
        roleService.initLocalCache();
    }

}
