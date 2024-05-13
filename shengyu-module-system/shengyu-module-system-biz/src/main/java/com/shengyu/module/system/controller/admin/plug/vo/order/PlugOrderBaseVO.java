package com.shengyu.module.system.controller.admin.plug.vo.order;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import org.springframework.format.annotation.DateTimeFormat;

import java.time.LocalDateTime;

import static com.shengyu.framework.common.util.date.DateUtils.FORMAT_YEAR_MONTH_DAY_HOUR_MINUTE_SECOND;

/**
* 插件订单 Base VO，提供给添加、修改、详细的子 VO 使用
* 如果子 VO 存在差异的字段，请不要添加到这里，影响 Swagger 文档生成
*/
@Data
public class PlugOrderBaseVO {

    @Schema(description = "订单编号", requiredMode = Schema.RequiredMode.REQUIRED)
    private String orderNo;

    @Schema(description = "订单状态 0：待审核,1：审核通过,2：审核不通过", requiredMode = Schema.RequiredMode.REQUIRED, example = "2")
    private Integer orderStatus;

    @Schema(description = "审核描述")
    private String auditNote;

    @Schema(description = "用户 IP", requiredMode = Schema.RequiredMode.REQUIRED)
    private String userIp;

    @Schema(description = "申请者编号", requiredMode = Schema.RequiredMode.REQUIRED, example = "31333")
    private Long userId;

    @Schema(description = "订单申请成功时间")
    @DateTimeFormat(pattern = FORMAT_YEAR_MONTH_DAY_HOUR_MINUTE_SECOND)
    private LocalDateTime successTime;

    @Schema(description = "订单备注")
    private String note;

}
