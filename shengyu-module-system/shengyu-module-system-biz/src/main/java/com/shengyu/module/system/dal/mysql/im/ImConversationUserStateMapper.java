package com.shengyu.module.system.dal.mysql.im;

import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.module.system.dal.dataobject.im.ImConversationUserStateDO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Select;

import java.time.LocalDateTime;
import java.util.List;

@Mapper
public interface ImConversationUserStateMapper extends BaseMapperX<ImConversationUserStateDO> {

    @Select("SELECT * FROM im_conversation_user_state " +
            "WHERE tenant_id = #{tenantId} AND user_id = #{userId} AND deleted_by_user = 0 AND deleted = 0 " +
            "AND cursor_version > #{cursorVersion} " +
            "ORDER BY cursor_version ASC " +
            "LIMIT #{limit}")
    List<ImConversationUserStateDO> selectSyncList(@Param("tenantId") Long tenantId,
                                                  @Param("userId") Long userId,
                                                  @Param("cursorVersion") Long cursorVersion,
                                                  @Param("limit") Integer limit);

    @Select({"<script>",
            "SELECT * FROM im_conversation_user_state ",
            "WHERE tenant_id = #{tenantId} AND user_id = #{userId} ",
            "  AND deleted = 0 ",
            "  AND chat_id IN ",
            "  <foreach collection='chatIds' item='cid' open='(' separator=',' close=')'>",
            "    #{cid}",
            "  </foreach>",
            "</script>"})
    List<ImConversationUserStateDO> selectListByUserIdAndChatIds(@Param("tenantId") Long tenantId,
                                                                @Param("userId") Long userId,
                                                                @Param("chatIds") List<Long> chatIds);

    @Insert("INSERT INTO im_conversation_user_state(" +
            "tenant_id, chat_id, user_id, cursor_version, conversation_version, " +
            "unread_count, last_read_sequence, last_read_time, " +
            "last_message_id, last_message_sequence, last_message_type, last_message_content, last_message_has_at_me, last_message_time, " +
            "is_pinned, no_disturb, draft, deleted_by_user, deleted) " +
            "VALUES(" +
            "#{tenantId}, #{chatId}, #{userId}, #{cursorVersion}, 1, " +
            "IFNULL(#{unreadDelta}, 0), IFNULL(#{lastReadSequence}, 0), #{lastReadTime}, " +
            "#{lastMessageId}, #{lastMessageSequence}, #{lastMessageType}, #{lastMessageContent}, #{lastMessageHasAtMe}, #{lastMessageTime}, " +
            "0, 0, NULL, 0, 0) " +
            "ON DUPLICATE KEY UPDATE " +
            "cursor_version = VALUES(cursor_version), " +
            "conversation_version = IFNULL(conversation_version, 0) + 1, " +
            "unread_count = GREATEST(IFNULL(unread_count, 0) + VALUES(unread_count), 0), " +
            "last_read_sequence = CASE WHEN VALUES(last_read_sequence) IS NULL THEN last_read_sequence " +
            "  ELSE GREATEST(IFNULL(last_read_sequence, 0), VALUES(last_read_sequence)) END, " +
            "last_read_time = CASE WHEN VALUES(last_read_time) IS NULL THEN last_read_time ELSE VALUES(last_read_time) END, " +
            "last_message_id = VALUES(last_message_id), " +
            "last_message_sequence = VALUES(last_message_sequence), " +
            "last_message_type = VALUES(last_message_type), " +
            "last_message_content = VALUES(last_message_content), " +
            "last_message_has_at_me = COALESCE(VALUES(last_message_has_at_me), last_message_has_at_me), " +
            "last_message_time = VALUES(last_message_time), " +
            "deleted_by_user = 0, " +
            "deleted = 0")
    int upsertAfterMessage(@Param("tenantId") Long tenantId,
                          @Param("chatId") Long chatId,
                          @Param("userId") Long userId,
                          @Param("cursorVersion") Long cursorVersion,
                          @Param("unreadDelta") Integer unreadDelta,
                          @Param("lastReadSequence") Long lastReadSequence,
                          @Param("lastReadTime") LocalDateTime lastReadTime,
                          @Param("lastMessageId") Long lastMessageId,
                          @Param("lastMessageSequence") Long lastMessageSequence,
                          @Param("lastMessageType") Integer lastMessageType,
                          @Param("lastMessageContent") String lastMessageContent,
                          @Param("lastMessageHasAtMe") Boolean lastMessageHasAtMe,
                          @Param("lastMessageTime") LocalDateTime lastMessageTime);

    @Insert("INSERT INTO im_conversation_user_state(" +
            "tenant_id, chat_id, user_id, cursor_version, conversation_version, " +
            "unread_count, last_read_sequence, last_read_time, " +
            "last_message_id, last_message_sequence, last_message_type, last_message_content, last_message_has_at_me, last_message_time, " +
            "is_pinned, no_disturb, draft, deleted_by_user, deleted) " +
            "VALUES(" +
            "#{tenantId}, #{chatId}, #{userId}, #{cursorVersion}, 1, " +
            "#{unreadCount}, #{lastReadSequence}, #{lastReadTime}, " +
            "#{lastMessageId}, #{lastMessageSequence}, #{lastMessageType}, #{lastMessageContent}, #{lastMessageHasAtMe}, #{lastMessageTime}, " +
            "#{isPinned}, #{noDisturb}, #{draft}, 0, 0) " +
            "ON DUPLICATE KEY UPDATE " +
            "cursor_version = VALUES(cursor_version), " +
            "conversation_version = IFNULL(conversation_version, 0) + 1, " +
            "unread_count = GREATEST(VALUES(unread_count), IFNULL(unread_count, 0)), " +
            "last_read_sequence = GREATEST(IFNULL(last_read_sequence, 0), IFNULL(VALUES(last_read_sequence), 0)), " +
            "last_read_time = CASE WHEN VALUES(last_read_time) IS NULL THEN last_read_time ELSE VALUES(last_read_time) END, " +
            "last_message_id = COALESCE(VALUES(last_message_id), last_message_id), " +
            "last_message_sequence = GREATEST(IFNULL(last_message_sequence, 0), IFNULL(VALUES(last_message_sequence), 0)), " +
            "last_message_type = COALESCE(VALUES(last_message_type), last_message_type), " +
            "last_message_content = COALESCE(VALUES(last_message_content), last_message_content), " +
            "last_message_has_at_me = COALESCE(VALUES(last_message_has_at_me), last_message_has_at_me), " +
            "last_message_time = COALESCE(VALUES(last_message_time), last_message_time), " +
            "is_pinned = COALESCE(VALUES(is_pinned), is_pinned), " +
            "no_disturb = COALESCE(VALUES(no_disturb), no_disturb), " +
            "draft = VALUES(draft), " +
            "deleted_by_user = 0, " +
            "deleted = 0")
    int upsertInitConversation(@Param("tenantId") Long tenantId,
                              @Param("chatId") Long chatId,
                              @Param("userId") Long userId,
                              @Param("cursorVersion") Long cursorVersion,
                              @Param("unreadCount") Integer unreadCount,
                              @Param("lastReadSequence") Long lastReadSequence,
                              @Param("lastReadTime") LocalDateTime lastReadTime,
                              @Param("lastMessageId") Long lastMessageId,
                              @Param("lastMessageSequence") Long lastMessageSequence,
                              @Param("lastMessageType") Integer lastMessageType,
                              @Param("lastMessageContent") String lastMessageContent,
                              @Param("lastMessageHasAtMe") Boolean lastMessageHasAtMe,
                              @Param("lastMessageTime") LocalDateTime lastMessageTime,
                              @Param("isPinned") Boolean isPinned,
                              @Param("noDisturb") Boolean noDisturb,
                              @Param("draft") String draft);

    @Insert("INSERT INTO im_conversation_user_state(" +
            "tenant_id, chat_id, user_id, cursor_version, conversation_version, " +
            "unread_count, last_read_sequence, last_read_time, " +
            "last_message_id, last_message_sequence, last_message_type, last_message_content, last_message_time, " +
            "is_pinned, no_disturb, draft, deleted_by_user, deleted) " +
            "VALUES(" +
            "#{tenantId}, #{chatId}, #{userId}, #{cursorVersion}, 1, " +
            "0, #{lastReadSequence}, #{lastReadTime}, " +
            "#{lastMessageId}, #{lastMessageSequence}, #{lastMessageType}, #{lastMessageContent}, #{lastMessageTime}, " +
            "#{isPinned}, #{noDisturb}, #{draft}, 0, 0) " +
            "ON DUPLICATE KEY UPDATE " +
            "cursor_version = VALUES(cursor_version), " +
            "conversation_version = IFNULL(conversation_version, 0) + 1, " +
            "unread_count = 0, " +
            "last_read_sequence = GREATEST(IFNULL(last_read_sequence, 0), IFNULL(VALUES(last_read_sequence), 0)), " +
            "last_read_time = CASE WHEN VALUES(last_read_time) IS NULL THEN last_read_time ELSE VALUES(last_read_time) END, " +
            "last_message_has_at_me = CASE " +
            "  WHEN GREATEST(IFNULL(last_read_sequence, 0), IFNULL(VALUES(last_read_sequence), 0)) >= IFNULL(last_message_sequence, 0) THEN b'0' " +
            "  ELSE last_message_has_at_me END, " +
            "is_pinned = COALESCE(VALUES(is_pinned), is_pinned), " +
            "no_disturb = COALESCE(VALUES(no_disturb), no_disturb), " +
            "draft = VALUES(draft), " +
            "deleted_by_user = 0, " +
            "deleted = 0")
    int upsertAfterRead(@Param("tenantId") Long tenantId,
                       @Param("chatId") Long chatId,
                       @Param("userId") Long userId,
                       @Param("cursorVersion") Long cursorVersion,
                       @Param("lastReadSequence") Long lastReadSequence,
                       @Param("lastReadTime") LocalDateTime lastReadTime,
                       @Param("lastMessageId") Long lastMessageId,
                       @Param("lastMessageSequence") Long lastMessageSequence,
                       @Param("lastMessageType") Integer lastMessageType,
                       @Param("lastMessageContent") String lastMessageContent,
                       @Param("lastMessageTime") LocalDateTime lastMessageTime,
                       @Param("isPinned") Boolean isPinned,
                       @Param("noDisturb") Boolean noDisturb,
                       @Param("draft") String draft);

    @Insert("INSERT INTO im_conversation_user_state(" +
            "tenant_id, chat_id, user_id, cursor_version, conversation_version, " +
            "unread_count, last_read_sequence, last_read_time, " +
            "last_message_id, last_message_sequence, last_message_type, last_message_content, last_message_time, " +
            "is_pinned, no_disturb, draft, deleted_by_user, deleted) " +
            "VALUES(" +
            "#{tenantId}, #{chatId}, #{userId}, #{cursorVersion}, 1, " +
            "0, 0, NULL, " +
            "NULL, 0, NULL, NULL, NULL, " +
            "#{isPinned}, #{noDisturb}, #{draft}, 0, 0) " +
            "ON DUPLICATE KEY UPDATE " +
            "cursor_version = VALUES(cursor_version), " +
            "conversation_version = IFNULL(conversation_version, 0) + 1, " +
            "is_pinned = COALESCE(VALUES(is_pinned), is_pinned), " +
            "no_disturb = COALESCE(VALUES(no_disturb), no_disturb), " +
            "draft = VALUES(draft), " +
            "deleted_by_user = 0, " +
            "deleted = 0")
    int upsertAfterSettings(@Param("tenantId") Long tenantId,
                           @Param("chatId") Long chatId,
                           @Param("userId") Long userId,
                           @Param("cursorVersion") Long cursorVersion,
                           @Param("isPinned") Boolean isPinned,
                           @Param("noDisturb") Boolean noDisturb,
                           @Param("draft") String draft);

    @Insert("INSERT INTO im_conversation_user_state(" +
            "tenant_id, chat_id, user_id, cursor_version, conversation_version, " +
            "unread_count, last_read_sequence, last_read_time, " +
            "last_message_id, last_message_sequence, last_message_type, last_message_content, last_message_time, " +
            "is_pinned, no_disturb, draft, deleted_by_user, deleted) " +
            "VALUES(" +
            "#{tenantId}, #{chatId}, #{userId}, #{cursorVersion}, 1, " +
            "0, 0, NULL, " +
            "NULL, 0, NULL, NULL, NULL, " +
            "0, 0, NULL, #{deletedByUser}, 0) " +
            "ON DUPLICATE KEY UPDATE " +
            "cursor_version = VALUES(cursor_version), " +
            "conversation_version = IFNULL(conversation_version, 0) + 1, " +
            "deleted_by_user = VALUES(deleted_by_user), " +
            "deleted = 0")
    int upsertAfterDelete(@Param("tenantId") Long tenantId,
                         @Param("chatId") Long chatId,
                         @Param("userId") Long userId,
                         @Param("cursorVersion") Long cursorVersion,
                         @Param("deletedByUser") Boolean deletedByUser);

    /**
     * 更新群组成员状态和离群时间（被踢/退群时调用）
     * @param tenantId 租户ID
     * @param userId 用户ID
     * @param chatId 会话ID
     * @param groupMemberStatus 群组成员状态：1=已退出, 2=已被踢
     * @param leftAt 离群时间
     * @param cursorVersion 游标版本号
     * @return 更新行数
     */
    default int updateGroupMemberStatus(Long tenantId, Long userId, Long chatId, Integer groupMemberStatus, java.time.LocalDateTime leftAt, Long cursorVersion) {
        return update(null, new com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper<ImConversationUserStateDO>()
                .eq(ImConversationUserStateDO::getTenantId, tenantId)
                .eq(ImConversationUserStateDO::getUserId, userId)
                .eq(ImConversationUserStateDO::getChatId, chatId)
                .eq(ImConversationUserStateDO::getDeleted, false)
                .set(ImConversationUserStateDO::getGroupMemberStatus, groupMemberStatus)
                .set(ImConversationUserStateDO::getLeftAt, leftAt)
                .set(cursorVersion != null, ImConversationUserStateDO::getCursorVersion, cursorVersion));
    }

    /**
     * 恢复群成员状态（重新入群时调用）
     * @param tenantId 租户ID
     * @param userId 用户ID
     * @param chatId 会话ID
     * @param cursorVersion 游标版本号
     * @return 更新行数
     */
    default int restoreGroupMemberStatus(Long tenantId, Long userId, Long chatId, Long cursorVersion) {
        return update(null, new com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper<ImConversationUserStateDO>()
                .eq(ImConversationUserStateDO::getTenantId, tenantId)
                .eq(ImConversationUserStateDO::getUserId, userId)
                .eq(ImConversationUserStateDO::getChatId, chatId)
                .eq(ImConversationUserStateDO::getDeleted, false)
                .set(ImConversationUserStateDO::getGroupMemberStatus, 0)
                .set(ImConversationUserStateDO::getLeftAt, null)
                .set(cursorVersion != null, ImConversationUserStateDO::getCursorVersion, cursorVersion));
    }
}
