package com.shengyu.module.system.service.flow;

import com.shengyu.framework.mybatis.core.service.IBaseService;
import com.shengyu.module.system.controller.admin.flow.dto.FlwProcessPermissionDTO;
import com.shengyu.module.system.dal.dataobject.flow.FlwProcessPermission;

import java.util.List;

/**
 * 流程定义权限 服务类
 *
 * @author 青苗
 * @since 2023-09-07
 */
public interface IFlwProcessPermissionService extends IBaseService<FlwProcessPermission> {

    /**
     * 保存流程定义权限
     *
     * @param processId 流程定义ID
     * @param dtoList   流程定义权限列表
     */
    boolean saveProcessPermissions(Long processId, List<FlwProcessPermissionDTO> dtoList);

    /**
     * 根据流程定义ID删除流程定义权限
     *
     * @param processId 流程定义ID
     */
    boolean removeByProcessId(Long processId);

    /**
     * 根据流程定义ID查询流程定义权限列表
     *
     * @param processId 流程定义ID
     */
    List<FlwProcessPermission> getByProcessId(Long processId);

    /**
     * 根据用户ID获取指定流程定义ID的权限信息
     *
     * @param userId    用户ID
     * @param processId 流程定义ID
     */
    FlwProcessPermission getByUserIdAndProcessId(Long userId, Long processId);
}
