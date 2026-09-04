package com.shengyu.module.system.dal.mysql.im;

import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.module.system.dal.dataobject.im.ImChatUserDO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;

import java.time.LocalDateTime;
import java.util.List;

@Mapper
public interface ImChatUserMapper extends BaseMapperX<ImChatUserDO> {

    /**
     * Creates a chat-user row without surfacing a concurrent creator as an
     * application failure. The unique key is the synchronization primitive.
     */
    @Insert("INSERT IGNORE INTO im_chat_user " +
            "(id, chat_id, user_id, unread_count, is_pinned, no_disturb, deleted_by_user, " +
            "create_time, update_time, creator, updater, tenant_id, deleted) " +
            "VALUES (#{id}, #{chatId}, #{userId}, #{unreadCount}, #{isPinned}, #{noDisturb}, " +
            "#{deletedByUser}, #{createTime}, #{updateTime}, #{creator}, #{updater}, #{tenantId}, #{deleted})")
    int insertIgnore(ImChatUserDO chatUser);

    default ImChatUserDO selectByUserIdAndChatId(Long userId, Long chatId) {
        return selectOne(new LambdaQueryWrapperX<ImChatUserDO>()
                .eq(ImChatUserDO::getUserId, userId)
                .eq(ImChatUserDO::getChatId, chatId)
                .eq(ImChatUserDO::getDeletedByUser, false));
    }

    default ImChatUserDO selectAnyByUserIdAndChatId(Long userId, Long chatId) {
        return selectOne(new LambdaQueryWrapperX<ImChatUserDO>()
                .eq(ImChatUserDO::getUserId, userId)
                .eq(ImChatUserDO::getChatId, chatId));
    }

    default List<ImChatUserDO> selectListByUserId(Long userId) {
        return selectList(new LambdaQueryWrapperX<ImChatUserDO>()
                .eq(ImChatUserDO::getUserId, userId)
                .eq(ImChatUserDO::getDeletedByUser, false)
                .orderByDesc(ImChatUserDO::getIsPinned)
                .orderByDesc(ImChatUserDO::getLastMessageTime));
    }

    /**
     * 分页查询用户的会话记录
     */
    default List<ImChatUserDO> selectListByUserIdWithPage(Long userId, int offset, int pageSize) {
        return selectList(new LambdaQueryWrapperX<ImChatUserDO>()
                .eq(ImChatUserDO::getUserId, userId)
                .eq(ImChatUserDO::getDeletedByUser, false)
                .orderByDesc(ImChatUserDO::getIsPinned)
                .orderByDesc(ImChatUserDO::getLastMessageTime)
                .last("LIMIT " + offset + ", " + pageSize));
    }

    /**
     * 按会话类型查询用户会话列表（SQL层过滤，避免内存过滤）
     */
    @Select({"<script>",
            "SELECT cu.*",
            "FROM im_chat_user cu",
            "JOIN im_chat c ON c.id = cu.chat_id AND c.deleted = 0",
            "WHERE cu.user_id = #{userId}",
            "  AND cu.deleted_by_user = 0",
            "<if test='conversationType != null'>",
            "  AND c.chat_type = #{conversationType}",
            "</if>",
            "ORDER BY cu.is_pinned DESC, cu.last_message_time DESC, cu.id DESC",
            "</script>"})
    List<ImChatUserDO> selectListByUserIdAndType(@Param("userId") Long userId,
                                                 @Param("conversationType") Integer conversationType);

    default List<ImChatUserDO> selectListByUserIdAndChatIds(Long userId, List<Long> chatIds) {
        return selectList(new LambdaQueryWrapperX<ImChatUserDO>()
                .eq(ImChatUserDO::getUserId, userId)
                .in(ImChatUserDO::getChatId, chatIds)
                .eq(ImChatUserDO::getDeletedByUser, false));
    }

    /**
     * 批量查询用户的会话记录（用于权限校验，不区分删除状态）
     */
    default List<ImChatUserDO> selectListByUserAndChatIds(Long userId, List<Long> chatIds) {
        return selectList(new LambdaQueryWrapperX<ImChatUserDO>()
                .eq(ImChatUserDO::getUserId, userId)
                .in(ImChatUserDO::getChatId, chatIds));
    }

    /**
     * 仅查询 unread_count > 0 的会话，减少数据量
     */
    @Select("SELECT * FROM im_chat_user WHERE user_id = #{userId} AND unread_count > 0 AND deleted_by_user = 0")
    List<ImChatUserDO> selectListWithUnread(@Param("userId") Long userId);

    /**
     * 获取单个会话的未读数（SQL 查询，不加载整个对象）
     */
    @Select("SELECT COALESCE(last_message_sequence - last_read_sequence, 0) FROM im_chat_user WHERE user_id = #{userId} AND chat_id = #{chatId} AND deleted_by_user = 0 AND deleted = 0 LIMIT 1")
    Integer selectUnreadCountByUserIdAndChatId(@Param("userId") Long userId, @Param("chatId") Long chatId);

    @Select({"<script>",
            "SELECT COUNT(1)",
            "FROM im_chat_user cu",
            "JOIN im_chat c ON c.id = cu.chat_id",
            "LEFT JOIN im_group g ON g.id = c.group_id",
            "LEFT JOIN system_users u1 ON u1.id = c.single_user1",
            "LEFT JOIN system_users u2 ON u2.id = c.single_user2",
            "WHERE cu.tenant_id = #{tenantId}",
            "  AND cu.user_id = #{userId}",
            "  AND cu.deleted_by_user = 0",
            "<if test='conversationType != null'>",
            "  AND c.chat_type = #{conversationType}",
            "</if>",
            "<if test='keyword != null and keyword != \"\"'>",
            "  AND (",
            "    (c.chat_type = 2 AND g.name LIKE CONCAT('%', #{keyword}, '%'))",
            "    OR",
            "    (c.chat_type = 1 AND (",
            "       (c.single_user1 = #{userId} AND u2.nickname LIKE CONCAT('%', #{keyword}, '%'))",
            "       OR",
            "       (c.single_user2 = #{userId} AND u1.nickname LIKE CONCAT('%', #{keyword}, '%'))",
            "    ))",
            "  )",
            "</if>",
            "</script>"})
    Long countChatIdsByUserForSearch(@Param("tenantId") Long tenantId,
                                    @Param("userId") Long userId,
                                    @Param("conversationType") Integer conversationType,
                                    @Param("keyword") String keyword);

    @Select({"<script>",
            "SELECT cu.chat_id",
            "FROM im_chat_user cu",
            "JOIN im_chat c ON c.id = cu.chat_id",
            "LEFT JOIN im_group g ON g.id = c.group_id",
            "LEFT JOIN system_users u1 ON u1.id = c.single_user1",
            "LEFT JOIN system_users u2 ON u2.id = c.single_user2",
            "WHERE cu.tenant_id = #{tenantId}",
            "  AND cu.user_id = #{userId}",
            "  AND cu.deleted_by_user = 0",
            "<if test='conversationType != null'>",
            "  AND c.chat_type = #{conversationType}",
            "</if>",
            "<if test='keyword != null and keyword != \"\"'>",
            "  AND (",
            "    (c.chat_type = 2 AND g.name LIKE CONCAT('%', #{keyword}, '%'))",
            "    OR",
            "    (c.chat_type = 1 AND (",
            "       (c.single_user1 = #{userId} AND u2.nickname LIKE CONCAT('%', #{keyword}, '%'))",
            "       OR",
            "       (c.single_user2 = #{userId} AND u1.nickname LIKE CONCAT('%', #{keyword}, '%'))",
            "    ))",
            "  )",
            "</if>",
            "ORDER BY cu.is_pinned DESC, cu.last_message_time DESC, cu.id DESC",
            "LIMIT #{limit} OFFSET #{offset}",
            "</script>"})
    List<Long> selectChatIdsByUserForSearch(@Param("tenantId") Long tenantId,
                                           @Param("userId") Long userId,
                                           @Param("conversationType") Integer conversationType,
                                           @Param("keyword") String keyword,
                                           @Param("offset") Long offset,
                                           @Param("limit") Long limit);

    default int updateSettings(Long userId, Long chatId, Boolean isPinned, Boolean noDisturb) {
        return update(null, new LambdaUpdateWrapper<ImChatUserDO>()
                .eq(ImChatUserDO::getUserId, userId)
                .eq(ImChatUserDO::getChatId, chatId)
                .set(isPinned != null, ImChatUserDO::getIsPinned, isPinned)
                .set(noDisturb != null, ImChatUserDO::getNoDisturb, noDisturb));
    }

    default int markRead(Long userId, Long chatId) {
        return update(null, new LambdaUpdateWrapper<ImChatUserDO>()
                .eq(ImChatUserDO::getUserId, userId)
                .eq(ImChatUserDO::getChatId, chatId)
                .set(ImChatUserDO::getUnreadCount, 0)
                .set(ImChatUserDO::getLastReadMessageId, null));
    }

    default int softDelete(Long userId, Long chatId) {
        return update(null, new LambdaUpdateWrapper<ImChatUserDO>()
                .eq(ImChatUserDO::getUserId, userId)
                .eq(ImChatUserDO::getChatId, chatId)
                .set(ImChatUserDO::getDeletedByUser, true));
    }

    default int reviveSoftDeleted(Long id) {
        return update(null, new LambdaUpdateWrapper<ImChatUserDO>()
                .eq(ImChatUserDO::getId, id)
                .set(ImChatUserDO::getDeletedByUser, false));
    }

    default int updateLastMessageAndIncrementUnread(Long id, Long lastMessageId, String lastMessageContent, LocalDateTime lastMessageTime,
                                                   Integer unreadIncrement, boolean noDisturb) {
        LambdaUpdateWrapper<ImChatUserDO> wrapper = new LambdaUpdateWrapper<ImChatUserDO>()
                .eq(ImChatUserDO::getId, id)
                .set(ImChatUserDO::getLastMessageId, lastMessageId)
                .set(ImChatUserDO::getLastMessageSequence, 0L)
                .set(ImChatUserDO::getLastMessageContent, lastMessageContent)
                .set(ImChatUserDO::getLastMessageTime, lastMessageTime);
        if (unreadIncrement != null && unreadIncrement > 0 && !noDisturb) {
            wrapper.setSql("unread_count = unread_count + " + unreadIncrement);
        }
        return update(null, wrapper);
    }

    default int updateLastMessageAndIncrementUnread(Long id, Long lastMessageId, Integer lastMessageType, String lastMessageContent,
                                                   LocalDateTime lastMessageTime, Integer unreadIncrement, boolean noDisturb) {
        LambdaUpdateWrapper<ImChatUserDO> wrapper = new LambdaUpdateWrapper<ImChatUserDO>()
                .eq(ImChatUserDO::getId, id)
                .set(ImChatUserDO::getLastMessageId, lastMessageId)
                .set(ImChatUserDO::getLastMessageSequence, 0L)
                .set(ImChatUserDO::getLastMessageType, lastMessageType)
                .set(ImChatUserDO::getLastMessageContent, lastMessageContent)
                .set(ImChatUserDO::getLastMessageTime, lastMessageTime);
        if (unreadIncrement != null && unreadIncrement > 0 && !noDisturb) {
            wrapper.setSql("unread_count = unread_count + " + unreadIncrement);
        }
        return update(null, wrapper);
    }

    default int updateLastMessageAndIncrementUnread(Long id, Long lastMessageId, Long lastMessageSequence, String lastMessageContent,
                                                   LocalDateTime lastMessageTime, Integer unreadIncrement, boolean noDisturb) {
        LambdaUpdateWrapper<ImChatUserDO> wrapper = new LambdaUpdateWrapper<ImChatUserDO>()
                .eq(ImChatUserDO::getId, id)
                .set(ImChatUserDO::getLastMessageId, lastMessageId)
                .set(ImChatUserDO::getLastMessageSequence, lastMessageSequence)
                .set(ImChatUserDO::getLastMessageContent, lastMessageContent)
                .set(ImChatUserDO::getLastMessageTime, lastMessageTime);
        if (unreadIncrement != null && unreadIncrement > 0 && !noDisturb) {
            wrapper.setSql("unread_count = unread_count + " + unreadIncrement);
        }
        return update(null, wrapper);
    }

    default int updateLastMessageAndIncrementUnread(Long id, Long lastMessageId, Long lastMessageSequence, Integer lastMessageType,
                                                   String lastMessageContent, LocalDateTime lastMessageTime,
                                                   Integer unreadIncrement, boolean noDisturb) {
        LambdaUpdateWrapper<ImChatUserDO> wrapper = new LambdaUpdateWrapper<ImChatUserDO>()
                .eq(ImChatUserDO::getId, id)
                .set(ImChatUserDO::getLastMessageId, lastMessageId)
                .set(ImChatUserDO::getLastMessageSequence, lastMessageSequence)
                .set(ImChatUserDO::getLastMessageType, lastMessageType)
                .set(ImChatUserDO::getLastMessageContent, lastMessageContent)
                .set(ImChatUserDO::getLastMessageTime, lastMessageTime);
        if (unreadIncrement != null && unreadIncrement > 0 && !noDisturb) {
            wrapper.setSql("unread_count = unread_count + " + unreadIncrement);
        }
        return update(null, wrapper);
    }

    /**
     * 更新会话最后一条消息及未读数（含发送者ID）
     */
    default int updateLastMessageAndIncrementUnread(Long id, Long lastMessageId, Long lastMessageSequence, Integer lastMessageType,
                                                   String lastMessageContent, LocalDateTime lastMessageTime,
                                                   Integer unreadIncrement, boolean noDisturb, Long lastMessageSenderId) {
        LambdaUpdateWrapper<ImChatUserDO> wrapper = new LambdaUpdateWrapper<ImChatUserDO>()
                .eq(ImChatUserDO::getId, id)
                .set(ImChatUserDO::getLastMessageId, lastMessageId)
                .set(ImChatUserDO::getLastMessageSequence, lastMessageSequence)
                .set(ImChatUserDO::getLastMessageType, lastMessageType)
                .set(ImChatUserDO::getLastMessageContent, lastMessageContent)
                .set(ImChatUserDO::getLastMessageTime, lastMessageTime)
                .set(ImChatUserDO::getLastMessageSenderId, lastMessageSenderId);
        if (unreadIncrement != null && unreadIncrement > 0 && !noDisturb) {
            wrapper.setSql("unread_count = unread_count + " + unreadIncrement);
        }
        return update(null, wrapper);
    }

    /**
     * 仅更新会话预览（lastMessageType/lastMessageContent），用于撤回等“最终态变更”。
     *
     * 约束：只在 lastMessageId 仍然等于目标 messageId 时才更新，避免 lastMessage 已推进后被回写覆盖。
     */
    default int updateLastMessagePreviewIfMatch(Long id, Long messageId, Integer lastMessageType, String lastMessageContent) {
        return update(null, new LambdaUpdateWrapper<ImChatUserDO>()
                .eq(ImChatUserDO::getId, id)
                .eq(ImChatUserDO::getLastMessageId, messageId)
                .set(ImChatUserDO::getLastMessageType, lastMessageType)
                .set(ImChatUserDO::getLastMessageContent, lastMessageContent));
    }

    @Select("SELECT COALESCE(SUM(GREATEST(IFNULL(last_message_sequence, 0) - IFNULL(last_read_sequence, 0), 0)), 0) " +
            "FROM im_chat_user " +
            "WHERE user_id = #{userId} AND deleted_by_user = 0 AND deleted = 0")
    Integer selectTotalUnreadCount(@Param("userId") Long userId);

    @Update("UPDATE im_chat_user SET last_read_sequence = GREATEST(IFNULL(last_read_sequence, 0), #{readSequence}), unread_count = 0 " +
            "WHERE user_id = #{userId} AND chat_id = #{chatId} AND deleted_by_user = 0 AND deleted = 0")
    int markReadToSequence(@Param("userId") Long userId, @Param("chatId") Long chatId, @Param("readSequence") Long readSequence);

    /**
     * 更新群组成员状态
     * @param userId 用户ID
     * @param chatId 会话ID
     * @param groupMemberStatus 群组成员状态：0=正常, 1=已退出, 2=已被踢, 3=群已解散
     * @return 更新行数
     */
    default int updateGroupMemberStatus(Long userId, Long chatId, Integer groupMemberStatus) {
        return update(null, new LambdaUpdateWrapper<ImChatUserDO>()
                .eq(ImChatUserDO::getUserId, userId)
                .eq(ImChatUserDO::getChatId, chatId)
                .set(ImChatUserDO::getGroupMemberStatus, groupMemberStatus));
    }

    /**
     * 批量更新群组成员状态（用于群解散场景）
     * @param chatId 会话ID
     * @param groupMemberStatus 群组成员状态：3=群已解散
     * @return 更新行数
     */
    default int batchUpdateGroupMemberStatusByChatId(Long chatId, Integer groupMemberStatus) {
        return update(null, new LambdaUpdateWrapper<ImChatUserDO>()
                .eq(ImChatUserDO::getChatId, chatId)
                .eq(ImChatUserDO::getDeletedByUser, false)
                .set(ImChatUserDO::getGroupMemberStatus, groupMemberStatus));
    }

    /**
     * 更新群组成员状态并设置离群时间
     * @param userId 用户ID
     * @param chatId 会话ID
     * @param groupMemberStatus 群组成员状态：1=已退出, 2=已被踢
     * @param leftAt 离群时间
     * @return 更新行数
     */
    default int updateGroupMemberStatusAndLeftAt(Long userId, Long chatId, Integer groupMemberStatus, LocalDateTime leftAt) {
        return update(null, new LambdaUpdateWrapper<ImChatUserDO>()
                .eq(ImChatUserDO::getUserId, userId)
                .eq(ImChatUserDO::getChatId, chatId)
                .set(ImChatUserDO::getGroupMemberStatus, groupMemberStatus)
                .set(ImChatUserDO::getLeftAt, leftAt));
    }

    /**
     * 恢复群成员状态（重新入群时调用）
     * @param userId 用户ID
     * @param chatId 会话ID
     * @return 更新行数
     */
    default int restoreGroupMemberStatus(Long userId, Long chatId) {
        return update(null, new LambdaUpdateWrapper<ImChatUserDO>()
                .eq(ImChatUserDO::getUserId, userId)
                .eq(ImChatUserDO::getChatId, chatId)
                .set(ImChatUserDO::getGroupMemberStatus, 0)
                .set(ImChatUserDO::getLeftAt, null));
    }

    /**
     * 查询用户的离群时间
     * @param userId 用户ID
     * @param chatId 会话ID
     * @return 离群时间，未离群返回null
     */
    default LocalDateTime selectLeftAt(Long userId, Long chatId) {
        ImChatUserDO chatUser = selectOne(new LambdaQueryWrapperX<ImChatUserDO>()
                .eq(ImChatUserDO::getUserId, userId)
                .eq(ImChatUserDO::getChatId, chatId));
        return chatUser != null ? chatUser.getLeftAt() : null;
    }

    /**
     * 保存群组快照数据（被踢/退群/解散时调用）
     * @param userId 用户ID
     * @param chatId 会话ID
     * @param snapshotData JSON格式的快照数据
     * @return 更新行数
     */
    default int saveSnapshotData(Long userId, Long chatId, String snapshotData) {
        return update(null, new LambdaUpdateWrapper<ImChatUserDO>()
                .eq(ImChatUserDO::getUserId, userId)
                .eq(ImChatUserDO::getChatId, chatId)
                .set(ImChatUserDO::getSnapshotData, snapshotData));
    }

    /**
     * 批量保存群组快照数据（用于群解散场景）
     * @param userIds 用户ID列表
     * @param chatId 会话ID
     * @param snapshotData JSON格式的快照数据
     * @return 更新行数
     */
    default int batchSaveSnapshotData(List<Long> userIds, Long chatId, String snapshotData) {
        if (userIds == null || userIds.isEmpty()) {
            return 0;
        }
        return update(null, new LambdaUpdateWrapper<ImChatUserDO>()
                .in(ImChatUserDO::getUserId, userIds)
                .eq(ImChatUserDO::getChatId, chatId)
                .set(ImChatUserDO::getSnapshotData, snapshotData));
    }

    /**
     * 清理群组快照数据（用户主动删除会话时调用）
     * 清空 group_member_status、left_at、snapshot_data，恢复为干净状态
     * 这样如果用户在群内，新消息到来时会重新创建干净的会话条目
     * @param userId 用户ID
     * @param chatId 会话ID
     * @return 更新行数
     */
    default int cleanGroupSnapshotAndStatus(Long userId, Long chatId) {
        return update(null, new LambdaUpdateWrapper<ImChatUserDO>()
                .eq(ImChatUserDO::getUserId, userId)
                .eq(ImChatUserDO::getChatId, chatId)
                .set(ImChatUserDO::getGroupMemberStatus, 0)
                .set(ImChatUserDO::getLeftAt, null)
                .set(ImChatUserDO::getSnapshotData, null));
    }

}
