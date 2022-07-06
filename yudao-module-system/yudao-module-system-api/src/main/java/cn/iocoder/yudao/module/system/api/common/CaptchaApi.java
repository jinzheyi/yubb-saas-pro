package cn.iocoder.yudao.module.system.api.common;

import cn.iocoder.yudao.module.system.api.common.dto.CaptchaImageRespDTO;

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
     * 获得平台验证码图片
     *
     * @return 平台验证码图片
     */
    CaptchaImageRespDTO getCenterCaptchaImage();

}
