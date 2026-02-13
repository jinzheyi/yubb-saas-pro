package com.shengyu.module.system.dal.mysql.im;

import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.module.system.dal.dataobject.im.ImMessageDO;
import org.apache.ibatis.annotations.Mapper;

import java.time.LocalDateTime;
import java.util.List;

/**
 * IM 消息 Mapper
 *
 * @author 圣钰科技
 */
@Mapper
public interface ImMessageMapper extends BaseMapperX<ImMessageDO> {

    /**
     * 根据会话ID分页查询消息列表(按发送时间倒序)
     *
     * @param conversationId 会话ID
     * @param pageParam 分页参数
     * @return 消息分页结果
     */
    default PageResult<ImMessageDO> selectPageByConversationId(Long conversationId, com.shengyu.framework.common.pojo.PageParam pageParam) {
        return selectPage(pageParam, new LambdaQueryWrapperX<ImMessageDO>()
                .eq(ImMessageDO::getConversationId, conversationId)
                .orderByDesc(ImMessageDO::getSendTime));
    }

    /**
     * 根据会话ID查询最后一条消息
     *
     * @param conversationId 会话ID
     * @return 最后一条消息
     */
    default ImMessageDO selectLastMessageByConversationId(Long conversationId) {
        return selectOne(new LambdaQueryWrapperX<ImMessageDO>()
                .eq(ImMessageDO::getConversationId, conversationId)
                .orderByDesc(ImMessageDO::getSendTime)
                .last("LIMIT 1"));
    }

    /**
     * 根据发送者ID和接收者ID查询消息列表
     *
     * @param senderId 发送者ID
     * @param receiverId 接收者ID
     * @return 消息列表
     */
    default List<ImMessageDO> selectListBySenderIdAndReceiverId(Long senderId, Long receiverId) {
        return selectList(new LambdaQueryWrapperX<ImMessageDO>()
                .eq(ImMessageDO::getSenderId, senderId)
                .eq(ImMessageDO::getReceiverId, receiverId)
                .orderByDesc(ImMessageDO::getSendTime));
    }

    /**
     * 根据群ID查询消息列表
     *
     * @param groupId 群ID
     * @return 消息列表
     */
    default List<ImMessageDO> selectListByGroupId(Long groupId) {
        return selectList(new LambdaQueryWrapperX<ImMessageDO>()
                .eq(ImMessageDO::getGroupId, groupId)
                .orderByDesc(ImMessageDO::getSendTime));
    }

    /**
     * 根据会话ID和时间范围查询消息列表
     *
     * @param conversationId 会话ID
     * @param startTime 开始时间
     * @param endTime 结束时间
     * @return 消息列表
     */
    default List<ImMessageDO> selectListByConversationIdAndTimeRange(Long conversationId, LocalDateTime startTime, LocalDateTime endTime) {
        return selectList(new LambdaQueryWrapperX<ImMessageDO>()
                .eq(ImMessageDO::getConversationId, conversationId)
                .between(ImMessageDO::getSendTime, startTime, endTime)
                .orderByDesc(ImMessageDO::getSendTime));
    }

    /**
     * 根据会话ID和消息类型查询消息列表
     *
     * @param conversationId 会话ID
     * @param messageType 消息类型
     * @return 消息列表
     */
    default List<ImMessageDO> selectListByConversationIdAndType(Long conversationId, Integer messageType) {
        return selectList(new LambdaQueryWrapperX<ImMessageDO>()
                .eq(ImMessageDO::getConversationId, conversationId)
                .eq(ImMessageDO::getMessageType, messageType)
                .orderByDesc(ImMessageDO::getSendTime));
    }

    /**
     * 统计会话未读消息数量
     *
     * @param conversationId 会话ID
     * @param userId 用户ID
     * @return 未读消息数量
     */
    default Long selectUnreadCountByConversationIdAndUserId(Long conversationId, Long userId) {
        return selectCount(new LambdaQueryWrapperX<ImMessageDO>()
                .eq(ImMessageDO::getConversationId, conversationId)
                .eq(ImMessageDO::getReceiverId, userId)
                .ne(ImMessageDO::getStatus, 4)); // 状态不等于已读
    }

    /**
     * 批量更新消息状态（按接收者ID过滤）
     *
     * @param messageIds 消息ID列表
     * @param receiverId 接收者ID
     * @param status 新状态
     * @return 更新数量
     */
    default int updateStatusByIdsAndReceiverId(List<Long> messageIds, Long receiverId, Integer status) {
        ImMessageDO updateEntity = new ImMessageDO();
        updateEntity.setStatus(status);
        return update(updateEntity, new LambdaQueryWrapperX<ImMessageDO>()
                .in(ImMessageDO::getId, messageIds)
                .eq(ImMessageDO::getReceiverId, receiverId));
    }

    /**
     * 统计未读消息数（按接收者ID和目标ID）
     *
     * @param receiverId 接收者ID
     * @param targetId 目标ID（单聊用户ID或群组ID）
     * @param conversationType 会话类型
     * @return 未读消息数
     */
    default int countUnreadByReceiverIdAndTargetId(Long receiverId, Long targetId, Integer conversationType) {
        LambdaQueryWrapperX<ImMessageDO> wrapper = new LambdaQueryWrapperX<ImMessageDO>()
                .eq(ImMessageDO::getReceiverId, receiverId)
                .eq(ImMessageDO::getStatus, 0); // 0-未读
        
        // 根据会话类型添加条件
        if (conversationType == 1) {
            // 单聊：发送者ID = targetId
            wrapper.eq(ImMessageDO::getSenderId, targetId);
        } else if (conversationType == 2) {
            // 群聊：群组ID = targetId
            wrapper.eq(ImMessageDO::getGroupId, targetId);
        }
        
        return selectCount(wrapper).intValue();
    }

}
