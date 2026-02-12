package com.shengyu.module.system.enums.im;

import cn.hutool.core.util.ObjUtil;
import com.shengyu.framework.common.core.ArrayValuable;
import lombok.AllArgsConstructor;
import lombok.Getter;

import java.util.Arrays;

/**
 * IM 会话类型枚举
 *
 * @author 圣钰科技
 */
@Getter
@AllArgsConstructor
public enum ImConversationTypeEnum implements ArrayValuable<Integer> {

    SINGLE(1, "单聊"),
    GROUP(2, "群聊");

    public static final Integer[] ARRAYS = Arrays.stream(values()).map(ImConversationTypeEnum::getType).toArray(Integer[]::new);

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

    public static boolean isSingle(Integer type) {
        return ObjUtil.equal(SINGLE.type, type);
    }

    public static boolean isGroup(Integer type) {
        return ObjUtil.equal(GROUP.type, type);
    }

}
