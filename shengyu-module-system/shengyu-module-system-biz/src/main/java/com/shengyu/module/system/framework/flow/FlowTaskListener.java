package com.shengyu.module.system.framework.flow;

import com.aizuda.boot.modules.common.MessageEvent;
import com.shengyu.module.system.dal.dataobject.flow.ApprovalContent;
import com.shengyu.module.system.dal.dataobject.flow.FlwProcessApproval;
import com.aizuda.boot.modules.flw.service.IFlwProcessApprovalService;
import com.aizuda.boot.modules.system.entity.enums.BusinessType;
import com.aizuda.boot.modules.system.service.ISysUserRoleService;
import com.shengyu.framework.flowlong.engine.FlowLongEngine;
import com.shengyu.framework.flowlong.engine.core.FlowCreator;
import com.shengyu.framework.flowlong.engine.core.enums.*;
import com.shengyu.framework.flowlong.engine.entity.*;
import com.shengyu.framework.flowlong.engine.listener.TaskListener;
import com.shengyu.framework.flowlong.engine.model.NodeAssignee;
import com.shengyu.framework.flowlong.engine.model.NodeModel;
import com.shengyu.framework.flowlong.engine.model.ProcessModel;
import com.aizuda.common.toolkit.CollectionUtils;
import com.aizuda.common.toolkit.StringUtils;
import com.aizuda.core.api.ApiAssert;
import javax.annotation.Resource;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.function.Supplier;

@Component
public class FlowTaskListener implements TaskListener {
    @Resource
    private IFlwProcessApprovalService flwProcessApprovalService;
    @Resource
    private FlowLongEngine flowLongEngine;
    @Resource
    private ApplicationEventPublisher applicationEventPublisher;
    @Resource
    private ISysUserRoleService userRoleService;

    @Override
    public boolean notify(TaskEventType eventType, Supplier<FlwTask> supplier, List<FlwTaskActor> taskActors,
                          NodeModel nodeModel, FlowCreator flowCreator) {
        // 获取当前任务信息
        FlwTask flwTask = supplier.get();

        // 不进行二次执行自动跳转逻辑，防止出现taskId不存在，退回需要发起人手动审批
        if (TaskEventType.create.eq(eventType) || TaskEventType.recreate.eq(eventType)
                // 重新发起审批创建
                || TaskEventType.reApproveCreate.eq(eventType)) {
            // 获取当前节点信息
            if (null != flwTask) {
                NodeModel currentNodeModel = this.getNodeModel(flwTask, nodeModel);
                // 创建人物，发起人自己，自动跳过
                if (TaskEventType.create.eq(eventType) && NodeApproveSelf.AutoSkip.eq(currentNodeModel.getApproveSelf())) {
                    if (NodeSetType.initiatorThemselves.eq(currentNodeModel.getSetType())) {
                        // 发起人自己，执行自动跳转逻辑
                        flowLongEngine.autoJumpTask(flwTask.getId(), flowCreator);
                    } else {
                        // 流程发起人自动跳过处理
                        final FlwInstance instance = flowLongEngine.queryService().getInstance(flwTask.getInstanceId());
                        if (taskActors.stream().anyMatch(t -> Objects.equals(t.getActorId(), instance.getCreateId()))) {
                            // 审批人与提交人为同一人时，执行自动跳转逻辑
                            flowLongEngine.autoJumpTask(flwTask.getId(), FlowCreator.of(instance.getTenantId(),
                                    instance.getCreateId(), instance.getCreateBy()));
                        }
                    }
                } else {
                    // 推送消息，需要勾选【审批提醒】
                    if (Boolean.TRUE.equals(currentNodeModel.getRemind())) {
                        this.sendMessage(flwTask, flowCreator);
                    }
                }
            }
            // 创建任务直接跳过
            return true;
        }

        // 监听处理其它任务事件
        FlwProcessApproval fpa = new FlwProcessApproval();
        if (null != flwTask) {
            fpa.setInstanceId(flwTask.getInstanceId());
            fpa.setTenantId(flwTask.getTenantId());
            fpa.setTaskId(flwTask.getId());
            if (eventType == TaskEventType.routeJump) {
                fpa.setTaskName(flwTask.getTaskName() + " -> 路由至 -> " + nodeModel.getNodeName());
            } else {
                fpa.setTaskName(flwTask.getTaskName());
            }
            PerformType performType = PerformType.get(flwTask.getPerformType());
            if (performType == PerformType.start && eventType == TaskEventType.start) {
                // 发起
                fpa.setType(1);
            } else {
                if (eventType == TaskEventType.assignment) {
                    TaskType taskType = TaskType.get(flwTask.getTaskType());
                    if (taskType == TaskType.transfer) {
                        // 转办、代理人办理完任务直接进入下一个节点
                        fpa.setType(6);
                    } else if (taskType == TaskType.delegate) {
                        // 委派、代理人办理完任务该任务重新归还给原处理人
                        fpa.setType(7);
                    } else if (taskType == TaskType.delegateReturn) {
                        // 委派归还任务
                        fpa.setType(18);
                    }
                }

                // 获取当前节点信息
                NodeModel currentNodeModel = this.getNodeModel(flwTask, nodeModel);
                boolean saveContent = false;
                ApprovalContent content = new ApprovalContent();
                if (TaskEventType.cc.eq(eventType)) {
                    // 自动抄送
                    content.setNodeUserList(currentNodeModel.getNodeAssigneeList());
                    saveContent = true;
                } else {

                    // 其它
                    String opinion = FlowHelper.getProcessApprovalOpinion();
                    if (StringUtils.hasLength(opinion)) {
                        FlowHelper.removeProcessApprovalOpinion();
                        content.setOpinion(opinion);
                        saveContent = true;
                    }

                    // 手动抄送
                    if (TaskEventType.createCc.eq(eventType)) {
                        content.setNodeUserList(taskActors.stream().map(NodeAssignee::of).toList());
                        if (null == content.getOpinion()) {
                            content.setOpinion("发起抄送任务");
                            saveContent = true;
                        }
                    }
                }

                if (NodeSetType.specifyMembers.eq(currentNodeModel.getSetType())) {
                    // 指定成员类型
                    content.setNodeUserList(currentNodeModel.getNodeAssigneeList());
                    saveContent = true;
                } else if (NodeSetType.role.eq(currentNodeModel.getSetType())) {
                    // 角色类型
                    content.setNodeRoleList(currentNodeModel.getNodeAssigneeList());
                    saveContent = true;
                }

                // 记录是否调用流程
                String callProcess = currentNodeModel.getCallProcess();
                if (StringUtils.hasLength(callProcess)) {
                    content.setCallProcess(callProcess);
                    saveContent = true;
                }

                // 记录审批内容
                if (saveContent) {
                    fpa.setContent(content);
                }
            }

            //用于流程图颜色标记
            fpa.setTaskKey(flwTask.getTaskKey());
        }

        if (TaskEventType.autoComplete.eq(eventType) || TaskEventType.autoReject.eq(eventType)
                || TaskEventType.trigger.eq(eventType)) {
            // 自动审批情况，设置默认处理人信息
            fpa.setCreateId(0L);
            fpa.setCreateBy("admin");
        }

        if (null == fpa.getType()) {
            // 其它类型转换
            fpa.setType(this.getType(eventType));
        }
        return flwProcessApprovalService.save(fpa);
    }

    private NodeModel getNodeModel(FlwTask flwTask, NodeModel nodeModel) {
        if (null == nodeModel) {
            // 不存在情况从数据库中获取
            ProcessModel processModel = flowLongEngine.runtimeService().getProcessModelByInstanceId(flwTask.getInstanceId());
            ServiceExceptionUtil.isEmpty(processModel, "流程模型节点查询异常");
            return processModel.getNode(flwTask.getTaskKey());
        }
        return nodeModel;
    }

    private int getType(TaskEventType eventType) {
        // 办理
        int type = 3;
        if (eventType == TaskEventType.start) {
            // 发起
            type = 1;
        } else if (eventType == TaskEventType.cc || eventType == TaskEventType.createCc) {
            // 抄送
            type = 2;
        } else if (eventType == TaskEventType.reject) {
            // 驳回
            type = 4;
        } else if (eventType == TaskEventType.claimRole || eventType == TaskEventType.claimDepartment) {
            // 认领
            type = 5;
        } else if (eventType == TaskEventType.jump || eventType == TaskEventType.routeJump
                || eventType == TaskEventType.rejectJump || eventType == TaskEventType.reApproveJump) {
            // 跳转
            type = 8;
        } else if (eventType == TaskEventType.reclaim) {
            // 拿回
            type = 9;
        } else if (eventType == TaskEventType.resume) {
            // 唤醒
            type = 10;
        } else if (eventType == TaskEventType.revoke || eventType == TaskEventType.withdraw) {
            // 撤销
            type = 15;
        } else if (eventType == TaskEventType.terminate) {
            // 终止
            type = 16;
        } else if (eventType == TaskEventType.timeout) {
            // 超时
            type = 17;
        } else if (eventType == TaskEventType.autoJump) {
            // 自动跳转
            type = 19;
        } else if (eventType == TaskEventType.autoComplete) {
            // 自动完成
            type = 20;
        } else if (eventType == TaskEventType.autoReject) {
            // 自动拒绝
            type = 21;
        } else if (eventType == TaskEventType.callProcess) {
            // 调用外部流程任务【办理子流程】
            type = 22;
        } else if (eventType == TaskEventType.trigger) {
            // 触发器任务
            type = 23;
        }
        return type;
    }

    public void sendMessage(FlwTask flwTask, FlowCreator flowCreator) {
        Optional<List<FlwTaskActor>> taskActorsOptional = flowLongEngine.queryService().getActiveTaskActorsByTaskId(flwTask.getId());
        if (taskActorsOptional.isPresent()) {
            List<FlwTaskActor> flwTaskActors = taskActorsOptional.get();
            if (CollectionUtils.isEmpty(flwTaskActors)) {
                // 暂时先不处理，根据具体业务调整
                return;
            }
            List<Long> actorIds = flwTaskActors.stream().map(t -> Long.valueOf(t.getActorId())).toList();
            FlwTaskActor fta = flwTaskActors.get(0);
            if (ActorType.role.eq(fta.getActorType())) {
                // 流程任务处理者为角色情况，查询对应用户ID列表
                actorIds = userRoleService.listUserIdsByRoleIds(actorIds);
            }
            FlwExtInstance extInstance = flowLongEngine.queryService().getExtInstance(flwTask.getInstanceId());
            // 发送消息
            MessageEvent messageEvent = new MessageEvent();
            messageEvent.setTitle("流程：" + extInstance.getProcessName() + " 待审批");
            messageEvent.setContent(messageEvent.getTitle() + " ，当前所在节点：" + flwTask.getTaskName() + " ，任务发起人：" + flowCreator.getCreateBy());
            messageEvent.setCreateId(Long.valueOf(flowCreator.getCreateId()));
            messageEvent.setCreateBy(flowCreator.getCreateBy());
            messageEvent.setCategory(2);
            messageEvent.setBusinessId(flwTask.getInstanceId());
            messageEvent.setBusinessType(BusinessType.flowTodoTask.name());
            messageEvent.setUserIds(actorIds);
            applicationEventPublisher.publishEvent(messageEvent);
        }
    }
}
