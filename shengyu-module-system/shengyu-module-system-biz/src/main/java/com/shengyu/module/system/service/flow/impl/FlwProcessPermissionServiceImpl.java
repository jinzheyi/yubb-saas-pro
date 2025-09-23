package com.shengyu.module.system.service.flow.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.shengyu.framework.mybatis.core.service.BaseServiceImpl;
import com.shengyu.module.system.controller.admin.flow.dto.FlwProcessPermissionDTO;
import com.shengyu.module.system.dal.dataobject.flow.FlwProcessPermission;
import com.shengyu.module.system.dal.mysql.flow.FlwProcessPermissionMapper;
import com.shengyu.module.system.service.flow.IFlwProcessPermissionService;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * 流程定义权限 服务实现类
 *
 * @author 青苗
 * @since 2023-09-07
 */
@Service
public class FlwProcessPermissionServiceImpl extends BaseServiceImpl<FlwProcessPermissionMapper, FlwProcessPermission> implements IFlwProcessPermissionService {

    @Override
    public boolean saveProcessPermissions(Long processId, List<FlwProcessPermissionDTO> dtoList) {
        // 保存流程定义权限列表
        return super.saveBatch(dtoList.stream().map(t -> t.toFlwProcessPermission(processId)).collect(
          Collectors.toList()));
    }

    @Override
    public boolean removeByProcessId(Long processId) {
        return super.remove(this.getWrappers(processId));
    }

    private LambdaQueryWrapper<FlwProcessPermission> getWrappers(Long processId) {
        return Wrappers.<FlwProcessPermission>lambdaQuery().eq(FlwProcessPermission::getProcessId, processId);
    }

    @Override
    public List<FlwProcessPermission> getByProcessId(Long processId) {
        return super.list(this.getWrappers(processId));
    }

    @Override
    public FlwProcessPermission getByUserIdAndProcessId(Long userId, Long processId) {
        FlwProcessPermission fpp = new FlwProcessPermission();
        fpp.setUserId(userId);
        fpp.setProcessId(processId);
        return super.getOne(Wrappers.query(fpp));
    }
}
