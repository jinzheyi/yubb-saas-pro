package com.shengyu.module.system.enums.im;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * IM 通话结束原因枚举
 *
 * @author 圣钰科技
 */
@Getter
@AllArgsConstructor
public enum ImCallEndReasonEnum {

    HANGUP("HANGUP", "正常挂断"),
    REJECT("REJECT", "拒绝"),
    TIMEOUT("TIMEOUT", "超时"),
    BUSY("BUSY", "忙线"),
    CANCEL("CANCEL", "取消"),
    CALLEE_OFFLINE("CALLEE_OFFLINE", "被叫离线"),
    ERROR("ERROR", "错误");

    /**
     * 结束原因
     */
    private final String reason;

    /**
     * 描述
     */
    private final String description;

}
