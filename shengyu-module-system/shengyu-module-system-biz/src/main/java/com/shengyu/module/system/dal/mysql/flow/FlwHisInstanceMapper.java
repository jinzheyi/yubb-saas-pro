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
import com.shengyu.module.system.dal.dataobject.flow.FlwHisInstance;
import com.shengyu.module.system.dal.dataobject.flow.FlwHisTaskActor;
import com.shengyu.module.system.dal.dataobject.flow.FlwHisTask;
import com.shengyu.module.system.dal.dataobject.flow.FlwProcess;
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
public interface FlwHisInstanceMapper extends BaseMapperX<FlwHisInstance> {

    /**
     * 我的申请任务分页列表
     */
    default Page<ProcessTaskVO> selectPageMyApplication(Page<ProcessTaskVO> page, ProcessTaskDTO dto) {
        return selectJoinPage(page, ProcessTaskVO.class,
                new MPJLambdaWrapper<FlwHisInstance>()
                        .select(FlwHisInstance::getProcessId, FlwHisInstance::getCurrentNodeName, FlwHisInstance::getCurrentNodeKey,
                                FlwHisInstance::getInstanceState, FlwHisInstance::getCreateId, FlwHisInstance::getCreateBy, FlwHisInstance::getCreateTime,
                                FlwHisInstance::getExpireTime, FlwHisInstance::getEndTime, FlwHisInstance::getDuration)
                        .selectAs(FlwHisInstance::getId, ProcessTaskVO::getInstanceId)

                        .select(FlwProcess::getProcessName, FlwProcess::getProcessType)

                        .leftJoin(FlwProcess.class, FlwProcess::getId, FlwHisInstance::getProcessId)

                        .eq(FlwHisInstance::getCreateId, dto.getCreateId())
                        .like(StrUtil.isNotBlank(dto.getProcessName()), FlwProcess::getProcessName, dto.getProcessName())
                        .like(StrUtil.isNotBlank(dto.getCreateBy()), FlwProcess::getCreateBy, dto.getCreateBy())
                        .eq(Objects.nonNull(dto.getInstanceId()), FlwHisInstance::getId, dto.getInstanceId())
                        .eq(Objects.nonNull(dto.getInstanceState()), FlwHisInstance::getInstanceState, dto.getInstanceState())
                        .ge(Objects.nonNull(dto.getBeginTime()), FlwHisInstance::getCreateTime, dto.getBeginTime())
                        .le(Objects.nonNull(dto.getEndTime()), FlwHisInstance::getCreateTime, dto.getEndTime())
                        .orderByDesc(FlwHisInstance::getCreateTime)
        );
    }

    /**
     * 我收到的任务分页列表
     */
    default Page<ProcessTaskVO> selectPageMyReceived(Page<ProcessTaskVO> page, ProcessTaskDTO dto) {
        return selectJoinPage(page, ProcessTaskVO.class,
                new MPJLambdaWrapper<FlwHisInstance>()
                        .select(FlwHisInstance::getProcessId, FlwHisInstance::getCurrentNodeName, FlwHisInstance::getCurrentNodeKey,
                                FlwHisInstance::getInstanceState, FlwHisInstance::getCreateId, FlwHisInstance::getCreateBy, FlwHisInstance::getCreateTime,
                                FlwHisInstance::getExpireTime, FlwHisInstance::getEndTime, FlwHisInstance::getDuration)
                        .selectAs(FlwHisInstance::getId, ProcessTaskVO::getInstanceId)

                        .select(FlwProcess::getProcessName, FlwProcess::getProcessType)

                        .leftJoin(FlwProcess.class, FlwProcess::getId, FlwHisInstance::getProcessId)
                        .innerJoin(FlwHisTask.class, FlwHisTask::getInstanceId, FlwHisInstance::getId)
                        .innerJoin(FlwHisTaskActor.class, FlwHisTaskActor::getTaskId, FlwHisTask::getId)

                        .eq(FlwHisTask::getTaskType, 2)
                        .eq(FlwHisTaskActor::getActorId, dto.getCreateId())
                        .like(StrUtil.isNotBlank(dto.getProcessName()), FlwProcess::getProcessName, dto.getProcessName())
                        .like(StrUtil.isNotBlank(dto.getCreateBy()), FlwProcess::getCreateBy, dto.getCreateBy())
                        .eq(Objects.nonNull(dto.getInstanceId()), FlwHisInstance::getId, dto.getInstanceId())
                        .eq(Objects.nonNull(dto.getInstanceState()), FlwHisInstance::getInstanceState, dto.getInstanceState())
                        .ge(Objects.nonNull(dto.getBeginTime()), FlwHisInstance::getCreateTime, dto.getBeginTime())
                        .le(Objects.nonNull(dto.getEndTime()), FlwHisInstance::getCreateTime, dto.getEndTime())
                        .orderByDesc(FlwHisInstance::getCreateTime)
        );
    }

}
