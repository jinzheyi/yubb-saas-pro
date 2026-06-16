package com.shengyu.module.system.service.im;

import com.shengyu.module.system.dal.dataobject.im.ImChatUserDO;
import com.shengyu.module.system.dal.mysql.im.ImChatUserMapper;
import com.shengyu.module.system.dal.redis.RedisKeyConstants;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;

/**
 * 会话快照 Redis 缓存 + 批量合并到 MySQL 服务。
 *
 * 设计目标：
 * 1. 小群写扩散场景下，先将会话状态写入 Redis Hash，避免每条消息都产生大量 DB 操作
 * 2. 定时任务（每 3 秒）批量将 dirty 快照合并到 MySQL
 * 3. 降低高并发场景下的 DB 压力（500 人群场景从 3000+ DB 操作大幅减少）
 */
@Service
@Slf4j
public class ConversationSnapshotService {

    @Resource
    private StringRedisTemplate stringRedisTemplate;

    @Resource
    private ImChatUserMapper chatUserMapper;

    private static final String SNAPSHOT_KEY_PREFIX = RedisKeyConstants.IM_SNAPSHOT + ":";
    private static final String DIRTY_KEY = RedisKeyConstants.IM_SNAPSHOT_DIRTY;
    private static final long SNAPSHOT_TTL_HOURS = 24;
    private static final int MAX_DIRTY_KEYS_PER_RUN = 200;

    /**
     * 写入会话快照到 Redis（异步调用方先写 Redis）
     *
     * @param userId            用户ID
     * @param chatId            会话ID
     * @param lastMessageId     最后一条消息ID
     * @param lastMessageSequence 最后一条消息序列号
     * @param lastMessageType   最后一条消息类型
     * @param lastMessageTime   最后一条消息发送时间
     * @param lastMessageContent 消息预览内容
     * @param unreadIncrement   未读数增量（发送者=0，接收者=1）
     * @param noDisturb         是否免打扰
     * @param lastMessageSenderId 最后一条消息发送者ID
     */
    public void writeSnapshot(Long userId, Long chatId,
                              Long lastMessageId, Long lastMessageSequence,
                              Integer lastMessageType, LocalDateTime lastMessageTime,
                              String lastMessageContent,
                              int unreadIncrement, boolean noDisturb,
                              Long lastMessageSenderId) {
        String key = SNAPSHOT_KEY_PREFIX + userId + ":" + chatId;
        try {
            Map<String, String> snapshot = new HashMap<>();
            snapshot.put("lastMessageId", String.valueOf(lastMessageId));
            snapshot.put("lastMessageSequence", String.valueOf(lastMessageSequence));
            snapshot.put("lastMessageType", String.valueOf(lastMessageType));
            snapshot.put("lastMessageTime", lastMessageTime != null ? lastMessageTime.toString() : "");
            snapshot.put("lastMessageContent", lastMessageContent != null ? lastMessageContent : "");
            snapshot.put("unreadIncrement", String.valueOf(unreadIncrement));
            snapshot.put("noDisturb", String.valueOf(noDisturb));
            snapshot.put("lastMessageSenderId", String.valueOf(lastMessageSenderId));

            stringRedisTemplate.opsForHash().putAll(key, snapshot);
            stringRedisTemplate.expire(key, SNAPSHOT_TTL_HOURS, TimeUnit.HOURS);

            // 标记 dirty
            stringRedisTemplate.opsForSet().add(DIRTY_KEY, userId + ":" + chatId);
        } catch (Exception e) {
            log.warn("[ConversationSnapshot] writeSnapshot failed, userId: {}, chatId: {}",
                    userId, chatId, e);
        }
    }

    /**
     * 定时合并 dirty 快照到 MySQL（每 3 秒执行）
     * 对标 ImLargeGroupUnreadMergeJob 的设计模式
     */
    @Scheduled(fixedDelay = 3000)
    public void mergeDirtySnapshots() {
        try {
            List<String> dirtyKeys = new ArrayList<>(stringRedisTemplate.opsForSet().pop(DIRTY_KEY, MAX_DIRTY_KEYS_PER_RUN));
            if (dirtyKeys.isEmpty()) {
                return;
            }

            int mergedCount = 0;
            for (String dirtyKey : dirtyKeys) {
                try {
                    if (mergeSingleSnapshot(dirtyKey)) {
                        mergedCount++;
                    }
                } catch (Exception e) {
                    log.warn("[ConversationSnapshot] merge failed for key {}: {}", dirtyKey, e.getMessage());
                }
            }

            if (mergedCount > 0) {
                log.info("[ConversationSnapshot] merged {} dirty snapshots to MySQL", mergedCount);
            }
        } catch (Exception e) {
            log.error("[ConversationSnapshot] mergeDirtySnapshots job execution failed", e);
        }
    }

    /**
     * 合并单个快照到 MySQL
     *
     * @param dirtyKey 格式为 "userId:chatId"
     * @return 是否合并成功
     */
    private boolean mergeSingleSnapshot(String dirtyKey) {
        String[] parts = dirtyKey.split(":", 2);
        Long userId = Long.parseLong(parts[0]);
        Long chatId = Long.parseLong(parts[1]);

        String redisKey = SNAPSHOT_KEY_PREFIX + dirtyKey;
        Map<Object, Object> snapshot = stringRedisTemplate.opsForHash().entries(redisKey);
        if (snapshot.isEmpty()) {
            return false;
        }

        // 解析快照数据
        Long lastMessageId = parseLong(snapshot.get("lastMessageId"));
        Long lastMessageSequence = parseLong(snapshot.get("lastMessageSequence"));
        Integer lastMessageType = parseInt(snapshot.get("lastMessageType"));
        String lastMessageTimeStr = (String) snapshot.get("lastMessageTime");
        LocalDateTime lastMessageTime = null;
        if (lastMessageTimeStr != null && !lastMessageTimeStr.isEmpty()) {
            try {
                lastMessageTime = LocalDateTime.parse(lastMessageTimeStr);
            } catch (DateTimeParseException e) {
                log.warn("[ConversationSnapshot] parse lastMessageTime failed: {}", lastMessageTimeStr);
            }
        }
        String lastMessageContent = (String) snapshot.get("lastMessageContent");
        int unreadIncrement = parseInt(snapshot.get("unreadIncrement"), 0);
        boolean noDisturb = Boolean.parseBoolean((String) snapshot.get("noDisturb"));
        Long lastMessageSenderId = parseLong(snapshot.get("lastMessageSenderId"));

        // 查找 chatUser 记录
        ImChatUserDO chatUser = chatUserMapper.selectAnyByUserIdAndChatId(userId, chatId);
        if (chatUser == null) {
            // 用户已退群或删除会话，清理 Redis
            stringRedisTemplate.delete(redisKey);
            return false;
        }

        // 合并到 im_chat_user
        chatUserMapper.updateLastMessageAndIncrementUnread(
                chatUser.getId(),
                lastMessageId,
                lastMessageSequence,
                lastMessageType,
                lastMessageContent,
                lastMessageTime,
                unreadIncrement,
                noDisturb,
                lastMessageSenderId
        );

        // 清理 Redis 快照
        stringRedisTemplate.delete(redisKey);
        return true;
    }

    private Long parseLong(Object value) {
        if (value == null) {
            return null;
        }
        try {
            return Long.parseLong(value.toString());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private Integer parseInt(Object value) {
        return parseInt(value, null);
    }

    private Integer parseInt(Object value, Integer defaultValue) {
        if (value == null) {
            return defaultValue;
        }
        try {
            return Integer.parseInt(value.toString());
        } catch (NumberFormatException e) {
            return defaultValue;
        }
    }
}
