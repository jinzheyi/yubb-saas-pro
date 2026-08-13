package com.shengyu.module.system.dal.redis.im;

import cn.hutool.json.JSONUtil;
import com.shengyu.module.system.dal.redis.RedisKeyConstants;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Repository;

import javax.annotation.Resource;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;

/**
 * 大群未读状态 Redis DAO
 *
 * 设计目标：
 * 1. 大群（>= 100 人）消息采用读扩散模型
 * 2. 未读状态先写入 Redis，由定时任务异步合并到 MySQL
 * 3. 使用 Redis Hash 存储未读状态，Set 标记 dirty keys
 */
@Repository
@Slf4j
public class LargeGroupUnreadRedisDAO {

    @Resource
    private StringRedisTemplate stringRedisTemplate;

    private static final long UNREAD_TTL_HOURS = 72;

    /**
     * 获取大群未读状态的 Redis Hash key
     */
    private static String formatUnreadKey(Long chatId, Long userId) {
        return String.format(RedisKeyConstants.LARGE_GROUP_UNREAD, chatId, userId);
    }

    /**
     * 记录大群未读消息到 Redis
     *
     * @param chatId    会话ID
     * @param userId    用户ID
     * @param messageId 消息ID
     * @param sequence  消息序列号
     * @param content   消息预览内容
     * @param senderId  发送者ID
     */
    public void recordUnread(Long chatId, Long userId, Long messageId, Long sequence, String content, Long senderId) {
        String key = formatUnreadKey(chatId, userId);
        try {
            String field = String.valueOf(messageId);
            String value = JSONUtil.createObj()
                    .set("sequence", sequence)
                    .set("content", content != null ? content : "")
                    .set("senderId", senderId)
                    .toString();
            stringRedisTemplate.opsForHash().put(key, field, value);
            stringRedisTemplate.expire(key, UNREAD_TTL_HOURS, TimeUnit.HOURS);

            // 标记为 dirty
            stringRedisTemplate.opsForSet().add(RedisKeyConstants.LARGE_GROUP_UNREAD_DIRTY, chatId + ":" + userId);
        } catch (Exception e) {
            log.error("[LargeGroupUnreadRedis] recordUnread failed, chatId: {}, userId: {}, messageId: {}",
                    chatId, userId, messageId, e);
        }
    }

    /**
     * 获取用户在大群中的未读消息列表
     *
     * @param chatId 会话ID
     * @param userId 用户ID
     * @return 未读消息列表（按 messageId 排序）
     */
    public List<LargeGroupUnreadEntry> getUnreadList(Long chatId, Long userId) {
        String key = formatUnreadKey(chatId, userId);
        try {
            Map<Object, Object> entries = stringRedisTemplate.opsForHash().entries(key);
            List<LargeGroupUnreadEntry> result = new ArrayList<>();
            for (Map.Entry<Object, Object> entry : entries.entrySet()) {
                String messageId = (String) entry.getKey();
                String value = (String) entry.getValue();
                try {
                    cn.hutool.json.JSONObject obj = JSONUtil.parseObj(value);
                    LargeGroupUnreadEntry e = new LargeGroupUnreadEntry();
                    e.setMessageId(Long.parseLong(messageId));
                    e.setSequence(obj.getLong("sequence", 0L));
                    e.setContent(obj.getStr("content", ""));
                    e.setSenderId(obj.getLong("senderId", 0L));
                    result.add(e);
                } catch (Exception parseEx) {
                    log.warn("[LargeGroupUnreadRedis] parse entry failed, key: {}, field: {}", key, messageId, parseEx);
                }
            }
            result.sort((a, b) -> Long.compare(a.getSequence(), b.getSequence()));
            return result;
        } catch (Exception e) {
            log.error("[LargeGroupUnreadRedis] getUnreadList failed, chatId: {}, userId: {}", chatId, userId, e);
            return new ArrayList<>();
        }
    }

    /**
     * 获取用户在大群中的未读数量
     *
     * @param chatId 会话ID
     * @param userId 用户ID
     * @return 未读消息数量
     */
    public long getUnreadCount(Long chatId, Long userId) {
        String key = formatUnreadKey(chatId, userId);
        try {
            return stringRedisTemplate.opsForHash().size(key);
        } catch (Exception e) {
            log.error("[LargeGroupUnreadRedis] getUnreadCount failed, chatId: {}, userId: {}", chatId, userId, e);
            return 0;
        }
    }

    /**
     * 删除已读消息
     *
     * @param chatId    会话ID
     * @param userId    用户ID
     * @param messageId 消息ID
     */
    public void removeUnread(Long chatId, Long userId, Long messageId) {
        String key = formatUnreadKey(chatId, userId);
        try {
            stringRedisTemplate.opsForHash().delete(key, String.valueOf(messageId));
        } catch (Exception e) {
            log.error("[LargeGroupUnreadRedis] removeUnread failed, chatId: {}, userId: {}, messageId: {}",
                    chatId, userId, messageId, e);
        }
    }

    /**
     * 清空用户在大群中的所有未读
     *
     * @param chatId 会话ID
     * @param userId 用户ID
     */
    public void clearUnread(Long chatId, Long userId) {
        String key = formatUnreadKey(chatId, userId);
        try {
            stringRedisTemplate.delete(key);
            stringRedisTemplate.opsForSet().remove(RedisKeyConstants.LARGE_GROUP_UNREAD_DIRTY, chatId + ":" + userId);
        } catch (Exception e) {
            log.error("[LargeGroupUnreadRedis] clearUnread failed, chatId: {}, userId: {}", chatId, userId, e);
        }
    }

    /**
     * 删除已成功合并的 Redis 快照字段。
     *
     * <p>不能删除整个 Hash：合并期间可能有新消息写入。dirty Set 已经由 pop 移除，
     * 因此此处也不能移除 dirty 标记，以免误删并发写入重新添加的标记。</p>
     */
    public void removeUnreadEntries(Long chatId, Long userId, List<Long> messageIds) {
        if (messageIds == null || messageIds.isEmpty()) {
            return;
        }
        String key = formatUnreadKey(chatId, userId);
        try {
            stringRedisTemplate.opsForHash().delete(key, messageIds.stream()
                    .map(String::valueOf).toArray(String[]::new));
        } catch (Exception e) {
            log.error("[LargeGroupUnreadRedis] removeUnreadEntries failed, chatId: {}, userId: {}", chatId, userId, e);
            throw new IllegalStateException("删除已合并的大群未读数据失败", e);
        }
    }

    /** 重新标记未成功合并的 dirty key。 */
    public void markDirty(String dirtyKey) {
        if (dirtyKey != null && !dirtyKey.isEmpty()) {
            stringRedisTemplate.opsForSet().add(RedisKeyConstants.LARGE_GROUP_UNREAD_DIRTY, dirtyKey);
        }
    }

    /**
     * 获取所有 dirty keys（用于定时任务批量合并）
     *
     * @param maxCount 最大获取数量
     * @return dirty key 列表，格式为 "chatId:userId"
     */
    public List<String> popDirtyKeys(int maxCount) {
        try {
            List<String> members = new ArrayList<>(stringRedisTemplate.opsForSet().pop(RedisKeyConstants.LARGE_GROUP_UNREAD_DIRTY, maxCount));
            if (members.isEmpty()) {
                return new ArrayList<>();
            }
            return new ArrayList<>(members);
        } catch (Exception e) {
            log.error("[LargeGroupUnreadRedis] popDirtyKeys failed", e);
            return new ArrayList<>();
        }
    }

    /**
     * 解析 dirty key
     *
     * @param dirtyKey 格式为 "chatId:userId"
     * @return [chatId, userId]
     */
    public static long[] parseDirtyKey(String dirtyKey) {
        if (dirtyKey == null) {
            throw new IllegalArgumentException("dirty key 不能为空");
        }
        String[] parts = dirtyKey.split(":", 2);
        if (parts.length != 2 || parts[0].isEmpty() || parts[1].isEmpty()) {
            throw new IllegalArgumentException("dirty key 格式必须为 chatId:userId：" + dirtyKey);
        }
        long chatId = Long.parseLong(parts[0]);
        long userId = Long.parseLong(parts[1]);
        if (chatId <= 0 || userId <= 0) {
            throw new IllegalArgumentException("dirty key 中的编号必须为正数：" + dirtyKey);
        }
        return new long[]{chatId, userId};
    }

    /**
     * 大群未读消息条目
     */
    public static class LargeGroupUnreadEntry {
        private Long messageId;
        private Long sequence;
        private String content;
        private Long senderId;

        public Long getMessageId() {
            return messageId;
        }

        public void setMessageId(Long messageId) {
            this.messageId = messageId;
        }

        public Long getSequence() {
            return sequence;
        }

        public void setSequence(Long sequence) {
            this.sequence = sequence;
        }

        public String getContent() {
            return content;
        }

        public void setContent(String content) {
            this.content = content;
        }

        public Long getSenderId() {
            return senderId;
        }

        public void setSenderId(Long senderId) {
            this.senderId = senderId;
        }
    }
}
