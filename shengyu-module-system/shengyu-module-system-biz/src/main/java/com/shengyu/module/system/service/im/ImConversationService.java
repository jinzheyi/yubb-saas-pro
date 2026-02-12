package com.shengyu.module.system.service.im;

import com.shengyu.module.system.controller.app.im.vo.conversation.AppImConversationCreateReqVO;
import com.shengyu.module.system.controller.app.im.vo.conversation.AppImConversationRespVO;
import com.shengyu.module.system.controller.app.im.vo.conversation.AppImConversationUpdateReqVO;
import com.shengyu.module.system.dal.dataobject.im.ImConversationDO;

import java.util.List;

/**
 * IM 会话 Service 接口
 *
 * @author 圣钰科技
 */
public interface ImConversationService {

    /**
     * 获取用户的会话列表
     *
     * @param userId 用户ID
     * @return 会话列表
     */
    List<AppImConversationRespVO> getConversationList(Long userId);

    /**
     * 获取用户的会话列表(按类型筛选)
     *
     * @param userId 用户ID
     * @param conversationType 会话类型(1-单聊 2-群聊)
     * @return 会话列表
     */
    List<AppImConversationRespVO> getConversationListByType(Long userId, Integer conversationType);

    /**
     * 创建或获取会话
     *
     * @param userId 用户ID
     * @param createReqVO 创建请求
     * @return 会话信息
     */
    AppImConversationRespVO createOrGetConversation(Long userId, AppImConversationCreateReqVO createReqVO);

    /**
     * 更新会话设置
     *
     * @param userId 用户ID
     * @param updateReqVO 更新请求
     */
    void updateConversation(Long userId, AppImConversationUpdateReqVO updateReqVO);

    /**
     * 删除会话
     *
     * @param userId 用户ID
     * @param conversationId 会话ID
     */
    void deleteConversation(Long userId, Long conversationId);

    /**
     * 标记会话已读
     *
     * @param userId 用户ID
     * @param conversationId 会话ID
     */
    void markConversationRead(Long userId, Long conversationId);

    /**
     * 获取用户未读消息总数
     *
     * @param userId 用户ID
     * @return 未读消息总数
     */
    Integer getUnreadCount(Long userId);

    /**
     * 更新会话的最后消息
     *
     * @param conversationId 会话ID
     * @param messageId 消息ID
     * @param messageContent 消息内容
     */
    void updateLastMessage(Long conversationId, Long messageId, String messageContent);

    /**
     * 增加会话未读数
     *
     * @param conversationId 会话ID
     */
    void incrementUnreadCount(Long conversationId);

    /**
     * 根据ID获取会话
     *
     * @param conversationId 会话ID
     * @return 会话DO
     */
    ImConversationDO getConversation(Long conversationId);

}
