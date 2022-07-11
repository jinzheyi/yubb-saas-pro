package cn.iocoder.yudao.module.platform.mq.message.permission;

import cn.iocoder.yudao.framework.mq.core.pubsub.AbstractChannelMessage;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 角色数据刷新 Message
 *
 * @author 芋道源码
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class PlatformRoleRefreshMessage extends AbstractChannelMessage {

    @Override
    public String getChannel() {
        return "platform.role.refresh";
    }

}
