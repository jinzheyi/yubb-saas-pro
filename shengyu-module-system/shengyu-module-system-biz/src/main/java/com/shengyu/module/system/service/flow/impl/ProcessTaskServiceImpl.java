package com.shengyu.module.system.service.flow.impl;

import com.baomidou.mybatisplus.core.toolkit.CollectionUtils;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.shengyu.framework.common.exception.util.ServiceExceptionUtil;
import com.shengyu.framework.common.util.json.JsonUtils;
import com.shengyu.framework.flowlong.engine.FlowDataTransfer;
import com.shengyu.framework.flowlong.engine.FlowLongEngine;
import com.shengyu.framework.flowlong.engine.TaskService;
import com.shengyu.framework.flowlong.engine.core.Execution;
import com.shengyu.framework.flowlong.engine.core.FlowCreator;
import com.shengyu.framework.flowlong.engine.core.FlowLongContext;
import com.shengyu.framework.flowlong.engine.core.PageParam;
import com.shengyu.framework.flowlong.engine.core.enums.PerformType;
import com.shengyu.framework.flowlong.engine.core.enums.ProcessType;
import com.shengyu.framework.flowlong.engine.core.enums.TaskType;
import com.shengyu.framework.flowlong.engine.entity.*;
import com.shengyu.framework.flowlong.engine.mapper.FlwExtInstanceMapper;
import com.shengyu.framework.flowlong.engine.model.ModelHelper;
import com.shengyu.framework.flowlong.engine.model.NodeAssignee;
import com.shengyu.framework.flowlong.engine.model.NodeModel;
import com.shengyu.framework.flowlong.engine.model.ProcessModel;
import com.shengyu.framework.security.core.LoginUser;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.module.system.controller.admin.flow.dto.*;
import com.shengyu.module.system.controller.admin.flow.vo.*;
import com.shengyu.module.system.dal.dataobject.flow.*;
import com.shengyu.module.system.dal.dataobject.user.AdminUserDO;
import com.shengyu.module.system.dal.mysql.flow.FlowlongMapper;
import com.shengyu.module.system.framework.flow.FlowForm;
import com.shengyu.module.system.framework.flow.FlowHelper;
import com.shengyu.module.system.service.flow.*;
import com.shengyu.module.system.service.notify.NotifySendService;
import com.shengyu.module.system.service.user.AdminUserService;
import org.apache.commons.collections4.MapUtils;
import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.annotation.Resource;
import java.util.*;
import java.util.stream.Collectors;

/**
 * 流程任务 服务实现类
 *
 * @author 青苗
 * @since 2023-12-11
 */
@Service
public class ProcessTaskServiceImpl implements IProcessTaskService {
    @Resource
    private FlowlongMapper flowlongMapper;
    @Resource
    private FlwExtInstanceMapper extInstanceMapper;
    @Resource
    private FlowLongEngine flowLongEngine;
    @Resource
    private IFlwProcessApprovalService flwProcessApprovalService;
    @Resource
    private IFlwProcessFormService flwProcessFormService;
    @Resource
    private IFlwFormTemplateService flwFormTemplateService;
    @Resource
    private IFlwProcessConfigureService flwProcessConfigureService;
    @Resource
    private AdminUserService adminUserService;
    @Resource
    private NotifySendService notifySendService;

    @Override
    public Page<PendingClaimTaskVO> pagePendingClaim(PageParam<ProcessTaskDTO> pageParam) {
        ProcessTaskDTO dto = this.getProcessTaskDTO(pageParam);
        Page<PendingClaimTaskVO> page = pageParam.page();
        page.setSearchCount(false);
        return flowlongMapper.selectPagePendingClaim(page, dto);
    }

    @Override
    public Page<PendingApprovalTaskVO> pagePendingApproval(PageParam<ProcessTaskDTO> pageParam) {
        ProcessTaskDTO dto = this.getProcessTaskDTO(pageParam);
        Page<PendingApprovalTaskVO> page = pageParam.page();
        page.setSearchCount(false);
        return flowlongMapper.selectPagePendingApproval(page, dto);
    }

    @Override
    public Page<ProcessTaskVO> pageMyApplication(PageParam<ProcessTaskDTO> pageParam) {
        ProcessTaskDTO dto = this.getProcessTaskDTO(pageParam);
        Page<ProcessTaskVO> page = pageParam.page();
        page.setSearchCount(false);
        return flowlongMapper.selectPageMyApplication(page, dto);
    }

    @Override
    public Page<ProcessTaskVO> pageMyReceived(PageParam<ProcessTaskDTO> pageParam) {
        ProcessTaskDTO dto = this.getProcessTaskDTO(pageParam);
        Page<ProcessTaskVO> page = pageParam.page();
        page.setSearchCount(false);
        return flowlongMapper.selectPageMyReceived(page, dto);
    }

    @Override
    public Page<ProcessTaskVO> pageApproved(PageParam<ProcessTaskDTO> pageParam) {
        ProcessTaskDTO dto = this.getProcessTaskDTO(pageParam);
        Page<ProcessTaskVO> page = pageParam.page();
        page.setSearchCount(false);
        return flowlongMapper.selectPageApproved(pageParam.page(), dto);
    }

    @Override
    public TaskApprovalVO approvalInfo(ProcessInfoDTO dto) {
        final Long instanceId = dto.getInstanceId();
        FlwHisInstance hisInstance = flowLongEngine.queryService().getHistInstance(instanceId);
        ServiceExceptionUtil.isEmpty(hisInstance, "未发现指定审批流程");
        TaskApprovalVO vo = new TaskApprovalVO();
        vo.setInstanceId(hisInstance.getId());
        vo.setInstanceState(hisInstance.getInstanceState());
        vo.setTaskId(dto.getTaskId());
        vo.setCreateId(hisInstance.getCreateId());
        vo.setCreateBy(hisInstance.getCreateBy());
        vo.setCreateTime(hisInstance.getCreateTime());

        // 获取当前流程模型
        FlwExtInstance extInstance = extInstanceMapper.selectById(instanceId);
        vo.setModelContent(extInstance.getModelContent());
        ProcessModel processModel = extInstance.model();

        // 表单配置权限
        if (null != dto.getTaskId()) {
            FlwTask flwTask = this.getFlwTask(dto.getTaskId());
            NodeModel nodeModel = processModel.getNode(flwTask.getTaskKey());
            Map<String, Object> extendConfig = nodeModel.getExtendConfig();
            if (null != extendConfig) {
                // 表单配置内容
                Object formConfig = extendConfig.get("formConfig");
                if (null != formConfig) {
                    vo.setFormConfig(formConfig);
                }
            }
            vo.setTaskType(flwTask.getTaskType());
            vo.setActionUrl(nodeModel.getActionUrl());

            // 设置按钮控制参数
            vo.setAllowTransfer(nodeModel.getAllowTransfer());
            vo.setAllowAppendNode(nodeModel.getAllowAppendNode());
            vo.setAllowRollback(nodeModel.getAllowRollback());
            vo.setAllowCc(nodeModel.getAllowCc());
            vo.setRejectStrategy(nodeModel.getRejectStrategy());
        }

        FlwProcessConfigure configure = flwProcessConfigureService.getByProcessId(hisInstance.getProcessId());
        if (null != configure) {
            boolean searchFormContent = true;

            // 流程设置
            vo.setProcessSetting(configure.getProcessSetting());

            // 表单设置
            if (ProcessType.business.eq(extInstance.getProcessType())) {
                // 业务流程，加载表单模板内容
                FlwFormTemplate formTemplate = flwFormTemplateService.getByConfigure(configure.getProcessForm());
                ServiceExceptionUtil.fail(null == formTemplate, "未发现指定业务流程表单模板");
                vo.setFormTemplate(formTemplate);
                if (Objects.equals(formTemplate.getType(), 1)) {
                    // 系统表单情况
                    searchFormContent = false;
                }
            }

            // 表单内容
            if (searchFormContent) {
                vo.setFormContent(this.formContent(instanceId, hisInstance.getParentInstanceId()));
            }
        }

        // 渲染节点列表
        Map<String, Object> formArgs = null;
        if (null != vo.getFormContent()) {
            Map<String, Object> formMap = JsonUtils.readMap(vo.getFormContent());
            if (null != formMap) {
                formArgs = (Map<String, Object>) formMap.get("formData");
            }
        }
        final Execution execution = new Execution(FlowHelper.getFlowCreator(), formArgs);
        final FlowLongContext flowLongContext = flowLongEngine.getContext();
        final NodeModel nodeModel = processModel.getNodeConfig();
        Map<String, Integer> renderNodes = new HashMap<>();
        List<String> usedNodeKeys = ModelHelper.getAllUsedNodeKeys(flowLongContext, execution, nodeModel, hisInstance.getCurrentNodeKey());
        for (String nodeKey : usedNodeKeys) {
            // 已执行节点
            renderNodes.put(nodeKey, 0);
        }

        // 审批记录列表
        List<FlwProcessApproval> processApprovals = flwProcessApprovalService.listByInstanceId(instanceId);

        // 待执行节点列表
        List<String> pendingNodeKeys = new ArrayList<>();

        // 追加当前正在审核任务记录
        if (null == hisInstance.getEndTime()) {
            List<FlwTask> flwTaskList = flowLongEngine.queryService().getTasksByInstanceId(instanceId);
            if (CollectionUtils.isNotEmpty(flwTaskList)) {
                FlwTask flwTask = flwTaskList.get(0);
                FlwProcessApproval fpa = new FlwProcessApproval();
                fpa.setInstanceId(instanceId);
                fpa.setTaskId(flwTask.getId());
                fpa.setTaskName(flwTask.getTaskName());
                fpa.setType(-1);
                Integer performType = flwTask.getPerformType();
                if (!(PerformType.timer.eq(performType) && PerformType.trigger.eq(performType))) {
                    // 排除 定时器 & 触发器
                    ApprovalContent content = new ApprovalContent();
                    if (PerformType.countersign.eq(performType)) {
                        // 会签情况
                        flowLongEngine.queryService().getActiveTaskActorsByInstanceId(flwTask.getInstanceId())
                                .ifPresent(content::appendNodeAssignee);
                    } else {
                        // 其它
                        flowLongEngine.queryService().getActiveTaskActorsByTaskId(flwTask.getId())
                                .ifPresent(content::appendNodeAssignee);
                    }
                    fpa.setContent(content);
                }
                processApprovals.add(fpa);

                // 正在执行节点
                for (FlwTask ft : flwTaskList) {
                    renderNodes.put(ft.getTaskKey(), 1);
                    pendingNodeKeys.add(ft.getTaskKey());
                }
            }
        } else {
            // 流程结束，渲染最终完成结束节点
            renderNodes.put(hisInstance.getCurrentNodeKey(), 0);
        }

        // 找到未记录【执行节点】的办理任务，获取可能在分支中已执行节点【排除包含正在执行节点的历史数据】
        processApprovals.stream().filter(t -> Objects.equals(3, t.getType()) && !usedNodeKeys.contains(t.getTaskKey()))
                .map(t -> ModelHelper.getAllUsedNodeKeys(flowLongContext, execution, nodeModel, t.getTaskKey()))
                .filter(nodeKeys -> nodeKeys.stream().noneMatch(pendingNodeKeys::contains))
                .forEach(nodeKeys -> nodeKeys.forEach(nodeKey -> renderNodes.put(nodeKey, 0)) );

        // 设置渲染节点信息
        vo.setRenderNodes(renderNodes);
        vo.setProcessApprovals(processApprovals);
        return vo;
    }

    /**
     * 查询流程表单内容
     * <p>
     * 普通流程，表单填写内容，子流程需要获取主流程表单
     * </p>
     */
    private String formContent(Long instanceId, Long parentInstanceId) {
        // 普通流程，表单填写内容，子流程需要获取主流程表单
        FlwProcessForm flwProcessForm;
        if (null != parentInstanceId) {
            flwProcessForm = flwProcessFormService.getByInstanceId(parentInstanceId);
        } else {
            flwProcessForm = flwProcessFormService.getByInstanceId(instanceId);
        }
        return null == flwProcessForm ? null : flwProcessForm.getContent();
    }

    @Override
    public List<Map<String, String>> listPreviousNodes(Long taskId) {
        FlwTask flwTask = this.getFlwTask(taskId);
        ProcessModel processModel = flowLongEngine.runtimeService().getProcessModelByInstanceId(flwTask.getInstanceId());
        List<String> nodeKeys = ModelHelper.getAllPreviousNodeKeys(processModel.getNode(flwTask.getTaskKey()));
        List<Map<String, String>> mapList = new ArrayList<>();
        if (CollectionUtils.isNotEmpty(nodeKeys)) {
            for (String nodeKey : nodeKeys) {
                // 模型中找到可回退历史节点信息
                NodeModel nodeModel = processModel.getNode(nodeKey);
                if (null != nodeModel) {
                    Map<String, String> map = new HashMap<>();
                    map.put("nodeName", nodeModel.getNodeName());
                    map.put("nodeKey", nodeModel.getNodeKey());
                    mapList.add(map);
                }
            }
        }
        return mapList;
    }

    @Override
    public Map<String, Object> listNextNodes(NextNodesDTO dto) {
        FlwInstance instance = flowLongEngine.queryService().getInstance(dto.getInstanceId());
        ServiceExceptionUtil.fail(null == instance, "当前流程实例不存在");
        FlwExtInstance extInstance = flowLongEngine.queryService().getExtInstance(dto.getInstanceId());
        NodeModel rootNodeModel = extInstance.model().getNodeConfig();
        Execution execution = new Execution(FlowHelper.getFlowCreator(), dto.getArgs());
        Map<String, Object> nodeModelsMap = new HashMap<>();
        List<NodeModel> nodeModels = ModelHelper.getNextChildNodes(flowLongEngine.getContext(), execution, rootNodeModel, instance.getCurrentNodeKey());
        if (null != nodeModels) {
            nodeModelsMap.put("nodeType", getNodeType(nodeModels));
            nodeModelsMap.put("nodeModels", nodeModels.stream().map(NodeModel::cloneBaseInfo).toList());
        }
        return nodeModelsMap;
    }

    private static int getNodeType(List<NodeModel> nodeModels) {
        // 1，普通审批
        int nodeType = 1;
        if (nodeModels.size() > 1) {
            // 判断是否为条件分支，根据父节点确定分支类型
            NodeModel nextParentNode = nodeModels.get(0).getParentNode();
            if (nextParentNode.conditionNode()) {
                // 4，条件分支
                nodeType = 4;
            } else if (nextParentNode.parallelNode()) {
                // 8，并行分支
                nodeType = 8;
            } else if (nextParentNode.inclusiveNode()) {
                // 9，包容分支
                nodeType = 9;
            }
        }
        return nodeType;
    }

    @Override
    public boolean viewed(Long taskId) {
        return flowLongEngine.taskService().viewTask(taskId, FlowHelper.getFlwTaskActor());
    }

    /**
     * 获取流程任务DTO
     */
    private ProcessTaskDTO getProcessTaskDTO(PageParam<ProcessTaskDTO> pageParam) {
        ProcessTaskDTO dto = pageParam.getData();
        if (null == dto) {
            dto = new ProcessTaskDTO();
        }
        LoginUser userSession = SecurityFrameworkUtils.getLoginUser();
        dto.setCreateId(userSession.getId());
        return dto;
    }

    @Transactional(rollbackFor = Exception.class)
    @Override
    public boolean reclaim(Long taskId, FlowCreator flowCreator) {
        TaskService taskService = flowLongEngine.taskService();
        return taskService.reclaimTask(taskId, flowCreator).isPresent();
    }

    @Transactional(rollbackFor = Exception.class)
    @Override
    public boolean claim(Long taskId, FlowCreator flowCreator) {
        TaskService taskService = flowLongEngine.taskService();
        return null != taskService.claimRole(taskId, flowCreator);
    }

    @Transactional(rollbackFor = Exception.class)
    @Override
    public boolean revoke(ProcessApprovalDTO dto, FlowCreator flowCreator) {
        FlwInstance flwInstance = flowLongEngine.queryService().getInstance(dto.getInstanceId());
        ServiceExceptionUtil.fail(null == flwInstance, "流程实例已结束");
        FlwProcessConfigure configure = flwProcessConfigureService.getByProcessId(flwInstance.getProcessId());
        if (null != configure && null != configure.getProcessSetting()) {
            ServiceExceptionUtil.fail(!Objects.equals(true, configure.getProcessSetting().getAllowRevocation()),
                    "该审批流程不允许撤回");
        }
        FlowHelper.setProcessApprovalOpinion(dto.getContent());
        if (dto.isTermination()) {
            // 发起人撤回终止
            flowLongEngine.runtimeService().revoke(dto.getInstanceId(), flowCreator);
            return true;
        }

        // 发起人撤回任务
        FlwHisTask fht = flowLongEngine.queryService().getStartTaskByInstanceId(dto.getInstanceId());
        TaskService taskService = flowLongEngine.taskService();
        return taskService.withdrawTask(fht.getId(), flowCreator).isPresent();
    }

    @Transactional(rollbackFor = Exception.class)
    @Override
    public boolean execute(ExecuteTaskDTO dto) {
        if (StringUtils.isNotBlank(dto.getOpinion())) {
            FlowHelper.setProcessApprovalOpinion(dto.getOpinion());
        }
        return flowLongEngine.executeTask(dto.getTaskId(), FlowHelper.getFlowCreator(), dto.getArgs());
    }

    @Override
    public List<FlwHisTaskVO> listHisTaskByInstanceId(Long instanceId) {
        List<FlwHisTaskVO> voList = flowlongMapper.selectListHisTaskByInstanceId(instanceId);
        if (CollectionUtils.isNotEmpty(voList)) {
            List<FlwHisTaskActorVO> actorList = flowlongMapper.selectListHisTaskActorVOByInstanceId(instanceId);
            if (CollectionUtils.isNotEmpty(actorList)) {
                voList.forEach(t -> t.setActorList(actorList.stream().filter(v -> Objects.equals(v.getTaskId(), t.getId()))
                        .collect(Collectors.toList())));
            }
        }
        return voList;
    }

    @Transactional(rollbackFor = Exception.class)
    @Override
    public boolean reject(RejectTaskDTO dto) {
        FlwTask flwTask = this.checkFlwTaskById(dto.getTaskId());
        FlowHelper.setProcessApprovalOpinion(dto.getReason());
        return flowLongEngine.executeRejectTask(flwTask, dto.getNodeKey(), FlowHelper.getFlowCreator(), dto.getArgs()).isPresent();
    }

    private FlwTask checkFlwTaskById(Long taskId) {
        FlwTask flwTask = flowLongEngine.queryService().getTask(taskId);
        ServiceExceptionUtil.isEmpty(flwTask, "当前ID执行任务不存在");
        return flwTask;
    }

    @Override
    public boolean carbonCopy(TaskCarbonCopyDTO dto) {
        FlwTask flwTask = this.checkFlwTaskById(dto.getTaskId());
        List<AdminUserDO> sysUsers = adminUserService.getUserList(dto.getUserIds());
        ServiceExceptionUtil.isEmpty(sysUsers, "指定用户不存在");
        flowLongEngine.queryService().getCcTaskActorsByInstanceId(flwTask.getInstanceId())
                .ifPresent(t -> t.forEach(actor -> sysUsers.forEach(user -> {
                    if (Objects.equals(actor.getActorId(), String.valueOf(user.getId()))) {
                        ServiceExceptionUtil.fail("用户【" + user.getNickname() + "】已抄送，请勿重复操作");
                    }
                })));

        // 传递抄送意见
        FlowHelper.setProcessApprovalOpinion(dto.getContent());

        // 创建抄送任务
        return flowLongEngine.createCcTask(flwTask, sysUsers.stream().map(t -> {
            NodeAssignee nodeAssignee = new NodeAssignee();
            nodeAssignee.setId(String.valueOf(t.getId()));
            nodeAssignee.setName(t.getNickname());
            return nodeAssignee;
        }).toList(), FlowHelper.getFlowCreator());
    }

    @Transactional(rollbackFor = Exception.class)
    @Override
    public boolean transfer(TaskAssigneeDTO dto) {
        FlowHelper.setProcessApprovalOpinion(dto.getContent());
        if (Objects.equals(0, dto.getType())) {
            // 转办
            TaskService taskService = flowLongEngine.taskService();
            return taskService.transferTask(dto.getTaskId(), FlowHelper.getFlowCreator(), dto.toFlowCreator());
        }

        // 委派
        TaskService taskService = flowLongEngine.taskService();
        return taskService.delegateTask(dto.getTaskId(), FlowHelper.getFlowCreator(), dto.toFlowCreator());
    }

    private FlwTask getFlwTask(Long taskId) {
        FlwTask flwTask = flowLongEngine.queryService().getTask(taskId);
        ServiceExceptionUtil.isEmpty(flwTask, "指定ID任务已执行完成");
        return flwTask;
    }

    @Transactional(rollbackFor = Exception.class)
    @Override
    public boolean comment(ProcessApprovalDTO dto) {
        return flwProcessApprovalService.comment(dto);
    }

    @Transactional(rollbackFor = Exception.class)
    @Override
    public boolean consent(TaskApprovalDTO dto) {
        // 判断是否修改模型
        if (MapUtils.isNotEmpty(dto.getAssigneeMap())) {

            // 传递动态分配处理人员
            FlowDataTransfer.dynamicAssignee(Collections.unmodifiableMap(dto.getAssigneeMap()));
        }

        // 获取任务，保存表单
        FlwTask flwTask = this.getFlwTask(dto.getTaskId());
        FlowHelper.setProcessApprovalOpinion(dto.getContent());
        ServiceExceptionUtil.fail(!flwProcessFormService.saveForm(flwTask.getInstanceId(), dto.getProcessForm()), "保存保单内容失败");
        FlowForm.argsTransfer(dto.getProcessForm());

        // 委派审批
        if (TaskType.delegate.eq(flwTask.getTaskType())) {
            return flowLongEngine.taskService().resolveTask(flwTask.getId(), FlowHelper.getFlowCreator());
        }

        // 普通审批
        return flowLongEngine.executeTask(dto.getTaskId(), FlowHelper.getFlowCreator());
    }

    @Transactional(rollbackFor = Exception.class)
    @Override
    public boolean rejection(TaskApprovalDTO dto) {
        FlwTask flwTask = this.getFlwTask(dto.getTaskId());
        FlowHelper.setProcessApprovalOpinion(dto.getContent());
        return flowLongEngine.executeRejectTask(flwTask, dto.getNodeKey(), FlowHelper.getFlowCreator(), dto.getArgs(), dto.isTermination()).isPresent();
    }

    @Transactional(rollbackFor = Exception.class)
    @Override
    public boolean appendNode(TaskAppendNodeDTO dto) {
        FlwTask flwTask = this.getFlwTask(dto.getTaskId());
        FlowHelper.setProcessApprovalOpinion(dto.getContent());
        return flowLongEngine.executeAppendNodeModel(flwTask.getId(), dto.toNodeModel(),
                FlowHelper.getFlowCreator(), dto.getType() == 9);
    }

    @Transactional(rollbackFor = Exception.class)
    @Override
    public boolean jump(TaskJumpDTO dto) {
        FlowHelper.setProcessApprovalOpinion(dto.getContent());
        return flowLongEngine.executeJumpTask(dto.getTaskId(), dto.getNodeKey(), FlowHelper.getFlowCreator());
    }

    @Override
    public Integer countPendingApproval() {
        LoginUser userSession = SecurityFrameworkUtils.getLoginUser();
        return flowlongMapper.selectCountPendingApproval(userSession.getId());
    }

    @Override
    public boolean urgeByInstanceId(Long instanceId) {
        FlwExtInstance extInstance = flowLongEngine.queryService().getExtInstance(instanceId);
        flowLongEngine.queryService().getActiveTaskActorsByInstanceId(instanceId)
                .ifPresent(taskActors -> {
                    if (taskActors.isEmpty()) {
                        return;
                    }
                    // 发送催办消息
                    List<Long> actorIds = taskActors.stream().map(t -> Long.valueOf(t.getActorId())).toList();
                    Map<String, Object> templateParams = new HashMap<>();
                    templateParams.put("processName", extInstance.getProcessName());
                    actorIds.forEach(actorId -> {
                        notifySendService.sendSingleNotifyToAdmin(actorId,
                                "flow_urge_msg", templateParams);
                    });
                });
        return true;
    }
}
