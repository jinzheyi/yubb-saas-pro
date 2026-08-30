package com.shengyu.module.system.controller.app.im.vo.call;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

/** LiveKit 入会凭据；每次接听或重连均按当前用户短期签发。 */
@Data
@Schema(description = "移动端 - 加入 LiveKit 通话 Response VO")
public class AppCallJoinRespVO {

    private String callSessionId;
    private String roomName;
    private String livekitUrl;
    private String accessToken;
    private Long expiresAt;
}
