package cn.iocoder.yudao.module.platform.mq.consumer.dept;

import cn.iocoder.yudao.framework.mq.core.pubsub.AbstractChannelMessageListener;
import cn.iocoder.yudao.module.platform.mq.message.dept.PlatformDeptRefreshMessage;
import cn.iocoder.yudao.module.platform.service.dept.PlatformDeptService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;

/**
 * 针对 {@link PlatformDeptRefreshMessage} 的消费者
 *
 * @author 芋道源码
 */
@Component
@Slf4j
public class PlatformDeptRefreshConsumer extends AbstractChannelMessageListener<PlatformDeptRefreshMessage> {

    @Resource
    private PlatformDeptService deptService;

    @Override
    public void onMessage(PlatformDeptRefreshMessage message) {
        log.info("[onMessage][收到 Dept 刷新消息]");
        deptService.initLocalCache();
    }

}
