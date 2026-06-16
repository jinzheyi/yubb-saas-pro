package com.shengyu.framework.websocket.core.audit;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * IM 审计日志事件类型枚举
 * 等保三级合规要求：记录所有安全相关操作
 *
 * @author 圣钰科技
 */
@Getter
@AllArgsConstructor
public enum AuditLogEvent {

    // ========== 认证相关 ==========
    AUTH_SUCCESS("AUTH_SUCCESS", "认证成功"),
    AUTH_FAILURE("AUTH_FAILURE", "认证失败"),

    // ========== 会话相关 ==========
    KICKED("KICKED", "被踢下线"),
    SESSION_EXPIRED("SESSION_EXPIRED", "会话过期"),

    // ========== 消息相关 ==========
    MESSAGE_SEND("MESSAGE_SEND", "消息发送"),
    MESSAGE_RECEIVE("MESSAGE_RECEIVE", "消息接收"),

    // ========== 群组相关 ==========
    GROUP_CREATE("GROUP_CREATE", "创建群"),
    GROUP_DISBAND("GROUP_DISBAND", "解散群"),
    USER_ADD_GROUP("USER_ADD_GROUP", "用户加入群"),
    USER_REMOVE_GROUP("USER_REMOVE_GROUP", "用户离开群"),

    // ========== 设备相关 ==========
    DEVICE_LOGIN("DEVICE_LOGIN", "设备登录"),
    DEVICE_KICK("DEVICE_KICK", "设备踢出"),
    ;

    private final String type;
    private final String name;

}
