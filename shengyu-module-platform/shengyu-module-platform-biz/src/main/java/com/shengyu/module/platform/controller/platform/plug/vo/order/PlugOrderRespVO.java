package com.shengyu.module.platform.controller.platform.plug.vo.order;

import com.shengyu.framework.common.enums.CommonConstants;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.time.LocalDateTime;

@Schema(description = "管理后台 - 插件订单 Response VO")
@Data
public class PlugOrderRespVO {

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
    @Schema(description = "订单状态 0：待审核,1：审核通过,2：审核不通过，3：拒绝审核。 CommonConstants.PlugOrderStatusEnum", requiredMode = Schema.RequiredMode.REQUIRED, example = "2")
    private Integer orderStatus;

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
     * 多租户编号
     */
    @Schema(description = "多租户编号")
    private Long tenantId;

}
