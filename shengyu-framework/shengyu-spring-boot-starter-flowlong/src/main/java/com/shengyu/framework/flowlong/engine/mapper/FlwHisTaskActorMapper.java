/*
 * Copyright 2023-2025 Licensed under the Dual Licensing
 * website: https://aizuda.com
 */
package com.shengyu.framework.flowlong.engine.mapper;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.github.yulichang.wrapper.MPJLambdaWrapper;
import com.shengyu.framework.flowlong.engine.core.enums.TaskState;
import com.shengyu.framework.flowlong.engine.core.enums.TaskType;
import com.shengyu.framework.flowlong.engine.entity.FlwHisTask;
import com.shengyu.framework.flowlong.engine.entity.FlwHisTaskActor;
import com.shengyu.framework.flowlong.engine.entity.FlwTask;
import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import java.util.List;

/**
 * 历史任务参与者 Mapper
 *
 * <p>
 * <a href="https://aizuda.com">官网</a>尊重知识产权，不允许非法使用，后果自负
 * </p>
 *
 * @author hubin
 * @since 1.0
 */
public interface FlwHisTaskActorMapper extends BaseMapperX<FlwHisTaskActor> {

    /**
     * 通过任务ID获取参与者列表
     *
     * @param taskId 任务ID
     * @return 参与者列表
     */
    default List<FlwHisTaskActor> selectListByTaskId(Long taskId) {
        return this.selectList(Wrappers.<FlwHisTaskActor>lambdaQuery().eq(FlwHisTaskActor::getTaskId, taskId));
    }

    /**
     * 通过任务ID获取参与者列表
     *
     * @param taskIds 任务ID列表
     * @return 历史任务参与者列表
     */
    default List<FlwHisTaskActor> selectListByTaskIds(List<Long> taskIds) {
        return this.selectList(Wrappers.<FlwHisTaskActor>lambdaQuery().in(FlwHisTaskActor::getTaskId, taskIds));
    }

    /**
     * 当前节点处理人参与过历史任务审批且通过的
     * @param flwTask 任务参数
     * @param actorId 处理人ID
     * @return 历史任务参与者列表
     */
    //TODO 这里要调整下，因为要考虑到重新发起的情况，可以思考使用ext_instance的taskkey来找到当前一个循环的审批情况
    default List<FlwHisTaskActor> selectListByTaskAndActorIdApprovalAndComplete(FlwTask flwTask, String actorId) {
        return this.selectJoinList(FlwHisTaskActor.class,
          new MPJLambdaWrapper<FlwHisTaskActor>()
            .selectAll(FlwHisTaskActor.class)
            .innerJoin(FlwHisTask.class, FlwHisTask::getId, FlwHisTaskActor::getTaskId)
            .eq(FlwHisTaskActor::getActorId, actorId)
            .eq(FlwHisTask::getInstanceId, flwTask.getInstanceId())
            .eq(FlwHisTask::getTaskType, TaskType.approval.getValue())
            .eq(FlwHisTask::getTaskState, TaskState.complete.getValue())
        );
    }

}
