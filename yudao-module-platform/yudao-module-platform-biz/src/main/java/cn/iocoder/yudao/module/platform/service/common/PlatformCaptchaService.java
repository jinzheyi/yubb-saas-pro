package cn.iocoder.yudao.module.platform.service.common;

import cn.iocoder.yudao.module.platform.controller.center.common.vo.CaptchaImageRespVO;

/**
 * 平台验证码 Service 接口
 *
 * @author 朱述勇
 * @copyright: 版权所有 开源组织 gitee(https://gitee.com/jinzheyi)作者：朱述勇<br/>
 * GitHub(https://github.com/jinzheyi)作者：朱述勇 。
 * @since 2022/7/6 23:53
 */
public interface PlatformCaptchaService {

    /**
     * 获得验证码图片
     * @return 验证码图片
     */
    CaptchaImageRespVO getCaptchaImage();

}
