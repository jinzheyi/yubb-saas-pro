package com.shengyu.module.system.service.im;

import cn.hutool.core.util.StrUtil;
import cn.hutool.jwt.JWT;
import cn.hutool.jwt.signers.JWTSignerUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * LiveKit 房间 Token 签发服务。
 *
 * <p>一个 Token 只对应一个用户设备和一个业务通话房间。LiveKit 会在不存在房间时
 * 在第一位合法参与者加入时创建房间，因此业务层不需要预创建媒体房间。</p>
 */
@Service
@RequiredArgsConstructor
public class LiveKitTokenService {

    private final LiveKitProperties properties;

    public LiveKitConnectionInfo issueJoinToken(Long tenantId, Long userId, String deviceId,
                                                 String callId, String roomName) {
        if (tenantId == null || userId == null || StrUtil.isBlank(deviceId)
                || StrUtil.isBlank(callId) || StrUtil.isBlank(roomName)) {
            throw new IllegalArgumentException("签发 LiveKit Token 的参与者或房间参数无效");
        }
        long now = System.currentTimeMillis();
        long expiresAt = now + properties.getTokenExpireSeconds() * 1000L;
        Map<String, Object> videoGrant = new LinkedHashMap<>();
        videoGrant.put("roomJoin", true);
        videoGrant.put("room", roomName);
        videoGrant.put("canPublish", true);
        videoGrant.put("canSubscribe", true);
        String accessToken = JWT.create()
                .setIssuer(properties.getApiKey())
                .setSubject(tenantId + ":" + userId + ":" + deviceId)
                .setNotBefore(new Date(now - 1000L))
                .setIssuedAt(new Date(now))
                .setExpiresAt(new Date(expiresAt))
                .setPayload("metadata", "callId=" + callId)
                .setPayload("video", videoGrant)
                .sign(JWTSignerUtil.hs256(properties.getApiSecret().getBytes(StandardCharsets.UTF_8)));
        return LiveKitConnectionInfo.builder()
                .roomName(roomName)
                .serverUrl(properties.getUrl())
                .accessToken(accessToken)
                .expiresAt(expiresAt)
                .build();
    }

}
