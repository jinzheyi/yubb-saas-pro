package com.shengyu.framework.flowlong.engine.core;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.IService;
import com.shengyu.framework.common.exception.util.ServiceExceptionUtil;

import java.util.function.Supplier;

public interface IBaseService<T> extends IService<T> {

    default void checkExists(boolean condition, Supplier<LambdaQueryWrapper<T>> supplier, String message) {
        if (condition) {
            this.checkExists((LambdaQueryWrapper)supplier.get(), message);
        }

    }

    default void checkExists(LambdaQueryWrapper<T> lqw, String message) {
        ServiceExceptionUtil.fail(this.count(lqw) > 0L, message);
    }

    default T checkById(Long id) {
        T t = (T)this.getById(id);
        ServiceExceptionUtil.fail(null == t, "指定ID查询数据不存在");
        return t;
    }

}
