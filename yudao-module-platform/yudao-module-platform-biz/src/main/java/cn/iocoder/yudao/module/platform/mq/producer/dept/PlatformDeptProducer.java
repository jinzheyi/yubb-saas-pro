package cn.iocoder.yudao.module.platform.mq.producer.dept;

import cn.iocoder.yudao.framework.mq.core.RedisMQTemplate;
import cn.iocoder.yudao.module.platform.mq.message.dept.PlatformDeptRefreshMessage;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;

/**
 * 部门相关消息的生产者（producer）
 * @author 朱述勇
 * @copyright: 版权所有 开源组织 gitee(https://gitee.com/jinzheyi)作者：朱述勇<br/>
 * GitHub(https://github.com/jinzheyi)作者：朱述勇 。
 * @since 2022/7/9 11:59 AM
 */
@Component
public class PlatformDeptProducer {

    @Resource
    private RedisMQTemplate redisMQTemplate;

    /**
     * 发送 {@link PlatformDeptRefreshMessage} 消息
     */
    public void sendDeptRefreshMessage() {
        PlatformDeptRefreshMessage message = new PlatformDeptRefreshMessage();
        redisMQTemplate.send(message);
    }

}
