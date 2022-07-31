package cn.iocoder.yudao.module.platform.mq.message.sms;

import cn.iocoder.yudao.framework.mq.core.pubsub.AbstractChannelMessage;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 短信渠道的数据刷新 Message
 *
 * @author 芋道源码
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class PlatformSmsChannelRefreshMessage extends AbstractChannelMessage {

    @Override
    public String getChannel() {
        return "platform.sms-channel.refresh";
    }

}
