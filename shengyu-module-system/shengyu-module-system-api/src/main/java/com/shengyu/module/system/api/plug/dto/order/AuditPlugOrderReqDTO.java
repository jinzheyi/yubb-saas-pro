package com.shengyu.module.system.api.plug.dto.order;

import com.shengyu.framework.common.enums.CommonConstants;
import lombok.Data;

import javax.validation.constraints.NotNull;

/**
 * 审核订单
 *
 * @author 朱述勇
 * @copyright: 版权所有 开源组织 gitee(https://gitee.com/jinzheyi)作者：朱述勇<br/>
 * GitHub(https://github.com/jinzheyi)作者：朱述勇 。
 * @since 2023/4/15 17:57
 */
@Data
public class AuditPlugOrderReqDTO {

    /**
     * ID
     */
    @NotNull(message = "插件订单id不能为空")
    private Long id;

    /**
     * 订单状态 0：待审核,1：审核通过,2：审核不通过
     *
     * 枚举 {@link CommonConstants.PlugOrderStatusEnum}
     */
    @NotNull(message = "审批状态不能为空")
    private Integer orderStatus;

    /**
     * 审批描述
     */
    private String auditNote;

}
