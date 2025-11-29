package com.shengyu.module.im.controller.admin.vo.group;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotNull;

@Schema(description = "管理后台 - 群组更新 Request VO")
@Data
public class ImGroupUpdateReqVO {

    @Schema(description = "群组ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1001")
    @NotNull(message = "群组ID不能为空")
    private Long groupId;

    @Schema(description = "群组名称", example = "技术交流群")
    private String name;

    @Schema(description = "群组头像", example = "https://example.com/avatar.jpg")
    private String avatar;

    @Schema(description = "群组描述", example = "技术交流群，欢迎大家加入")
    private String description;

}
