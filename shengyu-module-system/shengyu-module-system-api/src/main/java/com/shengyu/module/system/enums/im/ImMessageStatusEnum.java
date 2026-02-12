package com.shengyu.module.system.enums.im;

import cn.hutool.core.util.ObjUtil;
import com.shengyu.framework.common.core.ArrayValuable;
import lombok.AllArgsConstructor;
import lombok.Getter;

import java.util.Arrays;

/**
 * IM 消息状态枚举
 *
 * @author 圣钰科技
 */
@Getter
@AllArgsConstructor
public enum ImMessageStatusEnum implements ArrayValuable<Integer> {

    SENDING(1, "发送中"),
    SENT(2, "已发送"),
    DELIVERED(3, "已送达"),
    READ(4, "已读"),
    FAILED(5, "发送失败"),
    RECALLED(6, "已撤回");

    public static final Integer[] ARRAYS = Arrays.stream(values()).map(ImMessageStatusEnum::getStatus).toArray(Integer[]::new);

    /**
     * 状态值
     */
    private final Integer status;
    /**
     * 状态名
     */
    private final String name;

    @Override
    public Integer[] array() {
        return ARRAYS;
    }

    public static boolean isSending(Integer status) {
        return ObjUtil.equal(SENDING.status, status);
    }

    public static boolean isSent(Integer status) {
        return ObjUtil.equal(SENT.status, status);
    }

    public static boolean isDelivered(Integer status) {
        return ObjUtil.equal(DELIVERED.status, status);
    }

    public static boolean isRead(Integer status) {
        return ObjUtil.equal(READ.status, status);
    }

    public static boolean isFailed(Integer status) {
        return ObjUtil.equal(FAILED.status, status);
    }

    public static boolean isRecalled(Integer status) {
        return ObjUtil.equal(RECALLED.status, status);
    }

}
