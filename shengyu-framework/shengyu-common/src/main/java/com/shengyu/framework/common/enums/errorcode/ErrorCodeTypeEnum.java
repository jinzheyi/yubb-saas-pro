package com.shengyu.framework.common.enums.errorcode;

import com.shengyu.framework.common.core.ArrayValuable;
import lombok.AllArgsConstructor;
import lombok.Getter;

import java.util.Arrays;

/**
 * 错误码的类型枚举
 *
 * @author dylan
 */
@AllArgsConstructor
@Getter
public enum ErrorCodeTypeEnum implements ArrayValuable<Integer> {

    /**
     * 自动生成
     */
    AUTO_GENERATION(1),
    /**
     * 手动编辑
     */
    MANUAL_OPERATION(2);

    public static final Integer[] ARRAYS = Arrays.stream(values()).map(ErrorCodeTypeEnum::getType).toArray(Integer[]::new);
    /**
     * 类型
     */
    private final Integer type;

    @Override
    public Integer[] array() {
        return ARRAYS;
    }

}
