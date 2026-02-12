package com.shengyu.module.system.enums.im;

import cn.hutool.core.util.ObjUtil;
import com.shengyu.framework.common.core.ArrayValuable;
import lombok.AllArgsConstructor;
import lombok.Getter;

import java.util.Arrays;

/**
 * IM 群组类型枚举
 *
 * @author 圣钰科技
 */
@Getter
@AllArgsConstructor
public enum ImGroupTypeEnum implements ArrayValuable<Integer> {

    NORMAL(1, "普通群"),
    WORK(2, "工作群");

    public static final Integer[] ARRAYS = Arrays.stream(values()).map(ImGroupTypeEnum::getType).toArray(Integer[]::new);

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

    public static boolean isNormal(Integer type) {
        return ObjUtil.equal(NORMAL.type, type);
    }

    public static boolean isWork(Integer type) {
        return ObjUtil.equal(WORK.type, type);
    }

}
