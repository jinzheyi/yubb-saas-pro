package com.shengyu.module.system.dal.mysql.im;

import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.module.system.dal.dataobject.im.ImChatUserDO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Update;

import java.time.LocalDateTime;
import java.util.List;

@Mapper
public interface ImChatUserMapper extends BaseMapperX<ImChatUserDO> {

    default ImChatUserDO selectByUserIdAndChatId(Long userId, Long chatId) {
        return selectOne(new LambdaQueryWrapperX<ImChatUserDO>()
                .eq(ImChatUserDO::getUserId, userId)
                .eq(ImChatUserDO::getChatId, chatId)
                .eq(ImChatUserDO::getDeletedByUser, false));
    }

    default List<ImChatUserDO> selectListByUserId(Long userId) {
        return selectList(new LambdaQueryWrapperX<ImChatUserDO>()
                .eq(ImChatUserDO::getUserId, userId)
                .eq(ImChatUserDO::getDeletedByUser, false)
                .orderByDesc(ImChatUserDO::getIsPinned)
                .orderByDesc(ImChatUserDO::getLastMessageTime));
    }

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

    @Update("UPDATE im_chat_user SET last_read_sequence = GREATEST(last_read_sequence, #{readSequence}), unread_count = 0 " +
            "WHERE user_id = #{userId} AND chat_id = #{chatId} AND deleted_by_user = 0 AND deleted = 0")
    int markReadToSequence(@Param("userId") Long userId, @Param("chatId") Long chatId, @Param("readSequence") Long readSequence);

}
