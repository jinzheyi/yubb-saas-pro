package com.shengyu.module.system.dal.mysql.flow;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.shengyu.module.system.controller.admin.flow.dto.FlwProcessInstanceDTO;
import com.shengyu.module.system.controller.admin.flow.dto.ProcessTaskDTO;
import com.shengyu.module.system.controller.admin.flow.vo.*;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface FlowlongMapper {

    List<FlwProcessVO> selectFlwProcessList();

    List<FlwProcessVO> selectLaunchProcessList();

    /**
     * 待认领任务分页列表
     */
    Page<PendingClaimTaskVO> selectPagePendingClaim(Page<PendingClaimTaskVO> page, @Param("dto") ProcessTaskDTO dto);

    /**
     * 待审批任务分页列表
     */
    Page<PendingApprovalTaskVO> selectPagePendingApproval(Page<PendingApprovalTaskVO> page, @Param("dto") ProcessTaskDTO dto);

    /**
     * 我的申请任务分页列表
     */
    Page<ProcessTaskVO> selectPageMyApplication(Page<ProcessTaskVO> page, @Param("dto") ProcessTaskDTO dto);

    /**
     * 我收到的任务分页列表
     */
    Page<ProcessTaskVO> selectPageMyReceived(Page<ProcessTaskVO> page, @Param("dto") ProcessTaskDTO dto);

    /**
     * 已审批任务分页列表
     */
    Page<ProcessTaskVO> selectPageApproved(Page<ProcessTaskVO> page, @Param("dto") ProcessTaskDTO dto);

    /**
     * 查询流程实例ID的审批历史
     */
    List<FlwHisTaskVO> selectListHisTaskByInstanceId(@Param("instanceId") Long instanceId);

    /**
     * 查询流程实例ID的审批处理人
     */
    List<FlwHisTaskActorVO> selectListHisTaskActorVOByInstanceId(@Param("instanceId") Long instanceId);

    /**
     * 待办数量
     */
    Integer selectCountPendingApproval(@Param("actorId") Long actorId);

    /**
     * 不存在角色权限的流程ID列表
     */
    List<Long> selectNotExistProcessIds(@Param("userId") Long userId);

    /**
     * 流程实例分页列表
     */
    Page<FlwInstanceVO> selectPageInstance(Page<FlwInstanceVO> page, @Param("dto") FlwProcessInstanceDTO dto);
}
