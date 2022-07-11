package cn.iocoder.yudao.module.platform.mq.producer.permission;

import cn.iocoder.yudao.framework.mq.core.RedisMQTemplate;
import cn.iocoder.yudao.module.platform.mq.message.permission.PlatformMenuRefreshMessage;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;

/**
 * Menu 菜单相关消息的 Producer
 */
@Component
public class PlatformMenuProducer {

    @Resource
    private RedisMQTemplate redisMQTemplate;

    /**
     * 发送 {@link PlatformMenuRefreshMessage} 消息
     */
    public void sendMenuRefreshMessage() {
        PlatformMenuRefreshMessage message = new PlatformMenuRefreshMessage();
        redisMQTemplate.send(message);
    }

}
