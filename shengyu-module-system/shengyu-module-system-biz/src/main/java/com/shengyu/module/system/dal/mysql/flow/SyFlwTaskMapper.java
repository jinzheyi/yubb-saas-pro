package com.shengyu.module.system.dal.mysql.flow;

import cn.hutool.core.text.CharSequenceUtil;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.github.yulichang.wrapper.MPJLambdaWrapper;
import com.shengyu.framework.flowlong.engine.entity.FlwExtInstance;
import com.shengyu.framework.flowlong.engine.entity.FlwHisInstance;
import com.shengyu.framework.flowlong.engine.entity.FlwTask;
import com.shengyu.framework.flowlong.engine.entity.FlwTaskActor;
import com.shengyu.framework.flowlong.engine.mapper.FlwTaskMapper;
import com.shengyu.module.system.controller.admin.flow.dto.ProcessTaskDTO;
import com.shengyu.module.system.controller.admin.flow.vo.PendingApprovalTaskVO;
import com.shengyu.module.system.controller.admin.flow.vo.PendingClaimTaskVO;
import java.util.List;
import java.util.Objects;
import org.apache.commons.collections4.CollectionUtils;
import org.apache.ibatis.annotations.Mapper;
import org.springframework.context.annotation.Primary;

@Primary
@Mapper
public interface SyFlwTaskMapper extends FlwTaskMapper {

    /**
     * 待认领任务分页列表
     */
    default Page<PendingClaimTaskVO> selectPagePendingClaim(Page<PendingClaimTaskVO> page, ProcessTaskDTO dto, List<Long> flwTaskActorIdList) {
        if (CollectionUtils.isEmpty(flwTaskActorIdList)) {
            return new Page<>();
        }
        return selectJoinPage(page, PendingClaimTaskVO.class,
          new MPJLambdaWrapper<FlwTask>()
            .select(FlwHisInstance::getProcessId, FlwHisInstance::getInstanceState)
            .selectAs(FlwHisInstance::getId, PendingClaimTaskVO::getInstanceId)
            .selectAs(FlwHisInstance::getCreateBy, PendingClaimTaskVO::getLaunchBy)
            .selectAs(FlwHisInstance::getCreateTime, PendingClaimTaskVO::getLaunchTime)
            .select(FlwExtInstance::getProcessName, FlwExtInstance::getProcessType)
            .selectAs(FlwTask::getId, PendingClaimTaskVO::getTaskId)
            .select(FlwTask::getCreateTime,
              FlwTask::getTaskName,
              FlwTask::getTaskKey,
              FlwTask::getTaskType,
              FlwTask::getPerformType,
              FlwTask::getExpireTime,
              FlwTask::getRemindTime,
              FlwTask::getRemindRepeat)
            .innerJoin(FlwTaskActor.class, FlwTaskActor::getTaskId, FlwTask::getId)
            .leftJoin(FlwHisInstance.class, FlwHisInstance::getId, FlwTask::getInstanceId)
            .leftJoin(FlwExtInstance.class, FlwExtInstance::getId, FlwHisInstance::getId)
            .in(FlwTaskActor::getId, flwTaskActorIdList)

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
     * 待审批任务分页列表
     */
    default Page<PendingApprovalTaskVO> selectPagePendingApproval(Page<PendingApprovalTaskVO> page, ProcessTaskDTO dto,
      List<String> flwTaskActorIdList) {
        return selectJoinPage(page, PendingApprovalTaskVO.class,
          new MPJLambdaWrapper<FlwTask>()
            .select(FlwHisInstance::getProcessId, FlwHisInstance::getInstanceState)
            .selectAs(FlwHisInstance::getId, PendingApprovalTaskVO::getInstanceId)
            .selectAs(FlwHisInstance::getCreateBy, PendingApprovalTaskVO::getLaunchBy)
            .selectAs(FlwHisInstance::getCreateTime, PendingApprovalTaskVO::getLaunchTime)

            .select(FlwExtInstance::getProcessName, FlwExtInstance::getProcessType)

            .select(
              FlwTask::getCreateTime,
              FlwTask::getTaskName,
              FlwTask::getTaskKey,
              FlwTask::getPerformType,
              FlwTask::getAssignor,
              FlwTask::getExpireTime,
              FlwTask::getRemindTime,
              FlwTask::getRemindRepeat)
            .selectAs(FlwTask::getId, PendingApprovalTaskVO::getTaskId)

            .innerJoin(FlwTaskActor.class, FlwTaskActor::getTaskId, FlwTask::getId)
            .leftJoin(FlwHisInstance.class, FlwHisInstance::getId, FlwTask::getInstanceId)
            .leftJoin(FlwExtInstance.class, FlwExtInstance::getId, FlwHisInstance::getId)
            // 待审批任务 + 待认领的任务
            .in(FlwTaskActor::getActorId, flwTaskActorIdList)
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
     * 所有待审批任务分页列表
     */
    default Page<PendingApprovalTaskVO> selectPageAllPendingApproval(Page<PendingApprovalTaskVO> page, ProcessTaskDTO dto) {
        return selectJoinPage(page, PendingApprovalTaskVO.class,
          new MPJLambdaWrapper<FlwTask>()
            .select(FlwHisInstance::getProcessId, FlwHisInstance::getInstanceState)
            .selectAs(FlwHisInstance::getId, PendingApprovalTaskVO::getInstanceId)
            .selectAs(FlwHisInstance::getCreateBy, PendingApprovalTaskVO::getLaunchBy)
            .selectAs(FlwHisInstance::getCreateTime, PendingApprovalTaskVO::getLaunchTime)

            .select(FlwExtInstance::getProcessName, FlwExtInstance::getProcessType)

            .select(
              FlwTask::getCreateTime,
              FlwTask::getTaskName,
              FlwTask::getTaskKey,
              FlwTask::getPerformType,
              FlwTask::getAssignor,
              FlwTask::getExpireTime,
              FlwTask::getRemindTime,
              FlwTask::getRemindRepeat)
            .selectAs(FlwTask::getId, PendingApprovalTaskVO::getTaskId)

            .leftJoin(FlwHisInstance.class, FlwHisInstance::getId, FlwTask::getInstanceId)
            .leftJoin(FlwExtInstance.class, FlwExtInstance::getId, FlwHisInstance::getId)

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
     * 待办数量
     */
    default Long selectCountPendingApproval(List<String> flwTaskActorIdList) {
        return selectJoinCount(new MPJLambdaWrapper<FlwTask>()
          .innerJoin(FlwTaskActor.class, FlwTaskActor::getTaskId, FlwTask::getId)
          // 待审批任务 + 待认领的任务
          .in(FlwTaskActor::getActorId, flwTaskActorIdList)
        );
    }

}
