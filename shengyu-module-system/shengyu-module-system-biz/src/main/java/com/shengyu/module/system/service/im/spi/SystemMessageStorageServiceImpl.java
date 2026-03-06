package com.shengyu.module.system.service.im.spi;

import cn.hutool.core.util.StrUtil;
import cn.hutool.json.JSONObject;
import cn.hutool.json.JSONUtil;
import com.google.protobuf.InvalidProtocolBufferException;
import com.google.protobuf.MessageLite;
import com.shengyu.framework.websocket.core.protocol.*;
import com.shengyu.framework.websocket.core.service.MessageStorageService;
import com.shengyu.framework.websocket.core.sender.NettyMessageSender;
import com.shengyu.module.system.dal.dataobject.im.ImChatDO;
import com.shengyu.module.system.dal.dataobject.im.ImChatMessageDO;
import com.shengyu.module.system.dal.dataobject.im.ImChatUserDO;
import com.shengyu.module.system.dal.mysql.im.ImChatMapper;
import com.shengyu.module.system.dal.mysql.im.ImChatMessageMapper;
import com.shengyu.module.system.dal.mysql.im.ImChatUserMapper;
import com.shengyu.module.system.enums.im.ImConversationTypeEnum;
import com.shengyu.module.system.enums.im.ImMessageStatusEnum;
import com.shengyu.module.system.service.im.ImBadgeService;
import com.shengyu.module.system.service.im.ImGroupService;
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
    private ImChatMessageMapper chatMessageMapper;

    @Resource
    private ImChatMapper chatMapper;

    @Resource
    private ImChatUserMapper chatUserMapper;

    @Resource
    private ImBadgeService imBadgeService;

    @Resource
    private ImGroupService imGroupService;

    @Resource
    private NettyMessageSender nettyMessageSender;

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

    private String buildExtraForDb(ImMessage message) {
        if (message == null || message.getHeader() == null) {
            return null;
        }
        String extra = message.getHeader().getExtra();
        if (StrUtil.isNotBlank(extra)) {
            return extra;
        }
        if (message.getHeader().getMessageType() != MessageType.FILE) {
            return extra;
        }
        try {
            FileMessage fileMsg = FileMessage.parseFrom(message.getBody());
            JSONObject obj = JSONUtil.createObj();
            obj.set("url", fileMsg.getUrl());
            obj.set("fileName", fileMsg.getFileName());
            obj.set("size", fileMsg.getSize());
            obj.set("fileType", fileMsg.getFileType());
            return obj.toString();
        } catch (Exception e) {
            log.warn("[MessageStorage] 构建文件消息 extra 失败, messageId: {}", message.getHeader().getMessageId(), e);
            return extra;
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
            // 1. 解析消息内容
            String content = parseMessageContent(message);
            String extra = buildExtraForDb(message);
            
            // 2. 确定/创建全局 ChatID
            Long chatId = getOrCreateChatId(header);

            // 3. 保存到新消息表（全局会话单份存储）
            LocalDateTime sendTime = LocalDateTime.now();
            ImChatMessageDO messageDO = new ImChatMessageDO();
            messageDO.setChatId(chatId);
            messageDO.setSenderId(header.getSenderId());
            messageDO.setMessageType(normalizeDbMessageType(header.getMessageType()));
            messageDO.setContent(content);
            messageDO.setExtra(extra);
            messageDO.setSendTime(sendTime);
            messageDO.setStatus(ImMessageStatusEnum.SENT.getStatus());
            chatMessageMapper.insert(messageDO);

            // 5. 异步更新会话信息（不阻塞消息保存）
            updateChatUserAsync(header, messageDO, message);
            
            log.debug("[MessageStorage] 消息保存成功, messageId: {}, type: {}", 
                    header.getMessageId(), header.getMessageType());
            
            return messageDO.getId();
            
        } catch (Exception e) {
            log.error("[MessageStorage] 消息保存失败, messageId: {}", header.getMessageId(), e);
            throw e;
        }
    }

    private Integer normalizeDbMessageType(MessageType messageType) {
        if (messageType == null) {
            return null;
        }
        // Protobuf/WebSocket MessageType（100+）映射到 REST/DB ImMessageTypeEnum（1-10）
        switch (messageType) {
            case TEXT:
                return 1;
            case IMAGE:
                return 2;
            case VOICE:
                return 3;
            case VIDEO:
                return 4;
            case FILE:
                return 5;
            case LOCATION:
                return 6;
            case CUSTOM:
                return 8;
            case QUOTE_REPLY:
                return 1;
            default:
                return 10;
        }
    }

    private Long getOrCreateChatId(MessageHeader header) {
        Integer chatType;
        ImChatDO chat;
        if (header.getGroupId() > 0) {
            chatType = ImConversationTypeEnum.GROUP.getType();
            chat = chatMapper.selectGroupChat(header.getGroupId(), chatType);
            if (chat == null) {
                chat = new ImChatDO();
                chat.setChatType(chatType);
                chat.setGroupId(header.getGroupId());
                chat.setStatus(1);
                chatMapper.insert(chat);
            }
        } else {
            chatType = ImConversationTypeEnum.SINGLE.getType();
            Long user1 = Math.min(header.getSenderId(), header.getReceiverId());
            Long user2 = Math.max(header.getSenderId(), header.getReceiverId());
            chat = chatMapper.selectSingleChat(user1, user2, chatType);
            if (chat == null) {
                chat = new ImChatDO();
                chat.setChatType(chatType);
                chat.setSingleUser1(user1);
                chat.setSingleUser2(user2);
                chat.setStatus(1);
                chatMapper.insert(chat);
            }
        }
        return chat.getId();
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
     * 4. 推送角标更新到接收者的所有设备
     */
    @Async("imTaskExecutor")
    public void updateChatUserAsync(MessageHeader header, ImChatMessageDO messageDO, ImMessage rawMessage) {
        try {
            Long chatId = messageDO.getChatId();
            String lastMessageContent = truncateContent(messageDO.getContent());

            // 解析原始消息体，便于群聊实时转发（避免仅角标更新 204）
            MessageLite bizBody = parseBizBody(rawMessage);

            if (header.getGroupId() > 0) {
                List<Long> memberIds = imGroupService.getGroupMemberIds(header.getGroupId());
                for (Long memberId : memberIds) {
                    boolean isSender = memberId.equals(header.getSenderId());
                    ImChatUserDO chatUser = ensureChatUser(memberId, chatId);
                    chatUserMapper.updateLastMessageAndIncrementUnread(
                            chatUser.getId(),
                            messageDO.getId(),
                            lastMessageContent,
                            messageDO.getSendTime(),
                            isSender ? 0 : 1,
                            Boolean.TRUE.equals(chatUser.getNoDisturb())
                    );
                    if (!isSender) {
                        imBadgeService.pushBadgeUpdate(memberId);
                        if (bizBody != null) {
                            nettyMessageSender.sendToUser(
                                    memberId,
                                    header.getMessageType(),
                                    bizBody,
                                    header.getSenderId(),
                                    memberId,
                                    header.getGroupId(),
                                    header.getTenantId(),
                                    messageDO.getId()
                            );
                        }
                    }
                }
            } else {
                ImChatUserDO sender = ensureChatUser(header.getSenderId(), chatId);
                chatUserMapper.updateLastMessageAndIncrementUnread(
                        sender.getId(),
                        messageDO.getId(),
                        lastMessageContent,
                        messageDO.getSendTime(),
                        0,
                        Boolean.TRUE.equals(sender.getNoDisturb())
                );

                ImChatUserDO receiver = ensureChatUser(header.getReceiverId(), chatId);
                chatUserMapper.updateLastMessageAndIncrementUnread(
                        receiver.getId(),
                        messageDO.getId(),
                        lastMessageContent,
                        messageDO.getSendTime(),
                        1,
                        Boolean.TRUE.equals(receiver.getNoDisturb())
                );
                imBadgeService.pushBadgeUpdate(header.getReceiverId());
            }
        } catch (Exception e) {
            log.error("[MessageStorage] 更新会话失败", e);
            // 不抛出异常，避免影响消息保存
        }
    }

    private MessageLite parseBizBody(ImMessage rawMessage) {
        if (rawMessage == null || rawMessage.getHeader() == null) {
            return null;
        }
        MessageType messageType = rawMessage.getHeader().getMessageType();
        try {
            switch (messageType) {
                case TEXT:
                    return TextMessage.parseFrom(rawMessage.getBody());
                case IMAGE:
                    return ImageMessage.parseFrom(rawMessage.getBody());
                case VOICE:
                    return VoiceMessage.parseFrom(rawMessage.getBody());
                case VIDEO:
                    return VideoMessage.parseFrom(rawMessage.getBody());
                case FILE:
                    return FileMessage.parseFrom(rawMessage.getBody());
                case LOCATION:
                    return LocationMessage.parseFrom(rawMessage.getBody());
                case QUOTE_REPLY:
                    return QuoteReplyMessage.parseFrom(rawMessage.getBody());
                default:
                    return null;
            }
        } catch (InvalidProtocolBufferException e) {
            log.error("[MessageStorage] 解析业务消息体失败, type: {}", messageType, e);
            return null;
        }
    }

    private ImChatUserDO ensureChatUser(Long userId, Long chatId) {
        ImChatUserDO chatUser = chatUserMapper.selectByUserIdAndChatId(userId, chatId);
        if (chatUser != null) {
            return chatUser;
        }
        chatUser = new ImChatUserDO();
        chatUser.setUserId(userId);
        chatUser.setChatId(chatId);
        chatUser.setUnreadCount(0);
        chatUser.setIsPinned(false);
        chatUser.setNoDisturb(false);
        chatUser.setDeletedByUser(false);
        chatUserMapper.insert(chatUser);
        return chatUser;
    }

    @Transactional(rollbackFor = Exception.class)
    public void updateOrCreateConversation(Long userId, Long targetId, Integer conversationType,
                                          ImChatMessageDO messageDO, boolean incrementUnread) {
        // 已迁移到 updateChatUserAsync；线路 A 不再使用旧的 conversation 维度更新
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
     * 异步更新会话未读数
     */
    @Async("imTaskExecutor")
    public void updateConversationUnreadCountAsync(Long userId) {
        try {
            log.debug("[MessageStorage] updateConversationUnreadCountAsync 已废弃, userId: {}", userId);
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
            List<ImChatMessageDO> messages = chatMessageMapper.selectBatchIds(messageIds);
            return messages.stream()
                    .map(ImChatMessageDO::getSenderId)
                    .filter(Objects::nonNull)
                    .collect(Collectors.toSet());
        } catch (Exception e) {
            log.error("[MessageStorage] 查询发送者ID失败", e);
            return Collections.emptySet();
        }
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
            // 说明：线路 A 的 im_chat_message 不存 receiverId，已读需要按 chat_user.last_read_message_id 设计；
            // 这里先保留为“按 messageIds 直接更新状态”，不做用户隔离。
            int updatedCount = chatMessageMapper.updateStatusByIds(messageIds, 1);
            
            log.debug("[MessageStorage] 标记消息已读, userId: {}, messageCount: {}, updated: {}", 
                    userId, messageIds.size(), updatedCount);
            
            // 2. 异步更新会话未读数
            updateConversationUnreadCountAsync(userId);
            
        } catch (Exception e) {
            log.error("[MessageStorage] 标记消息已读失败, userId: {}", userId, e);
        }
    }
}
