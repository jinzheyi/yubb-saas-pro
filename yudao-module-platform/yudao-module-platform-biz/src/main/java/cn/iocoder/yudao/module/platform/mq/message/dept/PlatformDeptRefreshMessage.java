package cn.iocoder.yudao.module.platform.mq.message.dept;

import cn.iocoder.yudao.framework.mq.core.pubsub.AbstractChannelMessage;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 部门数据刷新 Message
 *
 * @author 朱述勇
 * @since 2022/7/9 12:06 PM
 * @copyright: 版权所有 开源组织 gitee(https://gitee.com/jinzheyi)作者：朱述勇<br/>
 * GitHub(https://github.com/jinzheyi)作者：朱述勇 。
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class PlatformDeptRefreshMessage extends AbstractChannelMessage {

    @Override
    public String getChannel() {
        return "platform.dept.refresh";
    }

}
