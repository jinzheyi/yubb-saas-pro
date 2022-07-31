package cn.iocoder.yudao.module.platform.api.sms;

import cn.iocoder.yudao.module.platform.api.sms.dto.code.PlatformSmsCodeCheckReqDTO;
import cn.iocoder.yudao.module.platform.api.sms.dto.code.PlatformSmsCodeSendReqDTO;
import cn.iocoder.yudao.module.platform.api.sms.dto.code.PlatformSmsCodeUseReqDTO;
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
public class PlatformSmsCodeApiImpl implements PlatformSmsCodeApi {

    @Resource
    private PlatformSmsCodeService platformSmsCodeService;

    @Override
    public void sendSmsCode(PlatformSmsCodeSendReqDTO reqDTO) {
        platformSmsCodeService.sendSmsCode(reqDTO);
    }

    @Override
    public void useSmsCode(PlatformSmsCodeUseReqDTO reqDTO) {
        platformSmsCodeService.useSmsCode(reqDTO);
    }

    @Override
    public void checkSmsCode(PlatformSmsCodeCheckReqDTO reqDTO) {
        platformSmsCodeService.checkSmsCode(reqDTO);
    }

}
