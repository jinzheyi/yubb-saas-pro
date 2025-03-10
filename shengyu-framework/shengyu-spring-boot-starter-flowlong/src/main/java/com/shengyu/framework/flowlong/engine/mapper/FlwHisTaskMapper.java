/*
 * Copyright 2023-2025 Licensed under the Dual Licensing
 * website: https://aizuda.com
 */
package com.shengyu.framework.flowlong.engine.mapper;

import com.shengyu.framework.flowlong.engine.assist.Assert;
import com.shengyu.framework.flowlong.engine.entity.FlwHisTask;
import com.shengyu.framework.flowlong.engine.entity.FlwTask;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;

/**
 * 历史任务 Mapper
 *
 * <p>
 * <a href="https://aizuda.com">官网</a>尊重知识产权，不允许非法使用，后果自负
 * </p>
 *
 * @author hubin
 * @since 1.0
 */
public interface FlwHisTaskMapper extends BaseMapper<FlwHisTask> {

    /**
     * 获取历史任务并检查ID的合法性
     *
     * @param id 任务ID
     * @return {@link FlwTask}
     */
    default FlwHisTask getCheckById(Long id) {
        FlwHisTask hisTask = selectById(id);
        Assert.isNull(hisTask, "指定的任务[id=" + id + "]不存在");
        return hisTask;
    }
}
