package com.shengyu.module.platform.api.mail;

import com.shengyu.module.platform.service.mail.MailSendService;
import java.util.Map;
import javax.annotation.Resource;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

/**
 * @author zhusy
 * @description: 提供给外部发送邮件的接口实现
 * @date 2024/4/2 21:09
 */
@Service
@Validated
public class MailSendApiImpl implements MailSendApi{

    @Resource
    private MailSendService mailSendService;

    @Override
    public Long sendSingleMail(String mail, Long userId, Integer userType, String templateCode,
        Map<String, Object> templateParams) {
        return mailSendService.sendSingleMail(mail, userId, userType, templateCode, templateParams);
    }

}
