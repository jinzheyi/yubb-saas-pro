package cn.iocoder.yudao.module.platform.mq.consumer.sms;

import cn.iocoder.yudao.framework.mq.core.stream.AbstractStreamMessageListener;
import cn.iocoder.yudao.module.platform.mq.message.sms.PlatformSmsSendMessage;
import cn.iocoder.yudao.module.platform.service.sms.PlatformSmsSendService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;

/**
 * 针对 {@link PlatformSmsSendMessage} 的消费者
 *
 * @author zzf
 */
@Component
@Slf4j
public class PlatformSmsSendConsumer extends AbstractStreamMessageListener<PlatformSmsSendMessage> {

    @Resource
    private PlatformSmsSendService platformsmsSendService;

    @Override
    public void onMessage(PlatformSmsSendMessage message) {
        log.info("[onMessage][消息内容({})]", message);
        platformsmsSendService.doSendSms(message);
    }

}
