package com.shengyu.module.system.enums.im;

import com.shengyu.framework.common.core.ArrayValuable;
import lombok.AllArgsConstructor;
import lombok.Getter;

import java.util.Arrays;

/**
 * 消息转发类型枚举
 */
@Getter
@AllArgsConstructor
public enum ImMessageForwardTypeEnum implements ArrayValuable<Integer> {

    SINGLE(1, "逐条转发"),
    COMBINE(2, "合并转发");

    public static final Integer[] ARRAYS = Arrays.stream(values()).map(ImMessageForwardTypeEnum::getType).toArray(Integer[]::new);

    /**
     * 类型值
     */
    private final Integer type;
    /**
     * 类型名
     */
    private final String name;

    @Override
    public Integer[] array() {
        return ARRAYS;
    }

    public static ImMessageForwardTypeEnum valueOf(Integer type) {
        return Arrays.stream(values())
                .filter(e -> e.getType().equals(type))
                .findFirst()
                .orElse(null);
    }

}
