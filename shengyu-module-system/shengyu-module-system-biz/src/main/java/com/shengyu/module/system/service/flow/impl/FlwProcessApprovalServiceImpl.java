package com.shengyu.module.system.service.flow.impl;

import com.aizuda.boot.modules.flw.entity.ApprovalContent;
import com.aizuda.boot.modules.flw.entity.FlwProcessApproval;
import com.aizuda.boot.modules.flw.entity.dto.ProcessApprovalDTO;
import com.aizuda.boot.modules.flw.mapper.FlwProcessApprovalMapper;
import com.aizuda.boot.modules.flw.service.IFlwProcessApprovalService;
import com.aizuda.bpm.engine.FlowLongEngine;
import com.aizuda.bpm.engine.entity.FlwTask;
import com.aizuda.service.service.BaseServiceImpl;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import lombok.AllArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * 流程审批记录 服务实现类
 *
 * @author hubin
 * @since 2024-03-03
 */
@Service
@AllArgsConstructor
public class FlwProcessApprovalServiceImpl extends BaseServiceImpl<FlwProcessApprovalMapper, FlwProcessApproval> implements IFlwProcessApprovalService {
    private FlowLongEngine flowLongEngine;

    @Override
    public Page<FlwProcessApproval> page(Page<FlwProcessApproval> page, FlwProcessApproval flwProcessApproval) {
        LambdaQueryWrapper<FlwProcessApproval> lqw = Wrappers.lambdaQuery(flwProcessApproval);
        return super.page(page, lqw);
    }

    @Override
    public List<FlwProcessApproval> listByInstanceId(Long instanceId) {
        return lambdaQuery().eq(FlwProcessApproval::getInstanceId, instanceId)
                .orderByAsc(FlwProcessApproval::getCreateTime).list();
    }

    private FlwProcessApproval getFlwProcessApproval(Long instanceId, Long taskId, Integer type, String opinion) {
        FlwProcessApproval fpa = new FlwProcessApproval();
        fpa.setInstanceId(instanceId);
        fpa.setType(type);
        if (null != taskId) {
            // 任务节点信息记录
            FlwTask flwTask = flowLongEngine.queryService().getTask(taskId);
            if (null != flwTask) {
                fpa.setTenantId(flwTask.getTenantId());
                fpa.setTaskId(flwTask.getId());
                fpa.setTaskKey(flwTask.getTaskKey());
                fpa.setTaskName(flwTask.getTaskName());
            }
        }
        ApprovalContent approvalContent = new ApprovalContent();
        approvalContent.setOpinion(opinion);
        fpa.setContent(approvalContent);
        return fpa;
    }

    @Override
    public boolean comment(ProcessApprovalDTO dto) {
        return super.save(getFlwProcessApproval(dto.getInstanceId(), dto.getTaskId(), 0, dto.getContent()));
    }
}
