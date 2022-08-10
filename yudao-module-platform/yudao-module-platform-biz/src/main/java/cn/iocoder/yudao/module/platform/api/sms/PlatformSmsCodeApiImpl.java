package cn.iocoder.yudao.module.platform.api.sms;

import cn.iocoder.yudao.module.platform.api.sms.dto.code.SmsCodeCheckReqDTO;
import cn.iocoder.yudao.module.platform.api.sms.dto.code.SmsCodeSendReqDTO;
import cn.iocoder.yudao.module.platform.api.sms.dto.code.SmsCodeUseReqDTO;
import cn.iocoder.yudao.module.platform.service.sms.PlatformSmsCodeService;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

import javax.annotation.Resource;

/**
 * 短信验证码 API 实现类
 *
 * @author 芋道源码
 */
@Service
@Validated
public class PlatformSmsCodeApiImpl implements SmsCodeApi {

    @Resource
    private PlatformSmsCodeService platformSmsCodeService;

    @Override
    public void sendSmsCode(SmsCodeSendReqDTO reqDTO) {
        platformSmsCodeService.sendSmsCode(reqDTO);
    }

    @Override
    public void useSmsCode(SmsCodeUseReqDTO reqDTO) {
        platformSmsCodeService.useSmsCode(reqDTO);
    }

    @Override
    public void checkSmsCode(SmsCodeCheckReqDTO reqDTO) {
        platformSmsCodeService.checkSmsCode(reqDTO);
    }

}
