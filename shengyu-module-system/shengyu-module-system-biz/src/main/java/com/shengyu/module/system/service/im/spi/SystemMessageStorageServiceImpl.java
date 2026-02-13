package com.shengyu.module.system.service.im.spi;

import com.google.protobuf.InvalidProtocolBufferException;
import com.shengyu.framework.websocket.core.protocol.*;
import com.shengyu.framework.websocket.core.service.MessageStorageService;
import com.shengyu.module.system.dal.dataobject.im.ImConversationDO;
import com.shengyu.module.system.dal.dataobject.im.ImMessageDO;
import com.shengyu.module.system.dal.mysql.im.ImConversationMapper;
import com.shengyu.module.system.dal.mysql.im.ImMessageMapper;
import com.shengyu.module.system.enums.im.ImConversationTypeEnum;
import com.shengyu.module.system.service.im.ImSequenceService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.annotation.Resource;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * System 模块 - 消息存储服务实现
 * 
 * 实现 WebSocket 中间件的 MessageStorageService SPI 接口
 * 负责将 WebSocket 接收到的消息持久化到数据库
 * 
 * 【高并发优化】
 * 1. 异步处理：消息保存和会话更新使用异步处理，不阻塞 Netty IO 线程
 * 2. 批量操作：支持批量插入消息（可扩展）
 * 3. 数据库优化：使用索引优化查询性能
 * 4. 缓存策略：会话信息可以缓存到 Redis（可扩展）
 * 5. 分库分表：消息表可以按用户ID或时间分片（可扩展）
 *
 * @author 圣钰科技
 */
@Service
@Slf4j
public class SystemMessageStorageServiceImpl implements MessageStorageService {

    @Resource
    private ImMessageMapper messageMapper;

    @Resource
    private ImConversationMapper conversationMapper;

    @Resource
    private ImSequenceService sequenceService;

    /**
     * 保存消息（同步方法，用于需要立即返回结果的场景）
     * 
     * 注意：此方法会阻塞 Netty IO 线程，仅在必要时使用
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void saveMessage(ImMessage message) {
        try {
            saveMessageWithId(message);
        } catch (Exception e) {
            log.error("[MessageStorage] 消息保存失败", e);
            // 不抛出异常，避免影响 WebSocket 连接
        }
    }

    /**
     * 保存消息并返回ID（同步方法）
     * 
     * 【性能优化】
     * 1. 使用雪花算法生成消息ID，避免数据库自增ID的性能瓶颈
     * 2. 序列号使用独立的序列生成器，支持分布式环境
     * 3. 会话更新异步处理，不阻塞消息保存
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long saveMessageWithId(ImMessage message) {
        MessageHeader header = message.getHeader();
        
        try {
            // 1. 生成序列号（已移除，不再需要）
            // Long sequence = sequenceService.generateMessageSequence();
            
            // 2. 解析消息内容
            String content = parseMessageContent(message);
            
            // 3. 转换为 DO 对象
            ImMessageDO messageDO = new ImMessageDO();
            messageDO.setId(header.getMessageId());
            messageDO.setMessageType(header.getMessageType().getNumber());
            messageDO.setSenderId(header.getSenderId());
            messageDO.setReceiverId(header.getReceiverId());
            messageDO.setGroupId(header.getGroupId());
            messageDO.setContent(content);
            messageDO.setExtra(header.getExtra());
            messageDO.setStatus(0); // 0-未读
            // messageDO.setSequence(sequence); // 已移除 sequence 字段
            
            // 4. 保存到数据库（使用批量插入可进一步优化）
            messageMapper.insert(messageDO);
            
            // 5. 异步更新会话信息（不阻塞消息保存）
            updateConversationAsync(header, messageDO);
            
            log.debug("[MessageStorage] 消息保存成功, messageId: {}, type: {}", 
                    header.getMessageId(), header.getMessageType());
            
            return messageDO.getId();
            
        } catch (Exception e) {
            log.error("[MessageStorage] 消息保存失败, messageId: {}", header.getMessageId(), e);
            throw e;
        }
    }

    /**
     * 解析消息内容
     * 
     * 根据消息类型解析 Protobuf 消息体
     */
    private String parseMessageContent(ImMessage message) {
        try {
            MessageType messageType = message.getHeader().getMessageType();
            
            switch (messageType) {
                case TEXT:
                    TextMessage textMsg = TextMessage.parseFrom(message.getBody());
                    return textMsg.getContent();
                    
                case IMAGE:
                    ImageMessage imageMsg = ImageMessage.parseFrom(message.getBody());
                    return imageMsg.getUrl();
                    
                case VOICE:
                    VoiceMessage voiceMsg = VoiceMessage.parseFrom(message.getBody());
                    return voiceMsg.getUrl();
                    
                case VIDEO:
                    VideoMessage videoMsg = VideoMessage.parseFrom(message.getBody());
                    return videoMsg.getUrl();
                    
                case FILE:
                    FileMessage fileMsg = FileMessage.parseFrom(message.getBody());
                    return fileMsg.getUrl();
                    
                case LOCATION:
                    LocationMessage locationMsg = LocationMessage.parseFrom(message.getBody());
                    return locationMsg.getAddress();
                    
                default:
                    // 其他类型直接返回 Base64 编码的字节
                    return message.getBody().toStringUtf8();
            }
        } catch (InvalidProtocolBufferException e) {
            log.error("[MessageStorage] 解析消息内容失败", e);
            return message.getBody().toStringUtf8();
        }
    }

    /**
     * 异步更新会话信息
     * 
     * 【性能优化】
     * 1. 使用 @Async 异步处理，不阻塞消息保存
     * 2. 使用独立的线程池处理会话更新
     * 3. 失败不影响消息保存
     * 
     * 说明：
     * 1. 新消息到达时，需要更新对应的会话
     * 2. 如果会话不存在，则创建新会话
     * 3. 更新会话的最后消息、未读数等信息
     */
    @Async("imTaskExecutor")
    public void updateConversationAsync(MessageHeader header, ImMessageDO messageDO) {
        try {
            // 单聊：更新发送者和接收者的会话
            if (header.getReceiverId() > 0) {
                // 更新接收者的会话（增加未读数）
                updateOrCreateConversation(
                        header.getReceiverId(),
                        header.getSenderId(),
                        ImConversationTypeEnum.SINGLE.getType(),
                        messageDO,
                        true
                );
                
                // 更新发送者的会话（不增加未读数）
                updateOrCreateConversation(
                        header.getSenderId(),
                        header.getReceiverId(),
                        ImConversationTypeEnum.SINGLE.getType(),
                        messageDO,
                        false
                );
            }
            // 群聊：更新所有群成员的会话
            else if (header.getGroupId() > 0) {
                // 群聊会话更新逻辑
                // 注意：群成员可能很多，这里需要优化
                // 方案1：使用消息队列异步处理
                // 方案2：使用批量更新SQL
                // 方案3：只更新发送者的会话，接收者的会话在拉取消息时更新
                log.debug("[MessageStorage] 群聊消息，groupId: {}, 需要更新群成员会话", header.getGroupId());
                
                // 这里简化处理，只更新发送者的会话
                updateOrCreateConversation(
                        header.getSenderId(),
                        header.getGroupId(),
                        ImConversationTypeEnum.GROUP.getType(),
                        messageDO,
                        false
                );
            }
        } catch (Exception e) {
            log.error("[MessageStorage] 更新会话失败", e);
            // 不抛出异常，避免影响消息保存
        }
    }

    /**
     * 更新或创建会话
     * 
     * 【性能优化】
     * 1. 使用唯一索引避免重复创建会话
     * 2. 使用乐观锁更新未读数
     * 3. 会话信息可以缓存到 Redis（可扩展）
     */
    @Transactional(rollbackFor = Exception.class)
    public void updateOrCreateConversation(Long userId, Long targetId, Integer conversationType, 
                                             ImMessageDO messageDO, boolean incrementUnread) {
        try {
            // 查询会话
            ImConversationDO conversation = conversationMapper.selectByUserIdAndTargetIdAndType(
                    userId, targetId, conversationType);
            
            if (conversation == null) {
                // 创建新会话
                conversation = new ImConversationDO();
                conversation.setUserId(userId);
                conversation.setTargetId(targetId);
                conversation.setConversationType(conversationType);
                conversation.setUnreadCount(incrementUnread ? 1 : 0);
                conversation.setLastMessageId(messageDO.getId());
                conversation.setLastMessageContent(truncateContent(messageDO.getContent()));
                conversation.setLastMessageTime(LocalDateTime.now());
                conversation.setIsPinned(false);
                conversation.setNoDisturb(false);
                conversation.setDeletedByUser(false);
                conversationMapper.insert(conversation);
            } else {
                // 更新会话
                conversation.setLastMessageId(messageDO.getId());
                conversation.setLastMessageContent(truncateContent(messageDO.getContent()));
                conversation.setLastMessageTime(LocalDateTime.now());
                
                // 增加未读数（如果不是发送者且未免打扰）
                if (incrementUnread && !conversation.getNoDisturb()) {
                    conversation.setUnreadCount(conversation.getUnreadCount() + 1);
                }
                
                // 如果会话被用户删除，则恢复
                if (conversation.getDeletedByUser()) {
                    conversation.setDeletedByUser(false);
                }
                
                conversationMapper.updateById(conversation);
            }
        } catch (Exception e) {
            log.error("[MessageStorage] 更新会话失败, userId: {}, targetId: {}", userId, targetId, e);
        }
    }

    /**
     * 截断消息内容（用于会话列表显示）
     */
    private String truncateContent(String content) {
        if (content == null) {
            return "";
        }
        if (content.length() > 100) {
            return content.substring(0, 100) + "...";
        }
        return content;
    }

    /**
     * 标记消息为已读
     * 
     * 【性能优化】
     * 1. 批量更新消息状态
     * 2. 只更新属于当前用户接收的消息
     * 3. 异步更新会话未读数
     * 
     * @param userId 用户ID
     * @param messageIds 消息ID列表
     */
    public void markMessagesAsRead(Long userId, List<Long> messageIds) {
        if (messageIds == null || messageIds.isEmpty()) {
            return;
        }

        try {
            // 1. 批量更新消息状态为已读
            int updatedCount = messageMapper.updateStatusByIdsAndReceiverId(messageIds, userId, 1);
            
            log.debug("[MessageStorage] 标记消息已读, userId: {}, messageCount: {}, updated: {}", 
                    userId, messageIds.size(), updatedCount);
            
            // 2. 异步更新会话未读数
            updateConversationUnreadCountAsync(userId);
            
        } catch (Exception e) {
            log.error("[MessageStorage] 标记消息已读失败, userId: {}", userId, e);
        }
    }

    /**
     * 异步更新会话未读数
     */
    @Async("imTaskExecutor")
    public void updateConversationUnreadCountAsync(Long userId) {
        try {
            // 重新计算所有会话的未读数
            List<ImConversationDO> conversations = conversationMapper.selectListByUserId(userId);
            
            for (ImConversationDO conversation : conversations) {
                // 查询该会话的未读消息数
                int unreadCount = messageMapper.countUnreadByReceiverIdAndTargetId(
                        userId, 
                        conversation.getTargetId(), 
                        conversation.getConversationType()
                );
                
                // 更新会话未读数
                if (conversation.getUnreadCount() != unreadCount) {
                    conversation.setUnreadCount(unreadCount);
                    conversationMapper.updateById(conversation);
                }
            }
            
            log.debug("[MessageStorage] 更新会话未读数完成, userId: {}", userId);
        } catch (Exception e) {
            log.error("[MessageStorage] 更新会话未读数失败, userId: {}", userId, e);
        }
    }

    /**
     * 根据消息ID列表查询发送者ID集合
     * 
     * 用于已读回执转发
     * 
     * @param messageIds 消息ID列表
     * @return 发送者ID集合
     */
    public Set<Long> getSenderIdsByMessageIds(List<Long> messageIds) {
        if (messageIds == null || messageIds.isEmpty()) {
            return Collections.emptySet();
        }

        try {
            List<ImMessageDO> messages = messageMapper.selectBatchIds(messageIds);
            return messages.stream()
                    .map(ImMessageDO::getSenderId)
                    .filter(Objects::nonNull)
                    .collect(Collectors.toSet());
        } catch (Exception e) {
            log.error("[MessageStorage] 查询发送者ID失败", e);
            return Collections.emptySet();
        }
    }

}
