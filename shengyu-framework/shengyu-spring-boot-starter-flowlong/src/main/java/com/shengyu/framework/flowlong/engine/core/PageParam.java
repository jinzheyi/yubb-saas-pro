/*
 * 爱组搭，低代码组件化开发平台
 * ------------------------------------------
 * 受知识产权保护，请勿删除版权申明，开发平台不允许做非法网站，后果自负
 */
package com.shengyu.framework.flowlong.engine.core;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import lombok.Getter;
import lombok.Setter;

import javax.validation.constraints.Positive;
import java.io.Serializable;

/**
 * 爱组搭 http://aizuda.com
 * ----------------------------------------
 * 分页查询参数
 *
 * @author 青苗
 * @since 2021-10-28
 */
@Getter
@Setter
public class PageParam<T> implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 请求数据的页码
     */
    @Positive
    private Long page;

    /**
     * 每页条数
     */
    @Positive
    private Long pageSize;

    /**
     * 查询实体对象
     */
    private T data;

    public <T> Page<T> page() {
        return page(20L);
    }

    public <T> Page<T> page(long size) {
        if (null == this.pageSize || this.pageSize < 1L) {
            this.pageSize = size;
        }
        if (null == this.page) {
            this.page = 1L;
        }
        return new Page(this.page, this.pageSize);
    }
}
