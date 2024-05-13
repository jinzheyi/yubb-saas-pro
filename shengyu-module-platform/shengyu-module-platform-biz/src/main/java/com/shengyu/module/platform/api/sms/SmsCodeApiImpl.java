package com.shengyu.module.platform.api.sms;

import com.shengyu.module.platform.api.sms.dto.code.SmsCodeSendReqDTO;
import com.shengyu.module.platform.api.sms.dto.code.SmsCodeUseReqDTO;
import com.shengyu.module.platform.api.sms.dto.code.SmsCodeValidateReqDTO;
import com.shengyu.module.platform.service.sms.SmsCodeService;
import javax.annotation.Resource;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

/**
 * 短信验证码 API 实现类
 *
 * @author 圣钰科技
 */
@Service
@Validated
public class SmsCodeApiImpl implements SmsCodeApi {

    @Resource
    private SmsCodeService smsCodeService;

    @Override
    public void sendSmsCode(SmsCodeSendReqDTO reqDTO) {
        smsCodeService.sendSmsCode(reqDTO);
    }

    @Override
    public void useSmsCode(SmsCodeUseReqDTO reqDTO) {
        smsCodeService.useSmsCode(reqDTO);
    }

    @Override
    public void validateSmsCode(SmsCodeValidateReqDTO reqDTO) {
        smsCodeService.validateSmsCode(reqDTO);
    }

}
