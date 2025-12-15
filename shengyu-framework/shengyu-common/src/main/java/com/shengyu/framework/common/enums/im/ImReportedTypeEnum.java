package com.shengyu.framework.common.enums.im;

import com.shengyu.framework.common.core.ArrayValuable;
import lombok.AllArgsConstructor;
import lombok.Getter;

import java.util.Arrays;
import java.util.stream.Collectors;

/**
 * 被举报类型枚举
 *
 * @author 朱述勇
 * @copyright: 版权所有 开源组织 gitee(https://gitee.com/jinzheyi)作者：朱述勇<br/>
 * GitHub(https://github.com/jinzheyi)作者：朱述勇 。
 * @since 2022/12/5 22:18
 */
@Getter
@AllArgsConstructor
public enum ImReportedTypeEnum implements ArrayValuable<String> {

    /**
     * 用户
     */
    USER("user"),

    /**
     * 群
     */
    GROUP("group"),

    ;

    /**
     * 消息场景
     */
    private final String value;

    public static final String[] ARRAYS = Arrays.stream(values()).map(ImReportedTypeEnum::getValue).collect(Collectors.toList()).toArray(new String[]{});

    @Override
    public String[] array() {
        return ARRAYS;
    }

}
