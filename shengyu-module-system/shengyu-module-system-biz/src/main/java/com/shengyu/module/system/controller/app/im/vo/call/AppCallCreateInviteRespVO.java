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

        @Schema(description = "LiveKit 房间名", example = "im_tenant_callId")
        private String roomName;

        @Schema(description = "发布者ID", example = "40001")
        private String publisherId;

        @Schema(description = "显示名称", example = "")
        private String displayName;

        @Schema(description = "LiveKit WebSocket 地址", example = "wss://rtc.example.com")
        private String livekitUrl;

        @Schema(description = "LiveKit 加入令牌", example = "eyJhbGciOiJIUzI1NiIs...")
        private String token;
    }
}
