package com.shengyu.module.system.service.flow.impl;

import com.shengyu.module.system.dal.dataobject.flow.FlwProcessActor;
import com.shengyu.module.system.dal.dataobject.flow.FlwProcessCategory;
import com.shengyu.module.system.dal.dataobject.flow.FlwProcessConfigure;
import com.shengyu.module.system.dal.dataobject.flow.FlwProcessPermission;
import com.shengyu.module.system.dal.dataobject.flow.dto.*;
import com.shengyu.module.system.dal.dataobject.flow.vo.FlwProcessCategoryVO;
import com.shengyu.module.system.dal.dataobject.flow.vo.FlwProcessVO;
import com.aizuda.boot.modules.flw.flow.FlowForm;
import com.aizuda.boot.modules.flw.flow.FlowHelper;
import com.aizuda.boot.modules.flw.mapper.FlowlongMapper;
import com.aizuda.boot.modules.flw.service.*;
import com.shengyu.framework.flowlong.engine.FlowDataTransfer;
import com.shengyu.framework.flowlong.engine.FlowLongEngine;
import com.shengyu.framework.flowlong.engine.ProcessService;
import com.shengyu.framework.flowlong.engine.core.FlowCreator;
import com.shengyu.framework.flowlong.engine.core.FlowLongContext;
import com.shengyu.framework.flowlong.engine.core.enums.FlowState;
import com.shengyu.framework.flowlong.engine.core.enums.InstanceState;
import com.shengyu.framework.flowlong.engine.core.enums.NodeSetType;
import com.shengyu.framework.flowlong.engine.core.enums.ProcessType;
import com.shengyu.framework.flowlong.engine.entity.FlwHisInstance;
import com.shengyu.framework.flowlong.engine.entity.FlwInstance;
import com.shengyu.framework.flowlong.engine.entity.FlwProcess;
import com.shengyu.framework.flowlong.engine.model.*;
import com.shengyu.framework.flowlong.mybatisplus.mapper.FlwProcessMapper;
import com.aizuda.common.toolkit.JacksonUtils;
import com.aizuda.core.api.ApiAssert;
import com.aizuda.service.web.UserSession;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import lombok.AllArgsConstructor;
import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

/**
 * 流程分类 服务实现类
 *
 * @author 青苗
 * @since 2023-09-07
 */
@Service
@AllArgsConstructor
public class FlwProcessServiceImpl extends ServiceImpl<FlwProcessMapper, FlwProcess> implements IFlwProcessService {
    private ProcessService processService;
    private IFlwProcessCategoryService flwProcessCategoryService;
    private IFlwProcessPermissionService flwProcessPermissionService;
    private IFlwProcessConfigureService flwProcessConfigureService;
    private IFlwProcessActorService flwProcessActorService;
    private IFlwProcessFormService flwProcessFormService;
    private IFlwFormTemplateService flwFormTemplateService;
    private FlowlongMapper flowlongMapper;
    private FlowLongEngine flowLongEngine;

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
    public List<FlwProcessCategoryVO> listCategoryAll(String keyword) {
        return this.listCategoryVO(keyword, false);
    }

    public List<FlwProcessCategoryVO> listCategoryVO(String keyword, boolean launch) {
        List<FlwProcessCategory> categoryList = flwProcessCategoryService.list();
        if (CollectionUtils.isEmpty(categoryList)) {
            return null;
        }
        // 全部查询
        List<FlwProcessCategoryVO> voList = new ArrayList<>();
        List<FlwProcessVO> flwProcessVOList;
        if (launch) {
            flwProcessVOList = flowlongMapper.selectLaunchProcessList();
        } else {
            flwProcessVOList = flowlongMapper.selectFlwProcessList();
        }

        boolean voIsNotEmpty = CollectionUtils.isNotEmpty(flwProcessVOList);
        if (voIsNotEmpty) {
            boolean needSort = true;
            if (launch) {
                // 发起流程，过滤不存在角色权限的流程
                UserSession userSession = UserSession.getLoginInfo();
                List<Long> notExistProcessIds = flowlongMapper.selectNotExistProcessIds(userSession.getId());
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
        ApiAssert.fail(null == flwProcess, "指定流程模型不存在");

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
                    ApiAssert.fail(null == dynamicAssignee, "发起人自选节点未设置处理人员");
                }
                ApiAssert.fail(null == dynamicAssignee || CollectionUtils.isEmpty(dynamicAssignee.getAssigneeList()),
                        "节点【 " + t.getNodeName() + " 】未设置处理人员");
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
        ApiAssert.fail(opt.isEmpty(), "流程启动失败");

        // 保存表单
        FlwInstance flwInstance = opt.get();
        ApiAssert.fail(!flwProcessFormService.saveForm(flwInstance.getId(), dto.getProcessForm()), "保存保单失败");
        return flwInstance.getId();
    }

    @Override
    public boolean removeProcessByInstanceId(Long instanceId) {
        FlwHisInstance fhi = flowLongEngine.queryService().getHistInstance(instanceId);
        ApiAssert.fail(null == fhi || InstanceState.saveAsDraft.ne(fhi.getInstanceState()), "非暂存待审流程实例，不能删除");
        flowLongEngine.runtimeService().cascadeRemoveByProcessId(fhi.getProcessId());
        return true;
    }

    @Override
    public boolean resumeProcessByInstanceId(Long instanceId) {
        return flowLongEngine.taskService().resume(instanceId, FlowHelper.getFlowCreator());
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
        ApiAssert.isEmpty(flwProcess, "未发现指定流程模型");
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
        ApiAssert.fail(null == dto.getCategoryId(), "流程定义分类ID不存在");
        ProcessModel processModel = ModelHelper.buildProcessModel(dto.getModelContent());
        NodeModel rootNode = processModel.getNodeConfig();
        int checkNodeModel = ModelHelper.checkNodeModel(rootNode);
        if (checkNodeModel > 0) {
            ApiAssert.equals(1, checkNodeModel, "模型节点名称不允许重复");
            ApiAssert.equals(2, checkNodeModel, "自动通过节点配置错误，请确保包含在条件分支节点中");
            ApiAssert.equals(3, checkNodeModel, "自动拒绝节点配置错误，请确保包含在条件分支节点中");
            ApiAssert.equals(4, checkNodeModel, "路由节点必须配置错误，请确保配置路由分支");
            ApiAssert.equals(5, checkNodeModel, "子流程节点配置错误，请确保已选择子流程");
        }
        ApiAssert.fail(null == rootNode.getChildNode(), "必须存在两个以上节点");
        int checkConditionNode = ModelHelper.checkConditionNode(rootNode);
        if (checkConditionNode > 0) {
            ApiAssert.equals(1, checkConditionNode, "存在多个条件表达式为空");
            ApiAssert.equals(2, checkConditionNode, "存在多个条件子节点为空");
            ApiAssert.equals(3, checkConditionNode, "存在条件节点KEY重复");
        }
        ApiAssert.fail(!ModelHelper.checkExistApprovalNode(rootNode), "必须存在审批节点");

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
            ApiAssert.fail(!flwProcessPermissionService.saveProcessPermissions(processId, processPermissionList),
                    "流程定义管理权限保存失败");
        }

        // 设置流程定义参与者，限制发起人角色
        List<NodeAssignee> nodeAssigneeList = rootNode.getNodeAssigneeList();
        if (CollectionUtils.isNotEmpty(nodeAssigneeList)) {
            ApiAssert.fail(!flwProcessActorService.saveProcessActors(processId, nodeAssigneeList.stream().map(t -> {
                FlwProcessActor fpa = new FlwProcessActor();
                fpa.setProcessId(processId);
                // 暂时支持角色限制
                fpa.setActorType(0);
                fpa.setActorId(Long.valueOf(t.getId()));
                fpa.setActorName(t.getName());
                return fpa;
            }).toList()), "流程发起人参与者信息保持失败");
        }

        // 保存流程定义配置
        if (null != dto.getCategoryId()) {
            ApiAssert.fail(!flwProcessConfigureService.saveByDto(processId, dto), "流程定义配置保存失败");
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
        ApiAssert.fail(count > 0, "流程唯一标识key不允许重复");
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
        UserSession userSession = UserSession.getLoginInfo();
        if (null == userSession || !UserSession.isAdmin(userSession.getId())) {
            FlwProcessPermission fpp = getFlwProcessPermissionByProcessId(userSession, processId);
            if (null != fpp) {
                ApiAssert.fail(!fpp.allowOperateApproval(), "无权限编辑操作审批流程");
            }
        }
    }

    protected FlwProcessPermission getFlwProcessPermissionByProcessId(UserSession userSession, Long processId) {
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
                ApiAssert.fail(!super.updateBatchById(fpList), "流程顺序保存失败");
            }
            // 更新流程分类顺序
            if (CollectionUtils.isNotEmpty(fpcList)) {
                ApiAssert.fail(!flwProcessCategoryService.sort(fpcList), "流程分类顺序保存失败");
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
        Map<String, Object> modelContentMap = JacksonUtils.readMap(modelContent);
        modelContentMap.put("name", dto.getProcessName());
        modelContentMap.put("key", dto.getProcessKey());
        dto.setModelContent(JacksonUtils.toJson(modelContentMap));
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
