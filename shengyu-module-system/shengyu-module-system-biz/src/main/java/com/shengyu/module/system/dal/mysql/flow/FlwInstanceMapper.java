/*
 * Copyright 2023-2025 Licensed under the Dual Licensing
 * website: https://aizuda.com
 */
package com.shengyu.module.system.dal.mysql.flow;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.module.system.dal.dataobject.flow.FlwInstance;

import java.util.List;
import java.util.Optional;

/**
 * 流程实例 Mapper
 *
 * <p>
 * <a href="https://aizuda.com">官网</a>尊重知识产权，不允许非法使用，后果自负
 * </p>
 *
 * @author hubin
 * @since 1.0
 */
public interface FlwInstanceMapper extends BaseMapperX<FlwInstance> {

    default Optional<List<FlwInstance>> listByParentInstanceId(Long parentInstanceId) {
        return Optional.ofNullable(selectList(Wrappers.<FlwInstance>lambdaQuery().eq(FlwInstance::getParentInstanceId, parentInstanceId)));
    }
}
