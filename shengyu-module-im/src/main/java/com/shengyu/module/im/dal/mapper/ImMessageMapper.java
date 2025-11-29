package com.shengyu.module.im.dal.mapper;

import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.module.im.dal.dataobject.ImMessageDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * IM消息Mapper
 *
 * @author 圣钰科技
 */
@Mapper
public interface ImMessageMapper extends BaseMapperX<ImMessageDO> {

    /**
     * 获取单聊历史消息
     *
     * @param senderId   发送者ID
     * @param receiverId 接收者ID
     * @param limit      限制条数
     * @param offset     偏移量
     * @return 消息列表
     */
    default List<ImMessageDO> getSingleChatHistory(Long senderId, Long receiverId, Integer limit, Integer offset) {
        return selectList(new LambdaQueryWrapperX<ImMessageDO>()
                .eq(ImMessageDO::getSenderId, senderId)
                .eq(ImMessageDO::getReceiverId, receiverId)
                .orderByDesc(ImMessageDO::getCreateTime)
                .last("LIMIT " + limit + " OFFSET " + offset));
    }

    /**
     * 获取群聊历史消息
     *
     * @param groupId 群组ID
     * @param limit   限制条数
     * @param offset  偏移量
     * @return 消息列表
     */
    default List<ImMessageDO> getGroupChatHistory(Long groupId, Integer limit, Integer offset) {
        return selectList(new LambdaQueryWrapperX<ImMessageDO>()
                .eq(ImMessageDO::getReceiverId, groupId)
                .orderByDesc(ImMessageDO::getCreateTime)
                .last("LIMIT " + limit + " OFFSET " + offset));
    }

    /**
     * 获取用户未读消息
     *
     * @param userId 用户ID
     * @return 未读消息列表
     */
    default List<ImMessageDO> getUnreadMessages(Long userId) {
        return selectList(new LambdaQueryWrapperX<ImMessageDO>()
                .eq(ImMessageDO::getReceiverId, userId)
                .eq(ImMessageDO::getStatus, 0) // 0表示未读
                .orderByAsc(ImMessageDO::getCreateTime));
    }

    /**
     * 批量更新消息状态
     *
     * @param messageIds 消息ID列表
     * @param status     目标状态
     * @return 更新条数
     */
    default int batchUpdateStatus(List<String> messageIds, Integer status) {
        // 使用MyBatis-Plus的UpdateWrapper来实现动态SQL更新
        com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper<ImMessageDO> updateWrapper = new com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper<>();
        updateWrapper.in(ImMessageDO::getMessageId, messageIds)
                .set(ImMessageDO::getStatus, status);
        return update(null, updateWrapper);
    }
}
