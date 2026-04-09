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
 * IM 会话增量同步接口限流服务
 *
 * 目标：
 * 1. 防止会话列表被暴力刷新
 * 2. 命中限流时返回可消费的 Retry-After（秒）
 */
@Service
@Slf4j
public class ImConversationSyncRateLimitService {

    @Resource
    private RedisTemplate<String, Object> redisTemplate;

    private static final String KEY_PREFIX = "system:im:conversation:sync:rate:";

    /**
     * 每个用户在窗口内最大请求数
     */
    private static final long MAX_REQUESTS = 20L;

    /**
     * 限流窗口
     */
    private static final Duration RATE_WINDOW = Duration.ofSeconds(10);

    public CheckResult check(Long tenantId, Long userId) {
        if (userId == null) {
            return CheckResult.allow();
        }
        Long tenant = tenantId != null ? tenantId : 0L;
        String key = KEY_PREFIX + tenant + ":" + userId;

        try {
            Long count = redisTemplate.opsForValue().increment(key, 1);
            if (count == null) {
                count = 0L;
            }
            if (count == 1L) {
                redisTemplate.expire(key, RATE_WINDOW);
            }
            if (count <= MAX_REQUESTS) {
                return CheckResult.allow();
            }
            Long ttl = redisTemplate.getExpire(key, TimeUnit.SECONDS);
            long retryAfterSeconds = (ttl != null && ttl > 0) ? ttl : 1L;
            return CheckResult.reject(retryAfterSeconds, count);
        } catch (Exception e) {
            // Redis 异常时放行，避免影响主流程可用性
            log.error("[ImConversationSyncRateLimit] 限流检查失败, tenantId: {}, userId: {}", tenant, userId, e);
            return CheckResult.allow();
        }
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

