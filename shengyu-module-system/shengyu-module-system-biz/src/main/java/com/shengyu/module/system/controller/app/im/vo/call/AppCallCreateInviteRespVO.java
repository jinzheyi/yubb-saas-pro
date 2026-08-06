package com.shengyu.module.system.controller.app.im.vo.call;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.util.List;

@Schema(description = "移动端 - 创建通话邀请 Response VO")
@Data
public class AppCallCreateInviteRespVO {

    @Schema(description = "通话会话ID", example = "abc123def456")
    private String callSessionId;

    @Schema(description = "邀请ID", example = "invite789xyz")
    private String inviteId;

    @Schema(description = "会话ID", example = "30001")
    private String chatId;

    @Schema(description = "通话类型：audio-语音 video-视频", example = "video")
    private String callType;

    @Schema(description = "通话状态", example = "ringing")
    private String status;

    @Schema(description = "RTC 房间信息")
    private RtcRoomInfo rtcRoom;

    @Data
    public static class RtcRoomInfo {
        @Schema(description = "通话会话ID", example = "abc123def456")
        private String callSessionId;

        @Schema(description = "Janus 房间ID", example = "123456")
        private String roomId;

        @Schema(description = "发布者ID", example = "40001")
        private String publisherId;

        @Schema(description = "显示名称", example = "")
        private String displayName;

        @Schema(description = "Janus 服务器URL", example = "")
        private String janusUrl;

        @Schema(description = "TURN 服务器URL列表")
        private List<String> turnUrls;

        @Schema(description = "TURN 用户名", example = "")
        private String turnUsername;

        @Schema(description = "TURN 密码", example = "")
        private String turnCredential;

        @Schema(description = "Janus Token", example = "eyJhbGciOiJIUzI1NiIs...")
        private String token;
    }
}
