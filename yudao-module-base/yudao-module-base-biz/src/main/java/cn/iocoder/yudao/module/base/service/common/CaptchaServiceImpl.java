package cn.iocoder.yudao.module.base.service.common;

import cn.hutool.captcha.CaptchaUtil;
import cn.hutool.captcha.CircleCaptcha;
import cn.hutool.core.util.IdUtil;
import cn.iocoder.yudao.module.base.api.common.dto.CaptchaImageReqDTO;
import cn.iocoder.yudao.module.base.api.common.dto.CaptchaImageRespDTO;
import cn.iocoder.yudao.module.base.redis.common.CaptchaRedisDAO;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;

/**
 * 验证码 Service 实现类
 */
@Service
public class CaptchaServiceImpl implements CaptchaService {

    @Resource
    private CaptchaRedisDAO captchaRedisDAO;

    @Override
    public CaptchaImageRespDTO getCaptchaImage(CaptchaImageReqDTO reqDTO) {
        if (!Boolean.TRUE.equals(reqDTO.getEnable())) {
            return CaptchaImageRespDTO.builder().enable(reqDTO.getEnable()).build();
        }
        // 生成验证码
        CircleCaptcha captcha = CaptchaUtil.createCircleCaptcha(reqDTO.getWidth(), reqDTO.getHeight());
        // 缓存到 Redis 中
        String uuid = IdUtil.fastSimpleUUID();
        captchaRedisDAO.set(uuid, captcha.getCode(), reqDTO.getTimeout());
        // 返回
        return CaptchaImageRespDTO.builder().uuid(uuid).img(captcha.getImageBase64()).enable(reqDTO.getEnable()).build();
    }

    @Override
    public String getCaptchaCode(String uuid) {
        return captchaRedisDAO.get(uuid);
    }

    @Override
    public void deleteCaptchaCode(String uuid) {
        captchaRedisDAO.delete(uuid);
    }

}
