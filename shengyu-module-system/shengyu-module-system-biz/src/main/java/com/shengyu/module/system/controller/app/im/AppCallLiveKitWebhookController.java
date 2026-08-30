package com.shengyu.module.system.controller.app.im;

import cn.hutool.jwt.JWT;
import cn.hutool.jwt.JWTValidator;
import cn.hutool.jwt.signers.JWTSigner;
import cn.hutool.jwt.signers.JWTSignerUtil;
import com.shengyu.framework.common.util.json.JsonUtils;
import com.shengyu.framework.tenant.core.aop.TenantIgnore;
import com.shengyu.module.system.service.im.LiveKitProperties;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.annotation.security.PermitAll;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Base64;
import java.util.Date;
import java.util.Map;

/** LiveKit 签名 Webhook：仅用于媒体事实审计和离线补偿观测，不反向覆盖业务终态。 */
@RestController
@RequestMapping("/system/im/call/livekit")
@RequiredArgsConstructor
@Slf4j
public class AppCallLiveKitWebhookController {

    private final LiveKitProperties properties;

    @PostMapping("/webhook")
    @PermitAll
    @TenantIgnore
    public ResponseEntity<Void> receive(@RequestBody String body,
                                        @RequestHeader("Authorization") String authorization) {
        verifySignature(body, authorization);
        Map<String, Object> event = JsonUtils.parseObject(body, Map.class);
        Map<String, Object> roomPayload = nestedMap(event.get("room"));
        Map<String, Object> participantPayload = nestedMap(event.get("participant"));
        log.info("[LiveKitWebhook] event={}, eventId={}, room={}, participant={}, createdAt={}",
                event.get("event"), event.get("id"), roomPayload.get("name"),
                participantPayload.get("identity"), event.get("createdAt"));
        return ResponseEntity.ok().build();
    }

    private void verifySignature(String body, String authorization) {
        if (authorization == null || authorization.trim().isEmpty()) {
            throw new IllegalArgumentException("LiveKit Webhook Authorization 为空");
        }
        String token = authorization.startsWith("Bearer ")
                ? authorization.substring("Bearer ".length()).trim() : authorization.trim();
        JWTSigner signer = JWTSignerUtil.hs256(properties.getApiSecret().getBytes(StandardCharsets.UTF_8));
        JWT jwt = JWT.of(token).setSigner(signer);
        JWTValidator.of(jwt).validateAlgorithm(signer).validateDate(new Date(), 30L);
        if (!properties.getApiKey().equals(String.valueOf(jwt.getPayload("iss")))) {
            throw new IllegalArgumentException("LiveKit Webhook issuer 无效");
        }
        String actual = Base64.getEncoder().encodeToString(sha256(body));
        String expected = String.valueOf(jwt.getPayload("sha256"));
        if (!MessageDigest.isEqual(actual.getBytes(StandardCharsets.UTF_8),
                expected.getBytes(StandardCharsets.UTF_8))) {
            throw new IllegalArgumentException("LiveKit Webhook body 校验失败");
        }
    }

    private byte[] sha256(String body) {
        try {
            return MessageDigest.getInstance("SHA-256").digest(body.getBytes(StandardCharsets.UTF_8));
        } catch (Exception exception) {
            throw new IllegalStateException("SHA-256 不可用", exception);
        }
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> nestedMap(Object value) {
        return value instanceof Map ? (Map<String, Object>) value : java.util.Collections.emptyMap();
    }
}
