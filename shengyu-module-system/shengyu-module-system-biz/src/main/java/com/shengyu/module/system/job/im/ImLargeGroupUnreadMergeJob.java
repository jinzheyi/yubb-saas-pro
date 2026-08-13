package com.shengyu.module.system.job.im;

import com.shengyu.framework.quartz.core.handler.JobHandler;
import com.shengyu.framework.tenant.core.aop.TenantIgnore;
import com.shengyu.module.system.dal.dataobject.im.ImChatMessageDO;
import com.shengyu.module.system.dal.dataobject.im.ImChatUserDO;
import com.shengyu.module.system.dal.mysql.im.ImChatMessageMapper;
import com.shengyu.module.system.dal.mysql.im.ImChatUserMapper;
import com.shengyu.module.system.dal.mysql.im.ImConversationUserStateMapper;
import com.shengyu.module.system.dal.redis.im.LargeGroupUnreadRedisDAO;
import com.shengyu.module.system.service.im.ImBadgeService;
import com.shengyu.module.system.service.im.ImCursorVersionService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionTemplate;

import javax.annotation.Resource;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;

/**
 * 大群未读状态合并任务。
 *
 * <p>这是全局 Job：Redis dirty key 不携带线程租户上下文，数据库记录的 tenantId
 * 是后续 cursor 和会话状态写入的权威来源。</p>
 */
@Component
@Slf4j
public class ImLargeGroupUnreadMergeJob implements JobHandler {

    private static final int MAX_DIRTY_KEYS_PER_RUN = 200;

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
    @Resource
    private TransactionTemplate transactionTemplate;

    @Override
    @TenantIgnore
    public String execute(String param) {
        List<String> dirtyKeys = largeGroupUnreadRedisDAO.popDirtyKeys(MAX_DIRTY_KEYS_PER_RUN);
        if (dirtyKeys.isEmpty()) {
            return "没有待合并的大群未读数据";
        }

        int mergedCount = 0;
        for (String dirtyKey : dirtyKeys) {
            try {
                mergeSingleDirtyKey(dirtyKey);
                mergedCount++;
            } catch (IllegalArgumentException e) {
                // 格式非法的 key 无法被后续重试修复，记录后丢弃，避免无限占用任务批次。
                log.warn("[ImLargeGroupUnreadMergeJob] 丢弃格式非法的 dirty key，dirtyKey={}", dirtyKey, e);
            } catch (Exception e) {
                // Redis Set 的 pop 是破坏性读取；失败时必须恢复 dirty 标记，以便下次重试。
                largeGroupUnreadRedisDAO.markDirty(dirtyKey);
                log.error("[ImLargeGroupUnreadMergeJob] 合并大群未读数据失败，dirtyKey={}", dirtyKey, e);
            }
        }
        return String.format("大群未读数据合并完成：成功 %d / %d", mergedCount, dirtyKeys.size());
    }

    private void mergeSingleDirtyKey(String dirtyKey) {
        long[] parts = LargeGroupUnreadRedisDAO.parseDirtyKey(dirtyKey);
        long chatId = parts[0];
        long userId = parts[1];
        List<LargeGroupUnreadRedisDAO.LargeGroupUnreadEntry> unreadEntries =
                largeGroupUnreadRedisDAO.getUnreadList(chatId, userId);
        if (unreadEntries.isEmpty()) {
            return;
        }

        Integer unreadCount = transactionTemplate.execute(status -> mergeUnreadEntries(chatId, userId, unreadEntries));
        // 只删除本次已持久化快照中的字段。新消息即使在合并期间写入，也会保留并重新触发 dirty。
        largeGroupUnreadRedisDAO.removeUnreadEntries(chatId, userId, unreadEntries.stream()
                .map(LargeGroupUnreadRedisDAO.LargeGroupUnreadEntry::getMessageId)
                .collect(Collectors.toList()));

        if (unreadCount != null && unreadCount > 0) {
            try {
                imBadgeService.pushIncrementalBadgeUpdate(userId, chatId, unreadCount);
            } catch (Exception e) {
                // 推送为 best effort；数据已提交时不能因推送失败重复合并未读计数。
                log.error("[ImLargeGroupUnreadMergeJob] 推送未读角标失败，chatId={}, userId={}", chatId, userId, e);
            }
        }
    }

    /** 在独立事务中持久化一个 Redis 快照，返回本次合并后的会话未读数。 */
    private int mergeUnreadEntries(long chatId, long userId,
                                   List<LargeGroupUnreadRedisDAO.LargeGroupUnreadEntry> unreadEntries) {
        ImChatUserDO chatUser = chatUserMapper.selectByUserIdAndChatId(userId, chatId);
        if (chatUser == null) {
            return 0;
        }
        long persistedLastSequence = chatUser.getLastMessageSequence() != null
                ? chatUser.getLastMessageSequence() : 0L;
        List<LargeGroupUnreadRedisDAO.LargeGroupUnreadEntry> unmergedEntries = unreadEntries.stream()
                .filter(entry -> entry.getSequence() != null && entry.getSequence() > persistedLastSequence)
                .collect(Collectors.toList());
        // 数据库已提交、Redis 删除失败后的重试会到达这里；按 sequence 去重，避免重复累计未读数。
        if (unmergedEntries.isEmpty()) {
            return 0;
        }
        LargeGroupUnreadRedisDAO.LargeGroupUnreadEntry latestEntry = unmergedEntries.get(unmergedEntries.size() - 1);
        ImChatMessageDO latestMessage = chatMessageMapper.selectById(latestEntry.getMessageId());
        if (latestMessage == null || !Objects.equals(chatUser.getTenantId(), latestMessage.getTenantId())) {
            log.warn("[ImLargeGroupUnreadMergeJob] 忽略租户不一致或已删除的未读消息，chatId={}, userId={}, messageId={}",
                    chatId, userId, latestEntry.getMessageId());
            return 0;
        }

        Long tenantId = chatUser.getTenantId();
        int unreadCount = unmergedEntries.size();
        Long cursorVersion = cursorVersionService.allocateNextCursorVersion(tenantId, userId);
        chatUserMapper.updateLastMessageAndIncrementUnread(chatUser.getId(), latestEntry.getMessageId(),
                latestEntry.getSequence(), latestMessage.getMessageType(), latestEntry.getContent(),
                latestMessage.getSendTime(), unreadCount, Boolean.TRUE.equals(chatUser.getNoDisturb()),
                latestMessage.getSenderId());
        conversationUserStateMapper.upsertAfterMessage(tenantId, chatId, userId, cursorVersion, unreadCount,
                0L, null, latestEntry.getMessageId(), latestEntry.getSequence(), latestMessage.getSenderId(),
                latestMessage.getMessageType(), latestEntry.getContent(), hasAtMe(latestMessage, userId),
                latestMessage.getSendTime());
        return unreadCount;
    }

    private boolean hasAtMe(ImChatMessageDO message, long userId) {
        if (message.getMentions() == null) {
            return false;
        }
        try {
            cn.hutool.json.JSONArray mentions = cn.hutool.json.JSONUtil.parseArray(message.getMentions());
            for (int i = 0; i < mentions.size(); i++) {
                long mentionedUserId = mentions.getJSONObject(i).getLong("userId", 0L);
                if (mentionedUserId == userId || mentionedUserId == -1L) {
                    return true;
                }
            }
        } catch (Exception e) {
            log.warn("[ImLargeGroupUnreadMergeJob] 解析消息提及列表失败，messageId={}", message.getId(), e);
        }
        return false;
    }
}
