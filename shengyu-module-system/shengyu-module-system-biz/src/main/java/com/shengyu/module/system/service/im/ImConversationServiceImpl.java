package com.shengyu.module.system.service.im;

import cn.hutool.core.bean.BeanUtil;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.module.system.controller.app.im.vo.conversation.AppImConversationCreateReqVO;
import com.shengyu.module.system.controller.app.im.vo.conversation.AppImConversationRespVO;
import com.shengyu.module.system.controller.app.im.vo.conversation.AppImConversationUpdateReqVO;
import com.shengyu.module.system.dal.dataobject.im.ImConversationDO;
import com.shengyu.module.system.dal.dataobject.im.ImGroupDO;
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
    public void incrementUnreadCount(Long conversationId) {
        ImConversationDO conversation = conversationMapper.selectById(conversationId);
        if (conversation != null && !conversation.getNoDisturb()) {
            conversation.setUnreadCount(conversation.getUnreadCount() + 1);
            conversationMapper.updateById(conversation);
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

}
