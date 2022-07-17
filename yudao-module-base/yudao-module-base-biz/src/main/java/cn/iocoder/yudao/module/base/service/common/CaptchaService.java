package cn.iocoder.yudao.module.base.service.common;

import cn.iocoder.yudao.module.base.api.common.dto.CaptchaImageReqDTO;
import cn.iocoder.yudao.module.base.api.common.dto.CaptchaImageRespDTO;

/**
 * 验证码 Service 接口
 */
public interface CaptchaService {

    /**
     * 获得验证码图片
     *
     * @return 验证码图片
     */
    CaptchaImageRespDTO getCaptchaImage(CaptchaImageReqDTO reqDTO);

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
