package cn.iocoder.yudao.module.platform.enums.logger;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * 平台登录结果的枚举类
 *
 * @author 朱述勇
 * @since 2022/7/7 3:19 PM
 * @copyright: 版权所有 开源组织 gitee(https://gitee.com/jinzheyi)作者：朱述勇<br/>
 * GitHub(https://github.com/jinzheyi)作者：朱述勇 。
 */
@Getter
@AllArgsConstructor
public enum PlatformLoginResultEnum {

    /**
     * 成功
     */
    SUCCESS(0),
    /**
     * 账号或密码不正确
     */
    BAD_CREDENTIALS(10),
    /**
     * 用户被禁用
     */
    USER_DISABLED(20),
    /**
     * 图片验证码不存在
     */
    CAPTCHA_NOT_FOUND(30),
    /**
     * 图片验证码不正确
     */
    CAPTCHA_CODE_ERROR(31),
    /**
     * 未知异常
     */
    UNKNOWN_ERROR(100),
    ;

    /**
     * 结果
     */
    private final Integer result;

}
