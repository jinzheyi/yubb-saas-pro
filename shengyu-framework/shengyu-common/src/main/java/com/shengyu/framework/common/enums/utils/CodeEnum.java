package com.shengyu.framework.common.enums.utils;

/**
 * 定义的枚举公共接口</p>
 * 实现此接口后可以调用工具类根据传入的code值获取name值</p>
 * 注意：调用接口的枚举类属性名必须是code和name
 *
 * @author 朱述勇
 * @since 2022/12/10 12:25
 * @copyright: 版权所有 开源组织 gitee(<a href="https://gitee.com/jinzheyi">jinzheyi</a>)作者：朱述勇<br/>
 * GitHub(<a href="https://github.com/jinzheyi">jinzheyi</a>)作者：朱述勇 。
 */
public interface CodeEnum {

    /**
     * code枚举值
     */
    Integer getCode();

    /**
     * 枚举值描述
     */
    String getName();

}
