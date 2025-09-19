package com.shengyu.module.system.framework.flow;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.text.CharSequenceUtil;
import cn.hutool.core.thread.ThreadUtil;
import cn.hutool.core.util.BooleanUtil;
import cn.hutool.extra.spring.SpringUtil;
import com.baomidou.mybatisplus.core.toolkit.CollectionUtils;
import com.shengyu.framework.common.exception.util.ServiceExceptionUtil;
import com.shengyu.framework.flowlong.engine.FlowLongEngine;
import com.shengyu.framework.flowlong.engine.core.FlowCreator;
import com.shengyu.framework.flowlong.engine.core.FlowLongContext;
import com.shengyu.framework.flowlong.engine.core.enums.*;
import com.shengyu.framework.flowlong.engine.entity.FlwExtInstance;
import com.shengyu.framework.flowlong.engine.entity.FlwInstance;
import com.shengyu.framework.flowlong.engine.entity.FlwProcessSetting;
import com.shengyu.framework.flowlong.engine.entity.FlwTask;
import com.shengyu.framework.flowlong.engine.entity.FlwTaskActor;
import com.shengyu.framework.flowlong.engine.listener.TaskListener;
import com.shengyu.framework.flowlong.engine.model.NodeAssignee;
import com.shengyu.framework.flowlong.engine.model.NodeModel;
import com.shengyu.framework.flowlong.engine.model.ProcessModel;
import com.shengyu.framework.security.core.LoginUser;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.module.system.controller.admin.flow.vo.TaskTransferVO;
import com.shengyu.framework.flowlong.engine.entity.ApprovalContent;
import com.shengyu.module.system.dal.dataobject.flow.FlwProcessApproval;
import com.shengyu.framework.flowlong.engine.entity.FlwProcessConfigure;
import com.shengyu.module.system.enums.ErrorCodeConstants;
import com.shengyu.module.system.service.flow.IFlwProcessApprovalService;
import com.shengyu.module.system.service.flow.IFlwProcessConfigureService;
import com.shengyu.module.system.service.flow.IFlwProcessTaskService;
import com.shengyu.module.system.service.flow.IFlwTransferConfigureService;
import com.shengyu.module.system.service.notify.NotifySendService;
import com.shengyu.module.system.service.permission.PermissionService;
import java.util.stream.Collectors;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

import javax.annotation.Resource;
import java.util.*;
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
    private IFlwProcessTaskService flwProcessTaskService;
    @Resource
    private IFlwTransferConfigureService flwTransferConfigureService;
    @Resource
    private IFlwProcessConfigureService flwProcessConfigureService;

    @Override
    public boolean notify(TaskEventType eventType, Supplier<FlwTask> supplier, List<FlwTaskActor> taskActors,
      NodeModel nodeModel, FlowCreator flowCreator) {
        if (TaskEventType.update == eventType) {
            // 任务更新事件不处理
            return true;
        }

        // 获取当前任务信息
        FlwTask flwTask = supplier.get();

        // 不进行二次执行自动跳转逻辑，防止出现taskId不存在，退回需要发起人手动审批
        if (TaskEventType.create.eq(eventType) || TaskEventType.recreate.eq(eventType)
          // 重新发起审批创建
          || TaskEventType.reApproveCreate.eq(eventType)) {
            return this.createEventHandle(eventType, flwTask, taskActors, nodeModel, flowCreator);
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
                // 获取当前节点信息
                NodeModel currentNodeModel = this.getNodeModel(flwTask, nodeModel);
                boolean saveContent = false;
                ApprovalContent content = new ApprovalContent();
                // 其它
                String opinion = FlowHelper.getProcessApprovalOpinion();
                if (StringUtils.hasLength(opinion)) {
                    FlowHelper.removeProcessApprovalOpinion();
                    content.setOpinion(opinion);
                    saveContent = true;
                }
                // 这里考虑以后可能会模型加传阅节点的需求，而不单单是手动传阅
                if (TaskEventType.cc.eq(eventType) || TaskEventType.circulate.eq(eventType)) {
                    // 自动抄送或自动传阅
                    content.setNodeUserList(currentNodeModel.getNodeAssigneeList());
                    saveContent = true;
                }
                // 手动抄送/手动传阅
                else if (TaskEventType.createCc.eq(eventType) || TaskEventType.createCirculate.eq(eventType)) {
                    if (CollUtil.isNotEmpty(taskActors)) {
                        content.setNodeUserList(taskActors.stream().map(NodeAssignee::of).collect(
                                Collectors.toList()));
                    }
                    if (null == content.getOpinion()) {
                        content.setOpinion(TaskEventType.createCc.eq(eventType)? "手动发起抄送任务" : "手动发起传阅任务");
                        saveContent = true;
                    }
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
        if (Objects.nonNull(flowCreator)) {
            fpa.setCreateId(flowCreator.getCreateId());
            fpa.setCreateBy(flowCreator.getCreateBy());
        } else {
            // 自动审批情况，设置默认处理人信息
            LoginUser userSession = SecurityFrameworkUtils.getLoginUser();
            if (null == userSession) {
                fpa.setCreateId(FlowCreator.ADMIN.getCreateId());
                fpa.setCreateBy(FlowCreator.ADMIN.getCreateBy());
            } else {
                fpa.setCreateId(String.valueOf(userSession.getId()));
                fpa.setCreateBy(userSession.getNickname());
            }
        }
        if (null == fpa.getType()) {
            // 其它类型转换
            fpa.setType(this.getType(eventType));
        }
        //睡眠1秒，防止生成的记录时间一致不好排序
        ThreadUtil.sleep(1000);
        return flwProcessApprovalService.save(fpa);
    }

    private boolean createEventHandle(TaskEventType eventType, FlwTask flwTask, List<FlwTaskActor> taskActors,
                                      NodeModel nodeModel, FlowCreator flowCreator) {
        // 获取当前节点信息
        if (null != flwTask) {
            NodeModel currentNodeModel = this.getNodeModel(flwTask, nodeModel);
            if (TaskEventType.create.eq(eventType)) {
                final FlwInstance instance = flowLongEngine.queryService().getInstance(flwTask.getInstanceId());
                final FlwExtInstance extInstance = flowLongEngine.queryService().getExtInstance(flwTask.getInstanceId());
                // 创建人，发起人自己，自动跳过
                if (NodeApproveSelf.AutoSkip.eq(currentNodeModel.getApproveSelf())) {
                    if (NodeSetType.initiatorThemselves.eq(currentNodeModel.getSetType())) {
                        // 发起人自己，执行自动跳转逻辑
                        return flowLongEngine.autoJumpTask(flwTask.getId(), FlowCreator.of(instance.getTenantId(),
                                instance.getCreateId(), instance.getCreateBy()));
                    }

                    // 流程发起人自动跳过处理
                    if (CollUtil.isNotEmpty(taskActors) && taskActors.stream().anyMatch(t -> Objects.equals(t.getActorId(), instance.getCreateId())
                            // 当前节点处理人参与父节点审批
                            || flwProcessTaskService.approvedParentNode(flwTask.getParentTaskId(), t.getActorId())
                    )) {
                        // 审批人与提交人为同一人时，执行自动跳转逻辑
                        return flowLongEngine.autoJumpTask(flwTask.getId(), FlowCreator.of(instance.getTenantId(),
                                instance.getCreateId(), instance.getCreateBy()));
                    }
                }
                // 发起人自选 并且 人员为空 并且 配置了节点允许人员为空自动通过
                if (NodeSetType.initiatorSelected.eq(currentNodeModel.getSetType())
                        && CollUtil.isEmpty(taskActors)
                        && BooleanUtil.isTrue(currentNodeModel.getAllowInitiatorSelectedPass())) {
                    return flowLongEngine.autoCompleteTask(flwTask.getId(), FlowCreator.ADMIN);
                }

                FlwProcessSetting processSetting = CharSequenceUtil.isNotBlank(extInstance.getProcessSetting())?
                        FlowLongContext.fromJson(extInstance.getProcessSetting(), FlwProcessSetting.class) : null;
                if (null != processSetting && !Objects.equals(3, processSetting.getRepeatOperateSkip()) && CollUtil.isNotEmpty(taskActors)) {
                    if (Objects.equals(1, processSetting.getRepeatOperateSkip())) {
                        Optional<FlwTaskActor> matchingActor = taskActors.stream()
                                .filter(t ->
                                        // 当前节点处理人参与过历史节点审批
                                        flwProcessTaskService.approvedCompleteAllNode(flwTask, t.getActorId()))
                                .findFirst();
                        if (matchingActor.isPresent()) {
                            FlwTaskActor flwTaskActor = matchingActor.get();
                            // 仅审批一次，后续重复的审批节点均自动同意
                            return flowLongEngine.autoCompleteTask(flwTask.getId(), FlowCreator.of(instance.getTenantId(),
                                    flwTaskActor.getActorId(), flwTaskActor.getActorName()));
                        }
                    }
                    if (Objects.equals(2, processSetting.getRepeatOperateSkip())) {
                        Optional<FlwTaskActor> matchingActor = taskActors.stream()
                                .filter(t ->
                                        // 当前节点处理人参与父节点审批
                                        flwProcessTaskService.approvedCompleteParentNode(flwTask, t.getActorId()))
                                .findFirst();
                        if (matchingActor.isPresent()) {
                            FlwTaskActor flwTaskActor = matchingActor.get();
                            //连续审批的节点自动同意
                            return flowLongEngine.autoCompleteTask(flwTask.getId(), FlowCreator.of(instance.getTenantId(),
                                    flwTaskActor.getActorId(), flwTaskActor.getActorName()));
                        }
                    }
                }

                // 允许转办处理
                if (Objects.equals(true, currentNodeModel.getAllowTransfer()) && CollUtil.isNotEmpty(taskActors)) {
                    for (FlwTaskActor fta : taskActors) {
                        TaskTransferVO ttv = flwTransferConfigureService.getTaskTransfer(Long.parseLong(fta.getActorId()));
                        if (null != ttv) {
                            FlowCreator fc = FlowCreator.of(fta.getTenantId(), fta.getActorId(), fta.getActorName());
                            return flowLongEngine.taskService().transferTask(flwTask.getId(), fc, ttv.toFlowCreator());
                        }
                    }
                }
            }

            // 推送消息，需要勾选【审批提醒】
            if (Boolean.TRUE.equals(currentNodeModel.getRemind())) {
                this.sendMessage(flwTask, flowCreator);
            }
        }
        // 创建任务直接跳过
        return true;
    }

    private NodeModel getNodeModel(FlwTask flwTask, NodeModel nodeModel) {
        if (null == nodeModel) {
            // 不存在情况从数据库中获取
            ProcessModel processModel = flowLongEngine.runtimeService().getProcessModelByInstanceId(flwTask.getInstanceId());
            ServiceExceptionUtil.isEmpty(processModel, ErrorCodeConstants.FLOW_1_002_029_048);
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
        } else if (eventType == TaskEventType.cc) {
            // 抄送
            type = 2;
        } else if (eventType == TaskEventType.createCc) {
            // 手动抄送
            type = 501;
        } else if (eventType == TaskEventType.reject) {
            // 驳回
            type = 4;
        } else if (eventType == TaskEventType.claimRole) {
            // 角色认领
            type = 5;
        } else if (eventType == TaskEventType.claimDepartment) {
            // 部门认领
            type = 502;
        } else if (eventType == TaskEventType.jump) {
            // 跳转
            type = 8;
        } else if (eventType == TaskEventType.routeJump) {
            // 路由跳转
            type = 503;
        } else if (eventType == TaskEventType.rejectJump) {
            // 驳回跳转
            type = 504;
        } else if (eventType == TaskEventType.reApproveJump) {
            // 重新审批跳转
            type = 505;
        } else if (eventType == TaskEventType.transfer) {
            // 转办、代理人办理完任务直接进入下一个节点
            type = 6;
        } else if (eventType == TaskEventType.delegate) {
            // 委派、代理人办理完任务该任务重新归还给原处理人
            type = 7;
        } else if (eventType == TaskEventType.reclaim) {
            // 拿回
            type = 9;
        } else if (eventType == TaskEventType.resume) {
            // 唤醒
            type = 10;
        } else if (eventType == TaskEventType.revoke) {
            // 撤销
            type = 15;
        } else if (eventType == TaskEventType.withdraw) {
            // 撤回
            type = 506;
        } else if (eventType == TaskEventType.terminate) {
            // 终止
            type = 16;
        } else if (eventType == TaskEventType.timeout) {
            // 超时
            type = 17;
        } else if (eventType == TaskEventType.delegateResolve) {
            // 委派归还任务
            type = 18;
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
        } else if (eventType == TaskEventType.circulate) {
            // 传阅
            type = TaskType.circulate.getValue();
        } else if (eventType == TaskEventType.createCirculate) {
            // 手动传阅
            type = 507;
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
                PermissionService permissionService = SpringUtil.getBean(PermissionService.class);
                actorIds =  new ArrayList<>(permissionService.getUserRoleIdListByRoleId(actorIds));
            }
            FlwExtInstance extInstance = flowLongEngine.queryService().getExtInstance(flwTask.getInstanceId());
            // 发送消息
            NotifySendService notifySendService = SpringUtil.getBean(NotifySendService.class);
            Map<String, Object> templateParams = new HashMap<>();
            templateParams.put("processName", extInstance.getProcessName());
            templateParams.put("taskName", flwTask.getTaskName());
            templateParams.put("createBy", flowCreator.getCreateBy());
            templateParams.put("createId", flowCreator.getCreateId());
            templateParams.put("businessId", flwTask.getInstanceId());
            templateParams.put("userIds", actorIds);
            actorIds.forEach(actorId -> {
                notifySendService.sendSingleNotifyToAdmin(actorId,
                        "flow_send_msg", templateParams);
            });
        }
    }
}
