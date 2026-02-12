package com.shengyu.module.system.controller.app.im.vo.group;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import jakarta.validation.constraints.NotNull;

@Schema(description = "移动端 - IM 群组更新 Request VO")
@Data
public class AppImGroupUpdateReqVO {

    @Schema(description = "群ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @NotNull(message = "群ID不能为空")
    private Long id;

    @Schema(description = "群名称", example = "技术交流群")
    private String name;

    @Schema(description = "群头像", example = "https://...")
    private String avatar;

    @Schema(description = "群公告", example = "欢迎加入技术交流群")
    private String notice;

    @Schema(description = "群简介", example = "这是一个技术交流群")
    private String introduction;

}
