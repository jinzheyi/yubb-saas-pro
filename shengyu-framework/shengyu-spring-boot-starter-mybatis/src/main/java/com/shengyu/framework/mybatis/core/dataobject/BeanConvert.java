/*
 * 爱组搭，低代码组件化开发平台
 * ------------------------------------------
 * 受知识产权保护，请勿删除版权申明，开发平台不允许做非法网站，后果自负
 */
package com.shengyu.framework.mybatis.core.dataobject;

import jodd.bean.BeanCopy;

/**
 * 爱组搭 http://aizuda.com
 * ----------------------------------------
 * 基础实体转换
 *
 * @author 青苗
 * @since 2021-10-28
 */
public interface BeanConvert {

    /**
     * 获取自动转换后的JavaBean对象
     *
     * @param clazz 转换对象类
     * @param <T>   转换对象
     * @return T 待转换对象
     */
    default <T> T convert(Class<T> clazz) {
        try {
            T t = clazz.getDeclaredConstructor().newInstance();
            BeanCopy.beans(this, t).copy();
            return t;
        } catch (Exception e) {
            throw new RuntimeException("转换对象失败", e);
        }
    }
}
