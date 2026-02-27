package com.shengyu.module.system.service.im;

import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.module.system.controller.app.im.vo.message.AppImMessagePageReqVO;
import com.shengyu.module.system.controller.app.im.vo.message.AppImMessageRespVO;
import com.shengyu.module.system.controller.app.im.vo.message.AppImMessageSearchReqVO;
import com.shengyu.module.system.controller.app.im.vo.message.AppImMessageSendReqVO;

/**
 * IM 消息 Service 接口
 *
 * @author 圣钰科技
 */
public interface ImMessageService {

    /**
     * 发送消息(通过REST API)
     * 
     * 注意: 实际消息发送应该通过WebSocket,此接口主要用于离线消息发送或系统消息
     *
     * @param userId 发送者ID
     * @param sendReqVO 发送请求
     * @return 消息ID
     */
    Long sendMessage(Long userId, AppImMessageSendReqVO sendReqVO);

    /**
     * 分页查询会话消息列表
     *
     * @param userId 用户ID
     * @param pageReqVO 分页请求
     * @return 消息分页结果
     */
    PageResult<AppImMessageRespVO> getMessagePage(Long userId, AppImMessagePageReqVO pageReqVO);

    /**
     * 撤回消息
     *
     * @param userId 用户ID
     * @param messageId 消息ID
     */
    void recallMessage(Long userId, Long messageId);

    /**
     * 删除消息
     *
     * @param userId 用户ID
     * @param messageId 消息ID
     */
    void deleteMessage(Long userId, Long messageId);

    /**
     * 标记消息已读
     *
     * @param userId 用户ID
     * @param messageId 消息ID
     */
    void markMessageRead(Long userId, Long messageId);

    /**
     * 批量标记消息已读
     *
     * @param userId 用户ID
     * @param messageIds 消息ID列表
     */
    void markMessagesRead(Long userId, java.util.List<Long> messageIds);

    /**
     * 清空会话消息
     *
     * @param userId 用户ID
     * @param conversationId 会话ID
     */
    void clearConversationMessages(Long userId, Long conversationId);

    /**
     * 搜索聊天记录
     *
     * @param userId 用户ID
     * @param searchReqVO 搜索请求
     * @return 消息分页结果
     */
    PageResult<AppImMessageRespVO> searchMessages(Long userId, AppImMessageSearchReqVO searchReqVO);

    /**
     * 查询会话的消息列表（按时间倒序，支持分页加载）
     *
     * @param userId 用户ID
     * @param conversationId 会话ID
     * @param lastMessageId 最后一条消息ID（用于分页，首次查询传null）
     * @param pageSize 每页大小
     * @return 消息列表
     */
    java.util.List<AppImMessageRespVO> getConversationMessages(Long userId, Long conversationId, Long lastMessageId, Integer pageSize);

    /**
     * 获取消息详情
     *
     * @param userId 用户ID
     * @param messageId 消息ID
     * @return 消息详情
     */
    AppImMessageRespVO getMessageDetail(Long userId, Long messageId);

    /**
     * 更新消息状态
     *
     * @param userId 用户ID
     * @param messageId 消息ID
     * @param status 新状态
     */
    void updateMessageStatus(Long userId, Long messageId, Integer status);

    /**
     * 批量更新消息状态
     *
     * @param userId 用户ID
     * @param messageIds 消息ID列表
     * @param status 新状态
     */
    void batchUpdateMessageStatus(Long userId, java.util.List<Long> messageIds, Integer status);

    /**
     * 转发消息
     *
     * @param userId 用户ID
     * @param messageId 消息ID
     * @param targetConversationId 目标会话ID
     * @return 新消息ID
     */
    Long forwardMessage(Long userId, Long messageId, Long targetConversationId);

}
