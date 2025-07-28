package com.shengyu.module.system.dal.mysql.flow;

import cn.hutool.core.text.CharSequenceUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.github.yulichang.wrapper.MPJLambdaWrapper;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.framework.flowlong.engine.entity.FlwHisInstance;
import com.shengyu.framework.flowlong.engine.entity.FlwHisTask;
import com.shengyu.framework.flowlong.engine.entity.FlwProcess;
import com.shengyu.framework.flowlong.engine.mapper.FlwHisTaskMapper;
import com.shengyu.module.system.controller.admin.flow.dto.ProcessTaskDTO;
import com.shengyu.module.system.controller.admin.flow.vo.FlwHisTaskVO;
import com.shengyu.module.system.controller.admin.flow.vo.PendingApprovalTaskVO;
import java.util.List;
import java.util.Objects;
import org.apache.ibatis.annotations.Mapper;
import org.springframework.context.annotation.Primary;

@Primary
@Mapper
public interface SyFlwHisTaskMapper extends FlwHisTaskMapper {

    /**
     * 查询流程实例ID的审批历史
     */
    default List<FlwHisTaskVO> selectListHisTaskByInstanceId(Long instanceId) {
        return BeanUtils.toBean(selectList(new LambdaQueryWrapper<FlwHisTask>()
                .eq(FlwHisTask::getInstanceId, instanceId)
                .orderByAsc(FlwHisTask::getCreateTime)), FlwHisTaskVO.class);
    }

    /**
     * 所有已审批任务分页列表
     */
    default Page<PendingApprovalTaskVO> selectPageAllApproved(Page<PendingApprovalTaskVO> page, ProcessTaskDTO dto) {
        return selectJoinPage(page, PendingApprovalTaskVO.class,
          new MPJLambdaWrapper<FlwHisTask>()
            .select(FlwHisInstance::getProcessId, FlwHisInstance::getInstanceState)
            .selectAs(FlwHisInstance::getId, PendingApprovalTaskVO::getInstanceId)
            .selectAs(FlwHisInstance::getCreateBy, PendingApprovalTaskVO::getLaunchBy)
            .selectAs(FlwHisInstance::getCreateTime, PendingApprovalTaskVO::getLaunchTime)

            .select(FlwProcess::getProcessName, FlwProcess::getProcessType)

            .select(
              FlwHisTask::getCreateTime,
              FlwHisTask::getTaskName,
              FlwHisTask::getTaskKey,
              FlwHisTask::getPerformType,
              FlwHisTask::getAssignor,
              FlwHisTask::getExpireTime,
              FlwHisTask::getRemindTime,
              FlwHisTask::getRemindRepeat)
            .selectAs(FlwHisTask::getId, PendingApprovalTaskVO::getTaskId)

            .leftJoin(FlwHisInstance.class, FlwHisInstance::getId, FlwHisTask::getInstanceId)
            .leftJoin(FlwProcess.class, FlwProcess::getId, FlwHisInstance::getProcessId)

            .like(CharSequenceUtil.isNotBlank(dto.getProcessName()), FlwProcess::getProcessName, dto.getProcessName())
            .like(CharSequenceUtil.isNotBlank(dto.getCreateBy()), FlwProcess::getCreateBy, dto.getCreateBy())
            .eq(Objects.nonNull(dto.getInstanceId()), FlwHisInstance::getId, dto.getInstanceId())
            .eq(Objects.nonNull(dto.getInstanceState()), FlwHisInstance::getInstanceState, dto.getInstanceState())
            .ge(Objects.nonNull(dto.getBeginTime()), FlwHisInstance::getCreateTime, dto.getBeginTime())
            .le(Objects.nonNull(dto.getEndTime()), FlwHisInstance::getCreateTime, dto.getEndTime())
            .orderByDesc(FlwHisInstance::getCreateTime)
        );
    }

}
