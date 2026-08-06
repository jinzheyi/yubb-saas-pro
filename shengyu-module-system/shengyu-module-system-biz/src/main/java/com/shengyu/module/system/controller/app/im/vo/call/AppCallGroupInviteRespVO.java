package com.shengyu.module.system.controller.app.im.vo.call;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.util.List;

@Schema(description = "移动端 - 群组通话邀请 Response VO")
@Data
public class AppCallGroupInviteRespVO {

    @Schema(description = "通话会话ID", example = "abc123def456")
    private String callSessionId;

    @Schema(description = "邀请ID列表")
    private List<String> inviteIds;

    @Schema(description = "已邀请人数", example = "3")
    private Integer invitedCount;
}
