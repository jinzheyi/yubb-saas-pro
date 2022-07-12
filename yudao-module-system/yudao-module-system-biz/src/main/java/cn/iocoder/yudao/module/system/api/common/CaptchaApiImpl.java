package cn.iocoder.yudao.module.system.api.common;

import cn.iocoder.yudao.module.system.api.common.dto.CaptchaImageRespDTO;
import cn.iocoder.yudao.module.system.service.common.CaptchaService;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;

/**
 * 验证码 api 实现
 *
 * @author 朱述勇
 * @copyright: 版权所有 开源组织 gitee(https://gitee.com/jinzheyi)作者：朱述勇<br/>
 * GitHub(https://github.com/jinzheyi)作者：朱述勇 。
 * @since 2022/7/6 23:09
 */
@Service
public class CaptchaApiImpl implements CaptchaApi {

    @Resource
    private CaptchaService captchaService;

    @Override
    public CaptchaImageRespDTO getCenterCaptchaImage() {
        return captchaService.getCenterCaptchaImage();
    }

    @Override
    public String getCenterCaptchaCode(String uuid) {
        return captchaService.getCaptchaCode(uuid);
    }

    @Override
    public void deleteCaptchaCode(String uuid) {
        captchaService.deleteCaptchaCode(uuid);
    }

}
