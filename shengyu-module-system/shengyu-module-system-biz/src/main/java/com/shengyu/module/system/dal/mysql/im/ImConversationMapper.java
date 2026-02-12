package com.shengyu.module.system.dal.mysql.im;

import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.module.system.dal.dataobject.im.ImConversationDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * IM 会话 Mapper
 *
 * @author 圣钰科技
 */
@Mapper
public interface ImConversationMapper extends BaseMapperX<ImConversationDO> {

    /**
     * 根据用户ID查询会话列表(按最后消息时间倒序)
     *
     * @param userId 用户ID
     * @return 会话列表
     */
    default List<ImConversationDO> selectListByUserId(Long userId) {
        return selectList(new LambdaQueryWrapperX<ImConversationDO>()
                .eq(ImConversationDO::getUserId, userId)
                .eq(ImConversationDO::getDeletedByUser, false)
                .orderByDesc(ImConversationDO::getLastMessageTime));
    }

    /**
     * 根据用户ID和会话类型查询会话列表
     *
     * @param userId 用户ID
     * @param conversationType 会话类型
     * @return 会话列表
     */
    default List<ImConversationDO> selectListByUserIdAndType(Long userId, Integer conversationType) {
        return selectList(new LambdaQueryWrapperX<ImConversationDO>()
                .eq(ImConversationDO::getUserId, userId)
                .eq(ImConversationDO::getConversationType, conversationType)
                .eq(ImConversationDO::getDeletedByUser, false)
                .orderByDesc(ImConversationDO::getLastMessageTime));
    }

    /**
     * 根据用户ID、目标ID和会话类型查询会话
     *
     * @param userId 用户ID
     * @param targetId 目标ID
     * @param conversationType 会话类型
     * @return 会话
     */
    default ImConversationDO selectByUserIdAndTargetIdAndType(Long userId, Long targetId, Integer conversationType) {
        return selectOne(new LambdaQueryWrapperX<ImConversationDO>()
                .eq(ImConversationDO::getUserId, userId)
                .eq(ImConversationDO::getTargetId, targetId)
                .eq(ImConversationDO::getConversationType, conversationType));
    }

    /**
     * 根据用户ID查询未读消息总数
     *
     * @param userId 用户ID
     * @return 未读消息总数
     */
    default Integer selectUnreadCountByUserId(Long userId) {
        List<ImConversationDO> conversations = selectList(new LambdaQueryWrapperX<ImConversationDO>()
                .eq(ImConversationDO::getUserId, userId)
                .eq(ImConversationDO::getDeletedByUser, false));
        return conversations.stream()
                .mapToInt(ImConversationDO::getUnreadCount)
                .sum();
    }

    /**
     * 根据用户ID查询置顶会话列表
     *
     * @param userId 用户ID
     * @return 置顶会话列表
     */
    default List<ImConversationDO> selectListByUserIdAndPinned(Long userId) {
        return selectList(new LambdaQueryWrapperX<ImConversationDO>()
                .eq(ImConversationDO::getUserId, userId)
                .eq(ImConversationDO::getIsPinned, true)
                .eq(ImConversationDO::getDeletedByUser, false)
                .orderByDesc(ImConversationDO::getLastMessageTime));
    }

}
