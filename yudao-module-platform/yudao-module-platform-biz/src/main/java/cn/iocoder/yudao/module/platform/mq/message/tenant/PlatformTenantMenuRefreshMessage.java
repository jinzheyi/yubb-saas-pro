package cn.iocoder.yudao.module.platform.mq.message.tenant;

import cn.iocoder.yudao.framework.mq.core.pubsub.AbstractChannelMessage;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 租户菜单数据刷新 Message
 *
 * @author 芋道源码
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class PlatformTenantMenuRefreshMessage extends AbstractChannelMessage {

    @Override
    public String getChannel() {
        return "tenant.menu.refresh";
    }

}
