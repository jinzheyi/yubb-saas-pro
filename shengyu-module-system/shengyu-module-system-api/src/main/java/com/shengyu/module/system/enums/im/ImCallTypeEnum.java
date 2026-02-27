package com.shengyu.module.system.enums.im;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * IM 通话类型枚举
 *
 * @author 圣钰科技
 */
@Getter
@AllArgsConstructor
public enum ImCallTypeEnum {

    VOICE(1, "语音通话"),
    VIDEO(2, "视频通话");

    /**
     * 类型
     */
    private final Integer type;

    /**
     * 描述
     */
    private final String description;

}
