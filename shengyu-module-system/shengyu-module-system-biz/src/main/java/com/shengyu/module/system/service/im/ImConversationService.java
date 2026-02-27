package com.shengyu.module.system.service.im;

import com.shengyu.module.system.controller.app.im.vo.conversation.AppImConversationCreateReqVO;
import com.shengyu.module.system.controller.app.im.vo.conversation.AppImConversationRespVO;
import com.shengyu.module.system.controller.app.im.vo.conversation.AppImConversationUpdateReqVO;
import com.shengyu.module.system.dal.dataobject.im.ImConversationDO;
import com.shengyu.module.system.dal.dataobject.im.ImMessageDO;

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
     * 更新会话的最后消息(使用消息对象)
     *
     * @param conversationId 会话ID
     * @param message 消息对象
     */
    void updateLastMessage(Long conversationId, ImMessageDO message);

    /**
     * 增加会话未读数
     *
     * @param conversationId 会话ID
     */
    void incrementUnreadCount(Long conversationId);

    /**
     * 增加会话未读数(指定增量)
     *
     * @param conversationId 会话ID
     * @param delta 增量
     */
    void incrementUnreadCount(Long conversationId, Integer delta);

    /**
     * 清空会话未读数
     *
     * @param conversationId 会话ID
     */
    void clearUnreadCount(Long conversationId);

    /**
     * 根据ID获取会话
     *
     * @param conversationId 会话ID
     * @return 会话DO
     */
    ImConversationDO getConversation(Long conversationId);

    /**
     * 根据目标ID和类型删除会话
     *
     * @param userId 用户ID
     * @param targetId 目标ID(单聊为对方用户ID,群聊为群ID)
     * @param conversationType 会话类型(1-单聊 2-群聊)
     */
    void deleteConversationByTarget(Long userId, Long targetId, Integer conversationType);


    /**
     * 获取用户的总未读数
     *
     * @param userId 用户ID
     * @return 总未读数
     */
    Integer getTotalUnreadCount(Long userId);

    /**
     * 获取用户的所有会话角标
     *
     * @param userId 用户ID
     * @return 会话角标列表
     */
    List<com.shengyu.framework.websocket.core.protocol.ConversationBadge> getConversationBadges(Long userId);

    /**
     * 获取会话详情
     *
     * @param userId 用户ID
     * @param conversationId 会话ID
     * @return 会话详情
     */
    AppImConversationRespVO getConversationDetail(Long userId, Long conversationId);

    /**
     * 获取或创建单聊会话
     *
     * @param userId 用户ID
     * @param targetUserId 对方用户ID
     * @return 会话信息
     */
    AppImConversationRespVO getOrCreateSingleConversation(Long userId, Long targetUserId);

    /**
     * 获取或创建群聊会话
     *
     * @param userId 用户ID
     * @param groupId 群组ID
     * @return 会话信息
     */
    AppImConversationRespVO getOrCreateGroupConversation(Long userId, Long groupId);

    /**
     * 置顶会话
     *
     * @param userId 用户ID
     * @param conversationId 会话ID
     * @param isPinned 是否置顶
     */
    void pinConversation(Long userId, Long conversationId, Boolean isPinned);

    /**
     * 设置免打扰
     *
     * @param userId 用户ID
     * @param conversationId 会话ID
     * @param noDisturb 是否免打扰
     */
    void setMute(Long userId, Long conversationId, Boolean noDisturb);

    /**
     * 保存草稿
     *
     * @param userId 用户ID
     * @param conversationId 会话ID
     * @param draft 草稿内容
     */
    void saveDraft(Long userId, Long conversationId, String draft);

    /**
     * 获取草稿
     *
     * @param userId 用户ID
     * @param conversationId 会话ID
     * @return 草稿内容
     */
    String getDraft(Long userId, Long conversationId);

    /**
     * 添加标签
     *
     * @param userId 用户ID
     * @param conversationId 会话ID
     * @param tag 标签
     */
    void addTag(Long userId, Long conversationId, String tag);

    /**
     * 移除标签
     *
     * @param userId 用户ID
     * @param conversationId 会话ID
     * @param tag 标签
     */
    void removeTag(Long userId, Long conversationId, String tag);

    /**
     * 获取会话标签列表
     *
     * @param userId 用户ID
     * @param conversationId 会话ID
     * @return 标签列表
     */
    List<String> getTags(Long userId, Long conversationId);

    /**
     * 按标签筛选会话
     *
     * @param userId 用户ID
     * @param tag 标签
     * @return 会话列表
     */
    List<AppImConversationRespVO> getConversationsByTag(Long userId, String tag);


}
