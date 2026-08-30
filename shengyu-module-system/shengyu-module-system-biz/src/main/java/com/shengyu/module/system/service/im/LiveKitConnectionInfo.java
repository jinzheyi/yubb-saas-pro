package com.shengyu.module.system.service.im;

import lombok.Builder;
import lombok.Value;

/** 服务端签发给单个已授权参与者的 LiveKit 连接信息。 */
@Value
@Builder
public class LiveKitConnectionInfo {
    String roomName;
    String serverUrl;
    String accessToken;
    long expiresAt;
}
