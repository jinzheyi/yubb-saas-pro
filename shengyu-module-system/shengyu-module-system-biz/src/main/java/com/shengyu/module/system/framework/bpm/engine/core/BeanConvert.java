package com.shengyu.module.system.framework.bpm.engine.core;

import jodd.bean.BeanCopy;

public interface BeanConvert {

    default <T> T convert(Class<T> clazz) {
        try {
            T t = (T)clazz.getDeclaredConstructor().newInstance();
            BeanCopy.beans(this, t).copy();
            return t;
        } catch (Exception e) {
            throw new RuntimeException("转换对象失败", e);
        }
    }

}
