package com.shengyu.framework.websocket.core.service;

/**
 * 消息频率限制服务接口（SPI）
 * 
 * 【架构设计】
 * 这是一个可选的 SPI 接口，由业务模块根据需要实现。
 * 
 * 中间件不提供默认实现，如果业务模块没有实现此接口，则不进行频率限制。
 * 业务模块可以实现此接口来提供消息频率限制能力。
 * 
 * 【实现方式】
 * 在业务模块中创建实现类：
 * 
 * <pre>
 * &#64;Service
 * public class SystemMessageRateLimitServiceImpl implements MessageRateLimitService {
 *     
 *     &#64;Autowired
 *     private RedisTemplate&lt;String, Object&gt; redisTemplate;
 *     
 *     &#64;Override
 *     public boolean checkRateLimit(Long userId) {
 *         String key = "im:rate:limit:" + userId;
 *         Long count = redisTemplate.opsForValue().increment(key, 1);
 *         if (count == 1) {
 *             redisTemplate.expire(key, Duration.ofSeconds(1));
 *         }
 *         return count &lt;= 10; // 每秒最多10条
 *     }
 * }
 * </pre>
 * 
 * 【限制策略】
 * 业务模块可以根据自己的需求设计限制策略：
 * - 普通用户：每秒10条
 * - VIP用户：每秒20条
 * - 临时禁止：连续超限3次禁止1分钟
 *
 * @author 圣钰科技
 */
public interface MessageRateLimitService {

    /**
     * 检查用户是否超过发送频率限制
     * 
     * @param userId 用户ID
     * @return true-允许发送，false-超过限制
     */
    boolean checkRateLimit(Long userId);

    /**
     * 获取用户当前发送频率
     * 
     * @param userId 用户ID
     * @return 当前秒内已发送的消息数
     */
    long getCurrentRate(Long userId);

    /**
     * 重置用户发送频率
     * 
     * @param userId 用户ID
     */
    void resetRateLimit(Long userId);

}
