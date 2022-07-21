package cn.iocoder.yudao.module.system.service.common;

import cn.iocoder.yudao.module.base.api.common.CaptchaApi;
import cn.iocoder.yudao.module.base.api.common.dto.CaptchaImageReqDTO;
import cn.iocoder.yudao.module.system.controller.admin.common.vo.CaptchaImageRespVO;
import cn.iocoder.yudao.module.system.convert.common.CaptchaConvert;
import cn.iocoder.yudao.module.system.framework.captcha.config.CaptchaProperties;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;

/**
 * 验证码 Service 实现类
 */
@Service
public class CaptchaServiceImpl implements CaptchaService {

    @Resource
    private CaptchaProperties captchaProperties;

    /**
     * 验证码是否开关
     *
     * 虽然 {@link CaptchaProperties#getEnable()} 有该属性，但是 Apollo 在 Spring Boot 下无法刷新 @ConfigurationProperties 注解，
     * 所以暂时只能这么处理~
     */
    @Value("${yudao.captcha.enable}")
    private Boolean enable;

    @Resource
    private CaptchaApi captchaApi;

    @Override
    public CaptchaImageRespVO getCaptchaImage() {
        CaptchaImageReqDTO reqDTO = new CaptchaImageReqDTO();
        reqDTO.setEnable(enable)
                .setWidth(captchaProperties.getWidth())
                .setHeight(captchaProperties.getHeight())
                .setTimeout(captchaProperties.getTimeout());
        // 返回
        return CaptchaConvert.INSTANCE.convert(captchaApi.getCaptchaImage(reqDTO));
    }

    @Override
    public Boolean isCaptchaEnable() {
        return enable;
    }

    @Override
    public String getCaptchaCode(String uuid) {
        return captchaApi.getCaptchaCode(uuid);
    }

    @Override
    public void deleteCaptchaCode(String uuid) {
        captchaApi.deleteCaptchaCode(uuid);
    }

}
