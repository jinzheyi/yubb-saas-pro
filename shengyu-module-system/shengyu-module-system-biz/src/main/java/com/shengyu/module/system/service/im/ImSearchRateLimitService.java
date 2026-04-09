package com.shengyu.module.system.service.im;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.time.Duration;
import java.util.concurrent.TimeUnit;

/**
 * IM 搜索接口限流服务
 *
 * 目标：
 * 1. 防止搜索接口被暴力调用
 * 2. 在 429 时提供 Retry-After（秒）
 */
@Service
@Slf4j
public class ImSearchRateLimitService {

    public static final String SCENE_MESSAGE = "message";
    public static final String SCENE_CONTACT = "contact";
    public static final String SCENE_CONVERSATION = "conversation";
    public static final String SCENE_GLOBAL = "global";

    @Resource
    private RedisTemplate<String, Object> redisTemplate;

    private static final String KEY_PREFIX = "system:im:search:rate:";
    private static final Duration RATE_WINDOW = Duration.ofSeconds(10);

    private static final long DEFAULT_MAX_REQUESTS = 30L;
    private static final long MESSAGE_MAX_REQUESTS = 20L;
    private static final long CONTACT_MAX_REQUESTS = 30L;
    private static final long CONVERSATION_MAX_REQUESTS = 30L;
    private static final long GLOBAL_MAX_REQUESTS = 20L;

    public CheckResult check(Long tenantId, Long userId, String scene) {
        if (userId == null) {
            return CheckResult.allow();
        }
        Long tenant = tenantId != null ? tenantId : 0L;
        String normalizedScene = normalizeScene(scene);
        String key = KEY_PREFIX + normalizedScene + ":" + tenant + ":" + userId;
        long maxRequests = resolveMaxRequests(normalizedScene);

        try {
            Long count = redisTemplate.opsForValue().increment(key, 1);
            if (count == null) {
                count = 0L;
            }
            if (count == 1L) {
                redisTemplate.expire(key, RATE_WINDOW);
            }
            if (count <= maxRequests) {
                return CheckResult.allow();
            }
            Long ttl = redisTemplate.getExpire(key, TimeUnit.SECONDS);
            long retryAfterSeconds = (ttl != null && ttl > 0) ? ttl : 1L;
            return CheckResult.reject(retryAfterSeconds, count);
        } catch (Exception e) {
            // Redis 异常时放行，避免影响主流程可用性
            log.error("[ImSearchRateLimit] 限流检查失败, scene: {}, tenantId: {}, userId: {}", normalizedScene, tenant, userId, e);
            return CheckResult.allow();
        }
    }

    private String normalizeScene(String scene) {
        if (scene == null) {
            return "default";
        }
        String s = scene.trim().toLowerCase();
        return s.isEmpty() ? "default" : s;
    }

    private long resolveMaxRequests(String scene) {
        if (SCENE_MESSAGE.equals(scene)) {
            return MESSAGE_MAX_REQUESTS;
        }
        if (SCENE_CONTACT.equals(scene)) {
            return CONTACT_MAX_REQUESTS;
        }
        if (SCENE_CONVERSATION.equals(scene)) {
            return CONVERSATION_MAX_REQUESTS;
        }
        if (SCENE_GLOBAL.equals(scene)) {
            return GLOBAL_MAX_REQUESTS;
        }
        return DEFAULT_MAX_REQUESTS;
    }

    @Data
    @AllArgsConstructor
    public static class CheckResult {
        private boolean allowed;
        private long retryAfterSeconds;
        private long currentCount;

        public static CheckResult allow() {
            return new CheckResult(true, 0L, 0L);
        }

        public static CheckResult reject(long retryAfterSeconds, long currentCount) {
            return new CheckResult(false, retryAfterSeconds, currentCount);
        }
    }
}
