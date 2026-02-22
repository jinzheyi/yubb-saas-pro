package com.shengyu.module.system.controller.app.im.vo.group;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.time.LocalDateTime;

@Schema(description = "移动端 - IM 群邀请码 Response VO")
@Data
public class AppImGroupInviteRespVO {

    @Schema(description = "邀请码", example = "GRP1A2B3C4D5E6F7G8H")
    private String inviteCode;

    @Schema(description = "二维码URL", example = "https://app.shengyu.com/group/join?code=GRP1A2B3C4D5E6F7G8H&groupId=123456")
    private String qrCodeUrl;

    @Schema(description = "过期时间")
    private LocalDateTime expireTime;

    @Schema(description = "已使用次数", example = "10")
    private Integer usedCount;

    @Schema(description = "最大使用次数(0表示不限制)", example = "0")
    private Integer maxUseCount;

}
