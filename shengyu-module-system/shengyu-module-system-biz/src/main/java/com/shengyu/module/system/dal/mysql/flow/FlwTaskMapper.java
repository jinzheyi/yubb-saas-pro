package com.shengyu.module.system.dal.mysql.flow;

import cn.hutool.core.util.StrUtil;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.github.yulichang.wrapper.MPJLambdaWrapper;
import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.module.system.controller.admin.flow.dto.ProcessTaskDTO;
import com.shengyu.module.system.controller.admin.flow.vo.PendingApprovalTaskVO;
import com.shengyu.module.system.dal.dataobject.flow.FlwHisInstance;
import com.shengyu.module.system.dal.dataobject.flow.FlwProcess;
import com.shengyu.module.system.dal.dataobject.flow.FlwTaskActor;
import com.shengyu.module.system.dal.dataobject.flow.FlwTask;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;
import java.util.Objects;

@Mapper
public interface FlwTaskMapper extends BaseMapperX<FlwTask> {

    /**
     * 待审批任务分页列表
     */
    default Page<PendingApprovalTaskVO> selectPagePendingApproval(Page<PendingApprovalTaskVO> page, ProcessTaskDTO dto) {
        return selectJoinPage(page, PendingApprovalTaskVO.class,
                new MPJLambdaWrapper<FlwTask>()
                        .select(FlwHisInstance::getProcessId, FlwHisInstance::getInstanceState)
                        .selectAs(FlwHisInstance::getId, PendingApprovalTaskVO::getInstanceId)
                        .selectAs(FlwHisInstance::getCreateBy, PendingApprovalTaskVO::getLaunchBy)
                        .selectAs(FlwHisInstance::getCreateTime, PendingApprovalTaskVO::getLaunchTime)

                        .select(FlwProcess::getProcessName, FlwProcess::getProcessType)

                        .select(FlwTask::getCreateTime, FlwTask::getTaskName, FlwTask::getTaskKey, FlwTask::getPerformType,
                                FlwTask::getAssignor, FlwTask::getExpireTime, FlwTask::getRemindTime, FlwTask::getRemindRepeat)
                        .selectAs(FlwProcess::getId, PendingApprovalTaskVO::getTaskId)

                        .innerJoin(FlwTaskActor.class, FlwTaskActor::getTaskId, FlwTask::getId)
                        .leftJoin(FlwHisInstance.class, FlwHisInstance::getId, FlwTask::getInstanceId)
                        .leftJoin(FlwProcess.class, FlwProcess::getId, FlwHisInstance::getProcessId)
                        .eq(FlwTaskActor::getActorType, 0)
                        .eq(FlwTaskActor::getActorId, dto.getCreateId())
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
     * 根据流程实例ID获取任务列表
     *
     * @param instanceId 流程实例ID
     * @return 任务列表
     */
    default List<FlwTask> selectListByInstanceId(Long instanceId) {
        return this.selectList(Wrappers.<FlwTask>lambdaQuery().eq(FlwTask::getInstanceId, instanceId));
    }

    /**
     * 根据父任务ID获取任务列表
     *
     * @param parentTaskId 父任务ID
     * @return 任务列表
     */
    default List<FlwTask> selectListByParentTaskId(Long parentTaskId) {
        return this.selectList(Wrappers.<FlwTask>lambdaQuery().eq(FlwTask::getParentTaskId, parentTaskId));
    }

    /**
     * 根据父任务ID获取任务数量
     *
     * @param parentTaskId 父任务ID
     * @return 任务数量
     */
    default Long selectCountByParentTaskId(Long parentTaskId) {
        return this.selectCount(Wrappers.<FlwTask>lambdaQuery().eq(FlwTask::getParentTaskId, parentTaskId));
    }

}
