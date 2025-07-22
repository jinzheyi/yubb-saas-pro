package com.shengyu.module.system.framework.flow;

import cn.hutool.extra.spring.SpringUtil;
import com.baomidou.mybatisplus.core.toolkit.CollectionUtils;
import com.shengyu.framework.common.exception.util.ServiceExceptionUtil;
import com.shengyu.framework.flowlong.engine.FlowLongEngine;
import com.shengyu.framework.flowlong.engine.TaskAccessStrategy;
import com.shengyu.framework.flowlong.engine.assist.ObjectUtils;
import com.shengyu.framework.flowlong.engine.core.FlowCreator;
import com.shengyu.framework.flowlong.engine.entity.FlwTaskActor;
import com.shengyu.module.system.controller.admin.user.vo.user.UserRespVO;
import com.shengyu.module.system.enums.ErrorCodeConstants;
import com.shengyu.module.system.service.permission.PermissionService;
import com.shengyu.module.system.service.user.AdminUserService;
import org.springframework.stereotype.Component;

import java.util.*;

@Component
public class FlowTaskAccessStrategy implements TaskAccessStrategy {

    @Override
    public FlwTaskActor isAllowed(String userId, List<FlwTaskActor> taskActors) {
        if (null == userId || ObjectUtils.isEmpty(taskActors)) {
            return null;
        }

        // 优先匹配用户参与者情况
        Optional<FlwTaskActor> ftaOpt = taskActors.stream().filter(t ->
                Objects.equals(0, t.getActorType()) && Objects.equals(t.getActorId(), userId)).findFirst();
        if (ftaOpt.isPresent()) {
            return ftaOpt.get();
        }

        FlwTaskActor flwTaskActor = taskActors.get(0);
        if (Objects.equals(flwTaskActor.getActorType(), 1)) {
            // 角色
            PermissionService sysUserRoleService = SpringUtil.getBean(PermissionService.class);
            return contains(taskActors, sysUserRoleService.getUserRoleIdListByUserId(Long.valueOf(userId)));
        } else if (Objects.equals(flwTaskActor.getActorType(), 2)) {
            // 部门
            AdminUserService sysUserDepartmentService = SpringUtil.getBean(AdminUserService.class);
            UserRespVO userRespVO = sysUserDepartmentService.getUser(Long.valueOf(userId));
            return contains(taskActors, Collections.singleton(Objects.nonNull(userRespVO) ? userRespVO.getDeptId() : null));
        }

        // 无匹配参与者
        return null;
    }

    private FlwTaskActor contains(List<FlwTaskActor> taskActors, Collection<Long> ids) {
        if (CollectionUtils.isEmpty(ids)) {
            return null;
        }
        return taskActors.stream().filter(t -> ids.contains(Long.valueOf(t.getActorId()))).findFirst().orElse(null);
    }

    @Override
    public FlwTaskActor getAllowedFlwTaskActor(Long taskId, FlowCreator flowCreator, List<FlwTaskActor> taskActors) {
        Optional<FlwTaskActor> taskActorOpt = taskActors.stream().filter(t -> Objects.equals(t.getActorId(), flowCreator.getCreateId())).findFirst();
        if (!taskActorOpt.isPresent()) {
            // 可以根据具体业务调整判断条件
            //todo 这里流程监控的业务可能后期会根据需求调整，暂时这样
            if (Objects.equals(FlowCreator.ADMIN.getCreateId(), flowCreator.getCreateId())) {
                // 管理员特权，任务监控 替用户操作
                FlowLongEngine flowLongEngine = SpringUtil.getBean(FlowLongEngine.class);
                List<FlwTaskActor> flwTaskActors = flowLongEngine.queryService().getTaskActorsByTaskId(taskId);
                if (ObjectUtils.isNotEmpty(flwTaskActors)) {
                    return flwTaskActors.get(0);
                }
            }
        }
        ServiceExceptionUtil.fail(!taskActorOpt.isPresent(), ErrorCodeConstants.FLOW_1_002_029_053);
        return taskActorOpt.get();
    }
}
