package com.shengyu.module.system.enums.im;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * IM 通话状态机状态枚举
 *
 * @author 圣钰科技
 */
@Getter
@AllArgsConstructor
public enum ImCallStateEnum {

    INIT("INIT", "初始状态"),
    RINGING("RINGING", "响铃中"),
    CONNECTING("CONNECTING", "连接中"),
    CONNECTED("CONNECTED", "已连接"),
    ENDED("ENDED", "已结束");

    /**
     * 状态
     */
    private final String state;

    /**
     * 描述
     */
    private final String description;

}
