package com.shengyu.module.system.controller.app.im.vo.group;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotNull;

@Schema(description = "移动端 - IM 群加群申请处理 Request VO")
@Data
public class AppImGroupJoinRequestProcessReqVO {

    @Schema(description = "申请单ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "10001")
    @NotNull(message = "申请单ID不能为空")
    private Long requestId;

    @Schema(description = "拒绝原因", example = "请联系群主确认身份")
    private String rejectReason;
}
