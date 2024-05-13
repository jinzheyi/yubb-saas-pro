package com.shengyu.module.system.api.plug.dto.order;

import com.shengyu.framework.common.enums.CommonConstants;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

@Data
public class PlugOrderDetailRespDTO {

    /**
     * ID
     */
    private Long id;

    /**
     * 订单编号
     */
    private String orderNo;

    /**
     * 订单状态 0：待审核,1：审核通过,2：审核不通过
     *
     * 枚举 {@link CommonConstants.PlugOrderStatusEnum}
     */
    private Integer orderStatus;

    /**
     * 审核描述
     */
    private String auditNote;

    /**
     * 用户 IP
     */
    private String userIp;

    /**
     * 申请者编号
     */
    private Long userId;

    /**
     * 订单申请成功时间
     */
    private LocalDateTime successTime;

    /**
     * 订单备注
     */
    private String note;

    /**
     * 创建时间
     */
    private LocalDateTime createTime;

    /**
     * 租户编号
     */
    private Long tenantId;

    /**
     * 订单项
     */
    private List<PlugOrderItemRespDTO> itemRespDTOS;

}
