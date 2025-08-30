/*
 * Copyright 2023-2025 Licensed under the Dual Licensing
 * website: https://aizuda.com
 */
package com.shengyu.framework.flowlong.engine.core.enums;

import java.util.Objects;
import lombok.Getter;

/**
 *
 * 权重
 * <p>
 * 票签任务时，该值为不同处理人员的分量比例
 * </p>
 * <p>
 * 代理任务时，该值为 1 时为代理人
 * </p>
 * <p>
 * 或签任务时，该值为 1 时为或签处理人
 * </p>
 * <p>
 * 抄送任务时，该值为 6 时为抄送人
 * </p>
 * <p>
 * 传阅任务时，该值为 500 时为传阅人
 * </p>
 *
 */
@Getter
public enum TaskWeightEnum {
    /**
     * 抄送
     */
    CC(6),
    /**
     * 传阅
     */
    CIRCULATE(500);

    private final int value;

    TaskWeightEnum(int value) {
        this.value = value;
    }

    public boolean ne(Integer value) {
        return !eq(value);
    }

    public boolean eq(Integer value) {
        return Objects.equals(this.value, value);
    }
}
