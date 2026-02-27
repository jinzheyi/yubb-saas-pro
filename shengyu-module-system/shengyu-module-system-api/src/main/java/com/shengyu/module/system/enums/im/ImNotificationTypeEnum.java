package com.shengyu.module.system.enums.im;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * IM 通知类型枚举
 *
 * @author 圣钰科技
 */
@Getter
@AllArgsConstructor
public enum ImNotificationTypeEnum {

    SYSTEM_ANNOUNCEMENT(1, "系统公告"),
    WORKFLOW_APPROVAL(2, "流程审批"),
    TODO_REMINDER(3, "待办提醒"),
    CUSTOM(4, "自定义通知");

    /**
     * 类型
     */
    private final Integer type;

    /**
     * 类型名称
     */
    private final String name;

}
