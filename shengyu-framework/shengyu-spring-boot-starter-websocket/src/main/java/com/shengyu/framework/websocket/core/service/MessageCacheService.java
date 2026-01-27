package com.shengyu.framework.websocket.core.service;

/**
 * 消息缓存服务接口（SPI）
 * 
 * 【架构设计】
 * 这是一个可选的 SPI 接口，由业务模块根据需要实现。
 * 
 * 中间件提供了默认的空实现（NoOpMessageCacheServiceImpl），不会影响核心功能。
 * 业务模块可以实现此接口来提供缓存能力，提升性能。
 * 
 * 【实现方式】
 * 在业务模块中创建实现类：
 * 
 * <pre>
 * &#64;Service
 * public class SystemMessageCacheServiceImpl implements MessageCacheService {
 *     
 *     &#64;Autowired
 *     private RedisTemplate&lt;String, Object&gt; redisTemplate;
 *     
 *     &#64;Override
 *     public void cacheUnreadCount(Long userId, long count) {
 *         String key = "system:im:unread:" + userId;
 *         redisTemplate.opsForValue().set(key, count, Duration.ofMinutes(30));
 *     }
 * }
 * </pre>
 * 
 * 【缓存策略】
 * 业务模块可以根据自己的需求设计缓存策略：
 * - 缓存 Key 前缀（区分不同业务模块）
 * - 缓存过期时间
 * - 缓存数据结构
 *
 * @author 圣钰科技
 */
public interface MessageCacheService {

    /**
     * 缓存未读消息计数
     *
     * @param userId 用户ID
     * @param count  未读消息数
     */
    void cacheUnreadCount(Long userId, long count);

    /**
     * 获取缓存的未读消息计数
     *
     * @param userId 用户ID
     * @return 未读消息数，不存在返回 null
     */
    Long getCachedUnreadCount(Long userId);

    /**
     * 删除缓存的未读消息计数
     *
     * @param userId 用户ID
     */
    void removeCachedUnreadCount(Long userId);

    /**
     * 增加未读消息计数
     *
     * @param userId 用户ID
     * @param delta  增量（可以为负数）
     * @return 增加后的计数
     */
    long incrementUnreadCount(Long userId, long delta);
}

