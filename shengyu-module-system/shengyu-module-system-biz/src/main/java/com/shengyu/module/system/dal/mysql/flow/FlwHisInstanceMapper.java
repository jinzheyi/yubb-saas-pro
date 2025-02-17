/*
 * Copyright 2023-2025 Licensed under the Dual Licensing
 * website: https://aizuda.com
 */
package com.shengyu.module.system.dal.mysql.flow;

import cn.hutool.core.util.StrUtil;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.github.yulichang.wrapper.MPJLambdaWrapper;
import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.module.system.controller.admin.flow.dto.ProcessTaskDTO;
import com.shengyu.module.system.controller.admin.flow.vo.ProcessTaskVO;
import com.shengyu.module.system.dal.dataobject.flow.FlwHisInstanceDO;
import com.shengyu.module.system.dal.dataobject.flow.FlwProcessDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.Objects;

/**
 * 历史流程实例 Mapper
 *
 * <p>
 * <a href="https://aizuda.com">官网</a>尊重知识产权，不允许非法使用，后果自负
 * </p>
 *
 * @author hubin
 * @since 1.0
 */
@Mapper
public interface FlwHisInstanceMapper extends BaseMapperX<FlwHisInstanceDO> {

    /**
     * 我的申请任务分页列表
     */
    default Page<ProcessTaskVO> selectPageMyApplication(Page<ProcessTaskVO> page, ProcessTaskDTO dto) {
        return selectJoinPage(page, ProcessTaskVO.class,
                new MPJLambdaWrapper<FlwHisInstanceDO>()
                        .select(FlwHisInstanceDO::getProcessId, FlwHisInstanceDO::getCurrentNodeName, FlwHisInstanceDO::getCurrentNodeKey,
                                FlwHisInstanceDO::getInstanceState, FlwHisInstanceDO::getCreateId, FlwHisInstanceDO::getCreateBy, FlwHisInstanceDO::getCreateTime,
                                FlwHisInstanceDO::getExpireTime, FlwHisInstanceDO::getEndTime, FlwHisInstanceDO::getDuration)
                        .selectAs(FlwHisInstanceDO::getId, ProcessTaskVO::getInstanceId)

                        .select(FlwProcessDO::getProcessName, FlwProcessDO::getProcessType)

                        .leftJoin(FlwProcessDO.class, FlwProcessDO::getId, FlwHisInstanceDO::getProcessId)
                        .eq(FlwHisInstanceDO::getCreateId, dto.getCreateId())
                        .like(StrUtil.isNotBlank(dto.getProcessName()), FlwProcessDO::getProcessName, dto.getProcessName())
                        .like(StrUtil.isNotBlank(dto.getCreateBy()), FlwProcessDO::getCreateBy, dto.getCreateBy())
                        .eq(Objects.nonNull(dto.getInstanceId()), FlwHisInstanceDO::getId, dto.getInstanceId())
                        .eq(Objects.nonNull(dto.getInstanceState()), FlwHisInstanceDO::getInstanceState, dto.getInstanceState())
                        .ge(Objects.nonNull(dto.getBeginTime()), FlwHisInstanceDO::getCreateTime, dto.getBeginTime())
                        .le(Objects.nonNull(dto.getEndTime()), FlwHisInstanceDO::getCreateTime, dto.getEndTime())
                        .orderByDesc(FlwHisInstanceDO::getCreateTime)
        );
    }

}
