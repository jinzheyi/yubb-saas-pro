package cn.iocoder.yudao.module.platform.service.common;

import cn.iocoder.yudao.module.platform.controller.center.common.vo.CaptchaImageRespVO;

/**
 * 验证码 Service 接口
 */
public interface PlatformCaptchaService {

    /**
     * 获得验证码图片
     *
     * @return 验证码图片
     */
    CaptchaImageRespVO getCaptchaImage();

    /**
     * 是否开启图片验证码
     *
     * @return 是否
     */
    Boolean isCaptchaEnable();

    /**
     * 获得 uuid 对应的验证码
     *
     * @param uuid 验证码编号
     * @return 验证码
     */
    String getCaptchaCode(String uuid);

    /**
     * 删除 uuid 对应的验证码
     *
     * @param uuid 验证码编号
     */
    void deleteCaptchaCode(String uuid);

}
