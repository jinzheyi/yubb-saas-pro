package cn.iocoder.yudao.module.platform.service.common;

import cn.iocoder.yudao.module.platform.controller.center.common.vo.CaptchaImageRespVO;
import cn.iocoder.yudao.module.platform.convert.common.CaptchaConvert;
import cn.iocoder.yudao.module.system.api.common.CaptchaApi;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;

/**
 * 平台验证码 Service 实现类
 *
 * @author 朱述勇
 * @copyright: 版权所有 开源组织 gitee(https://gitee.com/jinzheyi)作者：朱述勇<br/>
 * GitHub(https://github.com/jinzheyi)作者：朱述勇 。
 * @since 2022/7/6 23:54
 */
@Slf4j
@Service
public class PlatformCaptchaServiceImpl implements PlatformCaptchaService {

    @Resource
    private CaptchaApi captchaApi;

    @Override
    public CaptchaImageRespVO getCaptchaImage() {
        return CaptchaConvert.INSTANCE.convert(captchaApi.getCenterCaptchaImage());
    }

    @Override
    public Boolean isCaptchaEnable() {
        // TODO 暂时写死，后面再改
        return true;
    }

    @Override
    public String getCaptchaCode(String uuid) {
        return captchaApi.getCenterCaptchaCode(uuid);
    }

    @Override
    public void deleteCaptchaCode(String uuid) {
        captchaApi.deleteCaptchaCode(uuid);
    }

}
