package cn.iocoder.yudao.module.platform.mq.consumer.mail;

import cn.iocoder.yudao.framework.mq.core.stream.AbstractStreamMessageListener;
import cn.iocoder.yudao.module.platform.mq.message.mail.MailSendMessage;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

// TODO 芋艿：这个暂未实现
@Component
@Slf4j
public class PlatformMailSendConsumer extends AbstractStreamMessageListener<MailSendMessage> {

    @Override
    public void onMessage(MailSendMessage message) {
        log.info("[onMessage][消息内容({})]", message);
    }

}
