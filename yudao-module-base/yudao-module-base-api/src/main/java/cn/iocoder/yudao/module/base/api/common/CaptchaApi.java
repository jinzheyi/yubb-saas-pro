package cn.iocoder.yudao.module.base.api.common;

import cn.iocoder.yudao.module.base.api.common.dto.CaptchaImageReqDTO;
import cn.iocoder.yudao.module.base.api.common.dto.CaptchaImageRespDTO;

import javax.validation.Valid;

/**
 * 验证码 api 接口
 *
 * @author 朱述勇
 * @copyright: 版权所有 开源组织 gitee(https://gitee.com/jinzheyi)作者：朱述勇<br/>
 * GitHub(https://github.com/jinzheyi)作者：朱述勇 。
 * @since 2022/7/6 23:02
 */
public interface CaptchaApi {

    /**
     * 获得验证码图片
     *
     * @return 验证码图片
     */
    CaptchaImageRespDTO getCaptchaImage(@Valid CaptchaImageReqDTO reqDTO);

    /**
     * 获得 uuid 对应的验证码
     *
     * @param uuid 验证码验证编号
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
