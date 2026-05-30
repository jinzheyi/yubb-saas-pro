package com.shengyu.module.system.controller.app.im.vo.group;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotNull;

@Schema(description = "移动端 - IM 群邀请码生成 Request VO")
@Data
public class AppImGroupInviteGenerateReqVO {

    @Schema(description = "群组ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "123456")
    @NotNull(message = "{validation.im.group_id.required}")
    private Long groupId;

    @Schema(description = "有效期(小时),0或不传表示永久有效", example = "0")
    private Integer expireHours = 0; // 默认永久有效

    @Schema(description = "最大使用次数(0表示不限制)", example = "0")
    private Integer maxUseCount = 0; // 默认不限制

}
