package com.shengyu.module.platform.api.tenant.dto.menu;

import com.shengyu.framework.common.enums.CommonConstants;
import lombok.Data;

import java.util.List;

@Data
public class TenantMenuListReqDTO {

    /**
     * 菜单名称，模糊匹配
     */
    private String name;

    /**
     * 展示状态，参见 CommonStatusEnum 枚举类
     */
    private Integer status;

    /**
     * 菜单维度 0：普通菜单  1：插件菜单
     *
     * 枚举 {@link CommonConstants.MenuDimensionEnum}
     */
    private Integer dimension;

    /**
     * 插件id数组
     */
    private List<Long> plugIds;

    /**
     * 菜单id数组
     */
    private List<Long> ids;

}
