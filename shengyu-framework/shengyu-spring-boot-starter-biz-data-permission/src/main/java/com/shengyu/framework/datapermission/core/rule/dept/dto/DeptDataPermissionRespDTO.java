package com.shengyu.framework.datapermission.core.rule.dept.dto;

import lombok.Data;

import java.util.Set;

/**
 * 部门数据权限 Response DTO
 * 统一的数据权限响应对象，供平台端和租户端共用
 *
 * @author 圣钰科技
 */
@Data
public class DeptDataPermissionRespDTO {

    /**
     * 是否可查看全部数据
     */
    private Boolean all;

    /**
     * 是否可查看自己的数据
     */
    private Boolean self;

    /**
     * 可查看的部门编号数组
     */
    private Set<Long> deptIds;

}
