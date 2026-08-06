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

        @Schema(description = "Janus 房间ID")
        private String roomId;

        @Schema(description = "发布者ID")
        private String publisherId;

        @Schema(description = "显示名称")
        private String displayName;

        @Schema(description = "Janus 服务器URL")
        private String janusUrl;

        @Schema(description = "TURN 服务器URL列表")
        private List<String> turnUrls;

        @Schema(description = "TURN 用户名")
        private String turnUsername;

        @Schema(description = "TURN 密码")
        private String turnCredential;

        @Schema(description = "Janus Token")
        private String token;
    }
}
