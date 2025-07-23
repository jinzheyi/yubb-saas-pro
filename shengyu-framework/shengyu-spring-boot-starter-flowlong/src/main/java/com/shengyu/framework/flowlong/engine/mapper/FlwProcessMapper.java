/*
 * Copyright 2023-2025 Licensed under the Dual Licensing
 * website: https://aizuda.com
 */
package com.shengyu.framework.flowlong.engine.mapper;

import com.baomidou.mybatisplus.core.toolkit.StringUtils;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.shengyu.framework.flowlong.engine.entity.FlwProcess;
import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import java.util.List;

/**
 * 流程定义 Mapper
 *
 * <p>
 * <a href="https://aizuda.com">官网</a>尊重知识产权，不允许非法使用，后果自负
 * </p>
 *
 * @author hubin
 * @since 1.0
 */
public interface FlwProcessMapper extends BaseMapperX<FlwProcess> {

    default List<FlwProcess> selectListByProcessKey(String tenantId, String processKey) {
        return this.selectList(Wrappers.<FlwProcess>lambdaQuery()
                .eq(FlwProcess::getProcessKey, processKey)
                .eq(StringUtils.isNotBlank(tenantId), FlwProcess::getTenantId, tenantId)
                .orderByDesc(FlwProcess::getProcessVersion));
    }
}
