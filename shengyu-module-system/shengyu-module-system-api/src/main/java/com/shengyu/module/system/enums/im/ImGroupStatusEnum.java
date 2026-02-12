package com.shengyu.module.system.enums.im;

import cn.hutool.core.util.ObjUtil;
import com.shengyu.framework.common.core.ArrayValuable;
import lombok.AllArgsConstructor;
import lombok.Getter;

import java.util.Arrays;

/**
 * IM 群组状态枚举
 *
 * @author 圣钰科技
 */
@Getter
@AllArgsConstructor
public enum ImGroupStatusEnum implements ArrayValuable<Integer> {

    NORMAL(1, "正常"),
    DISSOLVED(2, "已解散");

    public static final Integer[] ARRAYS = Arrays.stream(values()).map(ImGroupStatusEnum::getStatus).toArray(Integer[]::new);

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

    public static boolean isNormal(Integer status) {
        return ObjUtil.equal(NORMAL.status, status);
    }

    public static boolean isDissolved(Integer status) {
        return ObjUtil.equal(DISSOLVED.status, status);
    }

}
