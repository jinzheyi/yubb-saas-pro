package com.shengyu.module.system.service.im;

import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.module.system.controller.app.im.vo.conversation.AppImConversationCreateReqVO;
import com.shengyu.module.system.controller.app.im.vo.conversation.AppImConversationRespVO;
import com.shengyu.module.system.controller.app.im.vo.conversation.AppImConversationSearchReqVO;
import com.shengyu.module.system.controller.app.im.vo.conversation.AppImConversationSyncRespVO;
import com.shengyu.module.system.controller.app.im.vo.conversation.AppImConversationUpdateReqVO;

import java.util.List;

/**
 * IM 会话 Service 接口
 *
 * @author 圣钰科技
 */
public interface ImConversationService {

    /**
     * 获取用户的会话列表（支持分页）
     *
     * @param userId 用户ID
     * @param pageNo 页码
     * @param pageSize 每页数量
     * @return 会话列表
     */
    List<AppImConversationRespVO> getConversationList(Long userId, Integer pageNo, Integer pageSize);

    /**
     * 获取用户的会话列表(按类型筛选)
     *
     * @param userId 用户ID
     * @param conversationType 会话类型(1-单聊 2-群聊)
     * @return 会话列表
     */
    List<AppImConversationRespVO> getConversationListByType(Long userId, Integer conversationType);

    /**
     * 会话搜索（仅返回当前用户可见会话）
     *
     * @param userId 用户ID
     * @param searchReqVO 搜索请求
     * @return 会话分页结果
     */
    PageResult<AppImConversationRespVO> searchConversations(Long userId, AppImConversationSearchReqVO searchReqVO);

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
     * @param chatId ChatID
     */
    void deleteConversation(Long userId, Long chatId);

    /**
     * 标记会话已读（按 sequence 水位推进，单调递增）
     *
     * @param userId 用户ID
     * @param chatId ChatID
     * @param readSequence 已读 sequence 水位
     */
    void markConversationReadBySequence(Long userId, Long chatId, Long readSequence);

    /**
     * 获取单个会话的未读数
     *
     * @param userId 用户ID
     * @param chatId 会话ID
     * @return 未读数
     */
    Integer getConversationUnreadCount(Long userId, Long chatId);

    /**
     * 获取用户未读消息总数
     *
     * @param userId 用户ID
     * @return 未读消息总数
     */
    Integer getUnreadCount(Long userId);

    /**
     * 会话增量同步（cursorVersion 版）
     *
     * @param userId 用户ID
     * @param cursorVersion 同步游标（用户维度版本号），首次可传 null/0
     * @param limit 拉取条数
     * @return 增量同步结果
     */
    AppImConversationSyncRespVO syncConversations(Long userId, Long cursorVersion, Integer limit);

    /**
     * 更新会话的最后消息
     *
     * @param chatId ChatID
     * @param messageId 消息ID
     * @param messageContent 消息内容
     */
    void updateLastMessage(Long chatId, Long messageId, String messageContent);

    /**
     * 增加会话未读数
     *
     * @param chatId ChatID
     */
    void incrementUnreadCount(Long chatId);

    /**
     * 增加会话未读数(指定增量)
     *
     * @param chatId ChatID
     * @param delta 增量
     */
    void incrementUnreadCount(Long chatId, Integer delta);

    /**
     * 根据ID获取会话（已废弃，保留接口兼容性）
     *
     * @param chatId ChatID
     * @return 始终返回 null，Route-A 使用 chatId 直接操作
     */
    default Object getConversation(Long chatId) {
        return null;
    }

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
     * @param chatId ChatID
     * @return 会话详情
     */
    AppImConversationRespVO getConversationDetail(Long userId, Long chatId);

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
     * @param chatId ChatID
     * @param isPinned 是否置顶
     */
    void pinConversation(Long userId, Long chatId, Boolean isPinned);

    /**
     * 设置免打扰
     *
     * @param userId 用户ID
     * @param chatId ChatID
     * @param noDisturb 是否免打扰
     */
    void setMute(Long userId, Long chatId, Boolean noDisturb);

    /**
     * 保存草稿
     *
     * @param userId 用户ID
     * @param chatId ChatID
     * @param draft 草稿内容
     */
    void saveDraft(Long userId, Long chatId, String draft);

    /**
     * 获取草稿
     *
     * @param userId 用户ID
     * @param chatId ChatID
     * @return 草稿内容
     */
    String getDraft(Long userId, Long chatId);

    /**
     * 添加标签
     *
     * @param userId 用户ID
     * @param chatId ChatID
     * @param tag 标签
     */
    void addTag(Long userId, Long chatId, String tag);

    /**
     * 移除标签
     *
     * @param userId 用户ID
     * @param chatId ChatID
     * @param tag 标签
     */
    void removeTag(Long userId, Long chatId, String tag);

    /**
     * 获取会话标签列表
     *
     * @param userId 用户ID
     * @param chatId ChatID
     * @return 标签列表
     */
    List<String> getTags(Long userId, Long chatId);

    /**
     * 按标签筛选会话
     *
     * @param userId 用户ID
     * @param tag 标签
     * @return 会话列表
     */
    List<AppImConversationRespVO> getConversationsByTag(Long userId, String tag);


}
