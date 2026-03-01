package com.shengyu.module.system.service.im;

import cn.hutool.core.bean.BeanUtil;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.framework.websocket.core.protocol.ConversationBadge;
import com.shengyu.module.system.controller.app.im.vo.conversation.AppImConversationCreateReqVO;
import com.shengyu.module.system.controller.app.im.vo.conversation.AppImConversationRespVO;
import com.shengyu.module.system.controller.app.im.vo.conversation.AppImConversationUpdateReqVO;
import com.shengyu.module.system.dal.dataobject.im.ImConversationDO;
import com.shengyu.module.system.dal.dataobject.im.ImGroupDO;
import com.shengyu.module.system.dal.dataobject.im.ImMessageDO;
import com.shengyu.module.system.dal.dataobject.user.AdminUserDO;
import com.shengyu.module.system.dal.mysql.im.ImConversationMapper;
import com.shengyu.module.system.dal.mysql.im.ImGroupMapper;
import com.shengyu.module.system.dal.mysql.user.AdminUserMapper;
import com.shengyu.module.system.enums.im.ImConversationTypeEnum;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.annotation.Resource;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

import static com.shengyu.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.shengyu.module.system.enums.ErrorCodeConstants.*;

/**
 * IM 会话 Service 实现类
 *
 * @author 圣钰科技
 */
@Service
@Slf4j
public class ImConversationServiceImpl implements ImConversationService {

    @Resource
    private ImConversationMapper conversationMapper;

    @Resource
    private ImGroupMapper groupMapper;

    @Resource
    private AdminUserMapper userMapper;

    @Override
    public List<AppImConversationRespVO> getConversationList(Long userId) {
        // 查询用户的所有会话
        List<ImConversationDO> conversations = conversationMapper.selectListByUserId(userId);
        
        // 排序会话列表: 置顶优先,按最后消息时间倒序
        conversations = sortConversations(conversations);
        
        // 转换为VO并填充目标信息
        return conversations.stream().map(conversation -> {
            AppImConversationRespVO respVO = BeanUtils.toBean(conversation, AppImConversationRespVO.class);
            fillTargetInfo(respVO, conversation);
            return respVO;
        }).collect(Collectors.toList());
    }

    @Override
    public List<AppImConversationRespVO> getConversationListByType(Long userId, Integer conversationType) {
        // 查询指定类型的会话
        List<ImConversationDO> conversations = conversationMapper.selectListByUserIdAndType(userId, conversationType);
        
        // 排序会话列表: 置顶优先,按最后消息时间倒序
        conversations = sortConversations(conversations);
        
        // 转换为VO并填充目标信息
        return conversations.stream().map(conversation -> {
            AppImConversationRespVO respVO = BeanUtils.toBean(conversation, AppImConversationRespVO.class);
            fillTargetInfo(respVO, conversation);
            return respVO;
        }).collect(Collectors.toList());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public AppImConversationRespVO createOrGetConversation(Long userId, AppImConversationCreateReqVO createReqVO) {
        log.info("[ImConversationService] 创建或获取会话, userId: {}, targetId: {}, type: {}", 
                userId, createReqVO.getTargetId(), createReqVO.getConversationType());

		// 参数校验（避免脏数据写入）
		if (createReqVO.getTargetId() == null || createReqVO.getConversationType() == null) {
			log.warn("[ImConversationService] 创建会话参数非法, userId: {}, targetId: {}, type: {}",
					userId, createReqVO.getTargetId(), createReqVO.getConversationType());
			throw exception(CONVERSATION_CREATE_FAILED);
		}
		if (!ImConversationTypeEnum.SINGLE.getType().equals(createReqVO.getConversationType())
				&& !ImConversationTypeEnum.GROUP.getType().equals(createReqVO.getConversationType())) {
			log.warn("[ImConversationService] 创建会话类型非法, userId: {}, targetId: {}, type: {}",
					userId, createReqVO.getTargetId(), createReqVO.getConversationType());
			throw exception(CONVERSATION_CREATE_FAILED);
		}
		if (ImConversationTypeEnum.GROUP.getType().equals(createReqVO.getConversationType())) {
			ImGroupDO group = groupMapper.selectById(createReqVO.getTargetId());
			if (group == null) {
				log.warn("[ImConversationService] 创建群聊会话失败，群组不存在, userId: {}, groupId: {}",
						userId, createReqVO.getTargetId());
				throw exception(GROUP_NOT_EXISTS);
			}
		} else {
			// 单聊：targetId 必须是对方用户 ID
			if (createReqVO.getTargetId().equals(userId)) {
				log.warn("[ImConversationService] 创建单聊会话失败，不能与自己创建会话, userId: {}", userId);
				throw exception(CONVERSATION_CREATE_FAILED);
			}
			AdminUserDO targetUser = userMapper.selectById(createReqVO.getTargetId());
			if (targetUser == null) {
				log.warn("[ImConversationService] 创建单聊会话失败，用户不存在, userId: {}, targetUserId: {}",
						userId, createReqVO.getTargetId());
				throw exception(USER_NOT_EXISTS);
			}
		}
        
        // 检查会话是否已存在
        ImConversationDO existConversation = conversationMapper.selectByUserIdAndTargetIdAndType(
                userId, createReqVO.getTargetId(), createReqVO.getConversationType());
        
        if (existConversation != null) {
            log.info("[ImConversationService] 会话已存在, conversationId: {}, deletedByUser: {}", 
                    existConversation.getId(), existConversation.getDeletedByUser());
            
            // 如果会话已存在且被用户删除,则恢复
            if (existConversation.getDeletedByUser()) {
                existConversation.setDeletedByUser(false);
                conversationMapper.updateById(existConversation);
                log.info("[ImConversationService] 恢复已删除的会话, conversationId: {}", existConversation.getId());
            }
            
            AppImConversationRespVO respVO = BeanUtils.toBean(existConversation, AppImConversationRespVO.class);
            fillTargetInfo(respVO, existConversation);
            return respVO;
        }

        // 创建新会话
        ImConversationDO conversation = new ImConversationDO();
        conversation.setUserId(userId);
        conversation.setTargetId(createReqVO.getTargetId());
        conversation.setConversationType(createReqVO.getConversationType());
        conversation.setUnreadCount(0);
        conversation.setIsPinned(false);
        conversation.setNoDisturb(false);
        conversation.setDeletedByUser(false);
        conversationMapper.insert(conversation);
        
        log.info("[ImConversationService] 创建新会话成功, conversationId: {}, userId: {}, targetId: {}, type: {}", 
                conversation.getId(), userId, createReqVO.getTargetId(), createReqVO.getConversationType());

        AppImConversationRespVO respVO = BeanUtils.toBean(conversation, AppImConversationRespVO.class);
        fillTargetInfo(respVO, conversation);
        return respVO;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateConversation(Long userId, AppImConversationUpdateReqVO updateReqVO) {
        // 查询会话
        ImConversationDO conversation = conversationMapper.selectById(updateReqVO.getId());
        if (conversation == null || !conversation.getUserId().equals(userId)) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }

        // 更新会话设置
        if (updateReqVO.getIsPinned() != null) {
            conversation.setIsPinned(updateReqVO.getIsPinned());
        }
        if (updateReqVO.getNoDisturb() != null) {
            conversation.setNoDisturb(updateReqVO.getNoDisturb());
        }
        conversationMapper.updateById(conversation);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteConversation(Long userId, Long conversationId) {
        // 查询会话
        ImConversationDO conversation = conversationMapper.selectById(conversationId);
        if (conversation == null || !conversation.getUserId().equals(userId)) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }

        // 标记为用户删除(软删除)
        conversation.setDeletedByUser(true);
        conversationMapper.updateById(conversation);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void markConversationRead(Long userId, Long conversationId) {
        // 查询会话
        ImConversationDO conversation = conversationMapper.selectById(conversationId);
        if (conversation == null || !conversation.getUserId().equals(userId)) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }

        // 清空未读数
        conversation.setUnreadCount(0);
        conversationMapper.updateById(conversation);
    }

    @Override
    public Integer getUnreadCount(Long userId) {
        return conversationMapper.selectUnreadCountByUserId(userId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateLastMessage(Long conversationId, Long messageId, String messageContent) {
        ImConversationDO conversation = conversationMapper.selectById(conversationId);
        if (conversation != null) {
            conversation.setLastMessageId(messageId);
            conversation.setLastMessageContent(messageContent);
            conversation.setLastMessageTime(LocalDateTime.now());
            conversationMapper.updateById(conversation);
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateLastMessage(Long conversationId, ImMessageDO message) {
        if (message == null) {
            return;
        }
        
        ImConversationDO conversation = conversationMapper.selectById(conversationId);
        if (conversation != null) {
            conversation.setLastMessageId(message.getId());
            conversation.setLastMessageContent(message.getContent());
            conversation.setLastMessageTime(message.getSendTime() != null ? message.getSendTime() : LocalDateTime.now());
            conversationMapper.updateById(conversation);
            
            log.info("[ImConversationService] 更新会话最后消息, conversationId: {}, messageId: {}", 
                    conversationId, message.getId());
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void incrementUnreadCount(Long conversationId) {
        incrementUnreadCount(conversationId, 1);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void incrementUnreadCount(Long conversationId, Integer delta) {
        if (delta == null || delta <= 0) {
            return;
        }
        
        ImConversationDO conversation = conversationMapper.selectById(conversationId);
        if (conversation != null && !conversation.getNoDisturb()) {
            conversation.setUnreadCount(conversation.getUnreadCount() + delta);
            conversationMapper.updateById(conversation);
            
            log.info("[ImConversationService] 增加会话未读数, conversationId: {}, delta: {}, newCount: {}", 
                    conversationId, delta, conversation.getUnreadCount());
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void clearUnreadCount(Long conversationId) {
        ImConversationDO conversation = conversationMapper.selectById(conversationId);
        if (conversation != null && conversation.getUnreadCount() > 0) {
            conversation.setUnreadCount(0);
            conversationMapper.updateById(conversation);
            
            log.info("[ImConversationService] 清空会话未读数, conversationId: {}", conversationId);
        }
    }

    @Override
    public ImConversationDO getConversation(Long conversationId) {
        return conversationMapper.selectById(conversationId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteConversationByTarget(Long userId, Long targetId, Integer conversationType) {
        // 查询会话
        ImConversationDO conversation = conversationMapper.selectByUserIdAndTargetIdAndType(userId, targetId, conversationType);
        if (conversation != null) {
            conversationMapper.deleteById(conversation.getId());
            log.info("[ImConversationService] 根据目标删除会话成功, userId: {}, targetId: {}, conversationType: {}", 
                    userId, targetId, conversationType);
        } else {
            log.warn("[ImConversationService] 会话不存在, userId: {}, targetId: {}, conversationType: {}", 
                    userId, targetId, conversationType);
        }
    }

    @Override
    public Integer getTotalUnreadCount(Long userId) {
        return conversationMapper.selectUnreadCountByUserId(userId);
    }

    @Override
    public List<ConversationBadge> getConversationBadges(Long userId) {
        // 查询用户的所有会话
        List<ImConversationDO> conversations = conversationMapper.selectListByUserId(userId);

        // 转换为 ConversationBadge 列表,只包含有未读消息的会话
        return conversations.stream()
                .filter(conv -> conv.getUnreadCount() != null && conv.getUnreadCount() > 0)
                .map(conv -> ConversationBadge.newBuilder()
                        .setConversationId(conv.getId())
                        .setUnreadCount(conv.getUnreadCount())
                        .build())
                .collect(Collectors.toList());
    }

    @Override
    public AppImConversationRespVO getConversationDetail(Long userId, Long conversationId) {
        // 查询会话
        ImConversationDO conversation = conversationMapper.selectById(conversationId);
        if (conversation == null || !conversation.getUserId().equals(userId)) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }

        // 转换为VO并填充目标信息
        AppImConversationRespVO respVO = BeanUtils.toBean(conversation, AppImConversationRespVO.class);
        fillTargetInfo(respVO, conversation);
        return respVO;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public AppImConversationRespVO getOrCreateSingleConversation(Long userId, Long targetUserId) {
        log.info("[ImConversationService] 获取或创建单聊会话, userId: {}, targetUserId: {}", userId, targetUserId);
        
        // 检查会话是否已存在
        ImConversationDO existConversation = conversationMapper.selectByUserIdAndTargetIdAndType(
                userId, targetUserId, ImConversationTypeEnum.SINGLE.getType());
        
        if (existConversation != null) {
            log.info("[ImConversationService] 单聊会话已存在, conversationId: {}, deletedByUser: {}", 
                    existConversation.getId(), existConversation.getDeletedByUser());
            
            // 如果会话已存在且被用户删除,则恢复
            if (existConversation.getDeletedByUser()) {
                existConversation.setDeletedByUser(false);
                conversationMapper.updateById(existConversation);
                log.info("[ImConversationService] 恢复已删除的单聊会话, conversationId: {}", existConversation.getId());
            }
            
            AppImConversationRespVO respVO = BeanUtils.toBean(existConversation, AppImConversationRespVO.class);
            fillTargetInfo(respVO, existConversation);
            return respVO;
        }

        // 创建新的单聊会话
        ImConversationDO conversation = new ImConversationDO();
        conversation.setUserId(userId);
        conversation.setTargetId(targetUserId);
        conversation.setConversationType(ImConversationTypeEnum.SINGLE.getType());
        conversation.setUnreadCount(0);
        conversation.setIsPinned(false);
        conversation.setNoDisturb(false);
        conversation.setDeletedByUser(false);
        conversationMapper.insert(conversation);
        
        log.info("[ImConversationService] 创建单聊会话成功, conversationId: {}, userId: {}, targetUserId: {}", 
                conversation.getId(), userId, targetUserId);

        AppImConversationRespVO respVO = BeanUtils.toBean(conversation, AppImConversationRespVO.class);
        fillTargetInfo(respVO, conversation);
        return respVO;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public AppImConversationRespVO getOrCreateGroupConversation(Long userId, Long groupId) {
        log.info("[ImConversationService] 获取或创建群聊会话, userId: {}, groupId: {}", userId, groupId);
        
        // 检查会话是否已存在
        ImConversationDO existConversation = conversationMapper.selectByUserIdAndTargetIdAndType(
                userId, groupId, ImConversationTypeEnum.GROUP.getType());
        
        if (existConversation != null) {
            log.info("[ImConversationService] 群聊会话已存在, conversationId: {}, deletedByUser: {}", 
                    existConversation.getId(), existConversation.getDeletedByUser());
            
            // 如果会话已存在且被用户删除,则恢复
            if (existConversation.getDeletedByUser()) {
                existConversation.setDeletedByUser(false);
                conversationMapper.updateById(existConversation);
                log.info("[ImConversationService] 恢复已删除的群聊会话, conversationId: {}", existConversation.getId());
            }
            
            AppImConversationRespVO respVO = BeanUtils.toBean(existConversation, AppImConversationRespVO.class);
            fillTargetInfo(respVO, existConversation);
            return respVO;
        }

        // 创建新的群聊会话
        ImConversationDO conversation = new ImConversationDO();
        conversation.setUserId(userId);
        conversation.setTargetId(groupId);
        conversation.setConversationType(ImConversationTypeEnum.GROUP.getType());
        conversation.setUnreadCount(0);
        conversation.setIsPinned(false);
        conversation.setNoDisturb(false);
        conversation.setDeletedByUser(false);
        conversationMapper.insert(conversation);
        
        log.info("[ImConversationService] 创建群聊会话成功, conversationId: {}, userId: {}, groupId: {}", 
                conversation.getId(), userId, groupId);

        AppImConversationRespVO respVO = BeanUtils.toBean(conversation, AppImConversationRespVO.class);
        fillTargetInfo(respVO, conversation);
        return respVO;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void pinConversation(Long userId, Long conversationId, Boolean isPinned) {
        // 查询会话
        ImConversationDO conversation = conversationMapper.selectById(conversationId);
        if (conversation == null || !conversation.getUserId().equals(userId)) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }

        // 更新置顶状态
        conversation.setIsPinned(isPinned);
        conversationMapper.updateById(conversation);
        
        log.info("[ImConversationService] 更新会话置顶状态, conversationId: {}, isPinned: {}", 
                conversationId, isPinned);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void setMute(Long userId, Long conversationId, Boolean noDisturb) {
        // 查询会话
        ImConversationDO conversation = conversationMapper.selectById(conversationId);
        if (conversation == null || !conversation.getUserId().equals(userId)) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }

        // 更新免打扰状态
        conversation.setNoDisturb(noDisturb);
        conversationMapper.updateById(conversation);
        
        log.info("[ImConversationService] 更新会话免打扰状态, conversationId: {}, noDisturb: {}", 
                conversationId, noDisturb);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void saveDraft(Long userId, Long conversationId, String draft) {
        // 查询会话
        ImConversationDO conversation = conversationMapper.selectById(conversationId);
        if (conversation == null || !conversation.getUserId().equals(userId)) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }

        // 保存草稿
        conversation.setDraft(draft);
        conversationMapper.updateById(conversation);
        
        log.info("[ImConversationService] 保存会话草稿, conversationId: {}, draftLength: {}", 
                conversationId, draft != null ? draft.length() : 0);
    }

    @Override
    public String getDraft(Long userId, Long conversationId) {
        // 查询会话
        ImConversationDO conversation = conversationMapper.selectById(conversationId);
        if (conversation == null || !conversation.getUserId().equals(userId)) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }

        return conversation.getDraft();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void addTag(Long userId, Long conversationId, String tag) {
        if (tag == null || tag.trim().isEmpty()) {
            return;
        }
        
        // 查询会话
        ImConversationDO conversation = conversationMapper.selectById(conversationId);
        if (conversation == null || !conversation.getUserId().equals(userId)) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }

        // 获取现有标签列表
        List<String> tags = getTags(userId, conversationId);
        
        // 如果标签已存在,不重复添加
        if (tags.contains(tag.trim())) {
            return;
        }
        
        // 添加新标签
        tags.add(tag.trim());
        conversation.setTags(String.join(",", tags));
        conversationMapper.updateById(conversation);
        
        log.info("[ImConversationService] 添加会话标签, conversationId: {}, tag: {}", conversationId, tag);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void removeTag(Long userId, Long conversationId, String tag) {
        if (tag == null || tag.trim().isEmpty()) {
            return;
        }
        
        // 查询会话
        ImConversationDO conversation = conversationMapper.selectById(conversationId);
        if (conversation == null || !conversation.getUserId().equals(userId)) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }

        // 获取现有标签列表
        List<String> tags = getTags(userId, conversationId);
        
        // 移除标签
        tags.remove(tag.trim());
        conversation.setTags(tags.isEmpty() ? null : String.join(",", tags));
        conversationMapper.updateById(conversation);
        
        log.info("[ImConversationService] 移除会话标签, conversationId: {}, tag: {}", conversationId, tag);
    }

    @Override
    public List<String> getTags(Long userId, Long conversationId) {
        // 查询会话
        ImConversationDO conversation = conversationMapper.selectById(conversationId);
        if (conversation == null || !conversation.getUserId().equals(userId)) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }

        // 解析标签列表
        if (conversation.getTags() == null || conversation.getTags().trim().isEmpty()) {
            return new java.util.ArrayList<>();
        }
        
        return java.util.Arrays.stream(conversation.getTags().split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .collect(Collectors.toList());
    }

    @Override
    public List<AppImConversationRespVO> getConversationsByTag(Long userId, String tag) {
        if (tag == null || tag.trim().isEmpty()) {
            return new java.util.ArrayList<>();
        }
        
        // 查询用户的所有会话
        List<ImConversationDO> conversations = conversationMapper.selectListByUserId(userId);
        
        // 筛选包含指定标签的会话
        List<ImConversationDO> filteredConversations = conversations.stream()
                .filter(conv -> {
                    if (conv.getTags() == null || conv.getTags().trim().isEmpty()) {
                        return false;
                    }
                    List<String> tags = java.util.Arrays.asList(conv.getTags().split(","));
                    return tags.stream().anyMatch(t -> t.trim().equals(tag.trim()));
                })
                .collect(Collectors.toList());
        
        // 排序会话列表
        filteredConversations = sortConversations(filteredConversations);
        
        // 转换为VO并填充目标信息
        return filteredConversations.stream().map(conversation -> {
            AppImConversationRespVO respVO = BeanUtils.toBean(conversation, AppImConversationRespVO.class);
            fillTargetInfo(respVO, conversation);
            return respVO;
        }).collect(Collectors.toList());
    }

    /**
     * 填充目标信息(对方名称、头像等)
     */
    private void fillTargetInfo(AppImConversationRespVO respVO, ImConversationDO conversation) {
        if (ImConversationTypeEnum.isSingle(conversation.getConversationType())) {
            // 单聊:查询对方用户信息
            AdminUserDO targetUser = userMapper.selectById(conversation.getTargetId());
            if (targetUser != null) {
                respVO.setTargetName(targetUser.getNickname());
                respVO.setTargetAvatar(targetUser.getAvatar());
            }
        } else if (ImConversationTypeEnum.isGroup(conversation.getConversationType())) {
            // 群聊:查询群组信息
            ImGroupDO group = groupMapper.selectById(conversation.getTargetId());
            if (group != null) {
                respVO.setTargetName(group.getName());
                respVO.setTargetAvatar(group.getAvatar());
                respVO.setGroupMemberCount(group.getMemberCount());
            }
        }
    }

    /**
     * 排序会话列表
     * 规则: 置顶会话在前,非置顶会话在后,同类会话按最后消息时间倒序
     *
     * @param conversations 会话列表
     * @return 排序后的会话列表
     */
    private List<ImConversationDO> sortConversations(List<ImConversationDO> conversations) {
        return conversations.stream()
                .sorted((c1, c2) -> {
                    // 1. 置顶优先: 置顶的会话排在前面
                    if (c1.getIsPinned() && !c2.getIsPinned()) {
                        return -1;
                    }
                    if (!c1.getIsPinned() && c2.getIsPinned()) {
                        return 1;
                    }
                    
                    // 2. 同类会话按最后消息时间倒序
                    LocalDateTime time1 = c1.getLastMessageTime();
                    LocalDateTime time2 = c2.getLastMessageTime();
                    
                    // 处理空值: 没有消息的会话排在后面
                    if (time1 == null && time2 == null) {
                        return 0;
                    }
                    if (time1 == null) {
                        return 1;
                    }
                    if (time2 == null) {
                        return -1;
                    }
                    
                    // 按时间倒序
                    return time2.compareTo(time1);
                })
                .collect(Collectors.toList());
    }

}
