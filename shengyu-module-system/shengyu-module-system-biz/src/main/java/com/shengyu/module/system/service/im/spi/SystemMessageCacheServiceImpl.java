package com.shengyu.module.system.service.im.spi;

import com.shengyu.framework.websocket.core.service.MessageCacheService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.time.Duration;

/**
 * System 模块 - 消息缓存服务实现
 * 
 * 实现 WebSocket 中间件的 MessageCacheService SPI 接口
 * 使用 Redis 缓存未读消息计数和用户信息，提升查询性能
 * 
 * 【缓存策略】
 * 1. 未读数缓存：30分钟过期，支持增量更新
 * 2. 用户信息缓存：1小时过期，LRU 淘汰策略
 * 3. 缓存 Key 前缀：system:im:cache:
 * 
 * 【性能优化】
 * 1. 使用 Redis 原子操作（INCR）实现未读数增量更新
 * 2. 缓存未命中时从数据库查询并回填缓存
 * 3. 支持批量操作（可扩展）
 *
 * @author 圣钰科技
 */
@Service
@Slf4j
public class SystemMessageCacheServiceImpl implements MessageCacheService {

    @Resource
    private RedisTemplate<String, Object> redisTemplate;

    /**
     * 缓存 Key 前缀
     */
    private static final String CACHE_KEY_PREFIX = "system:im:cache:";
    
    /**
     * 未读数缓存 Key 前缀
     */
    private static final String UNREAD_COUNT_KEY_PREFIX = CACHE_KEY_PREFIX + "unread:";
    
    /**
     * 用户信息缓存 Key 前缀
     */
    private static final String USER_INFO_KEY_PREFIX = CACHE_KEY_PREFIX + "user:";
    
    /**
     * 未读数缓存过期时间（30分钟）
     */
    private static final Duration UNREAD_COUNT_EXPIRE = Duration.ofMinutes(30);
    
    /**
     * 用户信息缓存过期时间（1小时）
     */
    private static final Duration USER_INFO_EXPIRE = Duration.ofHours(1);

    @Override
    public void cacheUnreadCount(Long userId, long count) {
        if (userId == null) {
            return;
        }
        
        try {
            String key = UNREAD_COUNT_KEY_PREFIX + userId;
            redisTemplate.opsForValue().set(key, count, UNREAD_COUNT_EXPIRE);
            log.debug("[MessageCache] 缓存未读数, userId: {}, count: {}", userId, count);
        } catch (Exception e) {
            log.error("[MessageCache] 缓存未读数失败, userId: {}", userId, e);
        }
    }

    @Override
    public Long getCachedUnreadCount(Long userId) {
        if (userId == null) {
            return null;
        }
        
        try {
            String key = UNREAD_COUNT_KEY_PREFIX + userId;
            Object value = redisTemplate.opsForValue().get(key);
            
            if (value == null) {
                log.debug("[MessageCache] 未读数缓存未命中, userId: {}", userId);
                return null;
            }
            
            Long count = Long.valueOf(value.toString());
            log.debug("[MessageCache] 获取缓存未读数, userId: {}, count: {}", userId, count);
            return count;
            
        } catch (Exception e) {
            log.error("[MessageCache] 获取缓存未读数失败, userId: {}", userId, e);
            return null;
        }
    }

    @Override
    public void removeCachedUnreadCount(Long userId) {
        if (userId == null) {
            return;
        }
        
        try {
            String key = UNREAD_COUNT_KEY_PREFIX + userId;
            redisTemplate.delete(key);
            log.debug("[MessageCache] 删除未读数缓存, userId: {}", userId);
        } catch (Exception e) {
            log.error("[MessageCache] 删除未读数缓存失败, userId: {}", userId, e);
        }
    }

    @Override
    public long incrementUnreadCount(Long userId, long delta) {
        if (userId == null) {
            return 0;
        }
        
        try {
            String key = UNREAD_COUNT_KEY_PREFIX + userId;
            
            // 使用 Redis 原子操作增加计数
            Long newCount = redisTemplate.opsForValue().increment(key, delta);
            
            if (newCount == null) {
                newCount = 0L;
            }
            
            // 设置过期时间（如果是新创建的 Key）
            if (newCount.equals(delta)) {
                redisTemplate.expire(key, UNREAD_COUNT_EXPIRE);
            }
            
            log.debug("[MessageCache] 增加未读数, userId: {}, delta: {}, newCount: {}", 
                    userId, delta, newCount);
            
            return newCount;
            
        } catch (Exception e) {
            log.error("[MessageCache] 增加未读数失败, userId: {}, delta: {}", userId, delta, e);
            return 0;
        }
    }

    /**
     * 缓存用户信息
     * 
     * @param userId 用户ID
     * @param userInfo 用户信息对象
     */
    public void cacheUserInfo(Long userId, Object userInfo) {
        if (userId == null || userInfo == null) {
            return;
        }
        
        try {
            String key = USER_INFO_KEY_PREFIX + userId;
            redisTemplate.opsForValue().set(key, userInfo, USER_INFO_EXPIRE);
            log.debug("[MessageCache] 缓存用户信息, userId: {}", userId);
        } catch (Exception e) {
            log.error("[MessageCache] 缓存用户信息失败, userId: {}", userId, e);
        }
    }

    /**
     * 获取缓存的用户信息
     * 
     * @param userId 用户ID
     * @return 用户信息对象，不存在返回 null
     */
    public Object getCachedUserInfo(Long userId) {
        if (userId == null) {
            return null;
        }
        
        try {
            String key = USER_INFO_KEY_PREFIX + userId;
            Object userInfo = redisTemplate.opsForValue().get(key);
            
            if (userInfo == null) {
                log.debug("[MessageCache] 用户信息缓存未命中, userId: {}", userId);
                return null;
            }
            
            log.debug("[MessageCache] 获取缓存用户信息, userId: {}", userId);
            return userInfo;
            
        } catch (Exception e) {
            log.error("[MessageCache] 获取缓存用户信息失败, userId: {}", userId, e);
            return null;
        }
    }

    /**
     * 删除缓存的用户信息
     * 
     * @param userId 用户ID
     */
    public void removeCachedUserInfo(Long userId) {
        if (userId == null) {
            return;
        }
        
        try {
            String key = USER_INFO_KEY_PREFIX + userId;
            redisTemplate.delete(key);
            log.debug("[MessageCache] 删除用户信息缓存, userId: {}", userId);
        } catch (Exception e) {
            log.error("[MessageCache] 删除用户信息缓存失败, userId: {}", userId, e);
        }
    }

}
