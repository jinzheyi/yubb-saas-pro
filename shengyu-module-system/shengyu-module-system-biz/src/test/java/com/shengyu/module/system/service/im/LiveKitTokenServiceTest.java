package com.shengyu.module.system.service.im;

import cn.hutool.jwt.JWT;
import cn.hutool.jwt.signers.JWTSignerUtil;
import org.junit.jupiter.api.Test;

import java.nio.charset.StandardCharsets;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class LiveKitTokenServiceTest {

    private static final String API_KEY = "local-test-key";
    private static final String API_SECRET = "local-test-secret-with-at-least-32-characters";

    @Test
    void issuesDeviceAndRoomScopedTokenFromValidatedConfiguration() {
        LiveKitProperties properties = validProperties();
        properties.validateClientUrl();
        LiveKitTokenService service = new LiveKitTokenService(properties);

        LiveKitConnectionInfo connection = service.issueJoinToken(
                1L, 2L, "device-a", "call-a", "im_1_call-a");

        assertEquals("ws://MacBook-Pro-3.local:7880", connection.getServerUrl());
        assertEquals("im_1_call-a", connection.getRoomName());
        assertFalse(connection.getAccessToken().isEmpty());
        assertTrue(connection.getExpiresAt() > System.currentTimeMillis());

        JWT token = JWT.of(connection.getAccessToken());
        assertTrue(token.verify(JWTSignerUtil.hs256(API_SECRET.getBytes(StandardCharsets.UTF_8))));
        assertEquals(API_KEY, token.getPayload("iss"));
        assertEquals("1:2:device-a", token.getPayload("sub"));
        @SuppressWarnings("unchecked")
        Map<String, Object> video = (Map<String, Object>) token.getPayload("video");
        assertEquals(Boolean.TRUE, video.get("roomJoin"));
        assertEquals("im_1_call-a", video.get("room"));
    }

    @Test
    void rejectsIncompleteConfigurationAtStartup() {
        LiveKitProperties properties = new LiveKitProperties();

        assertThrows(IllegalStateException.class, properties::validateClientUrl);
    }

    @Test
    void rejectsInsecureUrlUnlessLocalOverrideIsExplicit() {
        LiveKitProperties properties = validProperties();
        properties.setAllowInsecure(false);

        assertThrows(IllegalStateException.class, properties::validateClientUrl);
    }

    private LiveKitProperties validProperties() {
        LiveKitProperties properties = new LiveKitProperties();
        properties.setUrl("ws://MacBook-Pro-3.local:7880");
        properties.setApiKey(API_KEY);
        properties.setApiSecret(API_SECRET);
        properties.setAllowInsecure(true);
        properties.setTokenExpireSeconds(600);
        return properties;
    }
}
