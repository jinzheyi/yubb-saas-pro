package com.shengyu.module.system.framework.flow;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.extra.spring.SpringUtil;
import com.baomidou.mybatisplus.core.toolkit.CollectionUtils;
import com.shengyu.framework.common.exception.ErrorCode;
import com.shengyu.framework.common.exception.util.ServiceExceptionUtil;
import com.shengyu.framework.flowlong.engine.FlowConstants;
import com.shengyu.framework.flowlong.engine.FlowDataTransfer;
import com.shengyu.framework.flowlong.engine.TaskActorProvider;
import com.shengyu.framework.flowlong.engine.assist.ObjectUtils;
import com.shengyu.framework.flowlong.engine.core.Execution;
import com.shengyu.framework.flowlong.engine.core.FlowCreator;
import com.shengyu.framework.flowlong.engine.core.enums.NodeSetType;
import com.shengyu.framework.flowlong.engine.core.enums.TaskType;
import com.shengyu.framework.flowlong.engine.entity.FlwInstance;
import com.shengyu.framework.flowlong.engine.entity.FlwTaskActor;
import com.shengyu.framework.flowlong.engine.model.DynamicAssignee;
import com.shengyu.framework.flowlong.engine.model.NodeAssignee;
import com.shengyu.framework.flowlong.engine.model.NodeCandidate;
import com.shengyu.framework.flowlong.engine.model.NodeModel;
import com.shengyu.module.system.controller.admin.user.vo.user.UserRespVO;
import com.shengyu.module.system.enums.ErrorCodeConstants;
import com.shengyu.module.system.service.dept.DeptService;
import com.shengyu.module.system.service.permission.PermissionService;
import com.shengyu.module.system.service.user.AdminUserService;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.function.Supplier;
import java.util.stream.Collectors;
import org.springframework.stereotype.Component;

@Component
public class FlowTaskActorProvider implements TaskActorProvider {

    @Override
    public boolean isAllowed(NodeModel nodeModel, FlowCreator flowCreator) {
        List<NodeAssignee> nodeAssigneeList = nodeModel.getNodeAssigneeList();
        if (ObjectUtils.isNotEmpty(nodeAssigneeList)) {
            if (NodeSetType.specifyMembers.eq(nodeModel.getSetType())) {
                // 1，指定成员
                return nodeAssigneeList.stream().anyMatch((t) -> Objects.equals(t.getId(), flowCreator.getCreateId()));
            }

            if (NodeSetType.role.eq(nodeModel.getSetType())) {
                // 3，角色
                PermissionService sysUserRoleService = SpringUtil.getBean(PermissionService.class);
                List<Long> roleIds = nodeModel.getNodeAssigneeList().stream().map(t -> Long.valueOf(t.getId())).toList();
                ServiceExceptionUtil.fail(!sysUserRoleService.hasAnyRoleIds(Long.valueOf(flowCreator.getCreateId()), roleIds), ErrorCodeConstants.FLOW_1_002_029_006);
            }
        }
        return true;
    }

    @Override
    public Integer getActorType(NodeModel nodeModel) {
        // 全部人员参与审批分组策略
        if (nodeModel.allJoinGroupStrategy()) {
            // 0，用户
            return 0;
        }

        // 1，角色
        if (NodeSetType.role.eq(nodeModel.getSetType())) {
            return 1;
        }

        // 2，部门
        if (NodeSetType.department.eq(nodeModel.getSetType())) {
            return 2;
        }

        // 发起人自选情况
        if (NodeSetType.initiatorSelected.eq(nodeModel.getSetType())) {
            if (Objects.equals(3, nodeModel.getSelectMode())) {
                // 1，自选一个人 2，自选多个人 3，自选角色
                return 1;
            } else {
                // 候选情况
                NodeCandidate nodeCandidate = nodeModel.getNodeCandidate();
                if (null != nodeCandidate) {
                    // 1，角色
                    if (Objects.equals(1, nodeCandidate.getType())) {
                        return 1;
                    }

                    // 2，部门
                    if (Objects.equals(2, nodeCandidate.getType())) {
                        return 2;
                    }
                }
            }
        }

        // 其它类型自定义映射
        return 0;
    }

    @Override
    public List<FlwTaskActor> getTaskActors(NodeModel nodeModel, Execution execution) {
        final Integer nodeType = nodeModel.getType();
        if (TaskType.callProcess.eq(nodeType) || TaskType.trigger.eq(nodeType) || TaskType.timer.eq(nodeType)) {
            // 子流程，触发器情况
            return null;
        }

        final FlowCreator flowCreator = execution.getFlowCreator();
        if (TaskType.major.eq(nodeType)) {
            // 发起人审批，经过 isAllowed 验证合法，直接返回当前执行人
            return Collections.singletonList(FlwTaskActor.ofFlowCreator(flowCreator));
        }

        if (TaskType.approval.eq(nodeType)) {
            /*
             * 审核人类型
             * <p>
             * 1，指定成员
             * 2，主管
             * 3，角色
             * 4，发起人自选
             * 5，发起人自己
             * 6，连续多级主管
             * 7，部门
             * </p>
             */
            if (NodeSetType.supervisor.eq(nodeModel.getSetType())) {
                // 2，主管是取当时发起流程创建者的部门负责人
                FlwInstance fi = execution.getFlwInstance();
                return getDepartmentHeadInfo(FlowCreator.of(fi.getCreateId(), fi.getCreateBy()), nodeModel, () -> ErrorCodeConstants.FLOW_1_002_029_008);
            } else if (NodeSetType.initiatorSelected.eq(nodeModel.getSetType())) {
                // 4，发起人自选
                Map<String, Object> modelData = FlowDataTransfer.get(FlowConstants.processDynamicAssignee);
                if (ObjectUtils.isNotEmpty(modelData)) {
                    DynamicAssignee dynamicAssignee = (DynamicAssignee) modelData.get(nodeModel.getNodeKey());
                    if (null != dynamicAssignee && CollectionUtils.isNotEmpty(dynamicAssignee.getAssigneeList())) {
                        return dynamicAssignee.getAssigneeList().stream().map(t -> {
                            FlwTaskActor flwTaskActor = FlwTaskActor.ofNodeAssignee(t);
                            // 前端 1 用户 3 角色 转为后台对应的 0，用户 1，角色
                            Integer type = dynamicAssignee.getType();
                            flwTaskActor.setActorType(Objects.equals(3, type) ? 1 : 0);
                            return flwTaskActor;
                        }).toList();
                    }
                }
            } else if (NodeSetType.initiatorThemselves.eq(nodeModel.getSetType())) {
                // 5，发起人自己
                FlwInstance fi = execution.getFlwInstance();
                return Collections.singletonList(FlwTaskActor.ofUser(fi.getTenantId(), fi.getCreateId(), fi.getCreateBy()));
            } else if (NodeSetType.multiLevelSupervisors.eq(nodeModel.getSetType())) {
                // 6，连续多级主管,主管是取当时发起流程创建者的部门负责人
                FlwInstance fi = execution.getFlwInstance();
                return getDepartmentHeadInfo(FlowCreator.of(fi.getCreateId(), fi.getCreateBy()), nodeModel, () -> ErrorCodeConstants.FLOW_1_002_029_009);
            }
        }

        List<NodeAssignee> nodeAssigneeList = nodeModel.getNodeAssigneeList();
        if (ObjectUtils.isNotEmpty(nodeAssigneeList)) {
            if (null == nodeModel.getSetType()

              // 1，指定成员
              || NodeSetType.specifyMembers.eq(nodeModel.getSetType())

              // 4，发起人自选
              || NodeSetType.initiatorSelected.eq(nodeModel.getSetType())) {

                boolean isRole = false;
                boolean isDepartment = false;
                if (Objects.equals(3, nodeModel.getSelectMode())) {
                    // 3，自选角色
                    isRole = true;
                } else if (Objects.equals(4, nodeModel.getSelectMode())) {
                    // 4，自选部门
                    isDepartment = true;
                } else {
                    // 自选候选人判断参与者类型
                    NodeCandidate nodeCandidate = nodeModel.getNodeCandidate();
                    if (null != nodeCandidate) {
                        // 1，角色
                        if (Objects.equals(1, nodeCandidate.getType())) {
                            isRole = true;
                        } else if (Objects.equals(2, nodeCandidate.getType())) {
                            // 2，部门
                            isDepartment = true;
                        }
                    }
                }

                if (isRole) {
                    return flwTaskActorRoleUserList(nodeAssigneeList, nodeModel);
                }

                if (isDepartment) {
                    return flwTaskActorDepartmentUserList(nodeAssigneeList, nodeModel);
                }

                // 读取当前节点配置信息
                return nodeAssigneeList.stream().map(FlwTaskActor::ofNodeAssignee).collect(Collectors.toList());
            }

            if (NodeSetType.role.eq(nodeModel.getSetType())) {
                // 3，角色
                return flwTaskActorRoleUserList(nodeAssigneeList, nodeModel);
            }
            if (NodeSetType.department.eq(nodeModel.getSetType())) {
                // 7，部门
                return flwTaskActorDepartmentUserList(nodeAssigneeList, nodeModel);
            }
        }

        ServiceExceptionUtil.fail(ErrorCodeConstants.FLOW_1_002_029_005);
        return null;
    }

    /**
     * 获取部门用户信息
     * @param nodeAssigneeList 模型部门信息
     * @param nodeModel 节点模型
     * @return 部门用户信息
     */
    private List<FlwTaskActor> flwTaskActorDepartmentUserList(List<NodeAssignee> nodeAssigneeList, NodeModel nodeModel) {
        // 获取模型对应选择的部门数据
        List<FlwTaskActor> flwTaskActorList = nodeAssigneeList.stream()
          .map(t -> FlwTaskActor.ofDepartment(t.getTenantId(),
            t.getId(), t.getName())).collect(Collectors.toList());
        if (!nodeModel.allJoinGroupStrategy()) {
            // 7，部门
            return flwTaskActorList;
        }
        // 所有加入，非部门其中一人的加入
        AdminUserService adminUserService = SpringUtil.getBean(AdminUserService.class);
        List<FlwTaskActor> flwTaskActorUserList = new ArrayList<>();
        // 获取对应部门下所有用户
        flwTaskActorList.forEach(flwTaskActor -> flwTaskActorUserList.addAll(
          adminUserService.getUserListByDeptIds(Collections.singletonList(
              Long.valueOf(flwTaskActor.getActorId())))
            .stream().map(t ->
              FlwTaskActor.ofUser(flwTaskActor.getTenantId(), String.valueOf(t.getId()),
                t.getNickname() + "(" + flwTaskActor.getActorName() + ")"))
            .toList()));
        return flwTaskActorUserList;
    }

    /**
     * 获取角色用户信息
     * @param nodeAssigneeList 模型角色信息
     * @param nodeModel 节点模型
     * @return 角色用户信息
     */
    private List<FlwTaskActor> flwTaskActorRoleUserList(List<NodeAssignee> nodeAssigneeList, NodeModel nodeModel) {
        // 获取模型对应选择的角色数据
        List<FlwTaskActor> flwTaskActorList = nodeAssigneeList.stream()
          .map(t -> FlwTaskActor.ofRole(t.getTenantId(),
            t.getId(), t.getName())).collect(Collectors.toList());
        if (!nodeModel.allJoinGroupStrategy()) {
            // 3，角色
            return flwTaskActorList;
        }
        // 所有加入，非角色其中一人的加入
        PermissionService permissionService = SpringUtil.getBean(PermissionService.class);
        AdminUserService adminUserService = SpringUtil.getBean(AdminUserService.class);
          List<FlwTaskActor> flwTaskActorUserList = new ArrayList<>();
        // 获取对应角色下所有用户
        flwTaskActorList.forEach(flwTaskActor -> {
          Set<Long> userRoleIdListByRoleId = permissionService.getUserRoleIdListByRoleId(
            Collections.singletonList(Long.valueOf(flwTaskActor.getActorId())));
          if (CollUtil.isNotEmpty(userRoleIdListByRoleId)) {
            flwTaskActorUserList.addAll(adminUserService.getUserList(userRoleIdListByRoleId).stream().map(t ->
              FlwTaskActor.ofUser(flwTaskActor.getTenantId(), String.valueOf(t.getId()),
                t.getNickname() + "(" + flwTaskActor.getActorName() + ")")).toList());
          }
        });
        return flwTaskActorUserList;
    }

    /**
     * 获取部门主管信息
     *  @param flowCreator 流程创建者信息
     *  @param nodeModel  节点信息
     */
    private List<FlwTaskActor> getDepartmentHeadInfo(FlowCreator flowCreator, NodeModel nodeModel, Supplier<ErrorCode> supplier) {
        DeptService deptService = SpringUtil.getBean(DeptService.class);
        AdminUserService userService = SpringUtil.getBean(AdminUserService.class);
        UserRespVO userRespVO = userService.getUser(Long.valueOf(flowCreator.getCreateId()));
        if (Objects.isNull(userRespVO.getDeptId())) {
            ServiceExceptionUtil.fail(ErrorCodeConstants.FLOW_1_002_029_007);
        }
        List<UserRespVO> leaders = new ArrayList<>();
        if (0 == nodeModel.getDirectorMode()) {
            leaders = deptService.getAllAncestorLeaders(userRespVO.getDeptId());
        } else if (1 == nodeModel.getDirectorMode()) {
            leaders = deptService.getAncestorLeadersUpToLevel(userRespVO.getDeptId(), nodeModel.getDirectorLevel());
        }
        if (CollectionUtils.isEmpty(leaders)) {
            ServiceExceptionUtil.fail(supplier.get());
        }
        return leaders.stream().map(user -> {
            FlwTaskActor flwTaskActor = new FlwTaskActor();
            flwTaskActor.setActorId(String.valueOf(user.getId()));
            flwTaskActor.setActorName(user.getNickname());
            flwTaskActor.setActorType(0);
            return flwTaskActor;
        }).collect(Collectors.toList());
    }
}
