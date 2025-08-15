/*
 * Copyright 2023-2025 Licensed under the Dual Licensing
 * website: https://aizuda.com
 */
package com.shengyu.module.system.dal.mysql.flow;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.text.CharSequenceUtil;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.github.yulichang.wrapper.MPJLambdaWrapper;
import com.shengyu.framework.flowlong.engine.core.enums.TaskType;
import com.shengyu.framework.flowlong.engine.entity.FlwExtInstance;
import com.shengyu.framework.flowlong.engine.entity.FlwHisInstance;
import com.shengyu.framework.flowlong.engine.entity.FlwHisTask;
import com.shengyu.framework.flowlong.engine.entity.FlwHisTaskActor;
import com.shengyu.framework.flowlong.engine.mapper.FlwHisInstanceMapper;
import com.shengyu.module.system.controller.admin.flow.dto.FlwProcessInstanceDTO;
import com.shengyu.module.system.controller.admin.flow.dto.ProcessTaskDTO;
import com.shengyu.module.system.controller.admin.flow.vo.FlwInstanceVO;
import com.shengyu.module.system.controller.admin.flow.vo.ProcessTaskVO;
import java.util.List;
import java.util.Objects;
import javax.validation.constraints.NotNull;
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
    default Page<ProcessTaskVO> selectPageMyApplication(Page<ProcessTaskVO> page, @NotNull ProcessTaskDTO dto) {
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

            .select(FlwExtInstance::getProcessName, FlwExtInstance::getProcessType)

            .leftJoin(FlwExtInstance.class, FlwExtInstance::getId, FlwHisInstance::getId)

            .eq(FlwHisInstance::getCreateId, dto.getCreateId())
            .like(CharSequenceUtil.isNotBlank(dto.getProcessName()), FlwExtInstance::getProcessName, dto.getProcessName())
            .like(CharSequenceUtil.isNotBlank(dto.getCreateBy()), FlwExtInstance::getCreateBy, dto.getCreateBy())
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
    default Page<ProcessTaskVO> selectPageMyReceived(Page<ProcessTaskVO> page, @NotNull ProcessTaskDTO dto) {
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

            .select(FlwExtInstance::getProcessName, FlwExtInstance::getProcessType)

            .leftJoin(FlwExtInstance.class, FlwExtInstance::getId, FlwHisInstance::getId)
            .innerJoin(FlwHisTask.class, FlwHisTask::getInstanceId, FlwHisInstance::getId)
            .innerJoin(FlwHisTaskActor.class, FlwHisTaskActor::getTaskId, FlwHisTask::getId)
            //抄送的业务
            .eq(FlwHisTask::getTaskType, TaskType.cc.getValue())
            .eq(FlwHisTaskActor::getActorId, dto.getCreateId())
            .like(CharSequenceUtil.isNotBlank(dto.getProcessName()), FlwExtInstance::getProcessName, dto.getProcessName())
            .like(CharSequenceUtil.isNotBlank(dto.getCreateBy()), FlwExtInstance::getCreateBy, dto.getCreateBy())
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
            .like(Objects.nonNull(dto) && CharSequenceUtil.isNotBlank(dto.getProcessName()), FlwExtInstance::getProcessName, Objects.nonNull(dto)? dto.getProcessName() : "")
            .like(Objects.nonNull(dto) && CharSequenceUtil.isNotBlank(dto.getCurrentNodeName()), FlwHisInstance::getCurrentNodeName, Objects.nonNull(dto)? dto.getCurrentNodeName() : "")
            .in(CollUtil.isNotEmpty(processIdList), FlwExtInstance::getProcessId, processIdList)
            .orderByDesc(FlwHisInstance::getCreateTime)
        );
    }

}
