package com.shengyu.module.system.service.im.spi;

import cn.hutool.core.util.IdUtil;
import cn.hutool.core.util.StrUtil;
import cn.hutool.json.JSONObject;
import cn.hutool.json.JSONUtil;
import com.google.protobuf.InvalidProtocolBufferException;
import com.google.protobuf.MessageLite;
import com.shengyu.framework.common.exception.util.ServiceExceptionUtil;
import com.shengyu.framework.tenant.core.context.TenantContextHolder;
import com.shengyu.framework.websocket.core.protocol.*;
import com.shengyu.framework.websocket.core.sender.NettyMessageSender;
import com.shengyu.framework.websocket.core.service.MessageStorageService;
import com.shengyu.framework.websocket.core.service.dto.MessageSaveResult;
import com.shengyu.module.infra.api.file.FileApi;
import com.shengyu.module.infra.api.file.dto.FileDTO;
import com.shengyu.module.system.dal.dataobject.im.ImChatDO;
import com.shengyu.module.system.dal.dataobject.im.ImChatMessageDO;
import com.shengyu.module.system.dal.dataobject.im.ImChatUserDO;
import com.shengyu.module.system.dal.dataobject.im.ImGroupDO;
import com.shengyu.module.system.dal.dataobject.im.ImGroupUserDO;
import com.shengyu.module.system.dal.dataobject.user.AdminUserDO;
import com.shengyu.module.system.dal.mysql.im.ImChatMapper;
import com.shengyu.module.system.dal.mysql.im.ImChatMessageMapper;
import com.shengyu.module.system.dal.mysql.im.ImChatUserMapper;
import com.shengyu.module.system.dal.mysql.im.ImConversationUserStateMapper;
import com.shengyu.module.system.dal.mysql.im.ImGroupMapper;
import com.shengyu.module.system.dal.mysql.im.ImGroupUserMapper;
import com.shengyu.module.system.dal.mysql.user.AdminUserMapper;
import com.shengyu.module.system.dal.redis.im.LargeGroupUnreadRedisDAO;
import com.shengyu.module.system.enums.im.ImConversationTypeEnum;
import com.shengyu.module.system.enums.im.ImGroupMemberRoleEnum;
import com.shengyu.module.system.enums.im.ImMessageStatusEnum;
import com.shengyu.module.system.service.im.ConversationSnapshotService;
import com.shengyu.module.system.service.im.ImBadgeService;
import com.shengyu.module.system.service.im.ImCursorVersionService;
import com.shengyu.module.system.service.im.ImGroupService;
import com.shengyu.module.system.service.im.push.ImNotificationEventPublisher;
import com.shengyu.module.system.service.im.support.VoiceFileOwnershipValidator;
import lombok.extern.slf4j.Slf4j;
import org.apache.ibatis.session.ExecutorType;
import org.apache.ibatis.session.SqlSession;
import org.apache.ibatis.session.SqlSessionFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.annotation.Resource;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

import static com.shengyu.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.shengyu.module.system.enums.ErrorCodeConstants.GROUP_MEMBER_MUTED;
import static com.shengyu.module.system.enums.ErrorCodeConstants.GROUP_MUTED_ALL;
import static com.shengyu.module.system.enums.ErrorCodeConstants.GROUP_NOT_EXISTS;
import static com.shengyu.module.system.enums.ErrorCodeConstants.GROUP_PERMISSION_DENIED;
import static com.shengyu.module.system.enums.ErrorCodeConstants.NOT_GROUP_MEMBER;

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
    private static final long MAX_VOICE_SIZE_BYTES = 10L * 1024 * 1024;
    private static final long MAX_VOICE_DURATION_MS = 60000L;

    /**
     * 大群阈值：群成员数 >= 此值时采用读扩散模型
     */
    private static final int LARGE_GROUP_THRESHOLD = 100;


    @Resource
    private ImChatMessageMapper chatMessageMapper;

    @Resource
    private ImChatMapper chatMapper;

    @Resource
    private ImChatUserMapper chatUserMapper;

    @Resource
    private ImConversationUserStateMapper conversationUserStateMapper;

    @Resource
    private ImBadgeService imBadgeService;

    @Resource
    private ImGroupService imGroupService;

    @Resource
    private ImGroupMapper groupMapper;

    @Resource
    private ImGroupUserMapper groupUserMapper;

    @Resource
    private AdminUserMapper userMapper;

    @Resource
    private ImCursorVersionService cursorVersionService;

    @Resource
    private NettyMessageSender nettyMessageSender;

    @Resource
    private FileApi fileApi;

    @Resource
    private LargeGroupUnreadRedisDAO largeGroupUnreadRedisDAO;

    @Resource
    private SqlSessionFactory sqlSessionFactory;

    @Resource
    private ConversationSnapshotService conversationSnapshotService;

    @Resource
    private ImNotificationEventPublisher imNotificationEventPublisher;

    /**
     * 是否启用会话快照 Redis 缓存（默认 false）
     * 设置为 true 时，小群写扩散场景先写 Redis，由定时任务批量合并到 MySQL
     */
    @Value("${im.snapshot-cache-enabled:false}")
    private boolean snapshotCacheEnabled;

    private static class MentionParseResult {
        private boolean atAll;
        private Set<Long> userIds;
    }

    private void validateMentionRange(String content, String nickname, int startIndex, int endIndex) {
        if (content == null || endIndex <= 0) {
            return;
        }
        if (startIndex < 0 || endIndex <= startIndex || endIndex > content.length()) {
            throw ServiceExceptionUtil.invalidParamException("mentions 索引越界");
        }
        String expected = "@" + StrUtil.nullToEmpty(nickname);
        if (StrUtil.isBlank(expected.trim())) {
            throw ServiceExceptionUtil.invalidParamException("mentions.nickname 不能为空");
        }
        String actual = content.substring(startIndex, endIndex);
        if (!StrUtil.equals(actual, expected)) {
            throw ServiceExceptionUtil.invalidParamException("mentions 与消息内容不匹配");
        }
    }

    private void validateMentionUserId(Long mentionedUserId, List<Long> memberIds) {
        if (mentionedUserId == null) {
            throw ServiceExceptionUtil.invalidParamException("mentions.userId 不能为空");
        }
        if (mentionedUserId == -1L) {
            return;
        }
        if (mentionedUserId <= 0) {
            throw ServiceExceptionUtil.invalidParamException("mentions.userId 非法");
        }
        if (memberIds == null || !memberIds.contains(mentionedUserId)) {
            throw ServiceExceptionUtil.invalidParamException("被@用户不在群成员列表中");
        }
    }

    private void validateGroupMentions(ImMessage message, String content) throws InvalidProtocolBufferException {
        if (message == null || message.getHeader() == null) {
            return;
        }
        MessageHeader header = message.getHeader();
        if (header.getGroupId() <= 0) {
            return;
        }
        MessageType messageType = header.getMessageType();
        if (messageType != MessageType.TEXT && messageType != MessageType.QUOTE_REPLY) {
            return;
        }
        List<MentionUser> mentions = Collections.emptyList();
        List<Long> atUserIds = Collections.emptyList();
        if (messageType == MessageType.TEXT) {
            TextMessage textMessage = TextMessage.parseFrom(message.getBody());
            mentions = textMessage.getMentionsList();
            atUserIds = textMessage.getAtUserIdsList();
        } else if (messageType == MessageType.QUOTE_REPLY) {
            QuoteReplyMessage quoteReplyMessage = QuoteReplyMessage.parseFrom(message.getBody());
            mentions = quoteReplyMessage.getMentionsList();
            atUserIds = quoteReplyMessage.getAtUserIdsList();
        }
        if ((mentions == null || mentions.isEmpty()) && (atUserIds == null || atUserIds.isEmpty())) {
            return;
        }
        List<Long> memberIds = imGroupService.getGroupMemberIds(header.getGroupId());
        if (memberIds == null || !memberIds.contains(header.getSenderId())) {
            throw exception(NOT_GROUP_MEMBER);
        }
        Integer senderRole = imGroupService.getMemberRole(header.getGroupId(), header.getSenderId());
        boolean atAll = false;
        Set<Long> mentionedUserIds = new HashSet<>();
        if (mentions != null) {
            for (MentionUser mention : mentions) {
                if (mention == null) {
                    continue;
                }
                validateMentionRange(content, mention.getNickname(), mention.getStartIndex(), mention.getEndIndex());
                validateMentionUserId(mention.getUserId(), memberIds);
                if (mention.getUserId() == -1L) {
                    atAll = true;
                    continue;
                }
                mentionedUserIds.add(mention.getUserId());
            }
        }
        if (atUserIds != null) {
            for (Long atUserId : atUserIds) {
                validateMentionUserId(atUserId, memberIds);
                if (atUserId != null && atUserId == -1L) {
                    atAll = true;
                    continue;
                }
                if (atUserId != null) {
                    mentionedUserIds.add(atUserId);
                }
            }
        }
        if (atAll && (senderRole == null
                || (!ImGroupMemberRoleEnum.isOwner(senderRole) && !ImGroupMemberRoleEnum.isAdmin(senderRole)))) {
            throw exception(GROUP_PERMISSION_DENIED);
        }
    }

    private void validateGroupSendPermission(MessageHeader header) {
        if (header == null || header.getGroupId() <= 0 || header.getSenderId() <= 0) {
            return;
        }

        ImGroupDO group = groupMapper.selectById(header.getGroupId());
        if (group == null) {
            throw exception(GROUP_NOT_EXISTS);
        }

        ImGroupUserDO groupMember = groupUserMapper.selectByGroupIdAndUserId(header.getGroupId(), header.getSenderId());
        if (groupMember == null) {
            throw exception(NOT_GROUP_MEMBER);
        }

        LocalDateTime now = LocalDateTime.now();
        if (groupMember.getMuteEndTime() != null && groupMember.getMuteEndTime().isAfter(now)) {
            throw exception(GROUP_MEMBER_MUTED);
        }

        if (Boolean.TRUE.equals(group.getMuteAll())
                && !ImGroupMemberRoleEnum.isOwner(groupMember.getRole())
                && !ImGroupMemberRoleEnum.isAdmin(groupMember.getRole())) {
            throw exception(GROUP_MUTED_ALL);
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void markMessagesRead(Long userId, List<Long> messageIds) {
        if (userId == null || messageIds == null || messageIds.isEmpty()) {
            return;
        }

        List<ImChatMessageDO> messages = chatMessageMapper.selectBatchIds(messageIds);
        if (messages == null || messages.isEmpty()) {
            return;
        }

        List<Long> filteredIds = new ArrayList<>();
        for (ImChatMessageDO m : messages) {
            if (m == null || m.getId() == null || m.getChatId() == null) {
                continue;
            }
            ImChatUserDO chatUser = chatUserMapper.selectAnyByUserIdAndChatId(userId, m.getChatId());
            if (chatUser == null) {
                continue;
            }
            filteredIds.add(m.getId());
        }
        if (filteredIds.isEmpty()) {
            return;
        }

        chatMessageMapper.updateStatusByIds(filteredIds, ImMessageStatusEnum.READ.getStatus());
    }

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

    @Override
    public List<Long> batchSaveMessages(List<ImMessage> messages) {
        if (messages == null || messages.isEmpty()) {
            return Collections.emptyList();
        }

        SqlSession batchSession = null;
        try {
            batchSession = sqlSessionFactory.openSession(ExecutorType.BATCH, false);
            ImChatMessageMapper batchMapper = batchSession.getMapper(ImChatMessageMapper.class);

            for (ImMessage msg : messages) {
                MessageHeader header = msg.getHeader();
                try {
                    Long chatId = getOrCreateChatId(header);
                    validateVoiceMessageOwnership(msg, chatId);
                    validateGroupSendPermission(header);
                    String content = parseMessageContent(msg);
                    validateGroupMentions(msg, content);
                    String extra = buildExtraForDb(msg);
                    String mentionsJson = buildMentionsForDb(msg);
                    Long quoteMessageId = parseQuoteMessageId(msg);

                    Long sequence = chatMapper.nextSequence(chatId);

                    LocalDateTime sendTime = LocalDateTime.now();
                    ImChatMessageDO messageDO = new ImChatMessageDO();
                    if (header.getMessageId() > 0) {
                        messageDO.setId(header.getMessageId());
                    }
                    messageDO.setChatId(chatId);
                    messageDO.setSequence(sequence);
                    messageDO.setSenderId(header.getSenderId());
                    messageDO.setMessageType(normalizeDbMessageType(header.getMessageType()));
                    messageDO.setContent(content);
                    messageDO.setExtra(extra);
                    messageDO.setMentions(mentionsJson);
                    if (quoteMessageId != null && quoteMessageId > 0) {
                        messageDO.setQuoteMessageId(quoteMessageId);
                    }
                    messageDO.setSendTime(sendTime);
                    messageDO.setRev(1L);
                    messageDO.setStatus(ImMessageStatusEnum.SENT.getStatus());

                    batchMapper.insert(messageDO);
                } catch (Exception e) {
                    log.error("[MessageStorage] 批量保存单条消息失败, messageId: {}",
                            header != null ? header.getMessageId() : "null", e);
                    // 继续处理下一条消息
                }
            }
            batchSession.commit();
            batchSession.clearCache();

            log.info("[MessageStorage] 批量保存消息完成, total: {}", messages.size());

            return messages.stream()
                    .filter(m -> m != null && m.getHeader() != null)
                    .map(m -> m.getHeader().getMessageId())
                    .collect(Collectors.toList());
        } finally {
            if (batchSession != null) {
                batchSession.close();
            }
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public MessageSaveResult saveMessageWithResult(ImMessage message) {
        MessageHeader header = message.getHeader();
        Long id = saveMessageWithId(message);
        Long chatId = getOrCreateChatId(header);
        ImChatMessageDO existing = chatMessageMapper.selectById(id);
        Long seq = existing != null ? existing.getSequence() : null;
        return MessageSaveResult.builder()
                .messageId(id)
                .chatId(chatId)
                .sequence(seq)
                .build();
    }

    private String buildExtraForDb(ImMessage message) {
        if (message == null || message.getHeader() == null) {
            return null;
        }
        String extra = message.getHeader().getExtra();
        if (StrUtil.isNotBlank(extra)) {
            return extra;
        }
        if (message.getHeader().getMessageType() == MessageType.QUOTE_REPLY) {
            try {
                QuoteReplyMessage quoteMsg = QuoteReplyMessage.parseFrom(message.getBody());
                JSONObject obj = JSONUtil.createObj();
                if (quoteMsg.getQuoteMessageId() > 0) {
                    obj.set("quoteMessageId", String.valueOf(quoteMsg.getQuoteMessageId()));
                }
                if (StrUtil.isNotBlank(quoteMsg.getQuoteContent())) {
                    obj.set("quoteContent", quoteMsg.getQuoteContent());
                }
                if (StrUtil.isNotBlank(quoteMsg.getQuoteSenderName())) {
                    obj.set("quoteSenderName", quoteMsg.getQuoteSenderName());
                }
                if (quoteMsg.getQuoteSenderId() > 0) {
                    obj.set("quoteSenderId", quoteMsg.getQuoteSenderId());
                }
                return obj.isEmpty() ? null : obj.toString();
            } catch (Exception e) {
                return null;
            }
        }
        try {
            if (message.getHeader().getMessageType() == MessageType.VOICE) {
                return extra;
            }
            if (message.getHeader().getMessageType() == MessageType.IMAGE) {
                ImageMessage imageMsg = ImageMessage.parseFrom(message.getBody());
                JSONObject obj = JSONUtil.createObj();
                obj.set("url", imageMsg.getUrl());
                obj.set("thumbnailUrl", imageMsg.getThumbnailUrl());
                obj.set("width", imageMsg.getWidth());
                obj.set("height", imageMsg.getHeight());
                obj.set("size", imageMsg.getSize());
                if (StrUtil.isNotBlank(imageMsg.getFileName())) {
                    obj.set("fileName", imageMsg.getFileName());
                }
                return obj.toString();
            }
            if (message.getHeader().getMessageType() == MessageType.FILE) {
                FileMessage fileMsg = FileMessage.parseFrom(message.getBody());
                JSONObject obj = JSONUtil.createObj();
                obj.set("url", fileMsg.getUrl());
                obj.set("fileName", fileMsg.getFileName());
                obj.set("size", fileMsg.getSize());
                obj.set("fileType", fileMsg.getFileType());
                return obj.toString();
            }
        } catch (Exception e) {
            log.warn("[MessageStorage] 构建媒体消息 extra 失败, messageId: {}", message.getHeader().getMessageId(), e);
        }
        return extra;
    }

    private Long parseQuoteMessageId(ImMessage message) {
        if (message == null || message.getHeader() == null) {
            return null;
        }
        if (message.getHeader().getMessageType() != MessageType.QUOTE_REPLY) {
            return null;
        }
        try {
            QuoteReplyMessage quoteMsg = QuoteReplyMessage.parseFrom(message.getBody());
            long id = quoteMsg.getQuoteMessageId();
            return id > 0 ? id : null;
        } catch (Exception e) {
            return null;
        }
    }

    private String buildMentionsForDb(ImMessage message) {
        if (message == null || message.getHeader() == null) {
            return null;
        }
        MessageType type = message.getHeader().getMessageType();
        try {
            List<MentionUser> mentions;
            List<Long> atUserIds;
            if (type == MessageType.TEXT) {
                TextMessage textMsg = TextMessage.parseFrom(message.getBody());
                mentions = textMsg.getMentionsList();
                atUserIds = textMsg.getAtUserIdsList();
            } else if (type == MessageType.QUOTE_REPLY) {
                QuoteReplyMessage quoteMsg = QuoteReplyMessage.parseFrom(message.getBody());
                mentions = quoteMsg.getMentionsList();
                atUserIds = quoteMsg.getAtUserIdsList();
            } else {
                return null;
            }

            List<JSONObject> arr = new ArrayList<>();
            if (mentions != null && !mentions.isEmpty()) {
                for (MentionUser mu : mentions) {
                    if (mu == null) {
                        continue;
                    }
                    JSONObject obj = JSONUtil.createObj();
                    obj.set("userId", mu.getUserId());
                    obj.set("nickname", mu.getNickname());
                    obj.set("startIndex", mu.getStartIndex());
                    obj.set("endIndex", mu.getEndIndex());
                    arr.add(obj);
                }
            } else if (atUserIds != null && !atUserIds.isEmpty()) {
                for (Long atUserId : atUserIds) {
                    if (atUserId == null || atUserId <= 0 && atUserId != -1L) {
                        continue;
                    }
                    JSONObject obj = JSONUtil.createObj();
                    obj.set("userId", atUserId);
                    obj.set("nickname", atUserId == -1L ? "所有人" : "");
                    obj.set("startIndex", 0);
                    obj.set("endIndex", 0);
                    arr.add(obj);
                }
            }
            if (arr.isEmpty()) {
                return null;
            }
            return JSONUtil.toJsonStr(arr);
        } catch (Exception e) {
            return null;
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
            Long chatId = getOrCreateChatId(header);
            validateVoiceMessageOwnership(message, chatId);
            validateGroupSendPermission(header);
            String content = parseMessageContent(message);
            validateGroupMentions(message, content);
            String extra = buildExtraForDb(message);
            String mentionsJson = buildMentionsForDb(message);
            Long quoteMessageId = parseQuoteMessageId(message);

            // 2.1 分配会话内 sequence（单调递增）
            Long sequence = chatMapper.nextSequence(chatId);

            // 3. 保存到新消息表（全局会话单份存储）
            LocalDateTime sendTime = LocalDateTime.now();
            ImChatMessageDO messageDO = new ImChatMessageDO();
            if (header.getMessageId() > 0) {
                messageDO.setId(header.getMessageId());
            }
            messageDO.setChatId(chatId);
            messageDO.setSequence(sequence);
            messageDO.setSenderId(header.getSenderId());
            messageDO.setMessageType(normalizeDbMessageType(header.getMessageType()));
            messageDO.setContent(content);
            messageDO.setExtra(extra);
            messageDO.setMentions(mentionsJson);
            if (quoteMessageId != null && quoteMessageId > 0) {
                messageDO.setQuoteMessageId(quoteMessageId);
            }
            messageDO.setSendTime(sendTime);
            messageDO.setRev(1L);
            messageDO.setStatus(ImMessageStatusEnum.SENT.getStatus());
            try {
                chatMessageMapper.insert(messageDO);
            } catch (DuplicateKeyException e) {
                // 幂等：同一 messageId 重投时，直接返回既有记录
                if (header.getMessageId() > 0) {
                    ImChatMessageDO existing = chatMessageMapper.selectById(header.getMessageId());
                    if (existing != null) {
                        return existing.getId();
                    }
                }
                throw e;
            }

            // 5. 异步更新会话信息（不阻塞消息保存）
            updateChatUserAsync(header, messageDO, message);
            // Network delivery is intentionally deferred until this transaction
            // commits.  The event includes no message body or credentials.
            imNotificationEventPublisher.publishMessageCommitted(
                    header.getTenantId(), header.getSenderId(), header.getGroupId(),
                    header.getReceiverId(), chatId, messageDO.getId(),
                    messageDO.getSendTime().atZone(java.time.ZoneId.systemDefault()).toInstant().toEpochMilli());
            
            log.debug("[MessageStorage] 消息保存成功, messageId: {}, type: {}", 
                    header.getMessageId(), header.getMessageType());
            
            return messageDO.getId();
            
        } catch (Exception e) {
            log.error("[MessageStorage] 消息保存失败, messageId: {}", header.getMessageId(), e);
            if (e instanceof RuntimeException) {
                throw (RuntimeException) e;
            }
            throw new RuntimeException(e);
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
                return 9;
            case QUOTE_REPLY:
                return 1;
            default:
                return 10;
        }
    }

    private Long getOrCreateChatId(MessageHeader header) {
        Long tenantId = TenantContextHolder.getTenantId();
        if (tenantId == null) {
            tenantId = 0L;
        }
        if (header.getGroupId() > 0) {
            Integer chatType = ImConversationTypeEnum.GROUP.getType();
            chatMapper.insertGroupChatIfAbsent(tenantId, IdUtil.getSnowflakeNextId(), chatType, header.getGroupId(), 1);
            ImChatDO chat = chatMapper.selectGroupChat(header.getGroupId(), chatType);
            return chat != null ? chat.getId() : null;
        } else {
            Integer chatType = ImConversationTypeEnum.SINGLE.getType();
            Long user1 = Math.min(header.getSenderId(), header.getReceiverId());
            Long user2 = Math.max(header.getSenderId(), header.getReceiverId());
            chatMapper.insertSingleChatIfAbsent(tenantId, IdUtil.getSnowflakeNextId(), chatType, user1, user2, 1);
            ImChatDO chat = chatMapper.selectSingleChat(user1, user2, chatType);
            return chat != null ? chat.getId() : null;
        }
    }

    private void validateVoiceMessageOwnership(ImMessage message, Long chatId) {
        if (message == null || message.getHeader() == null || message.getHeader().getMessageType() != MessageType.VOICE) {
            return;
        }
        String extraRaw = message.getHeader().getExtra();
        if (StrUtil.isBlank(extraRaw)) {
            throw ServiceExceptionUtil.invalidParamException("VOICE message extra is required: fileId/duration/durationMs/size/format");
        }
        try {
            JSONObject obj = JSONUtil.parseObj(extraRaw);
            Long fileId = obj.getLong("fileId", null);
            Long size = obj.getLong("size", null);
            Integer duration = obj.getInt("duration", null);
            Long durationMs = obj.getLong("durationMs", null);
            String format = obj.getStr("format", "");
            if (fileId == null || fileId <= 0L || size == null || size <= 0L
                    || duration == null || duration <= 0 || durationMs == null || durationMs <= 0L
                    || StrUtil.isBlank(format)) {
                throw ServiceExceptionUtil.invalidParamException("VOICE message extra must contain fileId/duration/durationMs/size/format");
            }
            if (durationMs < 1000L || durationMs > MAX_VOICE_DURATION_MS) {
                throw ServiceExceptionUtil.invalidParamException("VOICE duration must be between 1000ms and 60000ms");
            }
            int normalizedDuration = (int) Math.max(1L, Math.round(durationMs / 1000.0d));
            if (duration.intValue() != normalizedDuration) {
                throw ServiceExceptionUtil.invalidParamException("VOICE duration does not match durationMs");
            }
            if (size > MAX_VOICE_SIZE_BYTES) {
                throw ServiceExceptionUtil.invalidParamException("VOICE size cannot exceed 10MB");
            }
            if (!isAllowedVoiceFormat(format)) {
                throw ServiceExceptionUtil.invalidParamException("VOICE format only supports mp3/aac/m4a/amr/wav");
            }

            VoiceMessage voiceMessage = VoiceMessage.parseFrom(message.getBody());
            if (voiceMessage.getDuration() != duration.intValue()) {
                throw ServiceExceptionUtil.invalidParamException("VOICE body duration does not match extra duration");
            }
            if (voiceMessage.getSize() != size.longValue()) {
                throw ServiceExceptionUtil.invalidParamException("VOICE body size does not match extra size");
            }

            FileDTO fileDTO = fileApi.getFile(fileId);
            if (fileDTO == null) {
                throw ServiceExceptionUtil.invalidParamException("VOICE fileId does not exist: {}", fileId);
            }
            Long groupId = message.getHeader().getGroupId() > 0 ? message.getHeader().getGroupId() : null;
            VoiceFileOwnershipValidator.validate(fileDTO, message.getHeader().getSenderId(), chatId, groupId);
            if (fileDTO.getSize() != null && fileDTO.getSize() > 0 && fileDTO.getSize().longValue() != size.longValue()) {
                throw ServiceExceptionUtil.invalidParamException("VOICE size does not match uploaded file record");
            }
            if (StrUtil.isNotBlank(fileDTO.getType()) && !isAllowedVoiceFormat(fileDTO.getType())) {
                throw ServiceExceptionUtil.invalidParamException("VOICE file type is invalid: {}", fileDTO.getType());
            }
        } catch (RuntimeException ex) {
            throw ex;
        } catch (InvalidProtocolBufferException ex) {
            throw ServiceExceptionUtil.invalidParamException("VOICE body is invalid: {}", ex.getMessage());
        } catch (Exception ex) {
            throw ServiceExceptionUtil.invalidParamException("VOICE extra must be valid JSON: {}", ex.getMessage());
        }
    }

    private boolean isAllowedVoiceFormat(String format) {
        if (StrUtil.isBlank(format)) {
            return false;
        }
        String normalized = format.trim().toLowerCase(Locale.ROOT);
        return "mp3".equals(normalized)
                || "aac".equals(normalized)
                || "m4a".equals(normalized)
                || "amr".equals(normalized)
                || "wav".equals(normalized)
                || "audio/mpeg".equals(normalized)
                || "audio/mp3".equals(normalized)
                || "audio/aac".equals(normalized)
                || "audio/x-aac".equals(normalized)
                || "audio/mp4".equals(normalized)
                || "audio/m4a".equals(normalized)
                || "audio/x-m4a".equals(normalized)
                || "audio/amr".equals(normalized)
                || "audio/wav".equals(normalized)
                || "audio/x-wav".equals(normalized)
                || "audio/wave".equals(normalized);
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

                case QUOTE_REPLY:
                    QuoteReplyMessage quoteMsg = QuoteReplyMessage.parseFrom(message.getBody());
                    return quoteMsg.getReplyContent();
                    
                case IMAGE:
                    ImageMessage imageMsg = ImageMessage.parseFrom(message.getBody());
                    return imageMsg.getUrl();
                    
                case VOICE:
                    return "[语音]";
                    
                case VIDEO:
                    VideoMessage videoMsg = VideoMessage.parseFrom(message.getBody());
                    return videoMsg.getUrl();
                    
                case FILE:
                    FileMessage fileMsg = FileMessage.parseFrom(message.getBody());
                    return fileMsg.getUrl();
                    
                case LOCATION:
                    LocationMessage locationMsg = LocationMessage.parseFrom(message.getBody());
                    JSONObject locationObj = JSONUtil.createObj();
                    locationObj.set("latitude", locationMsg.getLatitude());
                    locationObj.set("longitude", locationMsg.getLongitude());
                    locationObj.set("address", locationMsg.getAddress());
                    try {
                        String extra = message.getHeader() != null ? message.getHeader().getExtra() : "";
                        if (StrUtil.isNotBlank(extra)) {
                            JSONObject extraObj = JSONUtil.parseObj(extra);
                            String name = extraObj.getStr("name", extraObj.getStr("locationName", ""));
                            if (StrUtil.isNotBlank(name)) {
                                locationObj.set("name", name);
                            }
                            String provider = extraObj.getStr("provider", "");
                            if (StrUtil.isNotBlank(provider)) {
                                locationObj.set("provider", provider);
                            }
                            String mapUrl = extraObj.getStr("mapUrl", "");
                            if (StrUtil.isNotBlank(mapUrl)) {
                                locationObj.set("mapUrl", mapUrl);
                            }
                        }
                    } catch (Exception ignore) {
                        // ignore invalid extra, keep body baseline
                    }
                    return locationObj.toString();
                    
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
            if (header == null) {
                return;
            }
            Long chatId = messageDO.getChatId();
            Long tenantId = header.getTenantId();
            String basePreview = buildConversationPreview(header, messageDO, rawMessage);
            String lastMessageContent = truncateContent(basePreview);

            MentionParseResult mentionParsed = parseMentions(rawMessage);

            // 群聊：摘要需要带发送者（对标企微/钉钉）
            String senderName = "";
            if (header.getGroupId() > 0
                    && header.getMessageType() != MessageType.BADGE_UPDATE
                    && header.getMessageType() != MessageType.READ_RECEIPT) {
                try {
                    if (userMapper != null && header.getSenderId() > 0) {
                        AdminUserDO user = userMapper.selectById(header.getSenderId());
                        senderName = user != null && StrUtil.isNotBlank(user.getNickname()) ? user.getNickname() : "";
                    }
                } catch (Exception ignore) {
                    senderName = "";
                }
            }

            // 解析原始消息体，便于群聊实时转发（避免仅角标更新 204）
            MessageLite bizBody = parseBizBody(rawMessage);

            // enterprise: extra must carry rev for final-state merge; merge with file metadata when needed
            String extraWithRev = null;
            try {
                JSONObject obj = StrUtil.isNotBlank(messageDO.getExtra()) ? JSONUtil.parseObj(messageDO.getExtra()) : JSONUtil.createObj();
                obj.set("rev", 1);
                extraWithRev = obj.toString();
            } catch (Exception e) {
                try {
                    JSONObject obj = JSONUtil.createObj();
                    obj.set("rev", 1);
                    extraWithRev = obj.toString();
                } catch (Exception ignore) {
                    extraWithRev = null;
                }
            }

            if (header.getGroupId() > 0) {
                List<Long> memberIds = imGroupService.getGroupMemberIds(header.getGroupId());
                if (memberIds == null || memberIds.isEmpty()) {
                    return;
                }

                // 【混合扇出模型】区分群规模，小群用写扩散，大群用读扩散
                if (memberIds.size() >= LARGE_GROUP_THRESHOLD) {
                    // 大群：采用读扩散模型（消息状态写入 Redis，定时任务合并到 MySQL）
                    updateChatUserAsyncForLargeGroup(tenantId, chatId, header.getSenderId(), memberIds, messageDO, mentionParsed);
                } else {
                    // 小群/单聊：保持现有的写扩散（遍历成员逐推）
                    updateChatUserAsyncForSmallGroup(header, chatId, tenantId, memberIds, messageDO, rawMessage,
                            basePreview, senderName, mentionParsed, bizBody, extraWithRev);
                }
            } else {
                // 单聊：发送者侧添加"我:"前缀，接收者侧保持原样
                String senderPreview = buildSingleChatPreview(lastMessageContent);
                String receiverPreview = lastMessageContent;

                ImChatUserDO sender = ensureChatUser(header.getSenderId(), chatId);
                chatUserMapper.updateLastMessageAndIncrementUnread(
                        sender.getId(),
                        messageDO.getId(),
                        messageDO.getSequence(),
                        messageDO.getMessageType(),
                        senderPreview,
                        messageDO.getSendTime(),
                        0,
                        Boolean.TRUE.equals(sender.getNoDisturb()),
                        header.getSenderId()
                );

                Long senderCursorVersion = cursorVersionService.allocateNextCursorVersion(tenantId, header.getSenderId());
                conversationUserStateMapper.upsertAfterMessageForSender(
                        tenantId,
                        chatId,
                        header.getSenderId(),
                        senderCursorVersion,
                        messageDO.getSequence(),
                        messageDO.getSendTime(),
                        messageDO.getId(),
                        messageDO.getSequence(),
                        header.getSenderId(),
                        messageDO.getMessageType(),
                        senderPreview,
                        false,
                        messageDO.getSendTime()
                );

				// 发送者侧：持久化推进已读水位，避免重登后自己的消息出现未读角标
				if (messageDO.getSequence() != null) {
					try {
						chatUserMapper.markReadToSequence(header.getSenderId(), chatId, messageDO.getSequence());
					} catch (Exception ignore) {
						// ignore
					}
				}

                ImChatUserDO receiver = ensureChatUser(header.getReceiverId(), chatId);
                chatUserMapper.updateLastMessageAndIncrementUnread(
                        receiver.getId(),
                        messageDO.getId(),
                        messageDO.getSequence(),
                        messageDO.getMessageType(),
                        receiverPreview,
                        messageDO.getSendTime(),
                        1,
                        Boolean.TRUE.equals(receiver.getNoDisturb()),
                        header.getSenderId()
                );

                Long receiverCursorVersion = cursorVersionService.allocateNextCursorVersion(tenantId, header.getReceiverId());
                conversationUserStateMapper.upsertAfterMessage(
                        tenantId,
                        chatId,
                        header.getReceiverId(),
                        receiverCursorVersion,
                        1,
                        0L,
                        null,
                        messageDO.getId(),
                        messageDO.getSequence(),
                        header.getSenderId(),
                        messageDO.getMessageType(),
                        receiverPreview,
                        false,
                        messageDO.getSendTime()
                );
                imBadgeService.pushIncrementalBadgeUpdate(header.getReceiverId(), chatId, 1);

                // 单聊接收方实时转发业务消息（携带 rev），保证后续最终态合并一致
                try {
                    if (bizBody != null) {
                        nettyMessageSender.sendToUserWithExtra(
                                header.getReceiverId(),
                                header.getMessageType(),
                                bizBody,
                                header.getSenderId(),
                                header.getReceiverId(),
                                0L,
                                header.getTenantId(),
                                messageDO.getId(),
                                messageDO.getSequence(),
                                chatId,
                                receiverCursorVersion,
                                null,
                                extraWithRev
                        );
                    }
                } catch (Exception ignore) {
                    // ignore
                }
            }
        } catch (Exception e) {
            log.error("[MessageStorage] 更新会话失败", e);
            // 不抛出异常，避免影响消息保存
        }
    }

    private String buildConversationPreview(MessageHeader header, ImChatMessageDO messageDO, ImMessage rawMessage) {
        if (header == null || header.getMessageType() == null) {
            return messageDO != null && messageDO.getContent() != null ? messageDO.getContent() : "";
        }
        try {
            MessageType type = header.getMessageType();
            switch (type) {
                case TEXT: {
                    TextMessage textMsg = rawMessage != null ? TextMessage.parseFrom(rawMessage.getBody()) : null;
                    String content = textMsg != null ? textMsg.getContent() : null;
                    if (content == null) {
                        content = messageDO != null ? messageDO.getContent() : "";
                    }
                    return content;
                }
                case QUOTE_REPLY: {
                    QuoteReplyMessage quoteMsg = rawMessage != null ? QuoteReplyMessage.parseFrom(rawMessage.getBody()) : null;
                    String content = quoteMsg != null ? quoteMsg.getReplyContent() : null;
                    if (content == null) {
                        content = messageDO != null ? messageDO.getContent() : "";
                    }
                    return content;
                }
                case IMAGE:
                    return "[图片]";
                case VOICE:
                    return "[语音]";
                case VIDEO:
                    return "[视频]";
                case FILE:
                    return "[文件]";
                case LOCATION:
                    return "[位置]";
                case SYSTEM_NOTIFY:
                    return "[系统通知]";
                case READ_RECEIPT:
                    return "[已读回执]";
                case RECALL:
                    return "[消息撤回]";
                case TYPING:
                    return "[正在输入]";
                case BADGE_UPDATE:
                    return "[角标更新]";
                case WORKFLOW_NOTIFY:
                    return "[流程通知]";
                case TODO_REMINDER:
                    return "[待办提醒]";
                case CUSTOM: {
                    String customRaw = messageDO != null ? messageDO.getContent() : "";
                    if (StrUtil.isBlank(customRaw)) {
                        return "[自定义消息]";
                    }
                    try {
                        JSONObject customObj = JSONUtil.parseObj(customRaw);
                        String customType = customObj.getStr("type");
                        if ("FORWARD_COMBINE".equals(customType)) {
                            return "[聊天记录]";
                        }
                        if ("STICKER".equals(customType)) {
                            return "[动画表情]";
                        }
                        if ("CONTACT_CARD".equals(customType)) {
                            return "[名片]";
                        }
                    } catch (Exception ignore) {
                    }
                    return "[自定义消息]";
                }
                case CALL_RECORD:
                    // 通话记录消息：直接使用 messageDO.content（如 "[语音通话]" / "[视频通话]"）
                    return messageDO != null && StrUtil.isNotBlank(messageDO.getContent())
                            ? messageDO.getContent() : "[通话记录]";
                default:
                    return "[消息]";
            }
        } catch (Exception ignore) {
            return messageDO != null && messageDO.getContent() != null ? messageDO.getContent() : "";
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
        ImChatUserDO deletedChatUser = chatUserMapper.selectAnyByUserIdAndChatId(userId, chatId);
        if (deletedChatUser != null) {
            if (Boolean.TRUE.equals(deletedChatUser.getDeletedByUser())) {
                chatUserMapper.reviveSoftDeleted(deletedChatUser.getId());
                deletedChatUser.setDeletedByUser(false);
            }
            return deletedChatUser;
        }
        chatUser = new ImChatUserDO();
        chatUser.setUserId(userId);
        chatUser.setChatId(chatId);
        chatUser.setUnreadCount(0);
        chatUser.setIsPinned(false);
        chatUser.setNoDisturb(false);
        chatUser.setDeletedByUser(false);
        try {
            chatUserMapper.insert(chatUser);
        } catch (DuplicateKeyException e) {
            ImChatUserDO existing = chatUserMapper.selectAnyByUserIdAndChatId(userId, chatId);
            if (existing != null) {
                if (Boolean.TRUE.equals(existing.getDeletedByUser())) {
                    chatUserMapper.reviveSoftDeleted(existing.getId());
                    existing.setDeletedByUser(false);
                }
                return existing;
            }
            throw e;
        }
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
     * 构建群聊预览文案：仅返回原始内容，由前端根据发送者标记动态添加国际化前缀
     */
    private String buildGroupConversationPreview(String basePreview, boolean isSender,
                                                 String senderName, Long senderId) {
        String preview = StrUtil.nullToEmpty(basePreview).trim();
        if (preview.isEmpty()) {
            return truncateContent(preview);
        }
        // 去除发送者前缀：数据库只存原始内容，前端根据 isSelf 标记动态拼接国际化文案
        return truncateContent(preview);
    }

    /**
     * 构建单聊预览文案：仅返回原始内容，由前端根据发送者标记动态添加国际化前缀
     */
    private String buildSingleChatPreview(String basePreview) {
        String preview = StrUtil.nullToEmpty(basePreview).trim();
        if (preview.isEmpty()) {
            return truncateContent(preview);
        }
        // 去除发送者前缀：数据库只存原始内容，前端根据 isSelf 标记动态拼接国际化文案
        return truncateContent(preview);
    }

    /**
     * 大群读扩散：仅更新发送者状态 + 将未读记录写入 Redis，延迟批量合并到 MySQL。
     */
    private void updateChatUserAsyncForLargeGroup(Long tenantId, Long chatId, Long senderId, List<Long> memberIds,
                                                   ImChatMessageDO messageDO, MentionParseResult mentionParsed) {

        // 发送者仍然写扩散，保证自身状态正确
        Long senderCursorVersion = cursorVersionService.allocateNextCursorVersion(tenantId, senderId);
        conversationUserStateMapper.upsertAfterMessageForSender(
                tenantId, chatId, senderId, senderCursorVersion,
                messageDO.getSequence(), messageDO.getSendTime(),
                messageDO.getId(), messageDO.getSequence(),
                senderId, messageDO.getMessageType(),
                "", false, messageDO.getSendTime()
        );
        try {
            chatUserMapper.markReadToSequence(senderId, chatId, messageDO.getSequence());
        } catch (Exception ignore) {
            // ignore
        }

        // 其余成员采用读扩散：未读状态写入 Redis
        for (Long memberId : memberIds) {
            if (memberId.equals(senderId)) {
                continue;
            }
            try {
                // 确保 chat_user 记录存在（大群读扩散不需要操作 chatUser）
                ensureChatUser(memberId, chatId);

                // 将未读消息写入 Redis
                largeGroupUnreadRedisDAO.recordUnread(
                        chatId,
                        memberId,
                        messageDO.getId(),
                        messageDO.getSequence(),
                        messageDO.getContent(),
                        senderId
                );

                // @所有人或被@的用户，立即推送实时通知（保持体验）
                boolean lastMessageHasAtMe = mentionParsed != null && (mentionParsed.atAll
                        || (mentionParsed.userIds != null && mentionParsed.userIds.contains(memberId)));
                if (lastMessageHasAtMe) {
                    imBadgeService.pushIncrementalBadgeUpdate(memberId, chatId, 1);
                }
            } catch (Exception e) {
                log.warn("[MessageStorage] 大群未读记录失败, chatId: {}, memberId: {}, messageId: {}",
                        chatId, memberId, messageDO.getId(), e);
            }
        }
    }

    /**
     * 小群写扩散：保持现有的逐成员推送逻辑。
     * 【快照缓存优化】启用后先写 Redis，定时任务批量合并到 MySQL，减少 DB 压力
     */
    private void updateChatUserAsyncForSmallGroup(MessageHeader header, Long chatId, Long tenantId,
                                                   List<Long> memberIds, ImChatMessageDO messageDO,
                                                   ImMessage rawMessage, String basePreview,
                                                   String senderName, MentionParseResult mentionParsed,
                                                   MessageLite bizBody, String extraWithRev) {
        for (Long memberId : memberIds) {
            boolean isSender = memberId.equals(header.getSenderId());
            String finalPreview = buildGroupConversationPreview(
                    basePreview, isSender, senderName, header.getSenderId());

            // 预分配 cursorVersion（用于后续实时推送）
            Long cursorVersion = cursorVersionService.allocateNextCursorVersion(tenantId, memberId);

            if (snapshotCacheEnabled) {
                // 快照缓存模式：先写 Redis，定时任务批量合并到 MySQL
                ImChatUserDO chatUser = ensureChatUser(memberId, chatId);
                conversationSnapshotService.writeSnapshot(
                        memberId,
                        chatId,
                        messageDO.getId(),
                        messageDO.getSequence(),
                        messageDO.getMessageType(),
                        messageDO.getSendTime(),
                        finalPreview,
                        isSender ? 0 : 1,
                        Boolean.TRUE.equals(chatUser.getNoDisturb()),
                        header.getSenderId()
                );
            } else {
                // 传统模式：直接写 MySQL
                ImChatUserDO chatUser = ensureChatUser(memberId, chatId);
                chatUserMapper.updateLastMessageAndIncrementUnread(
                        chatUser.getId(),
                        messageDO.getId(),
                        messageDO.getSequence(),
                        messageDO.getMessageType(),
                        finalPreview,
                        messageDO.getSendTime(),
                        isSender ? 0 : 1,
                        Boolean.TRUE.equals(chatUser.getNoDisturb()),
                        header.getSenderId()
                );

                if (isSender) {
                    // 发送者：unread_count 强制归零
                    conversationUserStateMapper.upsertAfterMessageForSender(
                            tenantId,
                            chatId,
                            memberId,
                            cursorVersion,
                            messageDO.getSequence(),
                            messageDO.getSendTime(),
                            messageDO.getId(),
                            messageDO.getSequence(),
                            header.getSenderId(),
                            messageDO.getMessageType(),
                            finalPreview,
                            false,
                            messageDO.getSendTime()
                    );
                } else {
                    Long lastReadSeqForUpsert = 0L;
                    LocalDateTime lastReadTimeForUpsert = null;
                    boolean lastMessageHasAtMe = mentionParsed != null && (mentionParsed.atAll
                            || (mentionParsed.userIds != null && mentionParsed.userIds.contains(memberId)));
                    conversationUserStateMapper.upsertAfterMessage(
                            tenantId,
                            chatId,
                            memberId,
                            cursorVersion,
                            1,
                            lastReadSeqForUpsert,
                            lastReadTimeForUpsert,
                            messageDO.getId(),
                            messageDO.getSequence(),
                            header.getSenderId(),
                            messageDO.getMessageType(),
                            finalPreview,
                            lastMessageHasAtMe,
                            messageDO.getSendTime()
                    );
                }

                // 发送者侧：持久化推进已读水位，避免重登后自己的消息出现未读角标
                if (isSender && messageDO.getSequence() != null) {
                    try {
                        chatUserMapper.markReadToSequence(memberId, chatId, messageDO.getSequence());
                    } catch (Exception ignore) {
                        // ignore
                    }
                }
            }

            // 非发送者：实时推送消息和角标更新
            if (!isSender) {
                imBadgeService.pushIncrementalBadgeUpdate(memberId, chatId, 1);
                if (bizBody != null) {
                    nettyMessageSender.sendToUserWithExtra(
                            memberId,
                            header.getMessageType(),
                            bizBody,
                            header.getSenderId(),
                            memberId,
                            header.getGroupId(),
                            header.getTenantId(),
                            messageDO.getId(),
                            messageDO.getSequence(),
                            chatId,
                            cursorVersion,
                            null,
                            extraWithRev
                    );
                }
            }
        }
    }

    /**
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
        if (userId == null || userId <= 0 || messageIds == null || messageIds.isEmpty()) {
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

    private MentionParseResult parseMentions(ImMessage rawMessage) {
        MentionParseResult result = new MentionParseResult();
        result.atAll = false;
        result.userIds = new HashSet<>();
        if (rawMessage == null || rawMessage.getHeader() == null || rawMessage.getHeader().getMessageType() == null) {
            return result;
        }
        try {
            MessageType messageType = rawMessage.getHeader().getMessageType();
            if (messageType == MessageType.TEXT) {
                TextMessage textMessage = TextMessage.parseFrom(rawMessage.getBody());
                mergeMentions(result, textMessage.getMentionsList(), textMessage.getAtUserIdsList());
            } else if (messageType == MessageType.QUOTE_REPLY) {
                QuoteReplyMessage quoteReplyMessage = QuoteReplyMessage.parseFrom(rawMessage.getBody());
                mergeMentions(result, quoteReplyMessage.getMentionsList(), quoteReplyMessage.getAtUserIdsList());
            }
        } catch (Exception e) {
            log.warn("[MessageStorage] 解析提及失败, messageType: {}", rawMessage.getHeader().getMessageType(), e);
        }
        return result;
    }

    private void mergeMentions(MentionParseResult result, List<MentionUser> mentions, List<Long> atUserIds) {
        if (result == null) {
            return;
        }
        if (mentions != null && !mentions.isEmpty()) {
            for (MentionUser mention : mentions) {
                if (mention == null) {
                    continue;
                }
                long userId = mention.getUserId();
                if (userId == -1L) {
                    result.atAll = true;
                    continue;
                }
                if (userId > 0) {
                    result.userIds.add(userId);
                }
            }
        }
        if (atUserIds != null && !atUserIds.isEmpty()) {
            for (Long atUserId : atUserIds) {
                if (atUserId == null) {
                    continue;
                }
                if (atUserId == -1L) {
                    result.atAll = true;
                    continue;
                }
                if (atUserId > 0) {
                    result.userIds.add(atUserId);
                }
            }
        }
    }

    @Async("imTaskExecutor")
    public void updateConversationUnreadCountAsync(Long userId) {
        if (userId == null || userId <= 0) {
            return;
        }
        try {
            imBadgeService.pushBadgeUpdate(userId);
        } catch (Exception e) {
            log.warn("[MessageStorage] 异步推送角标失败, userId: {}", userId, e);
        }
    }
}
