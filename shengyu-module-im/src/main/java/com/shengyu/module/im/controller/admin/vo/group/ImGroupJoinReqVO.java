package com.shengyu.module.im.controller.admin.vo.group;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotNull;

@Schema(description = "管理后台 - 群组加入 Request VO")
@Data
public class ImGroupJoinReqVO {

    @Schema(description = "群组ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1001")
    @NotNull(message = "群组ID不能为空")
    private Long groupId;

}
