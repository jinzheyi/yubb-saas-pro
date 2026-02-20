package com.shengyu.module.system.controller.app.user.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Schema(description = "移动端 - 用户详情 Response VO")
@Data
public class AppUserDetailRespVO {

    @Schema(description = "用户ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    private Long id;

    @Schema(description = "用户昵称", requiredMode = Schema.RequiredMode.REQUIRED, example = "张三")
    private String nickname;

    @Schema(description = "真实姓名", example = "张三")
    private String realName;

    @Schema(description = "手机号码", example = "13800138000")
    private String mobile;

    @Schema(description = "用户邮箱", example = "zhangsan@example.com")
    private String email;

    @Schema(description = "用户头像", example = "https://...")
    private String avatar;

    @Schema(description = "用户性别(1-男 2-女)", example = "1")
    private Integer sex;

    @Schema(description = "部门ID", example = "1")
    private Long deptId;

    @Schema(description = "部门名称", example = "研发部")
    private String deptName;

    @Schema(description = "岗位名称", example = "Java开发工程师")
    private String postName;

    @Schema(description = "公司名称", example = "科技创新集团有限公司")
    private String companyName;

    @Schema(description = "备注", example = "这是一个备注")
    private String remark;

}
