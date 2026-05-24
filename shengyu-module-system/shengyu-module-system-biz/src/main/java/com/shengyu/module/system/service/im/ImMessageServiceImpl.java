package com.shengyu.module.system.service.im;

import cn.hutool.core.util.StrUtil;
import cn.hutool.json.JSONObject;
import cn.hutool.json.JSONUtil;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.google.protobuf.MessageLite;
import com.shengyu.framework.common.exception.ServiceException;
import com.shengyu.framework.common.exception.util.ServiceExceptionUtil;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.framework.tenant.core.context.TenantContextHolder;
import com.shengyu.framework.websocket.core.protocol.*;
import com.shengyu.framework.websocket.core.sender.NettyMessageSender;
import com.shengyu.module.infra.api.file.FileApi;
import com.shengyu.module.infra.api.file.dto.FileDTO;
import com.shengyu.module.system.controller.app.im.vo.message.*;
import com.shengyu.module.system.dal.dataobject.im.ImChatDO;
import com.shengyu.module.system.dal.dataobject.im.ImChatMessageDO;
import com.shengyu.module.system.dal.dataobject.im.ImChatUserDO;
import com.shengyu.module.system.dal.dataobject.im.ImGroupDO;
import com.shengyu.module.system.dal.dataobject.im.ImGroupUserDO;
import com.shengyu.module.system.dal.dataobject.user.AdminUserDO;
import com.shengyu.module.system.dal.mysql.im.*;
import com.shengyu.module.system.dal.mysql.user.AdminUserMapper;
import com.shengyu.module.system.enums.im.ImConversationTypeEnum;
import com.shengyu.module.system.enums.im.ImGroupMemberRoleEnum;
import com.shengyu.module.system.enums.im.ImMessageForwardTypeEnum;
import com.shengyu.module.system.enums.im.ImMessageStatusEnum;
import com.shengyu.module.system.enums.im.ImMessageTypeEnum;
import com.shengyu.module.system.service.im.support.ImSystemMessageI18nSupport;
import com.shengyu.module.system.service.im.support.VoiceFileOwnershipValidator;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.util.UriComponentsBuilder;

import javax.annotation.Resource;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

import static com.shengyu.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.shengyu.module.system.enums.ErrorCodeConstants.*;

/**
 * IM 消息 Service 实现类
 *
 * @author 圣钰科技
 */
@Service
@Slf4j
public class ImMessageServiceImpl implements ImMessageService {
    private static final long MAX_VOICE_SIZE_BYTES = 10L * 1024 * 1024;
    private static final long MAX_VOICE_DURATION_MS = 60000L;
    private static final int MAX_FORWARD_COMBINE_DEPTH = 20;
    private static final int WINDOW_LATEST_LIMIT_DEFAULT = 30;
    private static final int WINDOW_LATEST_LIMIT_MAX = 50;
    private static final int WINDOW_BEFORE_LIMIT_DEFAULT = 15;
    private static final int WINDOW_BEFORE_LIMIT_MAX = 30;
    private static final int WINDOW_AFTER_LIMIT_DEFAULT = 10;
    private static final int WINDOW_AFTER_LIMIT_MAX = 20;
    private static final int HISTORY_LIMIT_DEFAULT = 30;
    private static final int HISTORY_LIMIT_MAX = 50;
    private static final int LOCATION_MAP_DEFAULT_ZOOM = 16;
    private static final String LOCATION_MAP_DEFAULT_SIZE = "640*320";
    private static final String LOCATION_MAP_DEFAULT_SCALE = "2";
    private static final String LOCATION_MAP_DEFAULT_MARKER_COLOR = "0x2F88FF";
    private static final String LOCATION_MAP_DEFAULT_MARKER_SIZE = "large";

    private static class MentionParseResult {
        private final boolean atAll;
        private final Set<Long> userIds;

        private MentionParseResult(boolean atAll, Set<Long> userIds) {
            this.atAll = atAll;
            this.userIds = userIds;
        }
    }

	private List<MentionUser> parseMentionUsers(String mentionsJson) {
		if (StrUtil.isBlank(mentionsJson)) {
			return Collections.emptyList();
		}
		try {
			List<JSONObject> mentions = JSONUtil.parseArray(mentionsJson).toList(JSONObject.class);
			if (mentions == null || mentions.isEmpty()) {
				return Collections.emptyList();
			}
			List<MentionUser> result = new ArrayList<>();
			for (JSONObject m : mentions) {
				if (m == null) {
					continue;
				}
				Long userId = m.getLong("userId");
				if (userId == null) {
					continue;
				}
				String nickname = m.getStr("nickname", "");
				Integer startIndex = m.getInt("startIndex", 0);
				Integer endIndex = m.getInt("endIndex", 0);
				MentionUser mu = MentionUser.newBuilder()
						.setUserId(userId)
						.setNickname(nickname != null ? nickname : "")
						.setStartIndex(startIndex != null ? startIndex : 0)
						.setEndIndex(endIndex != null ? endIndex : 0)
						.build();
				result.add(mu);
			}
			return result;
		} catch (Exception ignore) {
			return Collections.emptyList();
		}
	}

	private List<Long> buildAtUserIdsFromMentions(String mentionsJson) {
		if (StrUtil.isBlank(mentionsJson)) {
			return Collections.emptyList();
		}
		try {
			List<JSONObject> mentions = JSONUtil.parseArray(mentionsJson).toList(JSONObject.class);
			if (mentions == null || mentions.isEmpty()) {
				return Collections.emptyList();
			}
			List<Long> ids = new ArrayList<>();
			for (JSONObject m : mentions) {
				if (m == null) {
					continue;
				}
				Long id = m.getLong("userId");
				if (id == null) {
					continue;
				}
				ids.add(id);
			}
			return ids;
		} catch (Exception ignore) {
			return Collections.emptyList();
		}
	}

    private MentionParseResult parseMentions(String mentionsJson) {
        if (StrUtil.isBlank(mentionsJson)) {
            return new MentionParseResult(false, Collections.emptySet());
        }
        try {
            List<JSONObject> mentions = JSONUtil.parseArray(mentionsJson).toList(JSONObject.class);
            if (mentions == null || mentions.isEmpty()) {
                return new MentionParseResult(false, Collections.emptySet());
            }
            boolean atAll = false;
            Set<Long> ids = new HashSet<>();
            for (JSONObject m : mentions) {
                if (m == null) {
                    continue;
                }
                Long id = m.getLong("userId");
                if (id == null) {
                    continue;
                }
                if (id == -1L) {
                    atAll = true;
                    continue;
                }
                ids.add(id);
            }
            return new MentionParseResult(atAll, ids);
        } catch (Exception e) {
            return new MentionParseResult(false, Collections.emptySet());
        }
    }

    private void validateMentionRange(String content, String nickname, Integer startIndex, Integer endIndex) {
        if (content == null) {
            return;
        }
        if (startIndex == null && endIndex == null) {
            return;
        }
        if (startIndex == null || endIndex == null) {
            throw ServiceExceptionUtil.invalidParamException("mentions 索引不完整");
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

    private void validateGroupMentions(Long senderId, ImChatDO chat, String content, String mentionsJson) {
        if (chat == null || !ImConversationTypeEnum.isGroup(chat.getChatType()) || StrUtil.isBlank(mentionsJson)) {
            return;
        }
        List<JSONObject> mentions;
        try {
            mentions = JSONUtil.parseArray(mentionsJson).toList(JSONObject.class);
        } catch (Exception e) {
            throw ServiceExceptionUtil.invalidParamException("mentions 不是合法 JSON");
        }
        if (mentions == null || mentions.isEmpty()) {
            return;
        }
        List<Long> memberIds = imGroupService.getGroupMemberIds(chat.getGroupId());
        if (memberIds == null || !memberIds.contains(senderId)) {
            throw exception(NOT_GROUP_MEMBER);
        }
        Integer senderRole = imGroupService.getMemberRole(chat.getGroupId(), senderId);
        boolean atAll = false;
        for (JSONObject mention : mentions) {
            if (mention == null) {
                continue;
            }
            Long mentionedUserId = mention.getLong("userId");
            if (mentionedUserId == null) {
                throw ServiceExceptionUtil.invalidParamException("mentions.userId 不能为空");
            }
            String nickname = mention.getStr("nickname", "");
            validateMentionRange(content, nickname, mention.getInt("startIndex", null), mention.getInt("endIndex", null));
            if (mentionedUserId == -1L) {
                atAll = true;
                continue;
            }
            if (mentionedUserId <= 0) {
                throw ServiceExceptionUtil.invalidParamException("mentions.userId 非法");
            }
            if (!memberIds.contains(mentionedUserId)) {
                throw ServiceExceptionUtil.invalidParamException("被@用户不在群成员列表中");
            }
        }
        if (atAll && (senderRole == null
                || (!ImGroupMemberRoleEnum.isOwner(senderRole) && !ImGroupMemberRoleEnum.isAdmin(senderRole)))) {
            throw exception(GROUP_PERMISSION_DENIED);
        }
    }

    private void validateGroupSendPermission(Long senderId, ImChatDO chat) {
        if (senderId == null || chat == null || !ImConversationTypeEnum.isGroup(chat.getChatType())) {
            return;
        }
        Long groupId = chat.getGroupId();
        if (groupId == null) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }

        ImGroupDO group = groupMapper.selectById(groupId);
        if (group == null) {
            throw exception(GROUP_NOT_EXISTS);
        }

        ImGroupUserDO groupMember = groupUserMapper.selectByGroupIdAndUserId(groupId, senderId);
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

    @Value("${im.recall.window-seconds:120}")
    private long recallWindowSeconds;

    @Value("${im.recall.admin-window-seconds:86400}")
    private long recallAdminWindowSeconds;

    @Value("${im.location.tencent-lbs-key:}")
    private String tencentLbsKey;

    @Value("${im.location.static-map-url:https://apis.map.qq.com/ws/staticmap/v2/}")
    private String locationStaticMapUrl;

    @Resource
    private ImChatMessageMapper chatMessageMapper;

    @Resource
    private ImChatMapper chatMapper;

    @Resource
    private ImChatUserMapper chatUserMapper;

    @Resource
    private ImChatMessageTombstoneMapper chatMessageTombstoneMapper;

    @Resource
    private ImMessageVoicePlayMapper messageVoicePlayMapper;

    @Resource
    private ImChatClearWatermarkMapper chatClearWatermarkMapper;

    @Resource
    private ImConversationUserStateMapper conversationUserStateMapper;

    @Resource
    private ImGroupService imGroupService;

    @Resource
    private ImGroupMapper groupMapper;

    @Resource
    private ImGroupUserMapper groupUserMapper;

    @Resource
    private AdminUserMapper userMapper;

    @Resource
    private ImBadgeService imBadgeService;

    @Resource
    private ImCursorVersionService cursorVersionService;

    @Resource
    private NettyMessageSender messageSender;

    @Resource
    private FileApi fileApi;

    @Resource
    private ImSystemMessageI18nSupport imSystemMessageI18nSupport;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long sendMessage(Long userId, AppImMessageSendReqVO sendReqVO) {
        Long chatId = sendReqVO.getChatId();
        
        // 幂等检查：如果传入了 clientMessageId，检查是否已存在
        String clientMessageId = sendReqVO.getClientMessageId();
        if (StrUtil.isNotBlank(clientMessageId)) {
            ImChatMessageDO existingMessage = chatMessageMapper.selectByClientMessageId(clientMessageId);
            if (existingMessage != null) {
                // 幂等返回：同一 clientMessageId 返回已存在的消息ID
                log.info("[ImMessageService] 幂等重发命中, clientMessageId: {}, existingMessageId: {}", 
                        clientMessageId, existingMessage.getId());
                return existingMessage.getId();
            }
        }
        
        ImChatUserDO selfChatUser = chatUserMapper.selectByUserIdAndChatId(userId, chatId);
        if (selfChatUser == null) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }

        ImChatDO chat = chatMapper.selectById(chatId);
        if (chat == null) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }

        validateGroupSendPermission(userId, chat);
        validateGroupMentions(userId, chat, sendReqVO.getContent(), sendReqVO.getMentions());

        ImChatMessageDO message = new ImChatMessageDO();
        message.setChatId(chatId);
        message.setSenderId(userId);
        message.setClientMessageId(clientMessageId);
        Integer dbMessageType = normalizeDbMessageType(sendReqVO.getMessageType());
        JSONObject validatedVoiceExtra = null;
        JSONObject validatedCustomPayload = null;
        message.setMessageType(dbMessageType);

        if (dbMessageType == 3) {
            validatedVoiceExtra = validateVoiceExtra(sendReqVO.getExtra(), userId, chatId, resolveVoiceGroupId(chat));
        } else if (dbMessageType == 5) {
            if (StrUtil.isBlank(sendReqVO.getExtra())) {
                throw ServiceExceptionUtil.invalidParamException("FILE 消息缺少 extra：必须包含 url/fileName/size/fileType(mimeType)");
            }
            try {
                JSONObject obj = JSONUtil.parseObj(sendReqVO.getExtra());
                String fileName = obj.getStr("fileName", obj.getStr("name", ""));
                Long size = obj.getLong("size", null);
                String fileType = obj.getStr("fileType", obj.getStr("mimeType", ""));
                String url = obj.getStr("url", "");
                if (StrUtil.isBlank(fileName) || size == null || size <= 0 || StrUtil.isBlank(fileType) || StrUtil.isBlank(url)) {
                    throw ServiceExceptionUtil.invalidParamException("FILE 消息 extra 字段不完整：必须包含 url/fileName/size/fileType(mimeType)");
                }
            } catch (ServiceException ex) {
                throw ex;
            } catch (Exception ex) {
                throw ServiceExceptionUtil.invalidParamException("FILE 消息 extra 不是合法 JSON：{}", ex.getMessage());
            }
        } else if (dbMessageType == 8) {
            if (StrUtil.isBlank(sendReqVO.getExtra())) {
                throw ServiceExceptionUtil.invalidParamException("STICKER 消息缺少 extra：必须包含 stickerId/fileId/url 等字段");
            }
            try {
                JSONObject obj = JSONUtil.parseObj(sendReqVO.getExtra());
                Long stickerId = obj.getLong("stickerId", null);
                Long fileId = obj.getLong("fileId", null);
                String url = obj.getStr("url", "");
                if (stickerId == null || (fileId == null && StrUtil.isBlank(url))) {
                    throw ServiceExceptionUtil.invalidParamException("STICKER 消息 extra 字段不完整：必须包含 stickerId 和 fileId/url");
                }
            } catch (ServiceException ex) {
                throw ex;
            } catch (Exception ex) {
                throw ServiceExceptionUtil.invalidParamException("STICKER 消息 extra 不是合法 JSON：{}", ex.getMessage());
            }
        } else if (dbMessageType == 9) {
            validatedCustomPayload = validateAndNormalizeCustomPayload(sendReqVO);
        }
        if (dbMessageType == 3) {
            message.setContent("[语音]");
            message.setExtra(validatedVoiceExtra != null ? validatedVoiceExtra.toString() : sendReqVO.getExtra());
        } else if (dbMessageType == 9 && validatedCustomPayload != null) {
            String normalized = validatedCustomPayload.toString();
            message.setContent(normalized);
            message.setExtra(normalized);
        } else {
            message.setContent(sendReqVO.getContent());
            message.setExtra(sendReqVO.getExtra());
        }
        // 分配会话内 sequence（单调递增），用于会话水位与未读计算
        Long sequence = chatMapper.nextSequence(chatId);
        message.setSequence(sequence);
        message.setSendTime(LocalDateTime.now());
        message.setRev(1L);
        message.setStatus(ImMessageStatusEnum.SENT.getStatus());
        message.setQuoteMessageId(sendReqVO.getQuoteMessageId());
        message.setMentions(sendReqVO.getMentions());
        chatMessageMapper.insert(message);

        String preview = getMessagePreview(dbMessageType, sendReqVO.getContent());
        updateChatUsersAfterSend(chat, message.getId(), message.getSequence(), message.getRev(), preview, message.getSendTime(), userId, sendReqVO);
        return message.getId();
    }

    @Override
    public List<AppImMessageRespVO> pullMessages(Long userId, AppImMessagePullReqVO pullReqVO) {
        ImChatUserDO chatUser = chatUserMapper.selectByUserIdAndChatId(userId, pullReqVO.getChatId());
        if (chatUser == null) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }

        Long lastSequence = pullReqVO.getLastSequence() != null ? pullReqVO.getLastSequence() : 0L;
        Integer limit = pullReqVO.getLimit() != null ? pullReqVO.getLimit() : 200;
        if (limit <= 0) {
            limit = 200;
        }
        if (limit > 500) {
            limit = 500;
        }

        List<ImChatMessageDO> list = chatMessageMapper.selectListByChatIdAndSequenceGt(pullReqVO.getChatId(), lastSequence, limit);

        // enterprise: clear-history watermark filter (sequence <= clearSequence not visible)
        Long clearSeq = null;
        try {
            Long tenantId = TenantContextHolder.getTenantId();
            if (tenantId == null) {
                tenantId = 0L;
            }
            clearSeq = chatClearWatermarkMapper.selectClearSequence(tenantId, userId, pullReqVO.getChatId());
        } catch (Exception ignore) {
            clearSeq = null;
        }
        final Long finalClearSeq = clearSeq;

        // enterprise: delete-for-me tombstone filter
        List<Long> messageIds = list.stream().filter(m -> m != null && m.getId() != null).map(ImChatMessageDO::getId).collect(Collectors.toList());
        List<Long> deletedIds = null;
        try {
            Long tenantId = TenantContextHolder.getTenantId();
            if (tenantId == null) {
                tenantId = 0L;
            }
            if (!messageIds.isEmpty()) {
                deletedIds = chatMessageTombstoneMapper.selectDeletedMessageIds(tenantId, userId, pullReqVO.getChatId(), messageIds);
            }
        } catch (Exception ignore) {
            deletedIds = null;
        }
        final List<Long> finalDeletedIds = deletedIds;

        List<AppImMessageRespVO> respList = list.stream()
                .filter(m -> m != null && m.getId() != null
                        && (finalClearSeq == null || finalClearSeq <= 0 || (m.getSequence() != null && m.getSequence() > finalClearSeq))
                        && (finalDeletedIds == null || !finalDeletedIds.contains(m.getId())))
                .map(message -> {
            AppImMessageRespVO respVO = BeanUtils.toBean(message, AppImMessageRespVO.class);
            respVO.setChatId(message.getChatId());
            respVO.setSequence(message.getSequence());
            // 兼容历史数据：如果 messageType 被存成了 Protobuf 的 100+，则转换回 REST/DB 的 1-10
            respVO.setMessageType(normalizeDbMessageType(respVO.getMessageType()));
            fillSenderInfo(respVO, message.getSenderId(), message.getChatId());
            respVO.setIsSelf(Objects.equals(message.getSenderId(), userId));
            fillChatTargetFields(respVO, userId);
            applyLocalizedSystemMessageContent(respVO, message);
            applyReeditFieldsForCurrentUser(respVO, message, userId);
            sanitizeRecalledMessage(respVO, message, userId);
            return respVO;
        }).collect(Collectors.toList());
        fillVoicePlayedFlags(userId, respList, pullReqVO.getChatId());
        return respList;
    }

    @Override
    public PageResult<AppImMessageRespVO> getMessagePage(Long userId, AppImMessagePageReqVO pageReqVO) {
        ImChatUserDO chatUser = chatUserMapper.selectByUserIdAndChatId(userId, pageReqVO.getChatId());
        if (chatUser == null) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }
        PageResult<ImChatMessageDO> pageResult = chatMessageMapper.selectPageByChatId(pageReqVO.getChatId(), pageReqVO);

        // enterprise: clear-history watermark filter
        Long clearSeq = null;
        try {
            Long tenantId = TenantContextHolder.getTenantId();
            if (tenantId == null) {
                tenantId = 0L;
            }
            clearSeq = chatClearWatermarkMapper.selectClearSequence(tenantId, userId, pageReqVO.getChatId());
        } catch (Exception ignore) {
            clearSeq = null;
        }
        final Long finalClearSeq = clearSeq;

        // enterprise: delete-for-me tombstone filter
        List<Long> pageIds = pageResult.getList().stream().filter(m -> m != null && m.getId() != null).map(ImChatMessageDO::getId).collect(Collectors.toList());
        List<Long> deletedIds = null;
        try {
            Long tenantId = TenantContextHolder.getTenantId();
            if (tenantId == null) {
                tenantId = 0L;
            }
            if (!pageIds.isEmpty()) {
                deletedIds = chatMessageTombstoneMapper.selectDeletedMessageIds(tenantId, userId, pageReqVO.getChatId(), pageIds);
            }
        } catch (Exception ignore) {
            deletedIds = null;
        }
        final List<Long> finalDeletedIds = deletedIds;

        List<AppImMessageRespVO> respVOList = pageResult.getList().stream()
                .filter(m -> m != null && m.getId() != null
                        && (finalClearSeq == null || finalClearSeq <= 0 || (m.getSequence() != null && m.getSequence() > finalClearSeq))
                        && (finalDeletedIds == null || !finalDeletedIds.contains(m.getId())))
                .map(message -> {
            AppImMessageRespVO respVO = BeanUtils.toBean(message, AppImMessageRespVO.class);
            respVO.setChatId(message.getChatId());
            respVO.setSequence(message.getSequence());
            // 兼容历史数据：如果 messageType 被存成了 Protobuf 的 100+，则转换回 REST/DB 的 1-10
            respVO.setMessageType(normalizeDbMessageType(respVO.getMessageType()));
            fillSenderInfo(respVO, message.getSenderId(), message.getChatId());
            respVO.setIsSelf(Objects.equals(message.getSenderId(), userId));
            fillChatTargetFields(respVO, userId);
            applyLocalizedSystemMessageContent(respVO, message);
            applyReeditFieldsForCurrentUser(respVO, message, userId);
            sanitizeRecalledMessage(respVO, message, userId);
            return respVO;
        }).collect(Collectors.toList());
        fillVoicePlayedFlags(userId, respVOList, pageReqVO.getChatId());
        return new PageResult<>(respVOList, pageResult.getTotal());
    }

    @Override
    public AppImMessageWindowRespVO getMessageWindow(Long userId, AppImMessageWindowReqVO windowReqVO) {
        ImChatUserDO chatUser = chatUserMapper.selectByUserIdAndChatId(userId, windowReqVO.getChatId());
        if (chatUser == null) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }

        Long tenantId = getCurrentTenantId();
        Long anchorSequence = resolveVisibleAnchorSequence(tenantId, userId, windowReqVO);
        if (anchorSequence != null) {
            return buildAnchorWindowResponse(userId, tenantId, chatUser, windowReqVO, anchorSequence);
        }
        String fallbackMode = hasAnchorHint(windowReqVO) ? "anchor" : "latest";
        return buildLatestWindowResponse(userId, tenantId, chatUser, windowReqVO,
                fallbackMode, !hasAnchorHint(windowReqVO), windowReqVO.getAnchorSequence());
    }

    @Override
    public AppImMessageHistoryRespVO getMessageHistory(Long userId, AppImMessageHistoryReqVO historyReqVO) {
        ImChatUserDO chatUser = chatUserMapper.selectByUserIdAndChatId(userId, historyReqVO.getChatId());
        if (chatUser == null) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }
        Long beforeSequence = historyReqVO.getBeforeSequence();
        if (beforeSequence == null || beforeSequence <= 0) {
            throw ServiceExceptionUtil.invalidParamException("beforeSequence必须大于0");
        }
        Integer limit = normalizeLimit(historyReqVO.getLimit(), HISTORY_LIMIT_DEFAULT, HISTORY_LIMIT_MAX);
        Long tenantId = getCurrentTenantId();
        List<ImChatMessageDO> historyDesc = chatMessageMapper.selectVisibleBeforeSequenceByUser(
                tenantId, userId, historyReqVO.getChatId(), beforeSequence, limit);
        List<AppImMessageRespVO> items = mapChatWindowMessages(userId, reverseBySequence(historyDesc));

        AppImMessageHistoryRespVO respVO = new AppImMessageHistoryRespVO();
        respVO.setChatId(historyReqVO.getChatId());
        respVO.setItems(items);
        if (!items.isEmpty()) {
            Long oldestSequence = items.get(0).getSequence();
            Long newestSequence = items.get(items.size() - 1).getSequence();
            respVO.setOldestSequence(oldestSequence);
            respVO.setNewestSequence(newestSequence);
            respVO.setHasOlder(hasOlderMessages(tenantId, userId, historyReqVO.getChatId(), oldestSequence));
        } else {
            respVO.setHasOlder(false);
        }
        return respVO;
    }

    @Override
    public List<AppImMessageRespVO> getConversationMessages(Long userId, Long chatId, Long lastMessageId, Integer pageSize) {
        // 旧接口不再支持（线路 A 统一走分页接口）
        throw exception(MESSAGE_SEND_FAILED);
    }

    @Override
    public AppImMessageRespVO getMessageDetail(Long userId, Long messageId) {
        ImChatMessageDO message = chatMessageMapper.selectById(messageId);
        if (message == null) {
            throw exception(MESSAGE_NOT_EXISTS);
        }
        ImChatUserDO chatUser = chatUserMapper.selectByUserIdAndChatId(userId, message.getChatId());
        if (chatUser == null) {
            throw exception(MESSAGE_NOT_EXISTS);
        }

        // enterprise: visibility filter (clear-history watermark + delete-for-me tombstone)
        Long tenantId = TenantContextHolder.getTenantId();
        if (tenantId == null) {
            tenantId = 0L;
        }
        boolean invisible = false;
        try {
            Long clearSeq = chatClearWatermarkMapper.selectClearSequence(tenantId, userId, message.getChatId());
            if (clearSeq != null && clearSeq > 0 && message.getSequence() != null && message.getSequence() <= clearSeq) {
                invisible = true;
            }
        } catch (Exception ignore) {
            // ignore
        }
        try {
            List<Long> deletedIds = chatMessageTombstoneMapper.selectDeletedMessageIds(tenantId, userId, message.getChatId(), Collections.singletonList(messageId));
            if (deletedIds != null && !deletedIds.isEmpty()) {
                invisible = true;
            }
        } catch (Exception ignore) {
            // ignore
        }
        if (invisible) {
            throw exception(MESSAGE_NOT_EXISTS);
        }

        AppImMessageRespVO respVO = BeanUtils.toBean(message, AppImMessageRespVO.class);
        respVO.setChatId(message.getChatId());
        respVO.setSequence(message.getSequence());
        respVO.setMessageType(normalizeDbMessageType(respVO.getMessageType()));
        fillSenderInfo(respVO, message.getSenderId(), message.getChatId());
        respVO.setIsSelf(Objects.equals(message.getSenderId(), userId));
        fillChatTargetFields(respVO, userId);
        applyLocalizedSystemMessageContent(respVO, message);
        applyReeditFieldsForCurrentUser(respVO, message, userId);
        sanitizeRecalledMessage(respVO, message, userId);
        fillVoicePlayedFlags(userId, Collections.singletonList(respVO), message.getChatId());
        return respVO;
    }

    private void applyReeditFieldsForCurrentUser(AppImMessageRespVO respVO, ImChatMessageDO message, Long userId) {
        if (respVO == null || message == null || userId == null) {
            return;
        }
        try {
            if (!Objects.equals(respVO.getStatus(), ImMessageStatusEnum.RECALLED.getStatus())) {
                return;
            }
            if (!Objects.equals(message.getSenderId(), userId)) {
                return;
            }
            if (!Objects.equals(message.getRecallBy(), userId)) {
                return;
            }
            if (!isReeditEligibleTextMessage(message, userId)) {
                return;
            }
            LocalDateTime recallTime = message.getRecallTime();
            if (recallTime == null) {
                return;
            }
            long deadlineTs = recallTime.plusSeconds(300L).atZone(java.time.ZoneId.systemDefault()).toInstant().toEpochMilli();
            if (System.currentTimeMillis() > deadlineTs) {
                return;
            }
            String content = message.getContent();
            if (StrUtil.isBlank(content) || "[消息已撤回]".equals(content)) {
                try {
                    String extra = message.getExtra();
                    if (StrUtil.isNotBlank(extra)) {
                        JSONObject obj = JSONUtil.parseObj(extra);
                        String c = obj.getStr("reeditContent");
                        if (StrUtil.isNotBlank(c) && !"[消息已撤回]".equals(c)) {
                            content = c;
                        }
                        String d = obj.getStr("reeditDeadlineTs");
                        if (StrUtil.isNotBlank(d)) {
                            deadlineTs = Long.parseLong(d);
                            if (System.currentTimeMillis() > deadlineTs) {
                                return;
                            }
                        }
                    }
                } catch (Exception ignore) {
                }
            }
            if (StrUtil.isBlank(content) || "[消息已撤回]".equals(content)) {
                return;
            }
            respVO.setReeditContent(content);
            respVO.setReeditDeadlineTs(String.valueOf(deadlineTs));
        } catch (Exception ignore) {
        }
    }

    private boolean isReeditEligibleTextMessage(ImChatMessageDO message, Long userId) {
        if (message == null || userId == null) {
            return false;
        }
        if (!Objects.equals(message.getSenderId(), userId)) {
            return false;
        }
        Integer normalizedType = normalizeDbMessageType(message.getMessageType());
        if (!Objects.equals(normalizedType, ImMessageTypeEnum.TEXT.getType())) {
            return false;
        }
        if (message.getQuoteMessageId() != null) {
            return false;
        }
        if (StrUtil.isNotBlank(message.getForwardedFrom())) {
            return false;
        }
        return StrUtil.isNotBlank(message.getContent());
    }

    private void applyLocalizedSystemMessageContent(AppImMessageRespVO respVO, ImChatMessageDO message) {
        if (respVO == null || message == null) {
            return;
        }
        if (!Objects.equals(respVO.getMessageType(), ImMessageTypeEnum.SYSTEM.getType())) {
            return;
        }
        respVO.setContent(imSystemMessageI18nSupport.render(message.getContent(), message.getExtra()));
    }

    private void sanitizeRecalledMessage(AppImMessageRespVO respVO, ImChatMessageDO message, Long currentUserId) {
        if (respVO == null || message == null) {
            return;
        }
        if (!Objects.equals(respVO.getStatus(), ImMessageStatusEnum.RECALLED.getStatus())) {
            return;
        }
        String recallTipContent = buildRecallTipContent(message, respVO, currentUserId);
        // enterprise security: recalled messages must not leak original content/extra/forward info via pull/page/detail
        respVO.setContent(recallTipContent);
        respVO.setExtra(null);
        respVO.setForwardedFrom(null);
        respVO.setMentions(null);
    }

    private String buildRecallTipContent(ImChatMessageDO message, AppImMessageRespVO respVO, Long currentUserId) {
        String senderName = respVO != null ? respVO.getSenderNickname() : "";
        String recallerName = "";
        try {
            String extra = message.getExtra();
            if (StrUtil.isNotBlank(extra)) {
                JSONObject obj = JSONUtil.parseObj(extra);
                recallerName = obj.getStr("recallerName");
                if (StrUtil.isBlank(senderName)) {
                    senderName = obj.getStr("senderName");
                }
            }
        } catch (Exception ignore) {
            recallerName = "";
        }
        if (StrUtil.isBlank(senderName) && message.getSenderId() != null && message.getSenderId() > 0L) {
            AdminUserDO sender = userMapper.selectById(message.getSenderId());
            if (sender != null) {
                senderName = sender.getNickname();
            }
        }
        if (StrUtil.isBlank(recallerName) && message.getRecallBy() != null && message.getRecallBy() > 0L) {
            AdminUserDO recaller = userMapper.selectById(message.getRecallBy());
            if (recaller != null) {
                recallerName = recaller.getNickname();
            }
        }
        return imSystemMessageI18nSupport.renderRecallMessage(currentUserId, message.getRecallBy(),
                message.getSenderId(), senderName, recallerName, "[消息已撤回]");
    }

    private AppImMessageWindowRespVO buildLatestWindowResponse(Long userId, Long tenantId, ImChatUserDO chatUser,
                                                               AppImMessageWindowReqVO windowReqVO,
                                                               String responseMode,
                                                               boolean anchorFound, Long anchorSequence) {
        Integer limit = normalizeLimit(windowReqVO.getLimit(), WINDOW_LATEST_LIMIT_DEFAULT, WINDOW_LATEST_LIMIT_MAX);
        List<ImChatMessageDO> latestDesc = chatMessageMapper.selectVisibleLatestByUser(
                tenantId, userId, windowReqVO.getChatId(), limit);
        List<AppImMessageRespVO> items = mapChatWindowMessages(userId, reverseBySequence(latestDesc));
        return buildWindowResponse(windowReqVO.getChatId(), responseMode, items, chatUser, anchorFound, anchorSequence);
    }

    private AppImMessageWindowRespVO buildAnchorWindowResponse(Long userId, Long tenantId, ImChatUserDO chatUser,
                                                               AppImMessageWindowReqVO windowReqVO,
                                                               Long anchorSequence) {
        Integer beforeLimit = normalizeLimit(windowReqVO.getBeforeLimit(), WINDOW_BEFORE_LIMIT_DEFAULT, WINDOW_BEFORE_LIMIT_MAX);
        Integer afterLimit = normalizeLimit(windowReqVO.getAfterLimit(), WINDOW_AFTER_LIMIT_DEFAULT, WINDOW_AFTER_LIMIT_MAX);

        List<ImChatMessageDO> beforeDesc = chatMessageMapper.selectVisibleBeforeSequenceByUser(
                tenantId, userId, windowReqVO.getChatId(), anchorSequence, beforeLimit);
        List<ImChatMessageDO> afterAsc = chatMessageMapper.selectVisibleAfterOrEqualSequenceByUser(
                tenantId, userId, windowReqVO.getChatId(), anchorSequence, afterLimit + 1);

        List<ImChatMessageDO> merged = new ArrayList<>(beforeDesc.size() + afterAsc.size());
        merged.addAll(reverseBySequence(beforeDesc));
        merged.addAll(afterAsc);

        List<AppImMessageRespVO> items = mapChatWindowMessages(userId, merged);
        AppImMessageWindowRespVO respVO = buildWindowResponse(windowReqVO.getChatId(), "anchor", items, chatUser, true, anchorSequence);
        if (!items.isEmpty()) {
            Long oldestSequence = items.get(0).getSequence();
            Long newestSequence = items.get(items.size() - 1).getSequence();
            respVO.setHasOlder(hasOlderMessages(tenantId, userId, windowReqVO.getChatId(), oldestSequence));
            respVO.setHasNewer(hasNewerMessages(tenantId, userId, windowReqVO.getChatId(), newestSequence));
        }
        return respVO;
    }

    private AppImMessageWindowRespVO buildWindowResponse(Long chatId, String mode, List<AppImMessageRespVO> items,
                                                         ImChatUserDO chatUser, boolean anchorFound,
                                                         Long anchorSequence) {
        AppImMessageWindowRespVO respVO = new AppImMessageWindowRespVO();
        respVO.setMode(mode);
        respVO.setChatId(chatId);
        respVO.setAnchorFound(anchorFound);
        respVO.setAnchorSequence(anchorSequence);
        respVO.setItems(items);
        if (items.isEmpty()) {
            respVO.setHasOlder(false);
            respVO.setHasNewer(false);
            respVO.setFirstUnreadSequence(null);
            return respVO;
        }
        Long oldestSequence = items.get(0).getSequence();
        Long newestSequence = items.get(items.size() - 1).getSequence();
        respVO.setOldestSequence(oldestSequence);
        respVO.setNewestSequence(newestSequence);
        respVO.setHasOlder(false);
        respVO.setHasNewer(false);
        respVO.setFirstUnreadSequence(findFirstUnreadSequence(items, chatUser != null ? chatUser.getLastReadSequence() : null));
        return respVO;
    }

    private Long resolveVisibleAnchorSequence(Long tenantId, Long userId, AppImMessageWindowReqVO windowReqVO) {
        if (windowReqVO == null || windowReqVO.getChatId() == null) {
            return null;
        }
        if (windowReqVO.getAnchorSequence() != null) {
            if (windowReqVO.getAnchorSequence() <= 0) {
                return null;
            }
            return chatMessageMapper.selectVisibleSequenceBySequence(
                    tenantId, userId, windowReqVO.getChatId(), windowReqVO.getAnchorSequence());
        }
        if (windowReqVO.getAnchorMessageId() != null) {
            if (windowReqVO.getAnchorMessageId() <= 0) {
                return null;
            }
            return chatMessageMapper.selectVisibleSequenceByMessageId(
                    tenantId, userId, windowReqVO.getChatId(), windowReqVO.getAnchorMessageId());
        }
        return null;
    }

    private boolean hasAnchorHint(AppImMessageWindowReqVO windowReqVO) {
        if (windowReqVO == null) {
            return false;
        }
        return windowReqVO.getAnchorSequence() != null || windowReqVO.getAnchorMessageId() != null;
    }

    private Long getCurrentTenantId() {
        Long tenantId = TenantContextHolder.getTenantId();
        return tenantId != null ? tenantId : 0L;
    }

    private Integer normalizeLimit(Integer rawLimit, int defaultLimit, int maxLimit) {
        if (rawLimit == null || rawLimit <= 0) {
            return defaultLimit;
        }
        return Math.min(rawLimit, maxLimit);
    }

    private List<ImChatMessageDO> reverseBySequence(List<ImChatMessageDO> messages) {
        if (messages == null || messages.isEmpty()) {
            return Collections.emptyList();
        }
        List<ImChatMessageDO> copy = new ArrayList<>(messages);
        Collections.reverse(copy);
        return copy;
    }

    private boolean hasOlderMessages(Long tenantId, Long userId, Long chatId, Long oldestSequence) {
        if (oldestSequence == null) {
            return false;
        }
        Long count = chatMessageMapper.countVisibleOlderThanSequence(tenantId, userId, chatId, oldestSequence);
        return count != null && count > 0;
    }

    private boolean hasNewerMessages(Long tenantId, Long userId, Long chatId, Long newestSequence) {
        if (newestSequence == null) {
            return false;
        }
        Long count = chatMessageMapper.countVisibleNewerThanSequence(tenantId, userId, chatId, newestSequence);
        return count != null && count > 0;
    }

    private Long findFirstUnreadSequence(List<AppImMessageRespVO> items, Long lastReadSequence) {
        if (items == null || items.isEmpty()) {
            return null;
        }
        long watermark = lastReadSequence != null ? lastReadSequence : 0L;
        for (AppImMessageRespVO item : items) {
            if (item == null || item.getSequence() == null) {
                continue;
            }
            if (item.getSequence() > watermark) {
                return item.getSequence();
            }
        }
        return null;
    }

    private List<AppImMessageRespVO> mapChatWindowMessages(Long userId, List<ImChatMessageDO> messages) {
        if (messages == null || messages.isEmpty()) {
            return Collections.emptyList();
        }
        Long chatId = messages.get(0).getChatId();
        ImChatDO chat = chatId != null ? chatMapper.selectById(chatId) : null;

        Set<Long> senderIds = messages.stream()
                .filter(Objects::nonNull)
                .map(ImChatMessageDO::getSenderId)
                .filter(Objects::nonNull)
                .collect(Collectors.toCollection(LinkedHashSet::new));
        Map<Long, AdminUserDO> senderMap = senderIds.isEmpty() ? Collections.emptyMap()
                : userMapper.selectBatchIds(senderIds).stream()
                .filter(Objects::nonNull)
                .collect(Collectors.toMap(AdminUserDO::getId, item -> item, (left, right) -> left));
        Map<Long, String> groupNicknameMap = buildGroupNicknameMap(chat, senderIds);

        List<AppImMessageRespVO> result = new ArrayList<>(messages.size());
        for (ImChatMessageDO message : messages) {
            if (message == null) {
                continue;
            }
            AppImMessageRespVO respVO = BeanUtils.toBean(message, AppImMessageRespVO.class);
            respVO.setChatId(message.getChatId());
            respVO.setSequence(message.getSequence());
            respVO.setMessageType(normalizeDbMessageType(respVO.getMessageType()));
            fillSenderInfo(respVO, message.getSenderId(), chat, senderMap, groupNicknameMap);
            respVO.setIsSelf(Objects.equals(message.getSenderId(), userId));
            fillChatTargetFields(respVO, userId, chat);
            applyLocalizedSystemMessageContent(respVO, message);
            applyReeditFieldsForCurrentUser(respVO, message, userId);
            sanitizeRecalledMessage(respVO, message, userId);
            result.add(respVO);
        }
        fillVoicePlayedFlags(userId, result, chatId);
        return result;
    }

    private void fillChatTargetFields(AppImMessageRespVO respVO, Long currentUserId, ImChatDO chat) {
        if (respVO == null || chat == null) {
            return;
        }
        if (ImConversationTypeEnum.isGroup(chat.getChatType())) {
            respVO.setGroupId(chat.getGroupId());
            return;
        }
        Long receiverId = Objects.equals(chat.getSingleUser1(), currentUserId) ? chat.getSingleUser2() : chat.getSingleUser1();
        respVO.setReceiverId(receiverId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateMessageStatus(Long userId, Long messageId, Integer status) {
        ImChatMessageDO message = chatMessageMapper.selectById(messageId);
        if (message == null) {
            throw exception(MESSAGE_NOT_EXISTS);
        }
        // 仅允许发送者撤回
        if (!Objects.equals(message.getSenderId(), userId)) {
            throw exception(MESSAGE_NOT_EXISTS);
        }
        chatMessageMapper.update(null, new LambdaUpdateWrapper<ImChatMessageDO>()
                .eq(ImChatMessageDO::getId, messageId)
                .set(ImChatMessageDO::getStatus, status));
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void batchUpdateMessageStatus(Long userId, List<Long> messageIds, Integer status) {
        if (messageIds == null || messageIds.isEmpty()) {
            return;
        }

        // 线路 A：按 messageId 批量更新
        int updatedCount = chatMessageMapper.updateStatusByIds(messageIds, status);
        log.debug("[ImMessageService] 批量更新消息状态成功, userId: {}, messageCount: {}, updated: {}, status: {}",
                userId, messageIds.size(), updatedCount, status);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void markVoicePlayed(Long userId, Long messageId) {
        if (messageId == null || messageId <= 0) {
            return;
        }
        ImChatMessageDO message = chatMessageMapper.selectById(messageId);
        if (message == null) {
            throw exception(MESSAGE_NOT_EXISTS);
        }
        ImChatUserDO chatUser = chatUserMapper.selectByUserIdAndChatId(userId, message.getChatId());
        if (chatUser == null) {
            throw exception(MESSAGE_NOT_EXISTS);
        }

        Integer normalizedType = normalizeDbMessageType(message.getMessageType());
        if (!Objects.equals(normalizedType, ImMessageTypeEnum.VOICE.getType())) {
            return;
        }
        // 自己发送的语音默认无未听点，不参与落库
        if (Objects.equals(message.getSenderId(), userId)) {
            return;
        }

        Long tenantId = getCurrentTenantId();
        int inserted = messageVoicePlayMapper.insertIgnore(tenantId, message.getChatId(), messageId, userId);
        if (inserted <= 0) {
            return;
        }

        try {
            JSONObject extra = JSONUtil.createObj();
            extra.set("action", "voice_played");
            extra.set("chatId", message.getChatId());
            extra.set("messageId", messageId);
            TextMessage body = TextMessage.newBuilder().setContent("").build();
            messageSender.sendToUserWithExtra(userId, MessageType.SYSTEM_NOTIFY, body,
                    0L, userId, 0L, tenantId,
                    null, null, message.getChatId(),
                    null, null, extra.toString());
        } catch (Exception e) {
            log.warn("[ImMessageService] 推送语音已播放同步通知失败, userId: {}, messageId: {}, error: {}",
                    userId, messageId, e.getMessage(), e);
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void batchMarkVoicePlayed(Long userId, List<Long> messageIds) {
        List<Long> candidateIds = normalizePositiveDistinctIds(messageIds);
        if (candidateIds.isEmpty()) {
            return;
        }
        List<ImChatMessageDO> messages = chatMessageMapper.selectBatchIds(candidateIds);
        if (messages == null || messages.isEmpty()) {
            return;
        }

        Long tenantId = getCurrentTenantId();
        Map<Long, ImChatUserDO> chatUserCache = new HashMap<>();
        Map<Long, List<Long>> insertedByChatId = new LinkedHashMap<>();
        for (ImChatMessageDO message : messages) {
            if (message == null || message.getId() == null || message.getChatId() == null) {
                continue;
            }
            Integer normalizedType = normalizeDbMessageType(message.getMessageType());
            if (!Objects.equals(normalizedType, ImMessageTypeEnum.VOICE.getType())) {
                continue;
            }
            if (Objects.equals(message.getSenderId(), userId)) {
                continue;
            }

            ImChatUserDO chatUser = chatUserCache.computeIfAbsent(message.getChatId(),
                    chatId -> chatUserMapper.selectByUserIdAndChatId(userId, chatId));
            if (chatUser == null) {
                continue;
            }

            int inserted = messageVoicePlayMapper.insertIgnore(tenantId, message.getChatId(), message.getId(), userId);
            if (inserted > 0) {
                insertedByChatId.computeIfAbsent(message.getChatId(), key -> new ArrayList<>()).add(message.getId());
            }
        }
        if (insertedByChatId.isEmpty()) {
            return;
        }
        for (Map.Entry<Long, List<Long>> entry : insertedByChatId.entrySet()) {
            pushVoicePlayedNotify(userId, tenantId, entry.getKey(), entry.getValue());
        }
    }

    @Override
    public List<Long> getVoicePlayedMessageIds(Long userId, Long chatId, List<Long> messageIds) {
        if (userId == null || chatId == null || chatId <= 0) {
            return Collections.emptyList();
        }
        List<Long> candidateIds = normalizePositiveDistinctIds(messageIds);
        if (candidateIds.isEmpty()) {
            return Collections.emptyList();
        }
        ImChatUserDO chatUser = chatUserMapper.selectByUserIdAndChatId(userId, chatId);
        if (chatUser == null) {
            return Collections.emptyList();
        }
        List<Long> playedIds = messageVoicePlayMapper.selectPlayedMessageIds(getCurrentTenantId(), userId, chatId, candidateIds);
        return playedIds != null ? playedIds : Collections.emptyList();
    }

    private void pushVoicePlayedNotify(Long userId, Long tenantId, Long chatId, List<Long> messageIds) {
        if (userId == null || chatId == null || messageIds == null || messageIds.isEmpty()) {
            return;
        }
        List<Long> normalizedIds = normalizePositiveDistinctIds(messageIds);
        if (normalizedIds.isEmpty()) {
            return;
        }
        try {
            JSONObject extra = JSONUtil.createObj();
            extra.set("action", "voice_played");
            extra.set("chatId", chatId);
            if (normalizedIds.size() == 1) {
                extra.set("messageId", normalizedIds.get(0));
            } else {
                extra.set("messageIds", normalizedIds);
            }
            TextMessage body = TextMessage.newBuilder().setContent("").build();
            messageSender.sendToUserWithExtra(userId, MessageType.SYSTEM_NOTIFY, body,
                    0L, userId, 0L, tenantId,
                    null, null, chatId,
                    null, null, extra.toString());
        } catch (Exception e) {
            log.warn("[ImMessageService] push voice-played notify failed, userId: {}, chatId: {}, messageCount: {}, error: {}",
                    userId, chatId, messageIds.size(), e.getMessage(), e);
        }
    }

    private List<Long> normalizePositiveDistinctIds(List<Long> ids) {
        if (ids == null || ids.isEmpty()) {
            return Collections.emptyList();
        }
        return ids.stream()
                .filter(Objects::nonNull)
                .filter(id -> id > 0)
                .distinct()
                .collect(Collectors.toList());
    }

    private void fillVoicePlayedFlags(Long userId, List<AppImMessageRespVO> respList, Long preferredChatId) {
        if (respList == null || respList.isEmpty() || userId == null) {
            return;
        }
        Map<Long, AppImMessageRespVO> voiceMap = new LinkedHashMap<>();
        for (AppImMessageRespVO resp : respList) {
            if (resp == null) {
                continue;
            }
            Integer normalizedType = normalizeDbMessageType(resp.getMessageType());
            if (!Objects.equals(normalizedType, ImMessageTypeEnum.VOICE.getType())) {
                continue;
            }
            if (Boolean.TRUE.equals(resp.getIsSelf())) {
                resp.setVoicePlayed(true);
                continue;
            }
            if (resp.getId() == null) {
                resp.setVoicePlayed(false);
                continue;
            }
            voiceMap.put(resp.getId(), resp);
        }
        if (voiceMap.isEmpty()) {
            return;
        }

        Set<Long> playedSet = Collections.emptySet();
        try {
            List<Long> messageIds = new ArrayList<>(voiceMap.keySet());
            List<Long> playedIds = messageVoicePlayMapper.selectPlayedMessageIds(
                    getCurrentTenantId(), userId, preferredChatId, messageIds);
            if (playedIds != null && !playedIds.isEmpty()) {
                playedSet = new HashSet<>(playedIds);
            }
        } catch (Exception e) {
            log.warn("[ImMessageService] 查询语音播放状态失败, userId: {}, messageCount: {}, error: {}",
                    userId, voiceMap.size(), e.getMessage(), e);
        }

        for (Map.Entry<Long, AppImMessageRespVO> entry : voiceMap.entrySet()) {
            AppImMessageRespVO resp = entry.getValue();
            resp.setVoicePlayed(playedSet.contains(entry.getKey()));
        }
    }

    private void updateChatUsersAfterSend(ImChatDO chat, Long lastMessageId, Long lastMessageSequence, Long messageRev,
                                         String lastMessageContent, LocalDateTime lastMessageTime,
                                         Long senderId, AppImMessageSendReqVO sendReqVO) {
        Integer dbMessageType = normalizeDbMessageType(sendReqVO.getMessageType());
        Long finalRev = messageRev != null && messageRev > 0 ? messageRev : 1L;
        Long tenantId = TenantContextHolder.getTenantId();
        if (tenantId == null) {
            tenantId = 0L;
        }

        try {
            log.info("[IM][send] updateChatUsersAfterSend chatId={}, chatType={}, lastMessageId={}, seq={}, rev={}, dbMessageType={}, senderId={}",
                    chat != null ? chat.getId() : null,
                    chat != null ? chat.getChatType() : null,
                    lastMessageId, lastMessageSequence, finalRev, dbMessageType, senderId);
        } catch (Exception ignore) {
            // ignore
        }
        MentionParseResult mentionParsed = parseMentions(sendReqVO != null ? sendReqVO.getMentions() : null);
        if (ImConversationTypeEnum.isGroup(chat.getChatType())) {
            List<Long> memberIds = imGroupService.getGroupMemberIds(chat.getGroupId());
            String senderDisplayName = resolveConversationPreviewSenderName(senderId);
            Map<Long, Long> cursorVerMap;
            try {
                cursorVerMap = cursorVersionService.allocateNextCursorVersions(tenantId, memberIds);
            } catch (Exception e) {
                cursorVerMap = Collections.emptyMap();
                log.warn("[ImMessageService] 批量分配 cursorVersion 失败(群消息), chatId: {}, groupId: {}, error: {}",
                        chat.getId(), chat.getGroupId(), e.getMessage());
            }

            for (Long memberId : memberIds) {
                ImChatUserDO chatUser = ensureChatUser(memberId, chat.getId());
                boolean isSender = Objects.equals(memberId, senderId);
                String finalPreview = buildGroupConversationPreview(
                        lastMessageContent, isSender, senderDisplayName, senderId);
                chatUserMapper.updateLastMessageAndIncrementUnread(
                        chatUser.getId(), lastMessageId, lastMessageSequence, dbMessageType, finalPreview, lastMessageTime,
                        isSender ? 0 : 1,
                        Boolean.TRUE.equals(chatUser.getNoDisturb()));

				// 发送者侧：持久化推进已读水位，避免重登后自己的消息出现未读角标
				if (isSender && lastMessageSequence != null) {
					try {
						chatUserMapper.markReadToSequence(senderId, chat.getId(), lastMessageSequence);
					} catch (Exception ignore) {
						// ignore
					}
				}

                // 同步写入 im_conversation_user_state，支持离线重连后 /sync 增量拉取
                try {
                    Long cursorVer = cursorVerMap.get(memberId);
                    if (cursorVer == null) {
                        cursorVer = cursorVersionService.allocateNextCursorVersion(tenantId, memberId);
                    }
                    int unreadDelta = isSender ? 0 : 1;
                    Long lastReadSeq = isSender ? lastMessageSequence : null;
                    LocalDateTime lastReadTime = isSender ? lastMessageTime : null;
                    Boolean lastMessageHasAtMe = Boolean.FALSE;
                    if (!isSender) {
                        if (mentionParsed.atAll) {
                            lastMessageHasAtMe = Boolean.TRUE;
                        } else if (mentionParsed.userIds != null && mentionParsed.userIds.contains(memberId)) {
                            lastMessageHasAtMe = Boolean.TRUE;
                        }
                    }
                    conversationUserStateMapper.upsertAfterMessage(
                            tenantId, chat.getId(), memberId, cursorVer,
                            unreadDelta, lastReadSeq, lastReadTime,
                            lastMessageId, lastMessageSequence, dbMessageType, finalPreview, lastMessageHasAtMe, lastMessageTime);
                } catch (Exception e) {
                    log.warn("[ImMessageService] 写入会话-用户态失败(群消息), chatId: {}, memberId: {}, error: {}",
                            chat.getId(), memberId, e.getMessage());
                }

                if (!isSender) {
                    imBadgeService.pushBadgeUpdate(memberId);
                }
                pushMessageToUser(memberId, chat.getId(), lastMessageId, lastMessageSequence, finalRev,
                        senderId, sendReqVO, resolveVoiceGroupId(chat));
            }
            
            // 处理@提及强提醒：被@用户即使群免打扰也收到推送
            handleMentionNotifications(chat, lastMessageId, lastMessageSequence, finalRev, senderId, sendReqVO, memberIds);
        } else {
            // 单聊：发送者侧添加"我:"前缀，接收者侧保持原样
            String senderPreview = buildSingleChatPreview(lastMessageContent, true, null);
            String receiverPreview = buildSingleChatPreview(lastMessageContent, false, null);

            ImChatUserDO sender = ensureChatUser(senderId, chat.getId());
            chatUserMapper.updateLastMessageAndIncrementUnread(
                    sender.getId(), lastMessageId, lastMessageSequence, dbMessageType, senderPreview, lastMessageTime,
                    0,
                    Boolean.TRUE.equals(sender.getNoDisturb()));

			// 发送者侧：持久化推进已读水位，避免重登后自己的消息出现未读角标
			if (lastMessageSequence != null) {
				try {
					chatUserMapper.markReadToSequence(senderId, chat.getId(), lastMessageSequence);
				} catch (Exception ignore) {
					// ignore
				}
			}

            // 发送者侧写入 im_conversation_user_state（lastRead=lastSeq，自己发的消息已读）
            Long receiverId = Objects.equals(chat.getSingleUser1(), senderId) ? chat.getSingleUser2() : chat.getSingleUser1();
            Map<Long, Long> cursorVerMap;
            try {
                cursorVerMap = cursorVersionService.allocateNextCursorVersions(tenantId, Arrays.asList(senderId, receiverId));
            } catch (Exception e) {
                cursorVerMap = Collections.emptyMap();
                log.warn("[ImMessageService] 批量分配 cursorVersion 失败(单聊消息), chatId: {}, senderId: {}, error: {}",
                        chat.getId(), senderId, e.getMessage());
            }
            try {
                Long senderCursorVer = cursorVerMap.get(senderId);
                if (senderCursorVer == null) {
                    senderCursorVer = cursorVersionService.allocateNextCursorVersion(tenantId, senderId);
                }
                conversationUserStateMapper.upsertAfterMessage(
                        tenantId, chat.getId(), senderId, senderCursorVer,
                        0, lastMessageSequence, lastMessageTime,
                        lastMessageId, lastMessageSequence, dbMessageType, senderPreview, false, lastMessageTime);
            } catch (Exception e) {
                log.warn("[ImMessageService] 写入会话-用户态失败(单聊发送者), chatId: {}, senderId: {}, error: {}",
                        chat.getId(), senderId, e.getMessage());
            }

            ImChatUserDO receiver = ensureChatUser(receiverId, chat.getId());
            chatUserMapper.updateLastMessageAndIncrementUnread(
                    receiver.getId(), lastMessageId, lastMessageSequence, dbMessageType, receiverPreview, lastMessageTime,
                    1,
                    Boolean.TRUE.equals(receiver.getNoDisturb()));

            // 接收者侧写入 im_conversation_user_state（unreadDelta=1，支持离线 /sync 拉取未读）
            try {
                Long receiverCursorVer = cursorVerMap.get(receiverId);
                if (receiverCursorVer == null) {
                    receiverCursorVer = cursorVersionService.allocateNextCursorVersion(tenantId, receiverId);
                }
                conversationUserStateMapper.upsertAfterMessage(
                        tenantId, chat.getId(), receiverId, receiverCursorVer,
                        1, null, null,
                        lastMessageId, lastMessageSequence, dbMessageType, receiverPreview, false, lastMessageTime);
            } catch (Exception e) {
                log.warn("[ImMessageService] 写入会话-用户态失败(单聊接收者), chatId: {}, receiverId: {}, error: {}",
                        chat.getId(), receiverId, e.getMessage());
            }

            imBadgeService.pushBadgeUpdate(receiverId);
            Long effectiveGroupId = resolveVoiceGroupId(chat);
            pushMessageToUser(senderId, chat.getId(), lastMessageId, lastMessageSequence, finalRev,
                    senderId, sendReqVO, effectiveGroupId);
            pushMessageToUser(receiverId, chat.getId(), lastMessageId, lastMessageSequence, finalRev,
                    senderId, sendReqVO, effectiveGroupId);
        }
    }

    private String resolveConversationPreviewSenderName(Long senderId) {
        if (senderId == null || senderId <= 0) {
            return "";
        }
        try {
            AdminUserDO sender = userMapper.selectById(senderId);
            if (sender != null && StrUtil.isNotBlank(sender.getNickname())) {
                return sender.getNickname().trim();
            }
        } catch (Exception ignore) {
            // ignore
        }
        return "";
    }

    private String buildGroupConversationPreview(String basePreview, boolean isSender,
                                                 String senderDisplayName, Long senderId) {
        String preview = StrUtil.nullToEmpty(basePreview).trim();
        if (preview.isEmpty()) {
            return preview;
        }
        String prefix = isSender
                ? "我"
                : (StrUtil.isNotBlank(senderDisplayName)
                ? senderDisplayName
                : String.valueOf(senderId != null ? senderId : 0L));
        return prefix + ":" + preview;
    }

    /**
     * 构建单聊预览文案：发送者侧添加"我:"前缀，接收者侧保持原样
     */
    private String buildSingleChatPreview(String basePreview, boolean isSender, String senderDisplayName) {
        String preview = StrUtil.nullToEmpty(basePreview).trim();
        if (preview.isEmpty()) {
            return preview;
        }
        if (isSender) {
            return "我:" + preview;
        }
        return preview;
    }

    /**
     * 统一 REST/DB 的 messageType（1-10）与 Protobuf/WebSocket 的 MessageType（100+）
     */
    private Integer normalizeDbMessageType(Integer messageType) {
        if (messageType == null) {
            return null;
        }
        // Protobuf/WebSocket 业务消息（100+）映射到 REST/DB（1-10）
        switch (messageType) {
            case 100:
                return 1;
            case 101:
                return 2;
            case 102:
                return 3;
            case 103:
                return 4;
            case 104:
                return 5;
            case 105:
                return 6;
            case 106:
                return ImMessageTypeEnum.CUSTOM.getType();
            case 205:
                // 引用回复本质上仍然是文本（前端用 quote 渲染），DB 侧按文本存储
                return 1;
            default:
                return messageType;
        }
    }

    private JSONObject validateVoiceExtra(String extra, Long userId, Long chatId, Long groupId) {
        if (StrUtil.isBlank(extra)) {
            throw ServiceExceptionUtil.invalidParamException("VOICE message extra is required: fileId/duration/durationMs/size/format");
        }
        try {
            JSONObject obj = JSONUtil.parseObj(extra);
            Long fileId = obj.getLong("fileId", null);
            Long size = obj.getLong("size", null);
            Integer duration = obj.getInt("duration", null);
            Long durationMs = obj.getLong("durationMs", null);
            String format = obj.getStr("format", "");
            if (fileId == null || fileId <= 0 || size == null || size <= 0
                    || duration == null || duration <= 0 || durationMs == null || durationMs <= 0
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

            FileDTO fileDTO = fileApi.getFile(fileId);
            if (fileDTO == null) {
                throw ServiceExceptionUtil.invalidParamException("VOICE fileId does not exist: {}", fileId);
            }
            VoiceFileOwnershipValidator.validate(fileDTO, userId, chatId, groupId);
            if (fileDTO.getSize() != null && fileDTO.getSize() > 0 && size.longValue() != fileDTO.getSize().longValue()) {
                throw ServiceExceptionUtil.invalidParamException("VOICE size does not match uploaded file record");
            }
            if (StrUtil.isNotBlank(fileDTO.getType()) && !isAllowedVoiceFormat(fileDTO.getType())) {
                throw ServiceExceptionUtil.invalidParamException("VOICE file type is invalid: {}", fileDTO.getType());
            }

            obj.set("duration", normalizedDuration);
            obj.set("durationMs", durationMs);
            obj.set("size", size);
            obj.set("format", format.trim());
            return obj;
        } catch (ServiceException ex) {
            throw ex;
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

    private Long resolveVoiceGroupId(ImChatDO chat) {
        if (chat == null) {
            return null;
        }
        if (Objects.equals(chat.getChatType(), ImConversationTypeEnum.GROUP.getType())
                && chat.getGroupId() != null && chat.getGroupId() > 0L) {
            return chat.getGroupId();
        }
        return null;
    }

    private void pushMessageToUser(Long userId, Long chatId, Long messageId, Long sequence, Long rev, Long senderId,
                                   AppImMessageSendReqVO sendReqVO, Long effectiveGroupId) {
        try {
            Long tenantId = TenantContextHolder.getTenantId();

            // 根据消息类型构建不同的消息体
            MessageType messageType;
            MessageLite messageBody;
            String headerExtra = sendReqVO.getExtra();

            Integer dbMessageType = normalizeDbMessageType(sendReqVO.getMessageType());
            switch (dbMessageType) {
                case 1: // 文本消息
                    messageType = MessageType.TEXT;
					List<Long> atUserIds = buildAtUserIdsFromMentions(sendReqVO.getMentions());
					List<MentionUser> mentionUsers = parseMentionUsers(sendReqVO.getMentions());
					TextMessage.Builder textBuilder = TextMessage.newBuilder().setContent(sendReqVO.getContent());
					if (atUserIds != null && !atUserIds.isEmpty()) {
						textBuilder.addAllAtUserIds(atUserIds);
					}
					if (mentionUsers != null && !mentionUsers.isEmpty()) {
						textBuilder.addAllMentions(mentionUsers);
					}
					messageBody = textBuilder.build();
                    break;
                case 2: // 图片消息
                    messageType = MessageType.IMAGE;
                    messageBody = ImageMessage.newBuilder()
                            .setUrl(sendReqVO.getContent())
                            .build();
                    break;
                case 3: // 语音消息
                    messageType = MessageType.VOICE;
                    String voiceUrl = sendReqVO.getContent();
                    int voiceDuration = 0;
                    long voiceSize = 0L;
                    if (StrUtil.isNotBlank(sendReqVO.getExtra())) {
                        try {
                            JSONObject obj = validateVoiceExtra(sendReqVO.getExtra(), senderId, chatId, effectiveGroupId);
                            headerExtra = obj.toString();
                            if (StrUtil.isBlank(voiceUrl)) {
                                Long fileId = obj.getLong("fileId", null);
                                if (fileId != null && fileId > 0) {
                                    FileDTO fileDTO = fileApi.getFile(fileId);
                                    if (fileDTO != null && StrUtil.isNotBlank(fileDTO.getUrl())) {
                                        voiceUrl = fileDTO.getUrl();
                                    }
                                }
                            }
                            voiceDuration = obj.getInt("duration", 0);
                            voiceSize = obj.getLong("size", 0L);
                        } catch (Exception ignore) {
                            // ignore
                        }
                    }
                    messageBody = VoiceMessage.newBuilder()
                            .setUrl(voiceUrl == null ? "" : voiceUrl)
                            .setDuration(voiceDuration)
                            .setSize(voiceSize)
                            .build();
                    break;
                case 4: // 视频消息
                    messageType = MessageType.VIDEO;
                    messageBody = VideoMessage.newBuilder()
                            .setUrl(sendReqVO.getContent())
                            .build();
                    break;
                case 5: // 文件消息
                    messageType = MessageType.FILE;
                    // 优先从 extra JSON 中取元数据（fileName/size/fileType/url），确保端侧展示一致
                    String url = sendReqVO.getContent();
                    String fileName = "";
                    long size = 0L;
                    String fileType = "";
                    if (StrUtil.isNotBlank(sendReqVO.getExtra())) {
                        try {
                            JSONObject obj = JSONUtil.parseObj(sendReqVO.getExtra());
                            if (StrUtil.isBlank(url)) {
                                url = obj.getStr("url", "");
                            }
                            fileName = obj.getStr("fileName", obj.getStr("name", ""));
                            size = obj.getLong("size", 0L);
                            fileType = obj.getStr("fileType", obj.getStr("mimeType", ""));
                        } catch (Exception ignore) {
                            // ignore
                        }
                    }
                    if (StrUtil.isBlank(fileName) && StrUtil.isNotBlank(url)) {
                        int idx = url.lastIndexOf('/');
                        fileName = idx >= 0 ? url.substring(idx + 1) : url;
                    }
                    FileMessage.Builder fileBuilder = FileMessage.newBuilder()
                            .setUrl(url == null ? "" : url)
                            .setFileName(fileName == null ? "" : fileName)
                            .setSize(size)
                            .setFileType(fileType == null ? "" : fileType);
                    messageBody = fileBuilder.build();
                    // 同步补齐 header.extra，便于存储侧直接落库
                    if (StrUtil.isBlank(headerExtra)) {
                        JSONObject obj = JSONUtil.createObj();
                        obj.set("url", url);
                        obj.set("fileName", fileName);
                        obj.set("size", size);
                        obj.set("fileType", fileType);
                        headerExtra = obj.toString();
                    }
                    break;
                case 6: // 位置消息
                    messageType = MessageType.LOCATION;
                    JSONObject locationObj = buildAndValidateLocationPayload(sendReqVO);
                    messageBody = LocationMessage.newBuilder()
                            .setLatitude(locationObj.getDouble("latitude", 0D))
                            .setLongitude(locationObj.getDouble("longitude", 0D))
                            .setAddress(locationObj.getStr("address", ""))
                            .build();
                    headerExtra = locationObj.toString();
                    break;
                case 9: // 自定义消息
                    messageType = MessageType.CUSTOM;
                    JSONObject customPayload = validateAndNormalizeCustomPayload(sendReqVO);
                    messageBody = TextMessage.newBuilder()
                            .setContent(customPayload.toString())
                            .build();
                    headerExtra = customPayload.toString();
                    break;
                case 8: // 自定义贴纸
                    messageType = MessageType.CUSTOM;
                    JSONObject stickerPayload = StrUtil.isNotBlank(sendReqVO.getExtra()) ? JSONUtil.parseObj(sendReqVO.getExtra()) : JSONUtil.createObj();
                    stickerPayload.set("type", "STICKER");
                    if (StrUtil.isBlank(stickerPayload.getStr("url", ""))) {
                        stickerPayload.set("url", StrUtil.nullToEmpty(sendReqVO.getContent()));
                    }
                    messageBody = TextMessage.newBuilder()
                            .setContent(stickerPayload.toString())
                            .build();
                    headerExtra = stickerPayload.toString();
                    break;
                default:
                    // 默认使用系统通知类型
                    messageType = MessageType.SYSTEM_NOTIFY;
                    messageBody = TextMessage.newBuilder()
                            .setContent(sendReqVO.getContent())
                            .build();
                    break;
            }

            Long receiverId = sendReqVO.getReceiverId();
            Long groupId = effectiveGroupId != null && effectiveGroupId > 0L ? effectiveGroupId : null;

            // enterprise: include rev for final-state merge; merge with existing header.extra (e.g. file metadata)
            String extraWithRev = null;
            Long finalRev = rev != null && rev > 0 ? rev : 1L;
            try {
                JSONObject obj = StrUtil.isNotBlank(headerExtra) ? JSONUtil.parseObj(headerExtra) : JSONUtil.createObj();
                obj.set("rev", finalRev);
                if (StrUtil.isNotBlank(sendReqVO.getClientMessageId())) {
                    obj.set("clientMessageId", sendReqVO.getClientMessageId());
                }
                extraWithRev = obj.toString();
            } catch (Exception e) {
                try {
                    JSONObject obj = JSONUtil.createObj();
                    obj.set("rev", finalRev);
                    if (StrUtil.isNotBlank(sendReqVO.getClientMessageId())) {
                        obj.set("clientMessageId", sendReqVO.getClientMessageId());
                    }
                    extraWithRev = obj.toString();
                } catch (Exception ignore) {
                    extraWithRev = null;
                }
            }

            // 群聊推送给成员时，前端会话路由依赖 groupId；单聊依赖 receiverId/senderId
            messageSender.sendToUserWithExtra(userId, messageType, messageBody,
                    senderId, receiverId, groupId, tenantId, messageId, sequence, chatId,
                    null, null, extraWithRev);
            log.debug("[ImMessageService] WebSocket 消息推送成功, userId: {}, messageId: {}", userId, messageId);
        } catch (Exception e) {
            log.error("[ImMessageService] WebSocket 消息推送失败, userId: {}, messageId: {}", userId, messageId, e);
        }
    }

    /**
     * 处理@提及强提醒
     * 被提及用户即使群免打扰也会收到推送
     * 
     * @param chat 会话
     * @param messageId 消息ID
     * @param sequence 序列号
     * @param rev 版本号
     * @param senderId 发送者ID
     * @param sendReqVO 发送请求
     * @param memberIds 群成员ID列表
     */
    private void handleMentionNotifications(ImChatDO chat, Long messageId, Long sequence, Long rev,
                                             Long senderId, AppImMessageSendReqVO sendReqVO, List<Long> memberIds) {
        String mentionsJson = sendReqVO.getMentions();
        if (StrUtil.isBlank(mentionsJson)) {
            return;
        }
        
        try {
            // 解析mentions字段
            List<JSONObject> mentions = JSONUtil.parseArray(mentionsJson).toList(JSONObject.class);
            if (mentions == null || mentions.isEmpty()) {
                return;
            }
            
            // 提取被@用户ID（支持 userId=-1 表示@所有人）
            boolean atAll = false;
            List<Long> mentionedUserIds = new ArrayList<>();
            for (JSONObject m : mentions) {
                if (m == null) {
                    continue;
                }
                Long id = m.getLong("userId");
                if (id == null) {
                    continue;
                }
                if (id == -1L) {
                    atAll = true;
                    continue;
                }
                mentionedUserIds.add(id);
            }
            
            if (!atAll && mentionedUserIds.isEmpty()) {
                return;
            }
            
            log.info("[ImMessageService] 处理@提及强提醒, chatId: {}, mentionedUserIds: {}", 
                    chat.getId(), mentionedUserIds);
            
            // 对被@用户发送强提醒推送（即使群免打扰）
            List<Long> targets;
            if (atAll) {
                targets = memberIds != null ? memberIds : Collections.emptyList();
            } else {
                targets = mentionedUserIds;
            }
            for (Long mentionedUserId : targets) {
                if (Objects.equals(mentionedUserId, senderId)) {
                    continue; // 不给自己推送
                }
                
                // 检查是否是群成员
                if (memberIds != null && !memberIds.contains(mentionedUserId)) {
                    log.warn("[ImMessageService] 被@用户不在群成员列表中, userId: {}, chatId: {}", 
                            mentionedUserId, chat.getId());
                    continue;
                }
                
                // 强提醒推送：即使群免打扰也推送
                try {
                    // 构建强提醒消息
                    JSONObject extraData = new JSONObject();
                    extraData.set("mentionType", "SINGLE");
                    extraData.set("forceNotify", true);
                    
                    TextMessage notifyBody = TextMessage.newBuilder()
                            .setContent("[有人@我]")
                            .build();
                    
                    Long tenantId = TenantContextHolder.getTenantId();
                    messageSender.sendToUserWithExtra(mentionedUserId, MessageType.TEXT, notifyBody,
                            senderId, null, chat.getGroupId(), tenantId != null ? tenantId : 0L,
                            messageId, sequence, chat.getId(),
                            null, null, extraData.toString());
                    
                    log.debug("[ImMessageService] @提及强提醒推送成功, mentionedUserId: {}, messageId: {}", 
                            mentionedUserId, messageId);
                } catch (Exception e) {
                    log.warn("[ImMessageService] @提及强提醒推送失败, mentionedUserId: {}, messageId: {}, error: {}", 
                            mentionedUserId, messageId, e.getMessage());
                }
            }
        } catch (Exception e) {
            log.warn("[ImMessageService] 解析mentions字段失败, mentions: {}, error: {}", 
                    mentionsJson, e.getMessage());
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

    private void fillSenderInfo(AppImMessageRespVO respVO, Long senderId, Long chatId) {
        if (respVO == null || senderId == null) {
            return;
        }
        ImChatDO chat = chatId != null ? chatMapper.selectById(chatId) : null;
        fillSenderInfo(respVO, senderId, chat, null, null);
    }

    private void fillSenderInfo(AppImMessageRespVO respVO, Long senderId, ImChatDO chat,
                                Map<Long, AdminUserDO> senderMap, Map<Long, String> groupNicknameMap) {
        if (respVO == null || senderId == null) {
            return;
        }
        String groupNickname = resolveGroupMemberNickname(chat, senderId, groupNicknameMap);
        AdminUserDO sender = senderMap != null ? senderMap.get(senderId) : userMapper.selectById(senderId);
        if (StrUtil.isNotBlank(groupNickname)) {
            respVO.setSenderNickname(groupNickname);
        } else if (sender != null) {
            respVO.setSenderNickname(sender.getNickname());
        }
        if (sender != null) {
            respVO.setSenderAvatar(sender.getAvatar());
        }
    }

    private Map<Long, String> buildGroupNicknameMap(ImChatDO chat, Collection<Long> senderIds) {
        if (chat == null || chat.getGroupId() == null || !ImConversationTypeEnum.isGroup(chat.getChatType())
                || senderIds == null || senderIds.isEmpty()) {
            return Collections.emptyMap();
        }
        List<Long> userIds = senderIds.stream()
                .filter(Objects::nonNull)
                .distinct()
                .collect(Collectors.toList());
        if (userIds.isEmpty()) {
            return Collections.emptyMap();
        }
        return groupUserMapper.selectListByGroupIdAndUserIds(chat.getGroupId(), userIds).stream()
                .filter(Objects::nonNull)
                .filter(item -> item.getUserId() != null && StrUtil.isNotBlank(item.getNickname()))
                .collect(Collectors.toMap(ImGroupUserDO::getUserId,
                        item -> StrUtil.trim(item.getNickname()),
                        (left, right) -> left));
    }

    private String resolveGroupMemberNickname(ImChatDO chat, Long senderId, Map<Long, String> groupNicknameMap) {
        if (chat == null || senderId == null || chat.getGroupId() == null || !ImConversationTypeEnum.isGroup(chat.getChatType())) {
            return null;
        }
        if (groupNicknameMap != null) {
            String nickname = groupNicknameMap.get(senderId);
            if (StrUtil.isNotBlank(nickname)) {
                return nickname;
            }
        }
        ImGroupUserDO groupUser = groupUserMapper.selectByGroupIdAndUserId(chat.getGroupId(), senderId);
        if (groupUser == null || StrUtil.isBlank(groupUser.getNickname())) {
            return null;
        }
        return StrUtil.trim(groupUser.getNickname());
    }

    private void fillChatTargetFields(AppImMessageRespVO respVO, Long currentUserId) {
        if (respVO.getChatId() == null) {
            return;
        }
        ImChatDO chat = chatMapper.selectById(respVO.getChatId());
        if (chat == null) {
            return;
        }
        if (ImConversationTypeEnum.isGroup(chat.getChatType())) {
            respVO.setGroupId(chat.getGroupId());
        } else {
            Long receiverId = Objects.equals(chat.getSingleUser1(), currentUserId) ? chat.getSingleUser2() : chat.getSingleUser1();
            respVO.setReceiverId(receiverId);
        }
    }

    private void fillConversationInfo(AppImMessageRespVO respVO, Long currentUserId) {
        if (respVO.getChatId() == null) {
            return;
        }
        ImChatDO chat = chatMapper.selectById(respVO.getChatId());
        if (chat == null) {
            return;
        }
        if (ImConversationTypeEnum.isGroup(chat.getChatType())) {
            if (chat.getGroupId() == null) {
                return;
            }
            ImGroupDO group = groupMapper.selectById(chat.getGroupId());
            if (group != null) {
                respVO.setConversationName(group.getName());
                respVO.setConversationAvatar(group.getAvatar());
            }
            return;
        }
        Long otherUserId = Objects.equals(chat.getSingleUser1(), currentUserId) ? chat.getSingleUser2() : chat.getSingleUser1();
        if (otherUserId == null) {
            return;
        }
        AdminUserDO otherUser = userMapper.selectById(otherUserId);
        if (otherUser != null) {
            respVO.setConversationName(otherUser.getNickname());
            respVO.setConversationAvatar(otherUser.getAvatar());
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long forwardMessage(Long userId, Long messageId, Long targetChatId) {
        // 单条转发，复用批量转发逻辑
        AppImMessageForwardReqVO forwardReqVO = new AppImMessageForwardReqVO();
        forwardReqVO.setTargetChatId(targetChatId);
        forwardReqVO.setMessageIds(Collections.singletonList(messageId));
        forwardReqVO.setForwardType(ImMessageForwardTypeEnum.SINGLE.getType());
        List<Long> result = forwardMessages(userId, forwardReqVO);
        return result != null && !result.isEmpty() ? result.get(0) : null;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public List<Long> forwardMessages(Long userId, AppImMessageForwardReqVO forwardReqVO) {
        Long targetChatId = forwardReqVO.getTargetChatId();
        List<Long> messageIds = forwardReqVO.getMessageIds();
        Integer forwardType = forwardReqVO.getForwardType();

        if (targetChatId == null || targetChatId <= 0) {
            throw exception(MESSAGE_SEND_FAILED, "目标会话不能为空");
        }
        if (messageIds == null || messageIds.isEmpty()) {
            throw exception(MESSAGE_SEND_FAILED, "转发消息不能为空");
        }
        if (messageIds.size() > 50) {
            throw exception(MESSAGE_SEND_FAILED, "单次最多转发50条消息");
        }
        List<Long> normalizedMessageIds = messageIds.stream()
                .filter(Objects::nonNull)
                .filter(id -> id > 0)
                .distinct()
                .collect(Collectors.toList());
        if (normalizedMessageIds.isEmpty()) {
            throw exception(MESSAGE_SEND_FAILED, "转发消息不能为空");
        }
        messageIds = normalizedMessageIds;
        if (ImMessageForwardTypeEnum.valueOf(forwardType) == null) {
            throw exception(MESSAGE_SEND_FAILED, "转发类型非法");
        }

        try {
            log.info("[IM][forward] start userId={}, targetChatId={}, forwardType={}, messageIds.size={}",
                    userId, targetChatId, forwardType, messageIds != null ? messageIds.size() : 0);
        } catch (Exception ignore) {
            // ignore
        }

        // 1. 校验目标会话
        ImChatUserDO targetChatUser = chatUserMapper.selectByUserIdAndChatId(userId, targetChatId);
        if (targetChatUser == null) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }
        ImChatDO targetChat = chatMapper.selectById(targetChatId);
        if (targetChat == null) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }

        try {
            log.info("[IM][forward] target chat meta chatId={}, chatType={}, groupId={}, singleUser1={}, singleUser2={}",
                    targetChat.getId(), targetChat.getChatType(), targetChat.getGroupId(),
                    targetChat.getSingleUser1(), targetChat.getSingleUser2());
        } catch (Exception ignore) {
            // ignore
        }

        // 2. 查询原消息并校验可见性
        List<ImChatMessageDO> originalMessages = chatMessageMapper.selectBatchIds(messageIds);
        if (originalMessages == null || originalMessages.isEmpty()) {
            throw exception(MESSAGE_NOT_EXISTS);
        }

        try {
            log.info("[IM][forward] load originalMessages ok requested={}, loaded={}",
                    messageIds != null ? messageIds.size() : 0, originalMessages.size());
        } catch (Exception ignore) {
            // ignore
        }

        Long tenantId = TenantContextHolder.getTenantId();
        if (tenantId == null) {
            tenantId = 0L;
        }

        // 过滤不可转发的消息：已撤回、已删除(tombstone)、不可见（非会话成员）
        List<ImChatMessageDO> forwardableMessages = new java.util.ArrayList<>();
        java.util.Map<Long, Integer> inputOrder = new java.util.HashMap<>();
        for (int i = 0; i < messageIds.size(); i++) {
            Long mid = messageIds.get(i);
            if (mid != null) {
                inputOrder.put(mid, i);
            }
        }
        for (ImChatMessageDO msg : originalMessages) {
            if (msg == null) {
                continue;
            }
            // 必须是自己可见的消息：只有会话成员才能转发（避免越权通过 messageId 读取他人会话消息）
            try {
                ImChatUserDO sourceChatUser = chatUserMapper.selectByUserIdAndChatId(userId, msg.getChatId());
                if (sourceChatUser == null) {
                    log.warn("[ImMessageService] 转发跳过不可见消息, userId: {}, messageId: {}, chatId: {}", userId, msg.getId(), msg.getChatId());
                    continue;
                }
            } catch (Exception ignore) {
                continue;
            }
            // 已撤回消息不可转发
            if (Objects.equals(msg.getStatus(), ImMessageStatusEnum.RECALLED.getStatus())) {
                log.warn("[ImMessageService] 转发跳过已撤回消息, messageId: {}", msg.getId());
                continue;
            }
            // tombstone过滤：对我删除的消息不可转发
            boolean isDeleted = chatMessageTombstoneMapper.existsByUserIdAndMessageId(userId, msg.getId());
            if (isDeleted) {
                log.warn("[ImMessageService] 转发跳过已删除消息, userId: {}, messageId: {}", userId, msg.getId());
                continue;
            }
            forwardableMessages.add(msg);
        }

        // 保持与入参 messageIds 一致的顺序（selectBatchIds 不保证顺序）
        try {
            forwardableMessages.sort((a, b) -> {
                Integer ia = inputOrder.get(a.getId());
                Integer ib = inputOrder.get(b.getId());
                if (ia == null && ib == null) {
                    return 0;
                }
                if (ia == null) {
                    return 1;
                }
                if (ib == null) {
                    return -1;
                }
                return ia.compareTo(ib);
            });
        } catch (Exception ignore) {
            // ignore
        }

        if (forwardableMessages.isEmpty()) {
            throw exception(MESSAGE_SEND_FAILED, "无可转发的消息");
        }

        try {
            log.info("[IM][forward] filter forwardable done forwardType={}, forwardableCount={} (requested={})",
                    forwardType, forwardableMessages.size(), messageIds != null ? messageIds.size() : 0);
        } catch (Exception ignore) {
            // ignore
        }

        // 3. 获取原发送者信息用于隐私保护展示
        List<Long> senderIds = forwardableMessages.stream()
                .map(ImChatMessageDO::getSenderId)
                .distinct()
                .collect(Collectors.toList());
        Map<Long, AdminUserDO> senderMap = new java.util.HashMap<>();
        if (!senderIds.isEmpty()) {
            List<AdminUserDO> senders = userMapper.selectBatchIds(senderIds);
            if (senders != null) {
                for (AdminUserDO sender : senders) {
                    senderMap.put(sender.getId(), sender);
                }
            }
        }

        List<Long> newMessageIds = new java.util.ArrayList<>();
        LocalDateTime forwardTime = LocalDateTime.now();

        // 4. 根据转发类型处理
        if (Objects.equals(forwardType, ImMessageForwardTypeEnum.COMBINE.getType())) {
            // 合并转发：生成一条 FORWARD_COMBINE 类型消息
            Long newMessageId = createCombineForwardMessage(userId, targetChat, forwardableMessages, 
                    senderMap, forwardReqVO.getComment(), forwardTime);
            newMessageIds.add(newMessageId);

            try {
                log.info("[IM][forward] combine ok userId={}, targetChatId={}, newMessageId={}, originalCount={}",
                        userId, targetChat.getId(), newMessageId, forwardableMessages.size());
            } catch (Exception ignore) {
                // ignore
            }
        } else {
            // 逐条转发：每条消息生成新消息
            for (ImChatMessageDO originalMsg : forwardableMessages) {
                Long newMessageId = createSingleForwardMessage(userId, targetChat, originalMsg, 
                        senderMap.get(originalMsg.getSenderId()), forwardTime);
                newMessageIds.add(newMessageId);
            }

            try {
                log.info("[IM][forward] single ok userId={}, targetChatId={}, newMessageIds.size={}, originalCount={}",
                        userId, targetChat.getId(), newMessageIds.size(), forwardableMessages.size());
            } catch (Exception ignore) {
                // ignore
            }
        }

        log.info("[ImMessageService] 转发消息成功, userId: {}, forwardType: {}, originalCount: {}, newMessageIds: {}",
                userId, forwardType, forwardableMessages.size(), newMessageIds);
        return newMessageIds;
    }

    @Override
    public AppImMessageRecallConfigRespVO getRecallConfig(Long userId) {
        AppImMessageRecallConfigRespVO respVO = new AppImMessageRecallConfigRespVO();
        respVO.setWindowSeconds((int) recallWindowSeconds);
        respVO.setAdminWindowSeconds((int) recallAdminWindowSeconds);
        return respVO;
    }

    /**
     * 创建单条转发消息
     */
    private Long createSingleForwardMessage(Long userId, ImChatDO targetChat, ImChatMessageDO originalMsg,
                                             AdminUserDO originalSender, LocalDateTime forwardTime) {
        ImChatMessageDO newMessage = new ImChatMessageDO();
        newMessage.setChatId(targetChat.getId());
        newMessage.setSenderId(userId);
        newMessage.setMessageType(originalMsg.getMessageType());
        newMessage.setContent(originalMsg.getContent());
        newMessage.setExtra(originalMsg.getExtra());

        Long sequence = chatMapper.nextSequence(targetChat.getId());
        newMessage.setSequence(sequence);
        newMessage.setSendTime(forwardTime);
        newMessage.setRev(1L);
        newMessage.setStatus(ImMessageStatusEnum.SENT.getStatus());

        // 构建转发来源信息
        JSONObject forwardedFrom = new JSONObject();
        forwardedFrom.set("originalMessageId", originalMsg.getId() != null ? originalMsg.getId().toString() : "");
        forwardedFrom.set("originalChatId", originalMsg.getChatId() != null ? originalMsg.getChatId().toString() : "");
        forwardedFrom.set("originalSenderId", originalMsg.getSenderId() != null ? originalMsg.getSenderId().toString() : "");
        forwardedFrom.set("originalSenderName", originalSender != null ? originalSender.getNickname() : "");
        forwardedFrom.set("forwardTime", forwardTime.toString());
        newMessage.setForwardedFrom(forwardedFrom.toString());

        chatMessageMapper.insert(newMessage);

        try {
            log.info("[IM][forward] insert single ok newMessageId={}, targetChatId={}, originalMessageId={}, originalChatId={}, originalType={}",
                    newMessage.getId(), targetChat.getId(),
                    originalMsg.getId(), originalMsg.getChatId(), originalMsg.getMessageType());
        } catch (Exception ignore) {
            // ignore
        }

        // 更新会话状态并推送
        String preview = getMessagePreview(originalMsg.getMessageType(), originalMsg.getContent());
        AppImMessageSendReqVO sendReqVO = new AppImMessageSendReqVO();
        sendReqVO.setMessageType(originalMsg.getMessageType());
        sendReqVO.setContent(originalMsg.getContent());
        sendReqVO.setExtra(originalMsg.getExtra());
        sendReqVO.setMentions(originalMsg.getMentions());
        fillForwardPushRoute(sendReqVO, targetChat, userId);
        updateChatUsersAfterSend(targetChat, newMessage.getId(), sequence, 1L, preview, forwardTime, userId, sendReqVO);

        return newMessage.getId();
    }

    /**
     * 创建合并转发消息
     */
    private Long createCombineForwardMessage(Long userId, ImChatDO targetChat, List<ImChatMessageDO> originalMessages,
                                              Map<Long, AdminUserDO> senderMap, String comment, LocalDateTime forwardTime) {
        ImChatMessageDO newMessage = new ImChatMessageDO();
        newMessage.setChatId(targetChat.getId());
        newMessage.setSenderId(userId);
        // 合并转发使用 CUSTOM 类型，前端按合并消息渲染
        newMessage.setMessageType(ImMessageTypeEnum.CUSTOM.getType());

        // 构建合并消息内容
        JSONObject body = new JSONObject();
        body.set("type", "FORWARD_COMBINE");

        // 构建消息列表
        List<JSONObject> messages = new java.util.ArrayList<>();
        int nestedRefCount = 0;
        int maxNestedDepth = 0;
        for (ImChatMessageDO msg : originalMessages) {
            JSONObject msgObj = new JSONObject();
            msgObj.set("messageId", msg.getId() != null ? msg.getId().toString() : "");
            msgObj.set("sourceChatId", msg.getChatId() != null ? msg.getChatId().toString() : "");
            msgObj.set("sourceSequence", msg.getSequence() != null ? msg.getSequence().toString() : "");

            // 引用化：如果合并包里又包含“聊天记录(合并转发消息)”，不再嵌套其 messages，避免套娃与消息体膨胀
            boolean isNestedCombine = false;
            int nestedDepth = 1;
            try {
                if (Objects.equals(msg.getMessageType(), ImMessageTypeEnum.CUSTOM.getType()) && StrUtil.isNotBlank(msg.getContent())) {
                    JSONObject nested = JSONUtil.parseObj(msg.getContent());
                    String t = nested.getStr("type", "");
                    if (StrUtil.isNotBlank(t) && Objects.equals(t, "FORWARD_COMBINE")) {
                        isNestedCombine = true;
                        Integer depth = nested.getInt("depth");
                        if (depth != null && depth > 0) {
                            nestedDepth = depth;
                        }
                    }
                }
            } catch (Exception ignore) {
                // ignore
            }

            if (isNestedCombine) {
                msgObj.set("messageType", ImMessageTypeEnum.TEXT.getType());
                msgObj.set("content", "[聊天记录]");
                msgObj.set("refMessageId", msg.getId() != null ? msg.getId().toString() : "");
                nestedRefCount++;
                if (nestedDepth > maxNestedDepth) {
                    maxNestedDepth = nestedDepth;
                }
            } else {
                msgObj.set("messageType", msg.getMessageType());
                msgObj.set("content", msg.getContent());
                msgObj.set("extra", msg.getExtra());
            }

            msgObj.set("senderId", msg.getSenderId() != null ? msg.getSenderId().toString() : "");
            AdminUserDO sender = senderMap.get(msg.getSenderId());
            msgObj.set("senderName", sender != null ? sender.getNickname() : "");
            msgObj.set("sendTime", msg.getSendTime() != null ? msg.getSendTime().toString() : "");
            messages.add(msgObj);
        }
        body.set("messages", messages);
        body.set("count", messages.size());
        int combineDepth = maxNestedDepth > 0 ? (maxNestedDepth + 1) : 1;
        if (combineDepth > MAX_FORWARD_COMBINE_DEPTH) {
            throw exception(MESSAGE_SEND_FAILED, "聊天记录引用层级过深");
        }
        body.set("depth", combineDepth);
        if (StrUtil.isNotBlank(comment)) {
            body.set("comment", comment);
        }

        newMessage.setContent(body.toString());

        Long sequence = chatMapper.nextSequence(targetChat.getId());
        newMessage.setSequence(sequence);
        newMessage.setSendTime(forwardTime);
        newMessage.setRev(1L);
        newMessage.setStatus(ImMessageStatusEnum.SENT.getStatus());

        // 构建转发来源信息（合并转发记录所有原消息）
        JSONObject forwardedFrom = new JSONObject();
        forwardedFrom.set("type", "COMBINE");
        forwardedFrom.set("messageIds", originalMessages.stream().map(m -> m.getId() != null ? m.getId().toString() : "").collect(Collectors.toList()));
        forwardedFrom.set("forwardTime", forwardTime.toString());
        newMessage.setForwardedFrom(forwardedFrom.toString());

        chatMessageMapper.insert(newMessage);

        try {
            log.info("[IM][forward] insert combine ok newMessageId={}, targetChatId={}, originalCount={}, nestedRefCount={}",
                    newMessage.getId(), targetChat.getId(), originalMessages != null ? originalMessages.size() : 0, nestedRefCount);
        } catch (Exception ignore) {
            // ignore
        }

        // 更新会话状态并推送
        String preview = "[合并转发] " + originalMessages.size() + "条消息";
        AppImMessageSendReqVO sendReqVO = new AppImMessageSendReqVO();
        sendReqVO.setMessageType(ImMessageTypeEnum.CUSTOM.getType());
        sendReqVO.setContent(newMessage.getContent());
        fillForwardPushRoute(sendReqVO, targetChat, userId);
        updateChatUsersAfterSend(targetChat, newMessage.getId(), sequence, 1L, preview, forwardTime, userId, sendReqVO);

        return newMessage.getId();
    }

    private void fillForwardPushRoute(AppImMessageSendReqVO sendReqVO, ImChatDO targetChat, Long senderId) {
        if (sendReqVO == null || targetChat == null) {
            return;
        }
        sendReqVO.setChatId(targetChat.getId());
        if (ImConversationTypeEnum.isGroup(targetChat.getChatType())) {
            sendReqVO.setGroupId(targetChat.getGroupId());
            sendReqVO.setReceiverId(null);
            return;
        }
        Long receiverId = Objects.equals(targetChat.getSingleUser1(), senderId)
                ? targetChat.getSingleUser2()
                : targetChat.getSingleUser1();
        sendReqVO.setReceiverId(receiverId);
        sendReqVO.setGroupId(null);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void recallMessage(Long userId, Long messageId) {
        ImChatMessageDO message = chatMessageMapper.selectById(messageId);
        if (message == null) {
            throw exception(MESSAGE_NOT_EXISTS);
        }

        // 幂等：已撤回消息不重复撤回，避免 rev 无意义递增导致多端最终态抖动
        if (Objects.equals(message.getStatus(), ImMessageStatusEnum.RECALLED.getStatus())) {
            return;
        }
        
        ImChatDO chat = chatMapper.selectById(message.getChatId());
        if (chat == null) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }
        
        // 权限检查：判断是否可以撤回
        boolean isSelfMessage = Objects.equals(message.getSenderId(), userId);
        boolean isGroupChat = ImConversationTypeEnum.isGroup(chat.getChatType());
        Integer memberRole = null;
        
        if (isGroupChat && !isSelfMessage) {
            // 群聊中撤回他人消息：检查是否是群主或管理员
            memberRole = imGroupService.getMemberRole(chat.getGroupId(), userId);
            if (memberRole == null) {
                throw exception(MESSAGE_RECALL_PERMISSION_DENIED);
            }
            // 只有群主(2)和管理员(1)可以撤回他人消息
            if (!ImGroupMemberRoleEnum.isOwner(memberRole) && !ImGroupMemberRoleEnum.isAdmin(memberRole)) {
                throw exception(MESSAGE_RECALL_PERMISSION_DENIED);
            }

            // enterprise: 权限细分 - 管理员仅可撤回普通成员消息，不可撤回群主/管理员消息（避免越权）
            if (ImGroupMemberRoleEnum.isAdmin(memberRole)) {
                Integer senderRole = imGroupService.getMemberRole(chat.getGroupId(), message.getSenderId());
                if (senderRole == null) {
                    throw exception(MESSAGE_RECALL_PERMISSION_DENIED);
                }
                if (ImGroupMemberRoleEnum.isOwner(senderRole) || ImGroupMemberRoleEnum.isAdmin(senderRole)) {
                    throw exception(MESSAGE_RECALL_PERMISSION_DENIED);
                }
            }
        } else if (!isSelfMessage) {
            // 单聊只能撤回自己的消息
            throw exception(MESSAGE_RECALL_PERMISSION_DENIED);
        }
        
        // 时限检查
        long windowSec;
        boolean unlimitedWindow = false;
        if (isSelfMessage) {
            // 自己的消息：默认2分钟
            windowSec = recallWindowSeconds > 0 ? recallWindowSeconds : 120L;
        } else if (ImGroupMemberRoleEnum.isOwner(memberRole)) {
            // 群主撤回：不限时
            windowSec = 0L;
            unlimitedWindow = true;
        } else {
            // 管理员撤回：默认24小时
            windowSec = recallAdminWindowSeconds > 0 ? recallAdminWindowSeconds : 24 * 60 * 60L;
        }

        if (!unlimitedWindow) {
            if (message.getSendTime() == null) {
                throw exception(MESSAGE_RECALL_TIMEOUT);
            }
            LocalDateTime windowAgo = LocalDateTime.now().minusSeconds(windowSec);
            if (message.getSendTime().isBefore(windowAgo)) {
                throw exception(MESSAGE_RECALL_TIMEOUT);
            }
        }
        
        LocalDateTime recallTime = LocalDateTime.now();
        Long oldRev = message.getRev() != null && message.getRev() > 0 ? message.getRev() : 1L;
        Long newRev = oldRev + 1L;
        String recallExtra = null;
        String recallerName = "";
        String senderName = "";
        try {
            AdminUserDO recaller = userMapper.selectById(userId);
            if (recaller != null && StrUtil.isNotBlank(recaller.getNickname())) {
                recallerName = recaller.getNickname().trim();
            }
            if (message.getSenderId() != null && message.getSenderId() > 0L) {
                if (Objects.equals(message.getSenderId(), userId) && StrUtil.isNotBlank(recallerName)) {
                    senderName = recallerName;
                } else {
                    AdminUserDO sender = userMapper.selectById(message.getSenderId());
                    if (sender != null && StrUtil.isNotBlank(sender.getNickname())) {
                        senderName = sender.getNickname().trim();
                    }
                }
            }
            JSONObject ex = JSONUtil.createObj();
            ex.set("senderName", senderName);
            ex.set("recallerName", recallerName);
            if (isSelfMessage && isReeditEligibleTextMessage(message, userId)) {
                ex.set("reeditContent", message.getContent());
                long deadlineTs = recallTime.plusSeconds(300L).atZone(java.time.ZoneId.systemDefault()).toInstant().toEpochMilli();
                ex.set("reeditDeadlineTs", String.valueOf(deadlineTs));
                ex.set("senderId", String.valueOf(userId));
                ex.set("isSelfRecall", true);
            }
            recallExtra = imSystemMessageI18nSupport.attachI18n(ex.toString(),
                    ImSystemMessageI18nSupport.EVENT_RECALL_PREVIEW, Collections.emptyMap());
        } catch (Exception ignore) {
            recallExtra = null;
        }
        LambdaUpdateWrapper<ImChatMessageDO> recallUpdate = new LambdaUpdateWrapper<ImChatMessageDO>()
                .eq(ImChatMessageDO::getId, messageId)
                .set(ImChatMessageDO::getStatus, ImMessageStatusEnum.RECALLED.getStatus())
                .set(ImChatMessageDO::getRecallTime, recallTime)
                .set(ImChatMessageDO::getRecallBy, userId)
                .setSql("rev = IFNULL(rev, 1) + 1");
        if (StrUtil.isNotBlank(recallExtra)) {
            recallUpdate.set(ImChatMessageDO::getExtra, recallExtra);
        }
        chatMessageMapper.update(null, recallUpdate);

        // 企微/钉钉口径：撤回影响会话列表预览的“最终态一致”，需持久化落库并通过 cursorVersion 增量同步到其它端
        try {
            Long tenantId = TenantContextHolder.getTenantId();
            if (tenantId == null) {
                tenantId = 0L;
            }
            ImChatDO messageChat = chatMapper.selectById(message.getChatId());
            if (messageChat != null) {
                List<ImChatUserDO> chatUsers = chatUserMapper.selectList(new LambdaQueryWrapperX<ImChatUserDO>()
                        .eq(ImChatUserDO::getChatId, message.getChatId())
                        .eq(ImChatUserDO::getDeletedByUser, false)
                        .eq(ImChatUserDO::getDeleted, false));
                if (chatUsers != null) {
                    for (ImChatUserDO cu : chatUsers) {
                        if (cu == null) {
                            continue;
                        }
                        // 仅当撤回消息仍是该用户会话 lastMessage 时才更新预览（避免 lastMessage 已推进造成回写覆盖）
                        int updated = chatUserMapper.updateLastMessagePreviewIfMatch(
                                cu.getId(),
                                messageId,
                                10,
                                "[消息已撤回]"
                        );
                        if (updated <= 0) {
                            continue;
                        }

                        Long targetUserId = cu.getUserId();
                        Long cursorVersion = cursorVersionService.allocateNextCursorVersion(tenantId, targetUserId);
                        // unreadCount/lastReadSeq 由 existing state/max 规则兜底，这里只用于推动“会话预览变更”跨端可见
                        conversationUserStateMapper.upsertAfterMessage(
                                tenantId,
                                message.getChatId(),
                                targetUserId,
                                cursorVersion,
                                0,
                                0L,
                                null,
                                messageId,
                                message.getSequence() != null ? message.getSequence() : 0L,
                                10,
                                "[消息已撤回]",
                                false,
                                message.getSendTime() != null ? message.getSendTime() : recallTime
                        );

                        // 主动推送“会话快照变更提示”，促使端侧增量 sync(cursor) 及时拉取预览变更（对标企微/钉钉多端一致）
                        try {
                            TextMessage notifyBody = TextMessage.newBuilder().setContent("").build();
                            messageSender.sendToUser(targetUserId, MessageType.SYSTEM_NOTIFY, notifyBody,
                                    0L, targetUserId, 0L, tenantId,
                                    null, null, message.getChatId(),
                                    cursorVersion, null);
                        } catch (Exception ignore) {
                            // ignore
                        }
                    }
                }
            }
        } catch (Exception e) {
            log.warn("[ImMessageService] 撤回预览落库/增量同步失败, userId: {}, messageId: {}, error: {}",
                    userId, messageId, e.getMessage(), e);
        }

        // 企业级一致性：撤回必须通过 WS 实时广播到会话参与方（对端/群成员）以及操作者的其他设备
        try {
            ImChatDO wsChat = chatMapper.selectById(message.getChatId());
            if (wsChat == null) {
                return;
            }
            Long tenantId = TenantContextHolder.getTenantId();
            RecallMessage body = RecallMessage.newBuilder().setMessageId(messageId).build();

            // WS 元数据：rev/recallTime/recallBy，端侧用 rev 做最终态合并（对标企微/钉钉乱序与补偿）
            String extra = null;
            try {
                JSONObject obj = JSONUtil.createObj();
                obj.set("rev", newRev);
                obj.set("recallBy", userId);
                obj.set("recallTime", recallTime != null ? recallTime.toString() : "");
                obj.set("recallerName", recallerName);
                extra = obj.toString();
            } catch (Exception ignore) {
                extra = null;
            }

            if (ImConversationTypeEnum.isGroup(wsChat.getChatType())) {
                Long groupId = wsChat.getGroupId();
                List<Long> memberIds = imGroupService.getGroupMemberIds(groupId);
                if (memberIds != null) {
                    for (Long memberId : memberIds) {
                        if (memberId == null || memberId <= 0) {
                            continue;
                        }
                        messageSender.sendToUserWithExtra(memberId, MessageType.RECALL, body,
                                userId, 0L, groupId, tenantId,
                                messageId, message.getSequence(), message.getChatId(),
                                null, null, extra);
                    }
                }
                // 确保操作者本人多端可见（即便不在 memberIds 里）；避免 memberIds 已包含操作者时重复发送
                boolean operatorInMembers = false;
                try {
                    operatorInMembers = memberIds != null && memberIds.contains(userId);
                } catch (Exception ignore) {
                    operatorInMembers = false;
                }
                if (!operatorInMembers) {
                    messageSender.sendToUserWithExtra(userId, MessageType.RECALL, body,
                            userId, 0L, groupId, tenantId,
                            messageId, message.getSequence(), message.getChatId(),
                            null, null, extra);
                }
            } else {
                Long otherUserId = Objects.equals(wsChat.getSingleUser1(), userId) ? wsChat.getSingleUser2() : wsChat.getSingleUser1();
                // 对端
                messageSender.sendToUserWithExtra(otherUserId, MessageType.RECALL, body,
                        userId, otherUserId, 0L, tenantId,
                        messageId, message.getSequence(), message.getChatId(),
                        null, null, extra);
                // 自己多端
                messageSender.sendToUserWithExtra(userId, MessageType.RECALL, body,
                        userId, otherUserId, 0L, tenantId,
                        messageId, message.getSequence(), message.getChatId(),
                        null, null, extra);
            }

            // enterprise: re-edit-after-recall hint
            // 仅“自撤回 + 文本消息”向发送者本人多端下发 originalContent，绝不广播给会话其它成员
            try {
                if (isReeditEligibleTextMessage(message, userId)
                        && isSelfMessage) {
                    long reeditWindowSec = 300L;
                    long deadlineTs = recallTime != null ? recallTime.plusSeconds(reeditWindowSec).atZone(java.time.ZoneId.systemDefault()).toInstant().toEpochMilli() : 0L;
                    String hintExtra = null;
                    try {
                        JSONObject obj = JSONUtil.createObj();
                        obj.set("action", "reedit_after_recall");
                        obj.set("chatId", message.getChatId());
                        obj.set("messageId", messageId);
                        obj.set("senderId", userId);
                        obj.set("rev", newRev);
                        obj.set("recallBy", userId);
                        obj.set("isSelfRecall", true);
                        obj.set("recallTime", recallTime != null ? recallTime.toString() : "");
                        obj.set("deadlineTs", deadlineTs);
                        obj.set("originalContent", StrUtil.nullToEmpty(message.getContent()));
                        hintExtra = obj.toString();
                    } catch (Exception ignore) {
                        hintExtra = null;
                    }
                    TextMessage notifyBody = TextMessage.newBuilder().setContent("").build();
                    messageSender.sendToUserWithExtra(userId, MessageType.SYSTEM_NOTIFY, notifyBody,
                            0L, userId, 0L, tenantId,
                            null, null, message.getChatId(),
                            null, null, hintExtra);
                }
            } catch (Exception ignore) {
                // ignore
            }
        } catch (Exception e) {
            log.warn("[ImMessageService] 推送撤回事件失败, userId: {}, messageId: {}, error: {}",
                    userId, messageId, e.getMessage(), e);
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteMessage(Long userId, Long messageId) {
        ImChatMessageDO message = chatMessageMapper.selectById(messageId);
        if (message == null) {
            throw exception(MESSAGE_NOT_EXISTS);
        }
        ImChatUserDO chatUser = chatUserMapper.selectByUserIdAndChatId(userId, message.getChatId());
        if (chatUser == null) {
            throw exception(MESSAGE_NOT_EXISTS);
        }

        Long tenantId = TenantContextHolder.getTenantId();
        if (tenantId == null) {
            tenantId = 0L;
        }

        // idempotent tombstone insert
        chatMessageTombstoneMapper.insertIgnore(tenantId, message.getChatId(), userId, messageId);

        // push conversation state change via cursorVersion so other devices hide this message on refresh/sync
        try {
            Long cursorVersion = cursorVersionService.allocateNextCursorVersion(tenantId, userId);
            conversationUserStateMapper.upsertAfterSettings(
                    tenantId,
                    message.getChatId(),
                    userId,
                    cursorVersion,
                    chatUser.getIsPinned(),
                    chatUser.getNoDisturb(),
                    chatUser.getDraft()
            );

            try {
                TextMessage body = TextMessage.newBuilder().setContent("").build();
                messageSender.sendToUserWithExtra(userId, MessageType.SYSTEM_NOTIFY, body,
                    0L, userId, 0L, tenantId,
                    null, null, message.getChatId(),
                    cursorVersion, null, null);
            } catch (Exception e) {
                log.warn("[IM][send] push failed userId={}, chatId={}, messageId={}, seq={}, rev={}, senderId={}, err={}",
                    userId, message.getChatId(), messageId, message.getSequence(), message.getRev(), userId, e.getMessage(), e);
            }

            try {
                imBadgeService.pushBadgeUpdate(userId);
            } catch (Exception e) {
                log.warn("[ImMessageService] 推送删除消息角标更新失败, userId: {}, messageId: {}, error: {}",
                        userId, messageId, e.getMessage(), e);
            }
        } catch (Exception e) {
            log.warn("[ImMessageService] 删除消息写入会话用户态失败, userId: {}, messageId: {}, error: {}",
                    userId, messageId, e.getMessage(), e);
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void clearConversationMessages(Long userId, Long chatId) {
        ImChatUserDO chatUser = chatUserMapper.selectByUserIdAndChatId(userId, chatId);
        if (chatUser == null) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }

        Long tenantId = TenantContextHolder.getTenantId();
        if (tenantId == null) {
            tenantId = 0L;
        }

        // enterprise: clear to current chat last_sequence (monotonic)
        Long clearSeq = 0L;
        try {
            ImChatDO chat = chatMapper.selectById(chatId);
            if (chat != null && chat.getLastSequence() != null && chat.getLastSequence() > 0) {
                clearSeq = chat.getLastSequence();
            }
        } catch (Exception ignore) {
            clearSeq = 0L;
        }
        if (clearSeq == null) {
            clearSeq = 0L;
        }

        chatClearWatermarkMapper.upsertMax(tenantId, chatId, userId, clearSeq);

        // push cross-device conversation state change
        try {
            Long cursorVersion = cursorVersionService.allocateNextCursorVersion(tenantId, userId);
            conversationUserStateMapper.upsertAfterSettings(
                    tenantId,
                    chatId,
                    userId,
                    cursorVersion,
                    chatUser.getIsPinned(),
                    chatUser.getNoDisturb(),
                    chatUser.getDraft()
            );

            try {
                TextMessage body = TextMessage.newBuilder().setContent("").build();
                messageSender.sendToUser(userId, MessageType.SYSTEM_NOTIFY, body,
                        0L, userId, 0L, tenantId,
                        null, null, chatId,
                        cursorVersion, null);
            } catch (Exception e) {
                log.warn("[ImMessageService] 推送清空聊天记录增量同步通知失败, userId: {}, chatId: {}, error: {}",
                        userId, chatId, e.getMessage(), e);
            }

            try {
                imBadgeService.pushBadgeUpdate(userId);
            } catch (Exception e) {
                log.warn("[ImMessageService] 推送清空聊天记录角标更新失败, userId: {}, chatId: {}, error: {}",
                        userId, chatId, e.getMessage(), e);
            }
        } catch (Exception e) {
            log.warn("[ImMessageService] 清空聊天记录写入会话用户态失败, userId: {}, chatId: {}, error: {}",
                    userId, chatId, e.getMessage(), e);
        }
    }

    @Override
    public PageResult<AppImMessageRespVO> searchMessages(Long userId, AppImMessageSearchReqVO searchReqVO) {
        if (searchReqVO == null) {
            return new PageResult<>(Collections.emptyList(), 0L);
        }
        String keyword = StrUtil.trimToEmpty(searchReqVO.getKeyword());
        if (StrUtil.isBlank(keyword)) {
            return new PageResult<>(Collections.emptyList(), 0L);
        }
        Long tenantId = TenantContextHolder.getTenantId();
        if (tenantId == null) {
            tenantId = 0L;
        }
        if (searchReqVO.getChatId() != null) {
            ImChatUserDO chatUser = chatUserMapper.selectByUserIdAndChatId(userId, searchReqVO.getChatId());
            if (chatUser == null) {
                return new PageResult<>(Collections.emptyList(), 0L);
            }
        }
        int pageNo = searchReqVO.getPageNo() != null && searchReqVO.getPageNo() > 0 ? searchReqVO.getPageNo() : 1;
        int pageSize = searchReqVO.getPageSize() != null && searchReqVO.getPageSize() > 0 ? searchReqVO.getPageSize() : 20;
        if (pageSize > 50) {
            pageSize = 50;
        }
        List<Integer> messageTypeList = resolveSearchMessageTypeList(searchReqVO);
        long offset = (long) (pageNo - 1) * pageSize;
        Long total = chatMessageMapper.countSearchPageByUser(tenantId, userId, searchReqVO.getChatId(), keyword,
                searchReqVO.getMessageType(), messageTypeList, searchReqVO.getStartTime(), searchReqVO.getEndTime());
        if (total == null || total <= 0) {
            return new PageResult<>(Collections.emptyList(), 0L);
        }
        List<ImChatMessageDO> messages = chatMessageMapper.selectSearchPageByUser(tenantId, userId, searchReqVO.getChatId(), keyword,
                searchReqVO.getMessageType(), messageTypeList, searchReqVO.getStartTime(), searchReqVO.getEndTime(), offset, (long) pageSize);
        List<AppImMessageRespVO> respVOList = messages.stream()
                .filter(Objects::nonNull)
                .map(message -> {
                    AppImMessageRespVO respVO = BeanUtils.toBean(message, AppImMessageRespVO.class);
                    respVO.setChatId(message.getChatId());
                    respVO.setSequence(message.getSequence());
                    respVO.setMessageType(normalizeDbMessageType(respVO.getMessageType()));
                    fillSenderInfo(respVO, message.getSenderId(), message.getChatId());
                    respVO.setIsSelf(Objects.equals(message.getSenderId(), userId));
                    fillChatTargetFields(respVO, userId);
                    fillConversationInfo(respVO, userId);
                    applyLocalizedSystemMessageContent(respVO, message);
                    applyReeditFieldsForCurrentUser(respVO, message, userId);
                    sanitizeRecalledMessage(respVO, message, userId);
                    return respVO;
                }).collect(Collectors.toList());
        fillVoicePlayedFlags(userId, respVOList, searchReqVO.getChatId());
        return new PageResult<>(respVOList, total);
    }

    @Override
    public PageResult<AppImChatMediaRespVO> getChatMediaPage(Long userId, AppImChatMediaPageReqVO pageReqVO) {
        if (pageReqVO == null || pageReqVO.getChatId() == null) {
            return new PageResult<>(Collections.emptyList(), 0L);
        }
        ImChatUserDO chatUser = chatUserMapper.selectByUserIdAndChatId(userId, pageReqVO.getChatId());
        if (chatUser == null) {
            return new PageResult<>(Collections.emptyList(), 0L);
        }
        Long tenantId = TenantContextHolder.getTenantId();
        if (tenantId == null) {
            tenantId = 0L;
        }
        int pageNo = pageReqVO.getPageNo() != null && pageReqVO.getPageNo() > 0 ? pageReqVO.getPageNo() : 1;
        int pageSize = pageReqVO.getPageSize() != null && pageReqVO.getPageSize() > 0 ? pageReqVO.getPageSize() : 20;
        if (pageSize > 50) {
            pageSize = 50;
        }
        List<Integer> messageTypeList = resolveMediaMessageTypeList(pageReqVO.getFileType());
        long offset = (long) (pageNo - 1) * pageSize;
        Long total = chatMessageMapper.countSearchPageByUser(
                tenantId, userId, pageReqVO.getChatId(), null, null, messageTypeList, null, null);
        if (total == null || total <= 0) {
            return new PageResult<>(Collections.emptyList(), 0L);
        }
        List<ImChatMessageDO> messages = chatMessageMapper.selectSearchPageByUser(
                tenantId, userId, pageReqVO.getChatId(), null, null, messageTypeList, null, null, offset, (long) pageSize);
        List<AppImChatMediaRespVO> list = messages.stream()
                .filter(Objects::nonNull)
                .map(this::buildChatMediaRespVO)
                .filter(Objects::nonNull)
                .collect(Collectors.toList());
        return new PageResult<>(list, total);
    }

    private List<Integer> resolveSearchMessageTypeList(AppImMessageSearchReqVO searchReqVO) {
        if (searchReqVO == null) {
            return null;
        }
        // messageType 精确过滤优先于分类过滤
        if (searchReqVO.getMessageType() != null) {
            return null;
        }
        String category = StrUtil.trimToEmpty(searchReqVO.getCategory()).toLowerCase();
        if ("media".equals(category)) {
            return Arrays.asList(
                    ImMessageTypeEnum.IMAGE.getType(),
                    ImMessageTypeEnum.VIDEO.getType(),
                    ImMessageTypeEnum.FILE.getType());
        }
        return null;
    }

    private List<Integer> resolveMediaMessageTypeList(String fileType) {
        String normalized = StrUtil.blankToDefault(StrUtil.trim(fileType), "all").toLowerCase();
        switch (normalized) {
            case "image":
                return Collections.singletonList(ImMessageTypeEnum.IMAGE.getType());
            case "video":
                return Collections.singletonList(ImMessageTypeEnum.VIDEO.getType());
            case "file":
                return Collections.singletonList(ImMessageTypeEnum.FILE.getType());
            default:
                return Arrays.asList(
                        ImMessageTypeEnum.IMAGE.getType(),
                        ImMessageTypeEnum.VIDEO.getType(),
                        ImMessageTypeEnum.FILE.getType());
        }
    }

    private AppImChatMediaRespVO buildChatMediaRespVO(ImChatMessageDO message) {
        Integer messageType = normalizeDbMessageType(message.getMessageType());
        if (messageType == null) {
            return null;
        }
        AppImChatMediaRespVO respVO = new AppImChatMediaRespVO();
        respVO.setMessageId(message.getId());
        respVO.setChatId(message.getChatId());
        respVO.setSenderId(message.getSenderId());
        respVO.setSendTime(message.getSendTime());
        fillChatMediaChatTarget(respVO, message.getChatId());
        fillChatMediaSender(respVO, message.getSenderId());

        JSONObject extraObj = parseChatMediaExtra(message.getExtra());
        String url = StrUtil.blankToDefault(resolveChatMediaUrl(message.getContent(), extraObj), "");
        respVO.setFileUrl(url);
        respVO.setThumbFileId(extraObj.getLong("thumbFileId", null));
        respVO.setThumbnailUrl(StrUtil.blankToDefault(
                extraObj.getStr("thumbnailUrl", extraObj.getStr("coverUrl", extraObj.getStr("thumbUrl", ""))),
                ""));
        respVO.setFileName(resolveChatMediaFileName(messageType, url, extraObj));
        respVO.setFileSize(resolveChatMediaFileSize(extraObj));
        respVO.setFileMimeType(resolveChatMediaMimeType(messageType, extraObj, url));
        respVO.setFileId(resolveChatMediaFileId(extraObj));

        if (Objects.equals(messageType, ImMessageTypeEnum.IMAGE.getType())) {
            respVO.setMediaType("image");
        } else if (Objects.equals(messageType, ImMessageTypeEnum.VIDEO.getType())) {
            respVO.setMediaType("video");
        } else if (Objects.equals(messageType, ImMessageTypeEnum.FILE.getType())) {
            respVO.setMediaType("file");
        } else {
            return null;
        }
        return respVO;
    }

    private void fillChatMediaChatTarget(AppImChatMediaRespVO respVO, Long chatId) {
        if (respVO == null || chatId == null) {
            return;
        }
        ImChatDO chat = chatMapper.selectById(chatId);
        if (chat != null) {
            respVO.setGroupId(chat.getGroupId());
        }
    }

    private void fillChatMediaSender(AppImChatMediaRespVO respVO, Long senderId) {
        if (respVO == null || senderId == null) {
            return;
        }
        AdminUserDO sender = userMapper.selectById(senderId);
        if (sender != null) {
            respVO.setSenderNickname(sender.getNickname());
        }
    }

    private JSONObject parseChatMediaExtra(String extra) {
        if (StrUtil.isBlank(extra)) {
            return null;
        }
        try {
            return JSONUtil.parseObj(extra);
        } catch (Exception ignore) {
            return null;
        }
    }

    private String resolveChatMediaUrl(String content, JSONObject extraObj) {
        if (extraObj != null) {
            String extraUrl = extraObj.getStr("url", "");
            if (StrUtil.isNotBlank(extraUrl)) {
                return extraUrl;
            }
        }
        return content;
    }

    private String resolveChatMediaFileName(Integer messageType, String url, JSONObject extraObj) {
        if (extraObj != null) {
            String extraName = extraObj.getStr("fileName", extraObj.getStr("name", ""));
            if (StrUtil.isNotBlank(extraName)) {
                return extraName;
            }
        }
        String nameFromUrl = extractChatMediaFileNameFromUrl(url);
        if (StrUtil.isNotBlank(nameFromUrl)) {
            return nameFromUrl;
        }
        if (Objects.equals(messageType, ImMessageTypeEnum.IMAGE.getType())) {
            return "图片";
        }
        if (Objects.equals(messageType, ImMessageTypeEnum.VIDEO.getType())) {
            return "视频";
        }
        return "文件";
    }

    private Long resolveChatMediaFileSize(JSONObject extraObj) {
        if (extraObj == null) {
            return 0L;
        }
        return extraObj.getLong("size", 0L);
    }

    private String resolveChatMediaMimeType(Integer messageType, JSONObject extraObj, String url) {
        if (extraObj != null) {
            String mimeType = extraObj.getStr("fileType", extraObj.getStr("mimeType", ""));
            if (StrUtil.isNotBlank(mimeType)) {
                return mimeType;
            }
        }
        String ext = extractChatMediaExtension(url);
        if (StrUtil.isBlank(ext)) {
            if (Objects.equals(messageType, ImMessageTypeEnum.IMAGE.getType())) {
                return "image/*";
            }
            if (Objects.equals(messageType, ImMessageTypeEnum.VIDEO.getType())) {
                return "video/*";
            }
            return "";
        }
        if (Objects.equals(messageType, ImMessageTypeEnum.IMAGE.getType())) {
            return "image/" + ext;
        }
        if (Objects.equals(messageType, ImMessageTypeEnum.VIDEO.getType())) {
            return "video/" + ext;
        }
        return "";
    }

    private Long resolveChatMediaFileId(JSONObject extraObj) {
        if (extraObj == null) {
            return null;
        }
        Long fileId = extraObj.getLong("fileId", null);
        return fileId != null && fileId > 0 ? fileId : null;
    }

    private String extractChatMediaFileNameFromUrl(String url) {
        if (StrUtil.isBlank(url)) {
            return "";
        }
        try {
            String path = UriComponentsBuilder.fromUriString(url).build().getPath();
            if (StrUtil.isBlank(path)) {
                path = url;
            }
            int idx = path.lastIndexOf('/');
            return idx >= 0 ? path.substring(idx + 1) : path;
        } catch (Exception ignore) {
            int idx = url.lastIndexOf('/');
            return idx >= 0 ? url.substring(idx + 1) : url;
        }
    }

    private String extractChatMediaExtension(String url) {
        String fileName = extractChatMediaFileNameFromUrl(url);
        if (StrUtil.isBlank(fileName) || !fileName.contains(".")) {
            return "";
        }
        return StrUtil.subAfter(fileName, ".", true).toLowerCase();
    }

    /**
     * 获取消息预览文本
     */
    private String getMessagePreview(Integer messageType, String content) {
        switch (messageType) {
            case 1: // 文本
                return content.length() > 50 ? content.substring(0, 50) + "..." : content;
            case 2: // 图片
                return "[图片]";
            case 3: // 语音
                return "[语音]";
            case 4: // 视频
                return "[视频]";
            case 5: // 文件
                return "[文件]";
            case 6: // 位置
                return "[位置]";
            case 7: // 表情包
                return "[表情]";
            case 8: // 自定义贴纸
                return "[动画表情]";
            case 9: // 自定义消息
                String customPreview = getCustomMessagePreview(content);
                return StrUtil.isNotBlank(customPreview) ? customPreview : "[自定义消息]";
            case 10: // 系统消息
                return "[系统消息]";
            default:
                return "[未知消息]";
        }
    }

    private String getCustomMessagePreview(String content) {
        if (StrUtil.isBlank(content)) {
            return "[自定义消息]";
        }
        try {
            JSONObject obj = JSONUtil.parseObj(content);
            String customType = obj.getStr("type", "");
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

    private JSONObject validateAndNormalizeCustomPayload(AppImMessageSendReqVO sendReqVO) {
        JSONObject merged = JSONUtil.createObj();
        if (StrUtil.isNotBlank(sendReqVO.getContent())) {
            try {
                Object contentObj = JSONUtil.parse(sendReqVO.getContent());
                if (contentObj instanceof JSONObject) {
                    merged.putAll((JSONObject) contentObj);
                }
            } catch (Exception ignore) {
                // ignore non-json content
            }
        }
        if (StrUtil.isNotBlank(sendReqVO.getExtra())) {
            try {
                Object extraObj = JSONUtil.parse(sendReqVO.getExtra());
                if (extraObj instanceof JSONObject) {
                    merged.putAll((JSONObject) extraObj);
                }
            } catch (Exception ex) {
                throw ServiceExceptionUtil.invalidParamException("CUSTOM extra 不是合法 JSON");
            }
        }
        String customType = merged.getStr("type", "");
        if (StrUtil.isBlank(customType)) {
            throw ServiceExceptionUtil.invalidParamException("CUSTOM 消息缺少 type");
        }
        if ("CONTACT_CARD".equals(customType)) {
            String userId = merged.getStr("userId", "");
            String displayName = merged.getStr("displayName", merged.getStr("name", ""));
            if (StrUtil.isBlank(userId) || StrUtil.isBlank(displayName)) {
                throw ServiceExceptionUtil.invalidParamException("CONTACT_CARD 缺少 userId/displayName");
            }
            JSONObject normalized = JSONUtil.createObj();
            normalized.set("type", "CONTACT_CARD");
            normalized.set("userId", userId);
            normalized.set("displayName", displayName);
            String deptName = merged.getStr("deptName", "");
            if (StrUtil.isNotBlank(deptName)) {
                normalized.set("deptName", deptName);
            }
            String postName = merged.getStr("postName", "");
            if (StrUtil.isNotBlank(postName)) {
                normalized.set("postName", postName);
            }
            String avatar = merged.getStr("avatar", "");
            if (StrUtil.isNotBlank(avatar)) {
                normalized.set("avatar", avatar);
            }
            return normalized;
        }
        return merged;
    }

    private JSONObject buildAndValidateLocationPayload(AppImMessageSendReqVO sendReqVO) {
        JSONObject merged = JSONUtil.createObj();
        Object rawContent = null;
        if (StrUtil.isNotBlank(sendReqVO.getContent())) {
            try {
                rawContent = JSONUtil.parse(sendReqVO.getContent());
            } catch (Exception ignore) {
                rawContent = sendReqVO.getContent();
            }
        }
        if (rawContent instanceof JSONObject) {
            merged.putAll((JSONObject) rawContent);
        }
        if (StrUtil.isNotBlank(sendReqVO.getExtra())) {
            try {
                Object extraObj = JSONUtil.parse(sendReqVO.getExtra());
                if (extraObj instanceof JSONObject) {
                    merged.putAll((JSONObject) extraObj);
                }
            } catch (Exception e) {
                throw ServiceExceptionUtil.invalidParamException("LOCATION extra 不是合法 JSON");
            }
        }

        Double latitude = merged.getDouble("latitude");
        Double longitude = merged.getDouble("longitude");
        if (latitude == null || longitude == null) {
            throw ServiceExceptionUtil.invalidParamException("LOCATION 缺少经纬度");
        }
        if (latitude < -90D || latitude > 90D) {
            throw ServiceExceptionUtil.invalidParamException("LOCATION latitude 超出范围");
        }
        if (longitude < -180D || longitude > 180D) {
            throw ServiceExceptionUtil.invalidParamException("LOCATION longitude 超出范围");
        }

        String address = merged.getStr("address", "");
        String name = merged.getStr("name", merged.getStr("locationName", ""));
        if (StrUtil.isBlank(address) && StrUtil.isBlank(name)) {
            throw ServiceExceptionUtil.invalidParamException("LOCATION address/name 至少一个非空");
        }

        JSONObject normalized = JSONUtil.createObj();
        normalized.set("latitude", latitude);
        normalized.set("longitude", longitude);
        normalized.set("address", StrUtil.nullToDefault(address, ""));
        if (StrUtil.isNotBlank(name)) {
            normalized.set("name", name);
        }
        String provider = merged.getStr("provider", "");
        if (StrUtil.isNotBlank(provider)) {
            normalized.set("provider", provider);
        }
        String mapUrl = merged.getStr("mapUrl", "");
        if (StrUtil.isBlank(mapUrl)) {
            mapUrl = buildTencentStaticMapUrl(latitude, longitude);
        }
        if (StrUtil.isNotBlank(mapUrl)) {
            normalized.set("mapUrl", mapUrl);
        }
        return normalized;
    }

    private String buildTencentStaticMapUrl(Double latitude, Double longitude) {
        if (latitude == null || longitude == null || StrUtil.isBlank(tencentLbsKey)) {
            return "";
        }
        String marker = "size:" + LOCATION_MAP_DEFAULT_MARKER_SIZE
                + "|color:" + LOCATION_MAP_DEFAULT_MARKER_COLOR
                + "|" + latitude + "," + longitude;
        return UriComponentsBuilder.fromHttpUrl(locationStaticMapUrl)
                .queryParam("center", latitude + "," + longitude)
                .queryParam("zoom", LOCATION_MAP_DEFAULT_ZOOM)
                .queryParam("size", LOCATION_MAP_DEFAULT_SIZE)
                .queryParam("scale", LOCATION_MAP_DEFAULT_SCALE)
                .queryParam("markers", marker)
                .queryParam("key", tencentLbsKey)
                .build()
                .encode()
                .toUriString();
    }

}
