package com.shengyu.module.system.controller.app.im.vo.group;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.time.LocalDateTime;

@Schema(description = "移动端 - IM 群邀请码验证 Response VO")
@Data
public class AppImGroupInviteVerifyRespVO {

    @Schema(description = "是否有效", example = "true")
    private Boolean valid;

    @Schema(description = "群组ID", example = "123456")
    private Long groupId;

    @Schema(description = "群名称", example = "技术交流群")
    private String groupName;

    @Schema(description = "群头像", example = "https://...")
    private String groupAvatar;

    @Schema(description = "成员数量", example = "50")
    private Integer memberCount;

    @Schema(description = "是否需要审批", example = "false")
    private Boolean needApproval;

    @Schema(description = "过期时间")
    private LocalDateTime expireTime;

    @Schema(description = "错误信息(验证失败时)", example = "邀请码已过期")
    private String errorMessage;

}
