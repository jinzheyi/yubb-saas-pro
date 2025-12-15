package com.shengyu.framework.common.enums.im;

import com.shengyu.framework.common.core.ArrayValuable;
import lombok.AllArgsConstructor;
import lombok.Getter;

import java.util.Arrays;
import java.util.stream.Collectors;

@Getter
@AllArgsConstructor
public enum ImMomentSeeEnum implements ArrayValuable<String> {

    /**
     * 全部可见
     */
    ALL("all"),

    /**
     * 私密可见
     */
    NONE("none"),

    ;

    /**
     * 申请状态
     */
    private final String value;

    public static final String[] ARRAYS = Arrays.stream(values()).map(ImMomentSeeEnum::getValue).collect(Collectors.toList()).toArray(new String[]{});

    @Override
    public String[] array() {
        return ARRAYS;
    }

}
