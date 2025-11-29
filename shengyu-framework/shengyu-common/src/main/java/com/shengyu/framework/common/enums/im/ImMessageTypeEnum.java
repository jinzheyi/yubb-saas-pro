package com.shengyu.framework.common.enums.im;

/**
 * IM消息类型枚举
 *
 * @author 圣钰科技
 */
public enum ImMessageTypeEnum {

    /**
     * 心跳消息
     */
    HEARTBEAT(0, "心跳消息"),

    /**
     * 登录请求
     */
    LOGIN_REQUEST(1, "登录请求"),

    /**
     * 登录响应
     */
    LOGIN_RESPONSE(2, "登录响应"),

    /**
     * 单聊消息
     */
    SINGLE_CHAT(3, "单聊消息"),

    /**
     * 群聊消息
     */
    GROUP_CHAT(4, "群聊消息"),

    /**
     * 消息确认
     */
    MESSAGE_ACK(5, "消息确认"),

    /**
     * 离线消息
     */
    OFFLINE_MESSAGE(6, "离线消息"),

    /**
     * 用户上线通知
     */
    USER_ONLINE(7, "用户上线通知"),

    /**
     * 用户下线通知
     */
    USER_OFFLINE(8, "用户下线通知"),

    /**
     * 错误消息
     */
    ERROR(9, "错误消息"),

    /**
     * 文件消息
     */
    FILE_MESSAGE(10, "文件消息"),

    /**
     * 图片消息
     */
    IMAGE_MESSAGE(11, "图片消息"),

    /**
     * 语音消息
     */
    VOICE_MESSAGE(12, "语音消息"),

    /**
     * 视频消息
     */
    VIDEO_MESSAGE(13, "视频消息"),

    /**
     * Token刷新请求
     */
    TOKEN_REFRESH_REQUEST(14, "Token刷新请求"),

    /**
     * Token刷新响应
     */
    TOKEN_REFRESH_RESPONSE(15, "Token刷新响应");

    private final Integer code;
    private final String name;

    ImMessageTypeEnum(Integer code, String name) {
        this.code = code;
        this.name = name;
    }

    public Integer getCode() {
        return code;
    }

    public String getName() {
        return name;
    }

    /**
     * 根据code获取枚举
     *
     * @param code 代码
     * @return 枚举
     */
    public static ImMessageTypeEnum getByCode(Integer code) {
        for (ImMessageTypeEnum value : values()) {
            if (value.getCode().equals(code)) {
                return value;
            }
        }
        return null;
    }
}
