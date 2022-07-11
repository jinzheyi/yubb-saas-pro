package cn.iocoder.yudao.module.platform.mq.message.permission;

import cn.iocoder.yudao.framework.mq.core.pubsub.AbstractChannelMessage;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 菜单数据刷新 Message
 *
 * @author 芋道源码
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class PlatformMenuRefreshMessage extends AbstractChannelMessage {

    @Override
    public String getChannel() {
        return "platform.menu.refresh";
    }

}
