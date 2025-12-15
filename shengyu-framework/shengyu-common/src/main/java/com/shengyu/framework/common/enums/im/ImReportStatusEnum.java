package com.shengyu.framework.common.enums.im;

import com.shengyu.framework.common.core.ArrayValuable;
import lombok.AllArgsConstructor;
import lombok.Getter;

import java.util.Arrays;
import java.util.stream.Collectors;

@Getter
@AllArgsConstructor
public enum ImReportStatusEnum implements ArrayValuable<String> {

    /**
     * 待处理
     */
    PENDING("pending"),
    /**
     * 拒绝
     */
    REFUSE("refuse"),
    /**
     * 同意
     */
    AGREE("agree"),

    ;

    /**
     * 申请状态
     */
    private final String value;

    public static final String[] ARRAYS = Arrays.stream(values()).map(ImReportStatusEnum::getValue).collect(Collectors.toList()).toArray(new String[]{});

    @Override
    public String[] array() {
        return ARRAYS;
    }

}
