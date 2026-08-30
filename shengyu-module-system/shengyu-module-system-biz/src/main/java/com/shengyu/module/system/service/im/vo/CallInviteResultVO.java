package com.shengyu.module.system.service.im.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * 通话邀请结果 VO
 *
 * @author 圣钰科技
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "通话邀请结果")
public class CallInviteResultVO {

    @Schema(description = "通话会话ID")
    private String callSessionId;

    @Schema(description = "邀请ID")
    private String inviteId;

    @Schema(description = "会话ID")
    private String chatId;

    @Schema(description = "通话类型：audio-语音 video-视频")
    private String callType;

    @Schema(description = "通话状态")
    private String status;

    @Schema(description = "RTC 房间信息")
    private RtcRoomInfo rtcRoom;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class RtcRoomInfo {
        
        @Schema(description = "通话会话ID")
        private String callSessionId;

        @Schema(description = "LiveKit 房间名")
        private String roomName;

        @Schema(description = "发布者ID")
        private String publisherId;

        @Schema(description = "显示名称")
        private String displayName;

        @Schema(description = "LiveKit WebSocket 地址")
        private String livekitUrl;

        @Schema(description = "LiveKit 加入令牌")
        private String token;
    }
}
