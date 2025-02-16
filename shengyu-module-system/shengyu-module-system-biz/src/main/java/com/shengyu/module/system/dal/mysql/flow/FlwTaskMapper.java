package com.shengyu.module.system.dal.mysql.flow;

import cn.hutool.core.util.StrUtil;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.github.yulichang.wrapper.MPJLambdaWrapper;
import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.module.system.controller.admin.flow.dto.ProcessTaskDTO;
import com.shengyu.module.system.controller.admin.flow.vo.PendingApprovalTaskVO;
import com.shengyu.module.system.dal.dataobject.flow.FlwHisInstanceDO;
import com.shengyu.module.system.dal.dataobject.flow.FlwProcessDO;
import com.shengyu.module.system.dal.dataobject.flow.FlwTaskActorDO;
import com.shengyu.module.system.dal.dataobject.flow.FlwTaskDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.Objects;

@Mapper
public interface FlwTaskMapper extends BaseMapperX<FlwTaskDO> {

    /**
     * 待审批任务分页列表
     */
    default Page<PendingApprovalTaskVO> selectPagePendingApproval(Page<PendingApprovalTaskVO> page, ProcessTaskDTO dto) {
        return selectJoinPage(page, PendingApprovalTaskVO.class,
                new MPJLambdaWrapper<FlwTaskDO>()
                        .select(FlwHisInstanceDO::getProcessId, FlwHisInstanceDO::getInstanceState)
                        .selectAs(FlwHisInstanceDO::getId, PendingApprovalTaskVO::getInstanceId)
                        .selectAs(FlwHisInstanceDO::getCreateBy, PendingApprovalTaskVO::getLaunchBy)
                        .selectAs(FlwHisInstanceDO::getCreateTime, PendingApprovalTaskVO::getLaunchTime)

                        .select(FlwProcessDO::getProcessName, FlwProcessDO::getProcessType)

                        .select(FlwTaskDO::getCreateTime, FlwTaskDO::getTaskName, FlwTaskDO::getTaskKey, FlwTaskDO::getPerformType,
                                FlwTaskDO::getAssignor, FlwTaskDO::getExpireTime, FlwTaskDO::getRemindTime, FlwTaskDO::getRemindRepeat)
                        .selectAs(FlwProcessDO::getId, PendingApprovalTaskVO::getTaskId)

                        .innerJoin(FlwTaskActorDO.class, FlwTaskActorDO::getTaskId, FlwTaskDO::getId)
                        .leftJoin(FlwHisInstanceDO.class, FlwHisInstanceDO::getId, FlwTaskDO::getInstanceId)
                        .leftJoin(FlwProcessDO.class, FlwProcessDO::getId, FlwHisInstanceDO::getProcessId)
                        .eq(FlwTaskActorDO::getActorType, 0)
                        .eq(FlwTaskActorDO::getActorId, dto.getCreateId())
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
