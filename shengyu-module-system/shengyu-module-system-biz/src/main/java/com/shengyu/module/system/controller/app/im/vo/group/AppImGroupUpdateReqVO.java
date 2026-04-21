package com.shengyu.module.system.controller.app.im.vo.group;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotNull;

@Schema(description = "移动端 - IM 群组更新 Request VO")
@Data
public class AppImGroupUpdateReqVO {

    @Schema(description = "群ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @NotNull(message = "{validation.im.group_id.required}")
    private Long id;

    @Schema(description = "群名称", example = "技术交流群")
    private String name;

    @Schema(description = "群头像", example = "https://...")
    private String avatar;

    @Schema(description = "群公告", example = "欢迎加入技术交流群")
    private String notice;

    @Schema(description = "群简介", example = "这是一个技术交流群")
    private String introduction;

    @Schema(description = "加群是否需要审批", example = "false")
    private Boolean needApproval;

    @Schema(description = "是否允许普通成员邀请他人入群", example = "true")
    private Boolean allowMemberInvite;

}
