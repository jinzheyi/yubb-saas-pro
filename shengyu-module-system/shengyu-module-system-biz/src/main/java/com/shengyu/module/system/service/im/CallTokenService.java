package com.shengyu.module.system.service.im;

import cn.hutool.core.util.IdUtil;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.util.Base64;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;

/**
 * 通话 Token 服务
 * 
 * 负责生成和验证 Janus Token，用于客户端连接 Janus 网关时的身份验证
 * 
 * Token 格式：{header}.{payload}.{signature}
 * - header: 固定为 {"alg":"HS256","typ":"JWT"}
 * - payload: 包含 userId、tenantId、roomId、exp 等信息
 * - signature: HMAC-SHA256 签名
 *
 * @author 圣钰科技
 */
@Service
@Slf4j
public class CallTokenService {

    @Value("${janus.token.secret:shengyu-janus-secret-key}")
    private String janusSecret;

    @Value("${janus.token.expire-seconds:86400}")
    private long tokenExpireSeconds;

    @Resource
    private JanusRoomManager janusRoomManager;

    /**
     * Token 缓存（用于快速验证）
     * key: token, value: TokenInfo
     */
    private final ConcurrentMap<String, TokenInfo> tokenCache = new ConcurrentHashMap<>();

    /**
     * Token 信息
     */
    public static class TokenInfo {
        private final String token;
        private final Long userId;
        private final Long tenantId;
        private final String roomId;
        private final long expireTime;

        public TokenInfo(String token, Long userId, Long tenantId, String roomId, long expireTime) {
            this.token = token;
            this.userId = userId;
            this.tenantId = tenantId;
            this.roomId = roomId;
            this.expireTime = expireTime;
        }

        public String getToken() {
            return token;
        }

        public Long getUserId() {
            return userId;
        }

        public Long getTenantId() {
            return tenantId;
        }

        public String getRoomId() {
            return roomId;
        }

        public long getExpireTime() {
            return expireTime;
        }

        public boolean isExpired() {
            return System.currentTimeMillis() > expireTime;
        }
    }

    /**
     * 生成 Janus Token
     * 
     * @param userId 用户ID
     * @param tenantId 租户ID
     * @param roomId 房间ID（可选，如果指定则限制只能访问该房间）
     * @return Token 字符串
     */
    public String generateToken(Long userId, Long tenantId, String roomId) {
        // 生成 Token ID
        String tokenId = IdUtil.simpleUUID();
        
        // 计算过期时间
        long expireTime = System.currentTimeMillis() + tokenExpireSeconds * 1000;
        
        // 构建 Header
        String header = Base64.getEncoder().encodeToString(
            "{\"alg\":\"HS256\",\"typ\":\"JWT\"}".getBytes(StandardCharsets.UTF_8)
        );
        
        // 构建 Payload
        String payloadJson = String.format(
            "{\"userId\":%d,\"tenantId\":%d,\"roomId\":\"%s\",\"exp\":%d,\"jti\":\"%s\"}",
            userId, tenantId, roomId != null ? roomId : "", expireTime, tokenId
        );
        String payload = Base64.getEncoder().encodeToString(
            payloadJson.getBytes(StandardCharsets.UTF_8)
        );
        
        // 生成签名
        String signature = generateSignature(header + "." + payload);
        
        // 组合 Token
        String token = header + "." + payload + "." + signature;
        
        // 缓存 Token 信息
        TokenInfo tokenInfo = new TokenInfo(token, userId, tenantId, roomId, expireTime);
        tokenCache.put(token, tokenInfo);
        
        log.info("[generateToken] 生成 Token 成功, userId={}, tenantId={}, roomId={}, expireTime={}", 
            userId, tenantId, roomId, expireTime);
        
        return token;
    }

    /**
     * 验证 Token
     * 
     * @param token Token 字符串
     * @return Token 信息，验证失败返回 null
     */
    public TokenInfo validateToken(String token) {
        // 先从缓存查找
        TokenInfo cachedInfo = tokenCache.get(token);
        if (cachedInfo != null) {
            // 检查是否过期
            if (cachedInfo.isExpired()) {
                log.warn("[validateToken] Token 已过期, token={}", token);
                tokenCache.remove(token);
                return null;
            }
            return cachedInfo;
        }
        
        // 缓存中没有，解析 Token
        try {
            String[] parts = token.split("\\.");
            if (parts.length != 3) {
                log.warn("[validateToken] Token 格式错误, token={}", token);
                return null;
            }
            
            String header = parts[0];
            String payload = parts[1];
            String signature = parts[2];
            
            // 验证签名
            String expectedSignature = generateSignature(header + "." + payload);
            if (!expectedSignature.equals(signature)) {
                log.warn("[validateToken] Token 签名验证失败, token={}", token);
                return null;
            }
            
            // 解析 Payload
            String payloadJson = new String(Base64.getDecoder().decode(payload), StandardCharsets.UTF_8);
            // 简单解析 JSON（生产环境建议使用 JSON 库）
            Long userId = extractLongValue(payloadJson, "userId");
            Long tenantId = extractLongValue(payloadJson, "tenantId");
            String roomId = extractStringValue(payloadJson, "roomId");
            long expireTime = extractLongValue(payloadJson, "exp");
            
            // 检查是否过期
            if (System.currentTimeMillis() > expireTime) {
                log.warn("[validateToken] Token 已过期, token={}", token);
                return null;
            }
            
            // 缓存 Token 信息
            TokenInfo tokenInfo = new TokenInfo(token, userId, tenantId, roomId, expireTime);
            tokenCache.put(token, tokenInfo);
            
            log.info("[validateToken] Token 验证成功, userId={}, tenantId={}, roomId={}", 
                userId, tenantId, roomId);
            
            return tokenInfo;
        } catch (Exception e) {
            log.error("[validateToken] Token 解析异常, token={}", token, e);
            return null;
        }
    }

    /**
     * 撤销 Token
     * 
     * @param token Token 字符串
     */
    public void revokeToken(String token) {
        TokenInfo removed = tokenCache.remove(token);
        if (removed != null) {
            log.info("[revokeToken] 撤销 Token 成功, userId={}, tenantId={}", 
                removed.getUserId(), removed.getTenantId());
        }
    }

    /**
     * 清理过期 Token
     * 
     * @return 清理的 Token 数量
     */
    public int cleanupExpiredTokens() {
        int cleanedCount = 0;
        for (java.util.Iterator<java.util.Map.Entry<String, TokenInfo>> it = tokenCache.entrySet().iterator(); it.hasNext(); ) {
            java.util.Map.Entry<String, TokenInfo> entry = it.next();
            if (entry.getValue().isExpired()) {
                it.remove();
                cleanedCount++;
            }
        }
        
        if (cleanedCount > 0) {
            log.info("[cleanupExpiredTokens] 清理过期 Token, count={}", cleanedCount);
        }
        
        return cleanedCount;
    }

    /**
     * 生成 HMAC-SHA256 签名
     */
    private String generateSignature(String data) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            SecretKeySpec secretKeySpec = new SecretKeySpec(
                janusSecret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"
            );
            mac.init(secretKeySpec);
            byte[] signatureBytes = mac.doFinal(data.getBytes(StandardCharsets.UTF_8));
            return Base64.getUrlEncoder().withoutPadding().encodeToString(signatureBytes);
        } catch (NoSuchAlgorithmException | InvalidKeyException e) {
            log.error("[generateSignature] 生成签名异常", e);
            throw new RuntimeException("生成签名失败", e);
        }
    }

    /**
     * 从 JSON 字符串中提取 Long 值
     */
    private Long extractLongValue(String json, String key) {
        String pattern = "\"" + key + "\":";
        int start = json.indexOf(pattern);
        if (start == -1) {
            return null;
        }
        start += pattern.length();
        int end = json.indexOf(",", start);
        if (end == -1) {
            end = json.indexOf("}", start);
        }
        if (end == -1) {
            return null;
        }
        String value = json.substring(start, end).trim();
        return Long.parseLong(value);
    }

    /**
     * 从 JSON 字符串中提取 String 值
     */
    private String extractStringValue(String json, String key) {
        String pattern = "\"" + key + "\":\"";
        int start = json.indexOf(pattern);
        if (start == -1) {
            return null;
        }
        start += pattern.length();
        int end = json.indexOf("\"", start);
        if (end == -1) {
            return null;
        }
        return json.substring(start, end);
    }
}
