package com.shengyu.module.system.framework.flow;

import com.aizuda.boot.modules.system.service.ISysUserDepartmentService;
import com.aizuda.boot.modules.system.service.ISysUserRoleService;
import com.shengyu.framework.flowlong.engine.TaskAccessStrategy;
import com.shengyu.framework.flowlong.engine.assist.ObjectUtils;
import com.shengyu.framework.flowlong.engine.entity.FlwTaskActor;
import com.aizuda.service.spring.SpringHelper;
import org.apache.commons.collections.CollectionUtils;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Objects;
import java.util.Optional;

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
            ISysUserRoleService sysUserRoleService = SpringHelper.getBean(ISysUserRoleService.class);
            return contains(taskActors, sysUserRoleService.listRoleIdsByUserId(Long.valueOf(userId)));
        } else if (Objects.equals(flwTaskActor.getActorType(), 2)) {
            // 部门
            ISysUserDepartmentService sysUserDepartmentService = SpringHelper.getBean(ISysUserDepartmentService.class);
            return contains(taskActors, sysUserDepartmentService.listDepartmentIdsByUserId(Long.valueOf(userId)));
        }

        // 无匹配参与者
        return null;
    }

    private FlwTaskActor contains(List<FlwTaskActor> taskActors, List<Long> ids) {
        if (CollectionUtils.isEmpty(ids)) {
            return null;
        }
        return taskActors.stream().filter(t -> ids.contains(Long.valueOf(t.getActorId()))).findFirst().orElse(null);
    }
}
