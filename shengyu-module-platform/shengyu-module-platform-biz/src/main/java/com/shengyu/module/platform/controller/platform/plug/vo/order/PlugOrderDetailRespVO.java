package com.shengyu.module.platform.controller.platform.plug.vo.order;

import com.shengyu.framework.common.enums.CommonConstants;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

@Schema(description = "管理后台 - 插件订单详情 Response VO")
@Data
public class PlugOrderDetailRespVO {

    /**
     * ID
     */
    @Schema(description = "id", requiredMode = Schema.RequiredMode.REQUIRED, example = "857")
    private Long id;

    /**
     * 订单编号
     */
    @Schema(description = "订单编号", required = true)
    private String orderNo;

    /**
     * 订单状态 0：待审核,1：审核通过,2：审核不通过
     *
     * 枚举 {@link CommonConstants.PlugOrderStatusEnum}
     */
    @Schema(description = "订单状态 0：待审核,1：审核通过,2：审核不通过。 CommonConstants.PlugOrderStatusEnum", requiredMode = Schema.RequiredMode.REQUIRED, example = "2")
    private Integer orderStatus;

    @Schema(description = "审核描述")
    private String auditNote;

    /**
     * 用户 IP
     */
    @Schema(description = "用户 IP")
    private String userIp;

    /**
     * 申请者编号
     */
    @Schema(description = "申请者编号")
    private Long userId;

    /**
     * 订单申请成功时间
     */
    @Schema(description = "订单申请成功时间")
    private LocalDateTime successTime;

    /**
     * 订单备注
     */
    @Schema(description = "订单备注")
    private String note;

    /**
     * 创建时间
     */
    @Schema(description = "创建时间", required = true)
    private LocalDateTime createTime;

    /**
     * 租户编号
     */
    @Schema(description = "租户编号", required = true)
    private Long tenantId;

    /**
     * 订单项
     */
    @Schema(description = "订单项")
    private List<PlugOrderItemRespVO> itemRespVOS;

}
