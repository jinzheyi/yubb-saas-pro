package com.shengyu.module.system.controller.app.im.vo.contact;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Schema(description = "移动端 - IM 联系人 Response VO")
@Data
public class AppImContactRespVO {

    @Schema(description = "用户ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    private Long id;

    @Schema(description = "用户昵称", requiredMode = Schema.RequiredMode.REQUIRED, example = "张三")
    private String nickname;

    @Schema(description = "用户头像", example = "https://...")
    private String avatar;

    @Schema(description = "部门ID", example = "1")
    private Long deptId;

    @Schema(description = "部门名称", example = "技术部")
    private String deptName;

    @Schema(description = "岗位名称", example = "Java工程师")
    private String postName;

    @Schema(description = "是否星标联系人", requiredMode = Schema.RequiredMode.REQUIRED, example = "false")
    private Boolean star;

    @Schema(description = "是否免打扰", requiredMode = Schema.RequiredMode.REQUIRED, example = "false")
    private Boolean noDisturb;

    @Schema(description = "拼音首字母", example = "Z")
    private String pinyin;

}
