package com.shengyu.module.system.api.permission.dto;

import com.shengyu.framework.common.enums.CommonStatusEnum;
import lombok.Data;

/**
 * 返回租户角色精简模式
 * @author 朱述勇
 * @copyright: 版权所有 开源组织 gitee(https://gitee.com/jinzheyi)作者：朱述勇<br/>
 * GitHub(https://github.com/jinzheyi)作者：朱述勇 。
 * @since 2022/7/21 22:00
 */
@Data
public class RoleSimpleRespDTO {

    /**
     * 角色ID
     */
    private Long id;

    /**
     * 角色标识
     *
     * 枚举
     */
    private String code;

    /**
     * 角色状态
     *
     * 枚举 {@link CommonStatusEnum}
     */
    private Integer status;

    /**
     * 多租户编号
     */
    private Long tenantId;

}
