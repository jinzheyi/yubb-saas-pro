package com.shengyu.module.system.controller.app.user.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Schema(description = "移动端 - 用户简要信息 Response VO")
@Data
public class AppUserSimpleRespVO {

    @Schema(description = "用户ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    private Long id;

    @Schema(description = "用户昵称", requiredMode = Schema.RequiredMode.REQUIRED, example = "张三")
    private String nickname;

    @Schema(description = "用户头像", example = "https://www.example.com/avatar.jpg")
    private String avatar;

    @Schema(description = "手机号码", example = "15601691300")
    private String mobile;

    @Schema(description = "邮箱", example = "shengyu@example.com")
    private String email;

    @Schema(description = "性别（0男 1女）", example = "0")
    private Integer sex;

    @Schema(description = "部门ID", example = "1")
    private Long deptId;

    @Schema(description = "部门名称", example = "研发部")
    private String deptName;

    @Schema(description = "岗位名称", example = "Java工程师")
    private String postName;

    @Schema(description = "状态（0正常 1停用）", example = "0")
    private Integer status;

}
