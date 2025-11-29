package com.shengyu.module.im.service;

import com.shengyu.module.im.dal.dataobject.ImMessageDO;
import com.shengyu.module.im.dto.ImMessage;

import java.util.List;

/**
 * IM消息服务
 *
 * @author 圣钰科技
 */
public interface ImMessageService {

    /**
     * 保存消息
     *
     * @param message 消息对象
     * @return 保存后的消息ID
     */
    Long saveMessage(ImMessage message);

    /**
     * 获取单聊历史消息
     *
     * @param senderId   发送者ID
     * @param receiverId 接收者ID
     * @param limit      限制条数
     * @param offset     偏移量
     * @return 消息列表
     */
    List<ImMessageDO> getSingleChatHistory(Long senderId, Long receiverId, Integer limit, Integer offset);

    /**
     * 获取群聊历史消息
     *
     * @param groupId 群组ID
     * @param limit   限制条数
     * @param offset  偏移量
     * @return 消息列表
     */
    List<ImMessageDO> getGroupChatHistory(Long groupId, Integer limit, Integer offset);

    /**
     * 获取用户未读消息
     *
     * @param userId 用户ID
     * @return 未读消息列表
     */
    List<ImMessageDO> getUnreadMessages(Long userId);

    /**
     * 更新消息状态
     *
     * @param messageId 消息ID
     * @param status    目标状态
     * @return 是否更新成功
     */
    boolean updateMessageStatus(String messageId, Integer status);

    /**
     * 批量更新消息状态
     *
     * @param messageIds 消息ID列表
     * @param status     目标状态
     * @return 更新条数
     */
    int batchUpdateMessageStatus(List<String> messageIds, Integer status);

    /**
     * 删除消息
     *
     * @param messageId 消息ID
     * @return 是否删除成功
     */
    boolean deleteMessage(String messageId);

    /**
     * 撤回消息
     *
     * @param messageId 消息ID
     * @param senderId  发送者ID
     * @return 是否撤回成功
     */
    boolean recallMessage(String messageId, Long senderId);
}
