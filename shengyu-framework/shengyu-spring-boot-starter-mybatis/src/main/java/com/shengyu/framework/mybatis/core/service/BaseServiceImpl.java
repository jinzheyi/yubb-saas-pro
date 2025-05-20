/*
 * 爱组搭，低代码组件化开发平台
 * ------------------------------------------
 * 受知识产权保护，请勿删除版权申明，开发平台不允许做非法网站，后果自负
 */
package com.shengyu.framework.mybatis.core.service;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;

/**
 * 爱组搭 http://aizuda.com
 * ----------------------------------------
 * 自定义 IBaseService 实现
 *
 * @author 青苗
 * @since 2021-10-28
 */
public class BaseServiceImpl<M extends BaseMapperX<T>, T> extends ServiceImpl<M, T> implements IBaseService<T> {

}
