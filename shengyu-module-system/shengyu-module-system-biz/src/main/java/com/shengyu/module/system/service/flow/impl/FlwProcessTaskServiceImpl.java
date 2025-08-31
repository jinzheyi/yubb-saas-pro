package com.shengyu.module.system.service.flow.impl;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.text.CharSequenceUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.CollectionUtils;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.shengyu.framework.common.exception.util.ServiceExceptionUtil;
import com.shengyu.framework.common.util.json.JsonUtils;
import com.shengyu.framework.flowlong.engine.FlowDataTransfer;
import com.shengyu.framework.flowlong.engine.FlowLongEngine;
import com.shengyu.framework.flowlong.engine.TaskService;
import com.shengyu.framework.flowlong.engine.core.*;
import com.shengyu.framework.flowlong.engine.core.enums.ActorType;
import com.shengyu.framework.flowlong.engine.core.enums.PerformType;
import com.shengyu.framework.flowlong.engine.core.enums.ProcessType;
import com.shengyu.framework.flowlong.engine.core.enums.TaskState;
import com.shengyu.framework.flowlong.engine.core.enums.TaskType;
import com.shengyu.framework.flowlong.engine.entity.FlwExtInstance;
import com.shengyu.framework.flowlong.engine.entity.FlwHisInstance;
import com.shengyu.framework.flowlong.engine.entity.FlwHisTask;
import com.shengyu.framework.flowlong.engine.entity.FlwHisTaskActor;
import com.shengyu.framework.flowlong.engine.entity.FlwInstance;
import com.shengyu.framework.flowlong.engine.entity.FlwProcessSetting;
import com.shengyu.framework.flowlong.engine.entity.FlwTask;
import com.shengyu.framework.flowlong.engine.entity.FlwTaskActor;
import com.shengyu.framework.flowlong.engine.mapper.FlwExtInstanceMapper;
import com.shengyu.framework.flowlong.engine.mapper.FlwHisTaskActorMapper;
import com.shengyu.framework.flowlong.engine.mapper.FlwTaskActorMapper;
import com.shengyu.framework.flowlong.engine.model.ModelHelper;
import com.shengyu.framework.flowlong.engine.model.NodeAssignee;
import com.shengyu.framework.flowlong.engine.model.NodeModel;
import com.shengyu.framework.flowlong.engine.model.ProcessModel;
import com.shengyu.framework.security.core.LoginUser;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.module.system.controller.admin.flow.dto.*;
import com.shengyu.module.system.controller.admin.flow.vo.FlwHisTaskActorVO;
import com.shengyu.module.system.controller.admin.flow.vo.FlwHisTaskVO;
import com.shengyu.module.system.controller.admin.flow.vo.PendingApprovalTaskVO;
import com.shengyu.module.system.controller.admin.flow.vo.PendingClaimTaskVO;
import com.shengyu.module.system.controller.admin.flow.vo.ProcessTaskVO;
import com.shengyu.module.system.controller.admin.flow.vo.TaskApprovalVO;
import com.shengyu.module.system.controller.admin.user.vo.user.UserRespVO;
import com.shengyu.framework.flowlong.engine.entity.ApprovalContent;
import com.shengyu.module.system.dal.dataobject.flow.FlwFormTemplate;
import com.shengyu.module.system.dal.dataobject.flow.FlwProcessApproval;
import com.shengyu.framework.flowlong.engine.entity.FlwProcessConfigure;
import com.shengyu.module.system.dal.dataobject.flow.FlwProcessForm;
import com.shengyu.module.system.dal.dataobject.user.AdminUserDO;
import com.shengyu.module.system.dal.mysql.flow.FlowlongMapper;
import com.shengyu.module.system.dal.mysql.flow.SyFlwHisInstanceMapper;
import com.shengyu.module.system.dal.mysql.flow.SyFlwHisTaskMapper;
import com.shengyu.module.system.dal.mysql.flow.SyFlwTaskMapper;
import com.shengyu.module.system.enums.ErrorCodeConstants;
import com.shengyu.module.system.framework.flow.FlowForm;
import com.shengyu.module.system.framework.flow.FlowHelper;
import com.shengyu.module.system.service.flow.IFlwFormTemplateService;
import com.shengyu.module.system.service.flow.IFlwProcessApprovalService;
import com.shengyu.module.system.service.flow.IFlwProcessConfigureService;
import com.shengyu.module.system.service.flow.IFlwProcessFormService;
import com.shengyu.module.system.service.flow.IFlwProcessTaskService;
import com.shengyu.module.system.service.notify.NotifySendService;
import com.shengyu.module.system.service.permission.PermissionService;
import com.shengyu.module.system.service.user.AdminUserService;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;
import javax.annotation.Resource;
import javax.validation.constraints.NotNull;
import org.apache.commons.collections4.MapUtils;
import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import static com.shengyu.framework.common.exception.util.ServiceExceptionUtil.exception;

/**
 * 流程任务 服务实现类
 *
 * @author 青苗
 * @since 2023-12-11
 */
@Service
public class FlwProcessTaskServiceImpl implements IFlwProcessTaskService {
    @Resource
    private FlowlongMapper flowlongMapper;
    @Resource
    private SyFlwTaskMapper syFlwTaskMapper;
    @Resource
    private SyFlwHisInstanceMapper syFlwHisInstanceMapper;
    @Resource
    private SyFlwHisTaskMapper syFlwHisTaskMapper;
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
    @Resource
    private PermissionService permissionService;
    @Resource
    private FlwTaskActorMapper flwTaskActorMapper;
    @Resource
    private FlwHisTaskActorMapper flwHisTaskActorMapper;

    @Override
    public Page<PendingClaimTaskVO> pagePendingClaim(PageParam<ProcessTaskDTO> pageParam) {
        ProcessTaskDTO dto = this.getProcessTaskDTO(pageParam);
        Page<PendingClaimTaskVO> page = pageParam.page();
        page.setSearchCount(false);
        UserRespVO userRespVO = adminUserService.getUser(dto.getUserId());
        List<Long> flwTaskActorIdList;
        //对应角色所属的待认领任务
        Set<Long> roleIdListByUserId = permissionService.getUserRoleIdListByUserId(userRespVO.getId());
        flwTaskActorIdList = flwTaskActorMapper.selectListByActorIdListAndActorType(roleIdListByUserId.stream().map(String::valueOf).toList(), ActorType.role.getValue())
          .stream().map(
            FlwTaskActor::getId).collect(Collectors.toList());
        //对应部门所属的待认领任务
        flwTaskActorIdList.addAll(flwTaskActorMapper.selectListByActorIdListAndActorType(
            adminUserService.getMyEnableDeptList().stream().map(
              userDeptRespVO -> String.valueOf(userDeptRespVO.getDeptId())).collect(Collectors.toList()), ActorType.department.getValue())
          .stream().map(
            FlwTaskActor::getId).toList());
        return syFlwTaskMapper.selectPagePendingClaim(page, dto, flwTaskActorIdList);
    }

    @Override
    public Page<PendingApprovalTaskVO> pagePendingApproval(PageParam<ProcessTaskDTO> pageParam) {
        ProcessTaskDTO dto = this.getProcessTaskDTO(pageParam);
        Page<PendingApprovalTaskVO> page = pageParam.page();
        page.setSearchCount(false);
        UserRespVO userRespVO = adminUserService.getUser(dto.getUserId());
        List<String> flwTaskActorIdList = new ArrayList<>();
        flwTaskActorIdList.add(String.valueOf(userRespVO.getId()));
        //对应角色所属的待认领任务
        flwTaskActorIdList.addAll(permissionService.getUserRoleIdListByUserId(userRespVO.getId()).stream().map(String::valueOf).toList());
        //对应部门所属的待认领任务
        flwTaskActorIdList.addAll(adminUserService.getMyEnableDeptList().stream().map(
          userDeptRespVO -> String.valueOf(userDeptRespVO.getDeptId())).toList());
        return syFlwTaskMapper.selectPagePendingApproval(page, dto, flwTaskActorIdList);
    }

    @Override
    public Page<PendingApprovalTaskVO> pageAllPendingApproval(PageParam<ProcessTaskDTO> pageParam) {
        ProcessTaskDTO dto = this.getProcessTaskDTO(pageParam);
        Page<PendingApprovalTaskVO> page = pageParam.page();
        page.setSearchCount(false);
        return syFlwTaskMapper.selectPageAllPendingApproval(page, dto);
    }

    @Override
    public Page<ProcessTaskVO> pageMyApplication(PageParam<ProcessTaskDTO> pageParam) {
        ProcessTaskDTO dto = this.getProcessTaskDTO(pageParam);
        Page<ProcessTaskVO> page = pageParam.page();
        page.setSearchCount(false);
        Page<ProcessTaskVO> processTaskVOPage = syFlwHisInstanceMapper.selectPageMyApplication(
          page, dto);
        if (CollUtil.isEmpty(processTaskVOPage.getRecords())) {
            return processTaskVOPage;
        }
        List<Long> instanceIdList = processTaskVOPage.getRecords().stream().map(ProcessTaskVO::getInstanceId).collect(Collectors.toList());
        List<String> fairstNodeKeyList = processTaskVOPage.getRecords().stream().map(ProcessTaskVO::getFirstNodeKey).collect(Collectors.toList());
        List<FlwTask> flwTaskList = syFlwTaskMapper.selectByInstanceIdAndNodeKeyList(instanceIdList, fairstNodeKeyList);
        processTaskVOPage.getRecords().forEach(processTaskVO -> {
            flwTaskList.stream().filter(t -> t.getTaskKey().equals(processTaskVO.getFirstNodeKey())
              && t.getInstanceId().equals(processTaskVO.getInstanceId())).findFirst().ifPresent(t -> processTaskVO.setTaskId(t.getId()));
        });
        return processTaskVOPage;
    }

    @Override
    public Page<ProcessTaskVO> pageMyReceived(PageParam<ProcessTaskDTO> pageParam, @NotNull Integer taskType) {
        ProcessTaskDTO dto = this.getProcessTaskDTO(pageParam);
        Page<ProcessTaskVO> page = pageParam.page();
        page.setSearchCount(false);
        Page<ProcessTaskVO> processTaskVOPage = syFlwHisInstanceMapper.selectPageMyReceived(page,
          dto, taskType);
        if (CollUtil.isEmpty(processTaskVOPage.getRecords())) {
            return processTaskVOPage;
        }
        processTaskVOPage.getRecords().forEach(processTaskVO -> {
            //获取传阅信息
            if (CharSequenceUtil.isNotBlank(processTaskVO.getExtend()) && Objects.equals(TaskType.circulate.getValue(), processTaskVO.getTaskType())) {
                processTaskVO.setCirculateArgs(FlowLongContext.fromJson(processTaskVO.getExtend(), CirculateArgs.class));
            }
        });
        return processTaskVOPage;
    }

    @Override
    public Page<ProcessTaskVO> pageApproved(PageParam<ProcessTaskDTO> pageParam) {
        ProcessTaskDTO dto = this.getProcessTaskDTO(pageParam);
        Page<ProcessTaskVO> page = pageParam.page();
        page.setSearchCount(false);
        return flowlongMapper.selectPageApproved(pageParam.page(), dto);
    }

    @Override
    public Page<PendingApprovalTaskVO> pageAllApproved(PageParam<ProcessTaskDTO> pageParam) {
        ProcessTaskDTO dto = this.getProcessTaskDTO(pageParam);
        Page<PendingApprovalTaskVO> page = pageParam.page();
        page.setSearchCount(false);
        return syFlwHisTaskMapper.selectPageAllApproved(page, dto);
    }

    @Override
    public TaskApprovalVO approvalInfo(ProcessInfoDTO dto) {
        final Long instanceId = dto.getInstanceId();
        FlwHisInstance hisInstance = flowLongEngine.queryService().getHistInstance(instanceId);
        ServiceExceptionUtil.isEmpty(hisInstance, ErrorCodeConstants.FLOW_1_002_029_018);
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
        // 流程设置
        vo.setProcessSetting(CharSequenceUtil.isNotBlank(extInstance.getProcessSetting())?
          FlowLongContext.fromJson(extInstance.getProcessSetting(), FlwProcessSetting.class) : null);
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
            vo.setAllowCirculate(nodeModel.getAllowCirculate());
            vo.setRejectStrategy(nodeModel.getRejectStrategy());
        }

        FlwProcessConfigure configure = flwProcessConfigureService.getByProcessId(hisInstance.getProcessId());
        if (null != configure) {
            boolean searchFormContent = true;

            // 表单设置
            if (ProcessType.business.eq(extInstance.getProcessType())) {
                // 业务流程，加载表单模板内容
                FlwFormTemplate formTemplate = flwFormTemplateService.getByConfigure(configure.getProcessForm());
                ServiceExceptionUtil.fail(null == formTemplate, ErrorCodeConstants.FLOW_1_002_029_019);
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
                FlwTask flwTask;
                if (null != dto.getTaskId() && flwTaskList.size() > 1) {
                    // 并行分支情况，找到指定任务 ID
                    flwTask = flwTaskList.stream().filter(t -> Objects.equals(dto.getTaskId(), t.getId())).findFirst().get();
                } else {
                    flwTask = flwTaskList.get(0);
                }
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
          .forEach(nodeKeys -> nodeKeys.forEach(nodeKey -> renderNodes.put(nodeKey, 0)));

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
        ServiceExceptionUtil.fail(null == instance, ErrorCodeConstants.FLOW_1_002_029_020);
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
        return flowLongEngine.taskService().viewTask(taskId, FlowHelper.getFlowCreator());
    }

    @Transactional(rollbackFor = Exception.class)
    @Override
    public boolean circulateViewed(TaskCirculateViewDTO dto) {
        FlwHisTaskActor flwHisTaskActor = Optional.ofNullable(flwHisTaskActorMapper.selectById(dto.getHisTaskActorId()))
          .orElseThrow(() -> exception(ErrorCodeConstants.FLOW_1_002_029_065));
        // 设置已阅
        flwHisTaskActor.setViewed(1);
        int updatedById = flwHisTaskActorMapper.updateById(flwHisTaskActor);
        List<FlwHisTaskActor> flwHisTaskActorList = flwHisTaskActorMapper.selectListByTaskId(
          flwHisTaskActor.getTaskId());
        // 传阅生成的流程审批记录
        List<FlwProcessApproval> flwProcessApprovals = flwProcessApprovalService.listByTaskId(
          flwHisTaskActor.getTaskId());
        if (CollectionUtils.isNotEmpty(flwProcessApprovals)) {
            flwProcessApprovals.forEach(flwProcessApproval -> {
                ApprovalContent content = flwProcessApproval.getContent();
                content.setNodeUserList(flwHisTaskActorList.stream().map(NodeAssignee::of).collect(
                  Collectors.toList()));
                flwProcessApproval.setContent(content);
            });
            flwProcessApprovalService.updateBatchById(flwProcessApprovals);
        }
        //评论
        if (CharSequenceUtil.isNotBlank(dto.getContent())) {
            ProcessApprovalDTO processApprovalDTO = new ProcessApprovalDTO();
            processApprovalDTO.setInstanceId(flwHisTaskActor.getInstanceId());
            processApprovalDTO.setContent(dto.getContent());
            flwProcessApprovalService.comment(processApprovalDTO, flwHisTaskActor.getWeight());
        }
        return updatedById >0;
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
        ServiceExceptionUtil.fail(null == flwInstance, ErrorCodeConstants.FLOW_1_002_029_015);
        FlwProcessConfigure configure = flwProcessConfigureService.getByProcessId(flwInstance.getProcessId());
        if (null != configure && null != configure.getProcessSetting()) {
            ServiceExceptionUtil.fail(!Objects.equals(true, configure.getProcessSetting().getAllowRevocation()),
                    ErrorCodeConstants.FLOW_1_002_029_016);
        }
        FlowHelper.setProcessApprovalOpinion(dto.getContent());
        if (dto.isTermination()) {
            // 发起人撤回终止
            flowLongEngine.runtimeService().revoke(dto.getInstanceId(), flowCreator);
            return true;
        }

        // 发起人撤回任务
        FlwHisTask fht = flowLongEngine.queryService().getStartTaskByInstanceId(dto.getInstanceId());
        ServiceExceptionUtil.fail(null == fht || fht.startNode(), ErrorCodeConstants.FLOW_1_002_029_017);
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
        List<FlwHisTaskVO> voList = syFlwHisTaskMapper.selectListHisTaskByInstanceId(instanceId);
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
        ServiceExceptionUtil.isEmpty(flwTask, ErrorCodeConstants.FLOW_1_002_029_012);
        return flwTask;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean carbonCopy(TaskCarbonCopyDTO dto) {
        FlwTask flwTask = this.checkFlwTaskById(dto.getTaskId());
        List<AdminUserDO> sysUsers = adminUserService.getUserList(dto.getUserIds());
        ServiceExceptionUtil.isEmpty(sysUsers, ErrorCodeConstants.FLOW_1_002_029_013);
        flowLongEngine.queryService().getCcTaskActorsByInstanceId(flwTask.getInstanceId())
                .ifPresent(t -> t.forEach(actor -> sysUsers.forEach(user -> {
                    if (Objects.equals(actor.getActorId(), String.valueOf(user.getId()))) {
                        ServiceExceptionUtil.fail(ErrorCodeConstants.FLOW_1_002_029_014, user.getNickname());
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

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean manualCirculate(ManualCirculateDTO dto) {
        FlwTask flwTask = null;
        FlwHisTask flwHisTask = null;
        if (Objects.isNull(dto.getTaskId()) && Objects.isNull(dto.getHisTaskId())) {
            ServiceExceptionUtil.fail(ErrorCodeConstants.FLOW_1_002_029_061);
        }
        if (Objects.nonNull(dto.getTaskId())) {
            flwTask = flowLongEngine.queryService().getTask(dto.getTaskId());
            ServiceExceptionUtil.isEmpty(flwTask, ErrorCodeConstants.FLOW_1_002_029_062);
        }
        if (Objects.nonNull(dto.getHisTaskId())) {
            flwHisTask = flowLongEngine.queryService().getHistTask(dto.getHisTaskId());
            ServiceExceptionUtil.isEmpty(flwHisTask, ErrorCodeConstants.FLOW_1_002_029_063);
        }
        List<AdminUserDO> sysUsers = adminUserService.getUserList(dto.getUserIdList());
        ServiceExceptionUtil.isEmpty(sysUsers, ErrorCodeConstants.FLOW_1_002_029_013);
        flowLongEngine.queryService().getCcTaskActorsByInstanceId(flwTask.getInstanceId())
                .ifPresent(t -> t.forEach(actor -> sysUsers.forEach(user -> {
                    if (Objects.equals(actor.getActorId(), String.valueOf(user.getId()))) {
                        ServiceExceptionUtil.fail(ErrorCodeConstants.FLOW_1_002_029_064, user.getNickname());
                    }
                })));

        // 传递传阅意见
        FlowHelper.setProcessApprovalOpinion(dto.getContent());
        // 传阅得特殊配置
        CirculateArgs args = CirculateArgs.of(dto.getAllowOpinion(), dto.getAllowCirculate(), dto.getNotifyMe());
        // 创建传阅任务
        return flowLongEngine.createCirculateTask(flwTask, flwHisTask, sysUsers.stream().map(t -> {
            NodeAssignee nodeAssignee = new NodeAssignee();
            nodeAssignee.setId(String.valueOf(t.getId()));
            nodeAssignee.setName(t.getNickname());
            nodeAssignee.setExtendConfig(FlowLongContext.obj2map(args));
            return nodeAssignee;
        }).toList(), FlowHelper.getFlowCreator());
    }

    @Transactional(rollbackFor = Exception.class)
    @Override
    public boolean transfer(TaskTransferDTO dto) {
        LoginUser userSession = SecurityFrameworkUtils.getLoginUser();
        ServiceExceptionUtil.fail(dto.getAssigneeList().stream().anyMatch(t ->
          Objects.equals(userSession.getId(), t.getUserId())), ErrorCodeConstants.FLOW_1_002_029_060);
        FlowHelper.setProcessApprovalOpinion(dto.getContent());
        FlowCreator flowCreator = FlowCreator.of(String.valueOf(userSession.getId()), userSession.getNickname());
        TaskService taskService = flowLongEngine.taskService();
        List<FlowCreator> flowCreators = dto.toFlowCreators();
        if (Objects.equals(0, dto.getType())) {
            // 转办
            return taskService.transferTask(dto.getTaskId(), flowCreator, flowCreators.get(0));
        } else if (Objects.equals(1, dto.getType())) {
            // 委派
            return taskService.delegateTask(dto.getTaskId(), flowCreator, flowCreators.get(0));
        }
        // 代理
        return taskService.agentTask(dto.getTaskId(), flowCreator, flowCreators);
    }

    private FlwTask getFlwTask(Long taskId) {
        FlwTask flwTask = flowLongEngine.queryService().getTask(taskId);
        ServiceExceptionUtil.isEmpty(flwTask, ErrorCodeConstants.FLOW_1_002_029_021);
        return flwTask;
    }

    @Transactional(rollbackFor = Exception.class)
    @Override
    public boolean comment(ProcessApprovalDTO dto) {
        return flwProcessApprovalService.comment(dto, 0);
    }

    @Transactional(rollbackFor = Exception.class)
    @Override
    public boolean consent(TaskApprovalDTO dto) {
        //当前任务处理人员为角色或者部门时，进行任务认领操作
        this.claimTask(dto.getTaskId(), FlowHelper.getFlowCreator());

        // 判断是否修改模型
        if (MapUtils.isNotEmpty(dto.getAssigneeMap())) {

            // 传递动态分配处理人员
            FlowDataTransfer.dynamicAssignee(Collections.unmodifiableMap(dto.getAssigneeMap()));
        }

        // 获取任务，保存表单
        FlwTask flwTask = this.getFlwTask(dto.getTaskId());
        FlowHelper.setProcessApprovalOpinion(dto.getContent());
        ServiceExceptionUtil.fail(!flwProcessFormService.saveForm(flwTask.getInstanceId(), dto.getProcessForm()), ErrorCodeConstants.FLOW_1_002_029_022);
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
        //当前任务处理人员为角色或者部门时，进行任务认领操作
        this.claimTask(dto.getTaskId(), FlowHelper.getFlowCreator());
        FlwTask flwTask = this.getFlwTask(dto.getTaskId());
        FlowHelper.setProcessApprovalOpinion(dto.getContent());
        return flowLongEngine.executeRejectTask(flwTask, dto.getNodeKey(), FlowHelper.getFlowCreator(), dto.getArgs(), dto.isTermination()).isPresent();
    }

    /**
     * 认领
     * @param taskId 任务ID
     * @param flowCreator 创建人
     */
    private boolean claimTask(Long taskId, FlowCreator flowCreator) {
        // 判断当前任务处理人员为角色或者部门时，进行任务认领操作
        Optional<FlwTaskActor> ftaOpt = flwTaskActorMapper.selectListByTaskId(taskId).stream().filter(t ->
          Objects.equals(ActorType.role.getValue(), t.getActorType()) || Objects.equals(ActorType.department.getValue(), t.getActorType())).findFirst();
        if (!ftaOpt.isPresent()) {
            return true;
        }
        FlwTaskActor flwTaskActor = ftaOpt.get();
        ProcessModel processModel = flowLongEngine.runtimeService().getProcessModelByInstanceId(flwTaskActor.getInstanceId());
        FlwTask flwTask = this.getFlwTask(taskId);
        NodeModel nodeModel = processModel.getNode(flwTask.getTaskKey());
        // 判断节点是否是 1，全部人员参与审批。这种情况下不需要进行任务认领
        if (nodeModel.allJoinGroupStrategy()) {
            return true;
        }
        // 进行任务认领操作
        TaskService taskService = flowLongEngine.taskService();
        if (ActorType.role.eq(flwTaskActor.getActorType())) {
            return null != taskService.claimRole(taskId, flowCreator);
        } else if (ActorType.department.eq(flwTaskActor.getActorType())) {
            return null != taskService.claimDepartment(taskId, flowCreator);
        }
        return false;
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
    public Long countPendingApproval() {
        LoginUser userSession = SecurityFrameworkUtils.getLoginUser();
        List<String> flwTaskActorIdList = new ArrayList<>();
        flwTaskActorIdList.add(String.valueOf(userSession.getId()));
        //对应角色所属的待认领任务
        flwTaskActorIdList.addAll(permissionService.getUserRoleIdListByUserId(userSession.getId()).stream().map(String::valueOf).toList());
        //对应部门所属的待认领任务
        flwTaskActorIdList.addAll(adminUserService.getMyEnableDeptList().stream().map(
          userDeptRespVO -> String.valueOf(userDeptRespVO.getDeptId())).toList());
        return syFlwTaskMapper.selectCountPendingApproval(flwTaskActorIdList);
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

    @Override
    public boolean approvedParentNode(Long parentTaskId, String actorId) {
        return flowlongMapper.selectCountByParentTaskIdAndActorId(parentTaskId, actorId) > 0;
    }

    @Override
    public boolean approvedCompleteParentNode(FlwTask flwTask, String actorId) {
        //只查询审批节点已通过得任务
        FlwHisTask current = syFlwHisTaskMapper.selectOne(new LambdaQueryWrapper<FlwHisTask>()
          .eq(FlwHisTask::getId, flwTask.getParentTaskId())
          .eq(FlwHisTask::getTaskType, TaskType.approval.getValue())
          .eq(FlwHisTask::getTaskState, TaskState.complete.getValue()), false);
        //没有父任务
        if (Objects.isNull(current)) {
            return false;
        }
        List<FlwHisTask> result = new ArrayList<>();
        // 防止循环引用
        Set<Long> visited = new HashSet<>();
        final String baseTaskKey = current.getTaskKey();
        // 开始递归向上
        result.add(current);
        traverseParentChain(current.getParentTaskId(), baseTaskKey, result, visited);
        if (CollUtil.isEmpty(result)) {
            return false;
        }
        //通过任务ID获取参与者列表
        List<FlwHisTaskActor> flwHisTaskActorList = flwHisTaskActorMapper.selectListByTaskIds(
          result.stream().map(FlwHisTask::getId).collect(
            Collectors.toList()));
        return flwHisTaskActorList.stream().anyMatch(t -> Objects.equals(actorId, t.getActorId()));
    }

    @Override
    public boolean approvedCompleteAllNode(FlwTask flwTask, String actorId) {
        return !flwHisTaskActorMapper.selectListByTaskAndActorIdApprovalAndComplete(flwTask, actorId).isEmpty();
    }

    private void traverseParentChain(Long taskId, String baseTaskKey,
      List<FlwHisTask> result, Set<Long> visited) {
        if (taskId == null || visited.contains(taskId)) {
            return;
        }
        // 防止脏数据循环引用
        visited.add(taskId);
        FlwHisTask task = syFlwHisTaskMapper.selectOne(new LambdaQueryWrapper<FlwHisTask>()
          .eq(FlwHisTask::getId, taskId)
          .eq(FlwHisTask::getTaskType, TaskType.approval.getValue())
          .eq(FlwHisTask::getTaskState, TaskState.complete.getValue()), false);
        if (task == null) {
            return;
        }
        // 如果 task_key 不一致，停止递归（不加入结果）
        if (!baseTaskKey.equals(task.getTaskKey())) {
            return;
        }

        // 符合条件，加入结果
        result.add(task);

        // 继续向上递归
        if (task.getParentTaskId() != null) {
            traverseParentChain(task.getParentTaskId(), baseTaskKey, result, visited);
        }
    }

}
