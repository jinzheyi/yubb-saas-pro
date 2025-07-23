package com.shengyu.module.system.dal.mysql.flow;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.shengyu.module.system.controller.admin.flow.dto.ProcessTaskDTO;
import com.shengyu.module.system.controller.admin.flow.vo.FlwHisTaskActorVO;
import com.shengyu.module.system.controller.admin.flow.vo.ProcessTaskVO;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface FlowlongMapper {

    /**
     * 已审批任务分页列表
     */
    Page<ProcessTaskVO> selectPageApproved(Page<ProcessTaskVO> page, @Param("dto") ProcessTaskDTO dto);

    /**
     * 查询流程实例ID的审批处理人
     */
    List<FlwHisTaskActorVO> selectListHisTaskActorVOByInstanceId(@Param("instanceId") Long instanceId);

    /**
     * 查询父节点参与者是否存在
     */
    Integer selectCountByParentTaskIdAndActorId(@Param("parentTaskId") Long parentTaskId, @Param("actorId") String actorId);

}
