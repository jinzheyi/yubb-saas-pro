package com.shengyu.module.system.service.im.spi;

import com.shengyu.framework.websocket.core.service.MessageRateLimitService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.time.Duration;

/**
 * System 模块 - 消息频率限制服务实现
 * 
 * 实现 WebSocket 中间件的 MessageRateLimitService SPI 接口
 * 使用 Redis 实现消息发送频率限制
 * 
 * 【限制策略】
 * 1. 普通用户：每秒最多10条消息
 * 2. VIP用户：每秒最多20条消息（可扩展）
 * 3. 连续超限3次：临时禁止1分钟（可扩展）
 * 
 * 【实现原理】
 * 1. 使用 Redis 的 INCR 命令实现原子计数
 * 2. 设置1秒过期时间，自动重置计数
 * 3. 超过限制时返回 false，拒绝发送
 *
 * @author 圣钰科技
 */
@Service
@Slf4j
public class SystemMessageRateLimitServiceImpl implements MessageRateLimitService {

    @Resource
    private RedisTemplate<String, Object> redisTemplate;

    /**
     * 缓存 Key 前缀
     */
    private static final String RATE_LIMIT_KEY_PREFIX = "system:im:rate:limit:";
    
    /**
     * 普通用户每秒最大消息数
     */
    private static final long MAX_RATE_NORMAL = 10;
    
    /**
     * 限制时间窗口（秒）
     */
    private static final Duration RATE_WINDOW = Duration.ofSeconds(1);

    @Override
    public boolean checkRateLimit(Long userId) {
        if (userId == null) {
            return false;
        }

        try {
            String key = RATE_LIMIT_KEY_PREFIX + userId;
            
            // 使用 Redis 原子操作增加计数
            Long count = redisTemplate.opsForValue().increment(key, 1);
            
            if (count == null) {
                count = 0L;
            }
            
            // 如果是第一次计数，设置过期时间
            if (count == 1) {
                redisTemplate.expire(key, RATE_WINDOW);
            }
            
            // 检查是否超过限制
            boolean allowed = count <= MAX_RATE_NORMAL;
            
            if (!allowed) {
                log.warn("[MessageRateLimit] 用户发送频率超限, userId: {}, count: {}, limit: {}", 
                        userId, count, MAX_RATE_NORMAL);
            }
            
            return allowed;
            
        } catch (Exception e) {
            log.error("[MessageRateLimit] 检查频率限制失败, userId: {}", userId, e);
            // 异常时允许发送，避免影响正常功能
            return true;
        }
    }

    @Override
    public long getCurrentRate(Long userId) {
        if (userId == null) {
            return 0;
        }

        try {
            String key = RATE_LIMIT_KEY_PREFIX + userId;
            Object value = redisTemplate.opsForValue().get(key);
            
            if (value == null) {
                return 0;
            }
            
            return Long.parseLong(value.toString());
            
        } catch (Exception e) {
            log.error("[MessageRateLimit] 获取当前频率失败, userId: {}", userId, e);
            return 0;
        }
    }

    @Override
    public void resetRateLimit(Long userId) {
        if (userId == null) {
            return;
        }

        try {
            String key = RATE_LIMIT_KEY_PREFIX + userId;
            redisTemplate.delete(key);
            log.info("[MessageRateLimit] 重置频率限制, userId: {}", userId);
            
        } catch (Exception e) {
            log.error("[MessageRateLimit] 重置频率限制失败, userId: {}", userId, e);
        }
    }

}
