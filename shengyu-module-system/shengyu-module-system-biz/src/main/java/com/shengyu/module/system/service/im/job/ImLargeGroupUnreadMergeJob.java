package com.shengyu.module.system.service.im.job;

import com.shengyu.framework.tenant.core.util.TenantUtils;
import com.shengyu.module.system.dal.dataobject.im.ImChatMessageDO;
import com.shengyu.module.system.dal.dataobject.im.ImChatUserDO;
import com.shengyu.module.system.dal.mysql.im.ImChatMessageMapper;
import com.shengyu.module.system.dal.mysql.im.ImChatUserMapper;
import com.shengyu.module.system.dal.mysql.im.ImConversationUserStateMapper;
import com.shengyu.module.system.dal.redis.im.LargeGroupUnreadRedisDAO;
import com.shengyu.module.system.service.im.ImBadgeService;
import com.shengyu.module.system.service.im.ImCursorVersionService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;
import java.util.List;

/**
 * 定时将大群未读状态从 Redis 合并到 MySQL。
 *
 * 设计目标：
 * 1. 每 5 秒执行一次，避免频繁写入 MySQL
 * 2. 每次处理最多 200 个 dirty keys
 * 3. 合并逻辑：将 Redis 中的未读消息统计合并到 im_chat_user 和 im_conversation_user_state
 */
@Component
@Slf4j
public class ImLargeGroupUnreadMergeJob {

    @Resource
    private LargeGroupUnreadRedisDAO largeGroupUnreadRedisDAO;

    @Resource
    private ImChatUserMapper chatUserMapper;

    @Resource
    private ImConversationUserStateMapper conversationUserStateMapper;

    @Resource
    private ImChatMessageMapper chatMessageMapper;

    @Resource
    private ImCursorVersionService cursorVersionService;

    @Resource
    private ImBadgeService imBadgeService;

    private static final int MAX_DIRTY_KEYS_PER_RUN = 200;

    @Scheduled(fixedDelay = 5000)
    public void mergeUnreadToMySQL() {
        try {
            List<String> dirtyKeys = largeGroupUnreadRedisDAO.popDirtyKeys(MAX_DIRTY_KEYS_PER_RUN);
            if (dirtyKeys.isEmpty()) {
                return;
            }

            log.info("[ImLargeGroupUnreadMergeJob] start merging {} dirty keys", dirtyKeys.size());

            TenantUtils.executeIgnore(() -> {
                for (String dirtyKey : dirtyKeys) {
                    try {
                        mergeSingleDirtyKey(dirtyKey);
                    } catch (Exception e) {
                        log.error("[ImLargeGroupUnreadMergeJob] failed to merge dirty key: {}", dirtyKey, e);
                    }
                }
            });

            log.info("[ImLargeGroupUnreadMergeJob] finished merging {} dirty keys", dirtyKeys.size());
        } catch (Exception e) {
            log.error("[ImLargeGroupUnreadMergeJob] job execution failed", e);
        }
    }

    /**
     * 合并单个 dirty key 的未读状态到 MySQL
     *
     * @param dirtyKey 格式为 "chatId:userId"
     */
    private void mergeSingleDirtyKey(String dirtyKey) {
        long[] parts = LargeGroupUnreadRedisDAO.parseDirtyKey(dirtyKey);
        long chatId = parts[0];
        long userId = parts[1];

        // 获取 Redis 中的未读消息列表
        List<LargeGroupUnreadRedisDAO.LargeGroupUnreadEntry> unreadEntries = largeGroupUnreadRedisDAO.getUnreadList(chatId, userId);
        if (unreadEntries.isEmpty()) {
            // 没有未读消息，直接清理
            largeGroupUnreadRedisDAO.clearUnread(chatId, userId);
            return;
        }

        // 查找用户对应的 chat_user 记录
        ImChatUserDO chatUser = chatUserMapper.selectByUserIdAndChatId(userId, chatId);
        if (chatUser == null) {
            // 用户已退群或删除会话，直接清理 Redis
            largeGroupUnreadRedisDAO.clearUnread(chatId, userId);
            return;
        }

        // 找出最新的消息序列号
        LargeGroupUnreadRedisDAO.LargeGroupUnreadEntry latestEntry = unreadEntries.get(unreadEntries.size() - 1);
        Long maxSequence = latestEntry.getSequence();
        Long maxMessageId = latestEntry.getMessageId();
        int unreadCount = unreadEntries.size();

        // 获取最新消息的详细信息
        ImChatMessageDO latestMessage = chatMessageMapper.selectById(maxMessageId);
        if (latestMessage == null) {
            // 消息已被删除，清理 Redis
            largeGroupUnreadRedisDAO.clearUnread(chatId, userId);
            return;
        }

        // 分配 cursor version
        Long tenantId = chatUser.getTenantId();
        Long cursorVersion = cursorVersionService.allocateNextCursorVersion(tenantId, userId);

        // 更新 im_chat_user 的未读数和最后消息信息
        chatUserMapper.updateLastMessageAndIncrementUnread(
                chatUser.getId(),
                maxMessageId,
                maxSequence,
                latestMessage.getMessageType(),
                latestEntry.getContent(),
                latestMessage.getSendTime(),
                unreadCount,
                Boolean.TRUE.equals(chatUser.getNoDisturb()),
                latestMessage.getSenderId()
        );

        // 更新 im_conversation_user_state
        boolean hasAtMe = false;
        if (latestMessage.getMentions() != null) {
            try {
                cn.hutool.json.JSONArray mentions = cn.hutool.json.JSONUtil.parseArray(latestMessage.getMentions());
                for (int i = 0; i < mentions.size(); i++) {
                    cn.hutool.json.JSONObject mention = mentions.getJSONObject(i);
                    long mentionedUserId = mention.getLong("userId", 0L);
                    if (mentionedUserId == userId || mentionedUserId == -1L) {
                        hasAtMe = true;
                        break;
                    }
                }
            } catch (Exception ignore) {
                // ignore parse error
            }
        }

        conversationUserStateMapper.upsertAfterMessage(
                tenantId,
                chatId,
                userId,
                cursorVersion,
                unreadCount,
                0L,
                null,
                maxMessageId,
                maxSequence,
                latestMessage.getSenderId(),
                latestMessage.getMessageType(),
                latestEntry.getContent(),
                hasAtMe,
                latestMessage.getSendTime()
        );

        // 推送角标更新
        imBadgeService.pushIncrementalBadgeUpdate(userId, chatId, unreadCount);

        // 合并成功后，清理 Redis 中的未读记录（保留 dirty 标记已被 pop）
        largeGroupUnreadRedisDAO.clearUnread(chatId, userId);
    }
}
