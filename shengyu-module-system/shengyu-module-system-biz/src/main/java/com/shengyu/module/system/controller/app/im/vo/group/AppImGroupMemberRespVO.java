package com.shengyu.module.system.controller.app.im.vo.group;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.time.LocalDateTime;

@Schema(description = "移动端 - IM 群成员 Response VO")
@Data
public class AppImGroupMemberRespVO {

    @Schema(description = "用户ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "100")
    private Long userId;

    @Schema(description = "在群里的昵称", example = "小明")
    private String nickname;

    @Schema(description = "群成员角色(0-普通成员 1-管理员 2-群主)", requiredMode = Schema.RequiredMode.REQUIRED, example = "0")
    private Integer role;

    @Schema(description = "是否禁言", requiredMode = Schema.RequiredMode.REQUIRED, example = "false")
    private Boolean muted;

    @Schema(description = "用户昵称", example = "张三")
    private String userNickname;

    @Schema(description = "用户头像", example = "https://...")
    private String userAvatar;

    @Schema(description = "部门名称", example = "技术部")
    private String deptName;

    @Schema(description = "加入时间", requiredMode = Schema.RequiredMode.REQUIRED)
    private LocalDateTime createTime;

}
