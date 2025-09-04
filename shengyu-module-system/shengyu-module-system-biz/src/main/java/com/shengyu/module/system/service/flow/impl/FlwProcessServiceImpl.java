package com.shengyu.module.system.service.flow.impl;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.collection.CollectionUtil;
import com.baomidou.mybatisplus.core.toolkit.CollectionUtils;
import com.shengyu.framework.common.exception.util.ServiceExceptionUtil;
import com.shengyu.framework.common.util.json.JsonUtils;
import com.shengyu.framework.flowlong.engine.QueryService;
import com.shengyu.framework.flowlong.engine.mapper.FlwProcessMapper;
import com.shengyu.framework.security.core.LoginUser;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.module.system.controller.admin.flow.dto.*;
import com.shengyu.module.system.controller.admin.flow.vo.FlwInstanceVO;
import com.shengyu.module.system.controller.admin.flow.vo.FlwProcessCategoryVO;
import com.shengyu.module.system.controller.admin.flow.vo.FlwProcessVO;
import com.shengyu.framework.flowlong.engine.entity.ApprovalContent;
import com.shengyu.module.system.dal.dataobject.flow.FlwProcessActor;
import com.shengyu.module.system.dal.dataobject.flow.FlwProcessApproval;
import com.shengyu.module.system.dal.dataobject.flow.FlwProcessCategory;
import com.shengyu.framework.flowlong.engine.entity.FlwProcessConfigure;
import com.shengyu.module.system.dal.dataobject.flow.FlwProcessPermission;
import com.shengyu.framework.flowlong.engine.FlowDataTransfer;
import com.shengyu.framework.flowlong.engine.FlowLongEngine;
import com.shengyu.framework.flowlong.engine.ProcessService;
import com.shengyu.framework.flowlong.engine.core.FlowCreator;
import com.shengyu.framework.flowlong.engine.core.FlowLongContext;
import com.shengyu.framework.flowlong.engine.core.enums.FlowState;
import com.shengyu.framework.flowlong.engine.core.enums.NodeSetType;
import com.shengyu.framework.flowlong.engine.core.enums.ProcessType;
import com.shengyu.framework.flowlong.engine.entity.FlwHisInstance;
import com.shengyu.framework.flowlong.engine.entity.FlwInstance;
import com.shengyu.framework.flowlong.engine.entity.FlwProcess;
import com.shengyu.framework.flowlong.engine.model.*;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.shengyu.module.system.dal.mysql.flow.FlwProcessActorMapper;
import com.shengyu.module.system.dal.mysql.flow.SyFlwHisInstanceMapper;
import com.shengyu.module.system.dal.mysql.flow.SyFlwProcessMapper;
import com.shengyu.module.system.enums.ErrorCodeConstants;
import com.shengyu.module.system.framework.flow.FlowForm;
import com.shengyu.module.system.framework.flow.FlowHelper;
import com.shengyu.module.system.service.flow.*;
import com.shengyu.module.system.service.permission.PermissionService;
import com.shengyu.module.system.service.user.AdminUserService;
import java.util.stream.Collectors;
import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.annotation.Resource;
import java.util.*;

/**
 * 流程分类 服务实现类
 *
 * @author 青苗
 * @since 2023-09-07
 */
@Service
public class FlwProcessServiceImpl extends ServiceImpl<FlwProcessMapper, FlwProcess> implements IFlwProcessService {
    @Resource
    private ProcessService processService;
    @Resource
    private IFlwProcessCategoryService flwProcessCategoryService;
    @Resource
    private IFlwProcessPermissionService flwProcessPermissionService;
    @Resource
    private IFlwProcessConfigureService flwProcessConfigureService;
    @Resource
    private IFlwProcessApprovalService flwProcessApprovalService;
    @Resource
    private IFlwProcessActorService flwProcessActorService;
    @Resource
    private IFlwProcessFormService flwProcessFormService;
    @Resource
    private IFlwFormTemplateService flwFormTemplateService;
    @Resource
    private FlowLongEngine flowLongEngine;
    @Resource
    private SyFlwProcessMapper syFlwProcessMapper;
    @Resource
    private SyFlwHisInstanceMapper syFlwHisInstanceMapper;
    @Resource
    private PermissionService permissionService;
    @Resource
    private FlwProcessActorMapper flwProcessActorMapper;
    @Resource
    private AdminUserService adminUserService;

    @Override
    public Page<FlwProcess> pageHistory(Page<FlwProcess> page, FlwProcessHistoryDTO dto) {
        FlwProcess flwProcess = this.checkById(dto.getProcessId());
        LambdaQueryWrapper<FlwProcess> lqw = Wrappers.lambdaQuery();
        lqw.select(FlwProcess::getId, FlwProcess::getProcessName, FlwProcess::getProcessIcon,
                FlwProcess::getProcessVersion, FlwProcess::getRemark, FlwProcess::getCreateTime);
        lqw.eq(FlwProcess::getProcessState, 2);
        lqw.eq(FlwProcess::getProcessKey, flwProcess.getProcessKey());
        lqw.orderByDesc(FlwProcess::getProcessVersion);
        return super.page(page, lqw);
    }

    @Override
    public Page<FlwInstanceVO> pageInstance(Page<FlwInstanceVO> page, FlwProcessInstanceDTO dto) {
        if (null != dto) {
            if (null == dto.getCompleted()) {
                dto.setCompleted(false);
            }
        }
        List<Long> processIdList = null;
        if (dto != null && Objects.nonNull(dto.getProcessCategoryId())) {
            processIdList = flwProcessConfigureService.list(
                new LambdaQueryWrapper<FlwProcessConfigure>()
                  .eq(FlwProcessConfigure::getCategoryId, dto.getProcessCategoryId())).stream()
              .map(FlwProcessConfigure::getProcessId).collect(Collectors.toList());
        }
        return syFlwHisInstanceMapper.selectPageInstance(page, dto, processIdList);
    }

    @Override
    public List<FlwProcessCategoryVO> listCategoryAll(String keyword) {
        return this.listCategoryVO(keyword, false);
    }

    public List<FlwProcessCategoryVO> listCategoryVO(String keyword, boolean launch) {
        List<FlwProcessCategory> categoryList = flwProcessCategoryService
          .list(new LambdaQueryWrapper<FlwProcessCategory>()
            .orderByAsc(FlwProcessCategory::getSort)
          );
        if (CollUtil.isEmpty(categoryList)) {
            return Collections.emptyList();
        }
        // 全部查询
        List<FlwProcessCategoryVO> voList = new ArrayList<>();
        List<FlwProcessVO> flwProcessVOList;
        if (launch) {
            //查询已启用的主流程
            flwProcessVOList = syFlwProcessMapper.selectLaunchProcessList();
        } else {
            //查询所有流程（包括未启用的，不包含历史版本的）
            flwProcessVOList = syFlwProcessMapper.selectFlwProcessList();
        }

        boolean voIsNotEmpty = CollectionUtil.isNotEmpty(flwProcessVOList);
        if (voIsNotEmpty) {
            boolean needSort = true;
            if (launch) {
                // 发起流程，过滤不存在角色权限的流程
                LoginUser userSession = SecurityFrameworkUtils.getLoginUser();
                // 查询当前用户角色ID集合
                List<Long> roleIdList = permissionService.getUserRoleIdListByUserId(userSession.getId()).stream().toList();
                // 查询当前用户不存在角色权限的流程ID集合
                List<Long> processIdList = flwProcessActorMapper.selectListByActorIdList(roleIdList)
                  .stream().map(FlwProcessActor::getProcessId).collect(Collectors.toList());
                List<Long> notExistProcessIds = flwProcessActorMapper.selectNotExistProcessIds(processIdList);
                if (CollectionUtils.isNotEmpty(notExistProcessIds)) {
                    needSort = false;
                    flwProcessVOList = flwProcessVOList.stream().sorted(Comparator.comparing(FlwProcessVO::getProcessSort))
                            .filter(t -> !notExistProcessIds.contains(t.getProcessId())).toList();
                }
            }
            // 排序
            if (needSort) {
                flwProcessVOList.sort(Comparator.comparing(FlwProcessVO::getProcessSort));
            }
        }

        if (null == keyword) {
            // 不存在关键词查询
            for (FlwProcessCategory fpc : categoryList) {
                if (voIsNotEmpty) {
                    List<FlwProcessVO> processList = flwProcessVOList.stream().filter(f -> Objects.equals(fpc.getId(), f.getCategoryId())).toList();
                    boolean isEmpty = CollectionUtils.isEmpty(processList);
                    if (isEmpty && launch) {
                        continue;
                    }
                    FlwProcessCategoryVO vo = FlwProcessCategoryVO.of(fpc);
                    vo.setProcessList(processList);
                    voList.add(vo);
                } else if (!launch) {
                    // 非发起列表情况
                    voList.add(FlwProcessCategoryVO.of(fpc));
                }
            }
        } else {
            // 关键词查询
            for (FlwProcessCategory fpc : categoryList) {
                if (voIsNotEmpty) {
                    List<FlwProcessVO> processList = flwProcessVOList.stream().filter(t -> Objects.equals(t.getCategoryId(), fpc.getId())
                            && t.getProcessName().contains(keyword)).toList();
                    if (fpc.getName().contains(keyword)) {
                        // 匹配分类名称
                        if (CollectionUtils.isEmpty(processList)) {
                            if (launch) {
                                continue;
                            }
                            FlwProcessCategoryVO vo = FlwProcessCategoryVO.of(fpc);
                            vo.setProcessList(flwProcessVOList.stream().filter(f -> Objects.equals(f.getCategoryId(), fpc.getId())).toList());
                            voList.add(vo);
                        } else {
                            FlwProcessCategoryVO vo = FlwProcessCategoryVO.of(fpc);
                            vo.setProcessList(processList);
                            voList.add(vo);
                        }
                    } else if (CollectionUtils.isNotEmpty(processList)) {
                        // 匹配流程定义
                        FlwProcessCategoryVO vo = FlwProcessCategoryVO.of(fpc);
                        vo.setProcessList(processList);
                        voList.add(vo);
                    }
                } else if (!launch) {
                    // 非发起列表情况
                    voList.add(FlwProcessCategoryVO.of(fpc));
                }
            }
        }
        return voList;
    }

    @Override
    public List<FlwProcessCategoryVO> listLaunch(String keyword) {
        return this.listCategoryVO(keyword, true);
    }

    @Override
    public List<FlwProcess> listChildTop10(String keyword) {
        // 查询正常状态的子流程
        return lambdaQuery().select(FlwProcess::getId, FlwProcess::getProcessName)
                .like(StringUtils.isNotEmpty(keyword), FlwProcess::getProcessName, keyword)
                .eq(FlwProcess::getProcessType, "child")
                .eq(FlwProcess::getProcessState, 1)
                .orderByDesc(FlwProcess::getCreateTime).last("LIMIT 10").list();
    }

    @Transactional(rollbackFor = Exception.class)
    @Override
    public Long launchProcess(ProcessStartDTO dto, FlowCreator flowCreator) {
        FlwProcess flwProcess = flowLongEngine.processService().getProcessById(dto.getProcessId());
        ServiceExceptionUtil.fail(null == flwProcess, ErrorCodeConstants.FLOW_1_002_029_023);

        // 获取未设置处理人员节点
        final Map<String, DynamicAssignee> assigneeMap = dto.getAssigneeMap();
        List<NodeModel> unsetAssigneeNodes = ModelHelper.getUnsetAssigneeNodes(flwProcess.model(true).getNodeConfig());
        if (CollectionUtils.isNotEmpty(unsetAssigneeNodes)) {
            unsetAssigneeNodes.forEach(t -> {
                if (NodeSetType.supervisor.eq(t.getSetType()) || NodeSetType.multiLevelSupervisors.eq(t.getSetType())) {
                    // 主管由 FlowTaskActorProvider 类提供，不认为非法逻辑
                    return;
                }

                final DynamicAssignee dynamicAssignee = assigneeMap.get(t.getNodeKey());
                if (NodeSetType.specifyMembers.eq(t.getSetType()) || NodeSetType.initiatorSelected.eq(t.getSetType())) {
                    ServiceExceptionUtil.fail(null == dynamicAssignee, ErrorCodeConstants.FLOW_1_002_029_024);
                }
                ServiceExceptionUtil.fail(null == dynamicAssignee || CollectionUtils.isEmpty(dynamicAssignee.getAssigneeList()),
                        ErrorCodeConstants.FLOW_1_002_029_025, t.getNodeName());
            });
        }
        // 传递动态分配处理人员
        if (null != assigneeMap) {
            FlowDataTransfer.dynamicAssignee(Collections.unmodifiableMap(assigneeMap));
        }

        // 传递表单参数
        FlowForm.argsTransfer(dto.getProcessForm());

        // 启动流程
        Optional<FlwInstance> opt = flowLongEngine.startInstanceById(dto.getProcessId(), flowCreator, null, dto.isSaveAsDraft(), () -> {
            FlwInstance flwInstance = new FlwInstance();
            flwInstance.setBusinessKey(dto.getBusinessKey());
            return flwInstance;
        });
        ServiceExceptionUtil.fail(opt.isEmpty(), ErrorCodeConstants.FLOW_1_002_029_026);

        // 保存表单
        FlwInstance flwInstance = opt.get();
        ServiceExceptionUtil.fail(!flwProcessFormService.saveForm(flwInstance.getId(), dto.getProcessForm()), ErrorCodeConstants.FLOW_1_002_029_027);
        return flwInstance.getId();
    }

    @Override
    public Map<String, Object> getVariableByInstanceId(Long instanceId) {
        QueryService queryService = flowLongEngine.queryService();
        FlwInstance fi = queryService.getInstance(instanceId);
        if (null != fi) {
            return fi.variableToMap();
        }

        // 已完成流程
        FlwHisInstance fhi = queryService.getHistInstance(instanceId);
        if (null != fhi) {
            return fhi.variableToMap();
        }

        // 不存在情况
        return new HashMap<>();
    }

    @Transactional(rollbackFor = Exception.class)
    @Override
    public boolean removeProcessByInstanceIds(List<Long> instanceIds) {
        for (Long instanceId : instanceIds) {
            FlwHisInstance fhi = flowLongEngine.queryService().getHistInstance(instanceId);
            if (null != fhi) {
                ServiceExceptionUtil.fail(fhi.getInstanceState() > 0, ErrorCodeConstants.FLOW_1_002_029_028);
                flowLongEngine.runtimeService().cascadeRemoveByInstanceId(instanceId);
            }
        }
        return true;
    }

    @Override
    public boolean resumeProcessByInstanceId(Long instanceId) {
        return flowLongEngine.taskService().resume(instanceId, FlowHelper.getFlowCreator());
    }

    @Override
    public boolean terminateProcessByInstanceId(Long instanceId) {
        return flowLongEngine.runtimeService().terminate(instanceId, FlowHelper.getFlowCreator());
    }

    @Transactional(rollbackFor = Exception.class)
    @Override
    public boolean destroyProcessByInstanceId(DestroyInstanceDTO dto) {
        if (StringUtils.isNoneBlank(dto.getOpinion())) {
            FlwProcessApproval fpa = new FlwProcessApproval();
            fpa.setInstanceId(dto.getInstanceId());
            fpa.setType(16);
            ApprovalContent content = new ApprovalContent();
            content.setOpinion(dto.getOpinion());
            fpa.setContent(content);
            flwProcessApprovalService.save(fpa);
        }
        return flowLongEngine.runtimeService().destroyByInstanceId(dto.getInstanceId(), null);
    }

    @Override
    public String getNodeModelById(Long id) {
        FlwProcess flwProcess = this.checkById(id);
        return flwProcess.getModelContent();
    }

    @Override
    public FlwProcessDTO getDtoById(Long id) {
        return getFlwProcessDTO(this.checkById(id));
    }

    public FlwProcessDTO getFlwProcessDTO(FlwProcess flwProcess) {
        ServiceExceptionUtil.isEmpty(flwProcess, ErrorCodeConstants.FLOW_1_002_029_029);
        FlwProcessDTO dto = FlwProcessDTO.of(flwProcess);
        // 流程权限
        List<FlwProcessPermission> permissionList = flwProcessPermissionService.getByProcessId(flwProcess.getId());
        if (CollectionUtils.isNotEmpty(permissionList)) {
            dto.setProcessPermissionList(permissionList.stream().map(FlwProcessPermissionDTO::of).toList());
        }
        // 流程配置
        FlwProcessConfigure configure = flwProcessConfigureService.getByProcessId(flwProcess.getId());
        if (null != configure) {
            dto.setCategoryId(configure.getCategoryId());
            dto.setProcessSetting(configure.getProcessSetting());
            if (ProcessType.business.eq(flwProcess.getProcessType())) {
                dto.setBusinessForm(configure.getProcessForm());
                // 加载表单模板内容
                dto.setFormTemplate(flwFormTemplateService.getByConfigure(configure.getProcessForm()));
            } else {
                dto.setProcessForm(configure.getProcessForm());
            }
        }
        return dto;
    }

    @Override
    public FlwProcessDTO getDtoByKey(String key) {
        return getFlwProcessDTO(baseMapper.selectOne(Wrappers.<FlwProcess>lambdaQuery()
                .eq(FlwProcess::getProcessKey, key).eq(FlwProcess::getProcessState, 1)));
    }

    @Transactional(rollbackFor = Exception.class)
    @Override
    public Long saveDto(FlwProcessDTO dto) {
        ServiceExceptionUtil.fail(null == dto.getCategoryId(), ErrorCodeConstants.FLOW_1_002_029_030);
        ProcessModel processModel = ModelHelper.buildProcessModel(dto.getModelContent());
        NodeModel rootNode = processModel.getNodeConfig();
        int checkNodeModel = ModelHelper.checkNodeModel(rootNode);
        if (checkNodeModel > 0) {
            ServiceExceptionUtil.equals(1, checkNodeModel, ErrorCodeConstants.FLOW_1_002_029_031);
            ServiceExceptionUtil.equals(2, checkNodeModel, ErrorCodeConstants.FLOW_1_002_029_032);
            ServiceExceptionUtil.equals(3, checkNodeModel, ErrorCodeConstants.FLOW_1_002_029_033);
            ServiceExceptionUtil.equals(4, checkNodeModel, ErrorCodeConstants.FLOW_1_002_029_034);
            ServiceExceptionUtil.equals(5, checkNodeModel, ErrorCodeConstants.FLOW_1_002_029_035);
            ServiceExceptionUtil.equals(6, checkNodeModel, ErrorCodeConstants.FLOW_1_002_029_052);
            ServiceExceptionUtil.equals(7, checkNodeModel, ErrorCodeConstants.FLOW_1_002_029_056);
        }
        ServiceExceptionUtil.fail(null == rootNode.getChildNode(), ErrorCodeConstants.FLOW_1_002_029_036);
        int checkConditionNode = ModelHelper.checkConditionNode(rootNode);
        if (checkConditionNode > 0) {
            ServiceExceptionUtil.equals(1, checkConditionNode, ErrorCodeConstants.FLOW_1_002_029_037);
            ServiceExceptionUtil.equals(2, checkConditionNode, ErrorCodeConstants.FLOW_1_002_029_038);
            ServiceExceptionUtil.equals(3, checkConditionNode, ErrorCodeConstants.FLOW_1_002_029_039);
        }
        ServiceExceptionUtil.fail(!ModelHelper.checkExistApprovalNode(rootNode), ErrorCodeConstants.FLOW_1_002_029_040);

        // 检查流程定义操作权限
        if (null != dto.getProcessId()) {
            this.checkOperateApproval(dto.getProcessId());
        }

        // 检查流程定义KEY唯一性
        this.checkProcessKey(dto.getProcessId(), dto.getProcessKey());

        // 部署流程定义，修改会产生历史流程
        final Long processId = processService.deploy(dto.getProcessId(), dto.getModelContent(),
                FlowHelper.getFlowCreator(), true, flwProcess -> {
                    // 流程图标
                    flwProcess.setProcessIcon(dto.getProcessIcon());

                    // 流程类型
                    flwProcess.setProcessType(dto.getProcessType());

                    // 创建 0 不可用状态，需要发布后才可以使用
                    flwProcess.setFlowState(FlowState.inactive);

                    // 备注说明
                    flwProcess.setRemark(dto.getRemark());
                });

        // 流程定义权限
        List<FlwProcessPermissionDTO> processPermissionList = dto.getProcessPermissionList();
        if (CollectionUtils.isNotEmpty(processPermissionList)) {
            ServiceExceptionUtil.fail(!flwProcessPermissionService.saveProcessPermissions(processId, processPermissionList),
                    ErrorCodeConstants.FLOW_1_002_029_041);
        }

        // 设置流程定义参与者，限制发起人角色
        List<NodeAssignee> nodeAssigneeList = rootNode.getNodeAssigneeList();
        if (CollectionUtils.isNotEmpty(nodeAssigneeList)) {
            ServiceExceptionUtil.fail(!flwProcessActorService.saveProcessActors(processId, nodeAssigneeList.stream().map(t -> {
                FlwProcessActor fpa = new FlwProcessActor();
                fpa.setProcessId(processId);
                // 暂时支持角色限制
                fpa.setActorType(0);
                fpa.setActorId(Long.valueOf(t.getId()));
                fpa.setActorName(t.getName());
                return fpa;
            }).toList()), ErrorCodeConstants.FLOW_1_002_029_042);
        }

        // 保存流程定义配置
        if (null != dto.getCategoryId()) {
            ServiceExceptionUtil.fail(!flwProcessConfigureService.saveByDto(processId, dto), ErrorCodeConstants.FLOW_1_002_029_043);
        }
        return processId;
    }

    /**
     * 验证判断非历史版本流程流程唯一标识key
     */
    private void checkProcessKey(Long processId, String processKey) {
        Long count = lambdaQuery().ne(null != processId, FlwProcess::getId, processId)
                .ne(FlwProcess::getProcessState, 2)
                .eq(FlwProcess::getProcessKey, processKey).count();
        ServiceExceptionUtil.fail(count > 0, ErrorCodeConstants.FLOW_1_002_029_044);
    }

    @Transactional(rollbackFor = Exception.class)
    @Override
    public boolean removeProcessInfo(Long id) {
        // 检查流程定义操作权限
        this.checkOperateApproval(id);

        // 删除流程
        FlwProcess flwProcess = this.checkById(id);
        if (Objects.equals(1, flwProcess.getProcessVersion())) {
            this.cascadeRemoveById(flwProcess.getId());
        } else {
            // 存在历史全部删除
            baseMapper.selectListByProcessKey(null,
                    flwProcess.getProcessKey()).forEach(t -> this.cascadeRemoveById(t.getId()));
        }
        return true;
    }

    private void cascadeRemoveById(Long id) {
        // 删除相关流程定义信息
        flwProcessActorService.removeByProcessId(id);
        flwProcessPermissionService.removeByProcessId(id);
        flwProcessConfigureService.removeByProcessId(id);
        // 级联删除相关信息
        flowLongEngine.processService().cascadeRemove(id);
    }

    private void checkOperateApproval(Long processId) {
        LoginUser userSession = SecurityFrameworkUtils.getLoginUser();
        if (userSession == null) {
            ServiceExceptionUtil.fail(true, ErrorCodeConstants.FLOW_1_002_029_054);
        }
        //非租户超管
        if (!adminUserService.hasTenantAdmin(userSession.getId())) {
            List<FlwProcessPermission> fppList = flwProcessPermissionService.getByProcessId(processId);
            //流程本身没有设置管理员，则无需判断
            if (CollUtil.isEmpty(fppList)) {
                return;
            }
            FlwProcessPermission fpp = fppList.stream()
              .filter(t -> Objects.equals(t.getUserId(), userSession.getId())).findFirst()
              .orElse(null);
            if (Objects.isNull(fpp)) {
                ServiceExceptionUtil.fail(true, ErrorCodeConstants.FLOW_1_002_029_055);
            }
            if (null != fpp) {
                ServiceExceptionUtil.fail(!fpp.allowOperateApproval(), ErrorCodeConstants.FLOW_1_002_029_055);
            }
        }
    }

    protected FlwProcessPermission getFlwProcessPermissionByProcessId(LoginUser userSession, Long processId) {
        Long userId = null == userSession ? null : userSession.getId();
        return flwProcessPermissionService.getByUserIdAndProcessId(userId, processId);
    }

    @Transactional(rollbackFor = Exception.class)
    @Override
    public boolean sort(List<FlwCategorySortDTO> dtoList) {
        if (CollectionUtils.isNotEmpty(dtoList)) {
            int i = 0;
            List<FlwProcessCategory> fpcList = new ArrayList<>();
            List<FlwProcess> fpList = new ArrayList<>();
            for (FlwCategorySortDTO dto : dtoList) {
                List<Long> processIds = dto.getProcessIds();
                if (CollectionUtils.isNotEmpty(processIds)) {
                    int j = 0;
                    fpcList.add(dto.toFlwProcessCategory(++i));
                    for (Long processId : processIds) {
                        FlwProcess fp = new FlwProcess();
                        fp.setId(processId);
                        fp.setSort(++j);
                        fpList.add(fp);
                    }
                }
            }
            // 更新流程排序
            if (CollectionUtils.isNotEmpty(fpList)) {
                flwProcessConfigureService.updateRelation(dtoList);
                ServiceExceptionUtil.fail(!super.updateBatchById(fpList), ErrorCodeConstants.FLOW_1_002_029_046);
            }
            // 更新流程分类顺序
            if (CollectionUtils.isNotEmpty(fpcList)) {
                ServiceExceptionUtil.fail(!flwProcessCategoryService.sort(fpcList), ErrorCodeConstants.FLOW_1_002_029_047);
            }
        }
        return true;
    }

    @Override
    public boolean updateSateById(Long id, Integer state) {
        // 检查流程定义操作权限
        this.checkOperateApproval(id);

        // 更新流程定义排序
        FlwProcess flwProcess = new FlwProcess();
        flwProcess.setId(id);
        int dbState = 0;
        if (Objects.equals(1, state)) {
            dbState = 1;
            // 删除缓存
            FlowLongContext.invalidateProcessModel(flwProcess.modelCacheKey());
        }
        flwProcess.setProcessState(dbState);
        return super.updateById(flwProcess);
    }

    @Transactional(rollbackFor = Exception.class)
    @Override
    public boolean cloneById(Long id) {
        // 检查流程定义操作权限
        this.checkOperateApproval(id);

        // 克隆流程
        String suffix = "Copy" + System.currentTimeMillis();
        FlwProcessDTO dto = this.getDtoById(id);
        dto.setProcessId(null);
        dto.setProcessName(dto.getProcessName() + suffix);
        dto.setProcessKey(dto.getProcessKey() + suffix);
        dto.setProcessType(dto.getProcessType());
        String modelContent = dto.getModelContent();
        Map<String, Object> modelContentMap = JsonUtils.readMap(modelContent);
        modelContentMap.put("name", dto.getProcessName());
        modelContentMap.put("key", dto.getProcessKey());
        dto.setModelContent(JsonUtils.toJsonString(modelContentMap));
        return null != this.saveDto(dto);
    }

    @Transactional(rollbackFor = Exception.class)
    @Override
    public boolean checkoutById(Long id) {
        // 检查流程定义操作权限
        this.checkOperateApproval(id);

        // 检出历史流程
        FlwProcess flwProcess = this.checkById(id);
        final int hisVersion = flwProcess.getProcessVersion();
        FlwProcess currentProcess = lambdaQuery().eq(FlwProcess::getProcessKey, flwProcess.getProcessKey())
                .ne(FlwProcess::getProcessState, 2).one();
        if (null != currentProcess) {
            // 启用历史流程，设置为当前版本
            FlwProcess temp = new FlwProcess();
            temp.setId(flwProcess.getId());
            temp.setProcessVersion(currentProcess.getProcessVersion());
            temp.setProcessState(currentProcess.getProcessState());
            if (super.updateById(temp)) {
                // 当前流程归档为历史状态
                FlwProcess his = new FlwProcess();
                his.setId(currentProcess.getId());
                his.setProcessVersion(hisVersion);
                his.setFlowState(FlowState.history);
                return super.updateById(his);
            }
        }
        return false;
    }
}
