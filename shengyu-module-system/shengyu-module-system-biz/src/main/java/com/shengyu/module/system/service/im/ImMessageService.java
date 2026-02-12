package com.shengyu.module.system.service.im;

import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.module.system.controller.app.im.vo.message.AppImMessagePageReqVO;
import com.shengyu.module.system.controller.app.im.vo.message.AppImMessageRespVO;
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

}
