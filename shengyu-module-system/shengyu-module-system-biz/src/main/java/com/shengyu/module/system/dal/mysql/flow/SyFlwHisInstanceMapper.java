/*
 * Copyright 2023-2025 Licensed under the Dual Licensing
 * website: https://aizuda.com
 */
package com.shengyu.module.system.dal.mysql.flow;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.util.StrUtil;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.github.yulichang.wrapper.MPJLambdaWrapper;
import com.jxscxkj.cxkjflow.biz.bpm.boot.model.dto.FlwProcessInstanceDTO;
import com.jxscxkj.cxkjflow.biz.bpm.boot.model.dto.ProcessTaskDTO;
import com.jxscxkj.cxkjflow.biz.bpm.boot.model.vo.FlwInstanceVO;
import com.jxscxkj.cxkjflow.biz.bpm.boot.model.vo.ProcessTaskVO;
import com.jxscxkj.cxkjflow.common.bpm.engine.core.enums.TaskType;
import com.jxscxkj.cxkjflow.common.bpm.engine.entity.FlwExtInstance;
import com.jxscxkj.cxkjflow.common.bpm.engine.entity.FlwHisInstance;
import com.jxscxkj.cxkjflow.common.bpm.engine.entity.FlwHisTask;
import com.jxscxkj.cxkjflow.common.bpm.engine.entity.FlwHisTaskActor;
import com.jxscxkj.cxkjflow.common.bpm.engine.entity.FlwProcess;
import com.jxscxkj.cxkjflow.common.bpm.engine.mapper.FlwHisInstanceMapper;
import java.util.List;
import java.util.Objects;
import org.apache.ibatis.annotations.Mapper;
import org.springframework.context.annotation.Primary;

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
@Primary
@Mapper
public interface SyFlwHisInstanceMapper extends FlwHisInstanceMapper {

    /**
     * 我的申请任务分页列表
     */
    default Page<ProcessTaskVO> selectPageMyApplication(Page<ProcessTaskVO> page, ProcessTaskDTO dto) {
        return selectJoinPage(page, ProcessTaskVO.class,
                new MPJLambdaWrapper<FlwHisInstance>()
                        .select(
                          FlwHisInstance::getProcessId,
                          FlwHisInstance::getCurrentNodeName,
                          FlwHisInstance::getCurrentNodeKey,
                          FlwHisInstance::getInstanceState,
                          FlwHisInstance::getCreateId,
                          FlwHisInstance::getCreateBy,
                          FlwHisInstance::getCreateTime,
                          FlwHisInstance::getExpireTime,
                          FlwHisInstance::getEndTime,
                          FlwHisInstance::getDuration)
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
                        .select(
                          FlwHisInstance::getProcessId,
                          FlwHisInstance::getCurrentNodeName,
                          FlwHisInstance::getCurrentNodeKey,
                          FlwHisInstance::getInstanceState,
                          FlwHisInstance::getCreateId,
                          FlwHisInstance::getCreateBy,
                          FlwHisInstance::getCreateTime,
                          FlwHisInstance::getExpireTime,
                          FlwHisInstance::getEndTime,
                          FlwHisInstance::getDuration)
                        .selectAs(FlwHisInstance::getId, ProcessTaskVO::getInstanceId)

                        .select(FlwProcess::getProcessName, FlwProcess::getProcessType)

                        .leftJoin(FlwProcess.class, FlwProcess::getId, FlwHisInstance::getProcessId)
                        .innerJoin(FlwHisTask.class, FlwHisTask::getInstanceId, FlwHisInstance::getId)
                        .innerJoin(FlwHisTaskActor.class, FlwHisTaskActor::getTaskId, FlwHisTask::getId)
                         //抄送的业务
                        .eq(FlwHisTask::getTaskType, TaskType.cc.getValue())
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

    /**
     * 流程实例分页列表
     */
    default Page<FlwInstanceVO> selectPageInstance(Page<FlwInstanceVO> page, FlwProcessInstanceDTO dto, List<Long> processIdList) {
        return selectJoinPage(page, FlwInstanceVO.class,
                new MPJLambdaWrapper<FlwHisInstance>()
                  .select(FlwHisInstance::getId,
                          FlwHisInstance::getCreateBy,
                          FlwHisInstance::getProcessId,
                          FlwHisInstance::getCurrentNodeName,
                          FlwHisInstance::getExpireTime,
                          FlwHisInstance::getInstanceState,
                          FlwHisInstance::getEndTime,
                          FlwHisInstance::getDuration
                        )
                  .select(FlwExtInstance::getProcessName)
                  .innerJoin(FlwExtInstance.class, FlwExtInstance::getId, FlwHisInstance::getId)
                  .isNotNull(Objects.nonNull(dto) && dto.getCompleted(), FlwHisInstance::getEndTime)
                  .isNull(Objects.nonNull(dto) && !dto.getCompleted(), FlwHisInstance::getEndTime)
                  .like(Objects.nonNull(dto) && StrUtil.isNotBlank(dto.getProcessName()), FlwExtInstance::getProcessName, dto.getProcessName())
                  .like(StrUtil.isNotBlank(dto.getCurrentNodeName()), FlwHisInstance::getCurrentNodeName, dto.getCurrentNodeName())
                  .in(CollUtil.isNotEmpty(processIdList), FlwExtInstance::getProcessId, processIdList)
                  .orderByDesc(FlwHisInstance::getCreateTime)
        );
    }

}
