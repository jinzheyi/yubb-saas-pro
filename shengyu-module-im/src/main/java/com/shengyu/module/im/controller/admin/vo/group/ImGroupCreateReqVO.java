package com.shengyu.module.im.controller.admin.vo.group;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotEmpty;

@Schema(description = "管理后台 - 群组创建 Request VO")
@Data
public class ImGroupCreateReqVO {

    @Schema(description = "群组名称", requiredMode = Schema.RequiredMode.REQUIRED, example = "技术交流群")
    @NotEmpty(message = "群组名称不能为空")
    private String name;

    @Schema(description = "群组头像", example = "https://example.com/avatar.jpg")
    private String avatar;

    @Schema(description = "群组描述", example = "技术交流群，欢迎大家加入")
    private String description;

}
