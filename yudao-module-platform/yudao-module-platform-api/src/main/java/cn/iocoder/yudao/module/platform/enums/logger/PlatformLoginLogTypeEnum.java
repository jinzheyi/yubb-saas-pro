package cn.iocoder.yudao.module.platform.enums.logger;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * 平台登录日志的类型枚举
 *
 * @author 朱述勇
 * @since 2022/7/7 2:46 PM
 * @copyright: 版权所有 开源组织 gitee(https://gitee.com/jinzheyi)作者：朱述勇<br/>
 * GitHub(https://github.com/jinzheyi)作者：朱述勇 。
 */
@Getter
@AllArgsConstructor
public enum PlatformLoginLogTypeEnum {

    /**
     * 使用账号登录
     */
    LOGIN_USERNAME(100),
    /**
     * 使用社交登录
     */
    LOGIN_SOCIAL(101),
    /**
     * 使用手机登录
     */
    LOGIN_MOBILE(103),
    /**
     * 使用短信登录
     */
    LOGIN_SMS(104),
    /**
     * 自己主动登出
     */
    LOGOUT_SELF(200),
    /**
     * 强制退出
     */
    LOGOUT_DELETE(202),
    ;

    /**
     * 日志类型
     */
    private final Integer type;

}
