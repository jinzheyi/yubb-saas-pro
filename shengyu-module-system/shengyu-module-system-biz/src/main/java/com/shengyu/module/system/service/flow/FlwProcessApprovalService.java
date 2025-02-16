package com.shengyu.module.system.service.flow;

import com.aizuda.boot.modules.flw.entity.FlwProcessApproval;
import com.aizuda.boot.modules.flw.entity.dto.ProcessApprovalDTO;
import com.aizuda.service.service.IBaseService;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;

import java.util.List;

/**
 * 流程审批记录 服务类
 *
 * @author hubin
 * @since 2024-03-03
 */
public interface FlwProcessApprovalService extends IBaseService<FlwProcessApproval> {

    Page<FlwProcessApproval> page(Page<FlwProcessApproval> page, FlwProcessApproval flwProcessApproval);

    /**
     * 根据流程实例ID查询审批记录列表
     *
     * @param instanceId 流程实例ID
     */
    List<FlwProcessApproval> listByInstanceId(Long instanceId);

    /**
     * 审批评论
     */
    boolean comment(ProcessApprovalDTO dto);

}
