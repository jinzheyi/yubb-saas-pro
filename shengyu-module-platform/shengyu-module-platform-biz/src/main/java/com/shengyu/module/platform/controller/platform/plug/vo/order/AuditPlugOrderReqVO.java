package com.shengyu.module.platform.controller.platform.plug.vo.order;

import com.shengyu.framework.common.enums.CommonConstants;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import org.hibernate.validator.constraints.Length;

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
public class AuditPlugOrderReqVO {

    /**
     * ID
     */
    @Schema(description = "插件订单id", required = true)
    @NotNull(message = "插件订单id不能为空")
    private Long id;

    /**
     * 订单状态 0：待审核,1：审核通过,2：审核不通过
     *
     * 枚举 {@link CommonConstants.PlugOrderStatusEnum}
     */
    @Schema(description = "审批状态 0：待审核,1：审核通过,2：审核不通过", required = true)
    @NotNull(message = "审批状态不能为空")
    private Integer orderStatus;

    @Schema(description = "审核描述")
    @Length(max = 200, message = "审核描述请不要超过200个字符")
    private String auditNote;

}
