package com.shengyu.module.system.dal.redis.im;

import com.shengyu.framework.common.util.json.JsonUtils;
import com.shengyu.module.system.dal.redis.RedisKeyConstants;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Repository;

import javax.annotation.Resource;
import java.util.List;
import java.util.concurrent.TimeUnit;

/**
 * 聊天消息 RedisDAO
 *
 * @author zhusy
 * @since 2025/12/19
 */
@Repository
public class ImMessageRedisDAO {

    @Resource
    private StringRedisTemplate stringRedisTemplate;

    /**
     * 设置用户在线状态
     *
     * @param userId 用户ID
     * @param status 在线状态
     */
    public void setOnlineStatus(Long userId, String status) {
        String redisKey = String.format(RedisKeyConstants.ONLINE_STATUS, userId);
        stringRedisTemplate.opsForValue().set(redisKey, status, 24, TimeUnit.HOURS);
    }

    /**
     * 获取用户在线状态
     *
     * @param userId 用户ID
     * @return 在线状态
     */
    public String getOnlineStatus(Long userId) {
        String redisKey = String.format(RedisKeyConstants.ONLINE_STATUS, userId);
        return stringRedisTemplate.opsForValue().get(redisKey);
    }

    /**
     * 删除用户在线状态
     *
     * @param userId 用户ID
     */
    public void deleteOnlineStatus(Long userId) {
        String redisKey = String.format(RedisKeyConstants.ONLINE_STATUS, userId);
        stringRedisTemplate.delete(redisKey);
    }

    /**
     * 添加离线消息
     *
     * @param userId 用户ID
     * @param message 消息内容
     */
    public void addOfflineMessage(Long userId, Object message) {
        String redisKey = String.format(RedisKeyConstants.OFFLINE_MESSAGE, userId);
        stringRedisTemplate.opsForList().rightPush(redisKey, JsonUtils.toJsonString(message));
    }

    /**
     * 获取离线消息列表
     *
     * @param userId 用户ID
     * @return 离线消息列表
     */
    public List<String> getOfflineMessages(Long userId) {
        String redisKey = String.format(RedisKeyConstants.OFFLINE_MESSAGE, userId);
        return stringRedisTemplate.opsForList().range(redisKey, 0, -1);
    }

    /**
     * 删除离线消息
     *
     * @param userId 用户ID
     */
    public void deleteOfflineMessages(Long userId) {
        String redisKey = String.format(RedisKeyConstants.OFFLINE_MESSAGE, userId);
        stringRedisTemplate.delete(redisKey);
    }

    /**
     * 添加聊天记录
     *
     * @param userId 用户ID
     * @param chatType 聊天类型
     * @param targetId 目标ID
     * @param message 消息内容
     */
    public void addChatLog(Long userId, String chatType, Long targetId, Object message) {
        String redisKey = String.format(RedisKeyConstants.CHAT_LOG, userId, chatType, targetId);
        stringRedisTemplate.opsForList().rightPush(redisKey, JsonUtils.toJsonString(message));
        // 设置聊天记录过期时间为7天
        stringRedisTemplate.expire(redisKey, 7, TimeUnit.DAYS);
    }

    /**
     * 获取聊天记录
     *
     * @param userId 用户ID
     * @param chatType 聊天类型
     * @param targetId 目标ID
     * @param start 起始位置
     * @param end 结束位置
     * @return 聊天记录列表
     */
    public List<String> getChatLog(Long userId, String chatType, Long targetId, long start, long end) {
        String redisKey = String.format(RedisKeyConstants.CHAT_LOG, userId, chatType, targetId);
        return stringRedisTemplate.opsForList().range(redisKey, start, end);
    }

    /**
     * 删除聊天记录
     *
     * @param userId 用户ID
     * @param chatType 聊天类型
     * @param targetId 目标ID
     */
    public void deleteChatLog(Long userId, String chatType, Long targetId) {
        String redisKey = String.format(RedisKeyConstants.CHAT_LOG, userId, chatType, targetId);
        stringRedisTemplate.delete(redisKey);
    }
}
