package cn.iocoder.yudao.module.platform.service.common;

import cn.hutool.captcha.CaptchaUtil;
import cn.hutool.captcha.CircleCaptcha;
import cn.hutool.core.util.IdUtil;
import cn.iocoder.yudao.module.platform.controller.center.common.vo.CaptchaImageRespVO;
import cn.iocoder.yudao.module.platform.convert.common.CaptchaConvert;
import cn.iocoder.yudao.module.platform.dal.redis.common.PlatformCaptchaRedisDAO;
import cn.iocoder.yudao.module.platform.framework.captcha.config.CaptchaProperties;
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
    private CaptchaProperties captchaProperties;

    @Resource
    private PlatformCaptchaRedisDAO platformCaptchaRedisDAO;

    @Override
    public CaptchaImageRespVO getCaptchaImage() {
        Boolean enable = this.isCaptchaEnable();
        if (!Boolean.TRUE.equals(enable)) {
            return CaptchaImageRespVO.builder().enable(enable).build();
        }
        // 生成验证码
        CircleCaptcha captcha = CaptchaUtil.createCircleCaptcha(captchaProperties.getWidth(), captchaProperties.getHeight());
        // 缓存到 Redis 中
        String uuid = IdUtil.fastSimpleUUID();
        platformCaptchaRedisDAO.set(uuid, captcha.getCode(), captchaProperties.getTimeout());
        // 返回
        return CaptchaConvert.INSTANCE.convert(uuid, captcha).setEnable(enable);
    }

    @Override
    public Boolean isCaptchaEnable() {
        return true;
    }

    @Override
    public String getCaptchaCode(String uuid) {
        return platformCaptchaRedisDAO.get(uuid);
    }

    @Override
    public void deleteCaptchaCode(String uuid) {
        platformCaptchaRedisDAO.delete(uuid);
    }

}
