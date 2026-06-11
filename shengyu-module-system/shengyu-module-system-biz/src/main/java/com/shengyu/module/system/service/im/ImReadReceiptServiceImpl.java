package com.shengyu.module.system.service.im;

import cn.hutool.core.util.StrUtil;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.tenant.core.context.TenantContextHolder;
import com.shengyu.module.system.controller.app.im.vo.readreceipt.AppImReadReceiptDetailReqVO;
import com.shengyu.module.system.controller.app.im.vo.readreceipt.AppImReadReceiptDetailRespVO;
import com.shengyu.module.system.controller.app.im.vo.readreceipt.AppImReadReceiptSummaryRespVO;
import com.shengyu.module.system.dal.dataobject.im.ImChatDO;
import com.shengyu.module.system.dal.dataobject.im.ImChatMessageDO;
import com.shengyu.module.system.dal.dataobject.im.ImGroupUserDO;
import com.shengyu.module.system.dal.mysql.im.ImChatMapper;
import com.shengyu.module.system.dal.mysql.im.ImChatMessageMapper;
import com.shengyu.module.system.dal.mysql.im.ImGroupUserMapper;
import com.shengyu.module.system.dal.mysql.im.ImReadReceiptMapper;
import com.shengyu.module.system.enums.im.ImConversationTypeEnum;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.util.*;
import java.util.stream.Collectors;

import static com.shengyu.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.shengyu.module.system.enums.ErrorCodeConstants.*;

@Service
@Slf4j
public class ImReadReceiptServiceImpl implements ImReadReceiptService {

    @Resource
    private ImChatMessageMapper chatMessageMapper;

    @Resource
    private ImChatMapper chatMapper;

    @Resource
    private ImGroupUserMapper groupUserMapper;

    @Resource
    private ImReadReceiptMapper readReceiptMapper;

    @Override
    public AppImReadReceiptSummaryRespVO getSummary(Long userId, Long messageId) {
        ImChatMessageDO msg = chatMessageMapper.selectById(messageId);
        if (msg == null) {
            // 消息可能刚发送还未完全落库，返回 null 由前端重试，避免抛出"消息不存在"错误提示
            log.debug("[ImReadReceiptService] 消息暂未落库，返回 null, messageId: {}", messageId);
            return null;
        }
        ImChatDO chat = chatMapper.selectById(msg.getChatId());
        if (chat == null) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }
        if (!ImConversationTypeEnum.isGroup(chat.getChatType())) {
            throw exception(MESSAGE_SEND_FAILED);
        }

        Long tenantId = TenantContextHolder.getTenantId();
        if (tenantId == null) {
            tenantId = 0L;
        }

        ImGroupUserDO groupUser = groupUserMapper.selectByGroupIdAndUserId(chat.getGroupId(), userId);
        if (groupUser == null) {
            throw exception(GROUP_MEMBER_NOT_EXISTS);
        }

        // 口径：发送者侧查看“已读/未读”时，不统计发送者本人
        Long excludeUserId = msg.getSenderId();
        Long total = groupUserMapper.selectCountByGroupId(chat.getGroupId());
        if (total == null) {
            total = 0L;
        }
        if (excludeUserId != null && excludeUserId > 0 && total > 0) {
            total = Math.max(total - 1, 0L);
        }
        Long seq = msg.getSequence() != null ? msg.getSequence() : 0L;
        Long read = readReceiptMapper.countReadMembers(tenantId, chat.getGroupId(), chat.getId(), excludeUserId, seq);
        if (read == null) {
            read = 0L;
        }
        Long unread = Math.max(total - read, 0L);

        AppImReadReceiptSummaryRespVO respVO = new AppImReadReceiptSummaryRespVO();
        respVO.setMessageId(messageId);
        respVO.setChatId(chat.getId());
        respVO.setSequence(seq);
        respVO.setTotalCount(total);
        respVO.setReadCount(read);
        respVO.setUnreadCount(unread);
        respVO.setMessageType(msg.getMessageType());
        respVO.setReadBasis("conversation_read_watermark");
        return respVO;
    }

    @Override
    public List<AppImReadReceiptSummaryRespVO> getSummaryBatch(Long userId, List<Long> messageIds) {
        if (messageIds == null || messageIds.isEmpty()) {
            return Collections.emptyList();
        }
        Set<Long> normalizedIds = new LinkedHashSet<>();
        for (Long messageId : messageIds) {
            if (messageId != null && messageId > 0) {
                normalizedIds.add(messageId);
            }
            if (normalizedIds.size() >= 50) {
                break;
            }
        }
        if (normalizedIds.isEmpty()) {
            return Collections.emptyList();
        }

        // 1. 批量查询消息
        List<ImChatMessageDO> messages = chatMessageMapper.selectBatchIds(normalizedIds);
        if (messages == null || messages.isEmpty()) {
            return Collections.emptyList();
        }

        // 2. 批量查询会话信息
        Set<Long> chatIds = messages.stream()
                .filter(m -> m != null && m.getChatId() != null)
                .map(ImChatMessageDO::getChatId)
                .collect(Collectors.toSet());
        List<ImChatDO> chats = chatMapper.selectBatchIds(chatIds);
        Map<Long, ImChatDO> chatMap = chats.stream()
                .filter(c -> c != null)
                .collect(Collectors.toMap(ImChatDO::getId, c -> c, (v1, v2) -> v1));

        // 3. 批量处理每条消息的摘要
        Long tenantId = TenantContextHolder.getTenantId();
        if (tenantId == null) {
            tenantId = 0L;
        }

        List<AppImReadReceiptSummaryRespVO> result = new ArrayList<>(normalizedIds.size());
        for (ImChatMessageDO message : messages) {
            if (message == null || message.getId() == null) {
                continue;
            }
            try {
                ImChatDO chat = chatMap.get(message.getChatId());
                if (chat == null) {
                    continue;
                }
                if (!ImConversationTypeEnum.isGroup(chat.getChatType())) {
                    continue;
                }

                ImGroupUserDO groupUser = groupUserMapper.selectByGroupIdAndUserId(chat.getGroupId(), userId);
                if (groupUser == null) {
                    continue;
                }

                Long excludeUserId = message.getSenderId();
                Long total = groupUserMapper.selectCountByGroupId(chat.getGroupId());
                if (total == null) {
                    total = 0L;
                }
                if (excludeUserId != null && excludeUserId > 0 && total > 0) {
                    total = Math.max(total - 1, 0L);
                }

                Long seq = message.getSequence() != null ? message.getSequence() : 0L;
                Long read = readReceiptMapper.countReadMembers(tenantId, chat.getGroupId(), chat.getId(), excludeUserId, seq);
                if (read == null) {
                    read = 0L;
                }
                Long unread = Math.max(total - read, 0L);

                AppImReadReceiptSummaryRespVO summary = new AppImReadReceiptSummaryRespVO();
                summary.setMessageId(message.getId());
                summary.setChatId(chat.getId());
                summary.setSequence(seq);
                summary.setTotalCount(total);
                summary.setReadCount(read);
                summary.setUnreadCount(unread);
                summary.setMessageType(message.getMessageType());
                summary.setReadBasis("conversation_read_watermark");

                result.add(summary);
            } catch (Exception e) {
                log.warn("[ImReadReceiptService] 批量摘要跳过 messageId={}", message.getId(), e);
            }
        }

        return result;
    }

    @Override
    public PageResult<AppImReadReceiptDetailRespVO> getDetail(Long userId, AppImReadReceiptDetailReqVO reqVO) {
        ImChatMessageDO msg = chatMessageMapper.selectById(reqVO.getMessageId());
        if (msg == null) {
            throw exception(MESSAGE_NOT_EXISTS);
        }
        ImChatDO chat = chatMapper.selectById(msg.getChatId());
        if (chat == null) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }
        if (!ImConversationTypeEnum.isGroup(chat.getChatType())) {
            throw exception(MESSAGE_SEND_FAILED);
        }

        Long tenantId = TenantContextHolder.getTenantId();
        if (tenantId == null) {
            tenantId = 0L;
        }

        ImGroupUserDO groupUser = groupUserMapper.selectByGroupIdAndUserId(chat.getGroupId(), userId);
        if (groupUser == null) {
            throw exception(GROUP_MEMBER_NOT_EXISTS);
        }

        String status = reqVO.getStatus();
        if (!StrUtil.equalsAnyIgnoreCase(status, "read", "unread")) {
            throw exception(MESSAGE_SEND_FAILED);
        }
        status = status.toLowerCase();

        Integer pageNo = reqVO.getPageNo() != null && reqVO.getPageNo() > 0 ? reqVO.getPageNo() : 1;
        Integer pageSize = reqVO.getPageSize() != null && reqVO.getPageSize() > 0 ? reqVO.getPageSize() : 20;
        if (pageSize > 200) {
            pageSize = 200;
        }
        int offset = (pageNo - 1) * pageSize;

        Long seq = msg.getSequence() != null ? msg.getSequence() : 0L;
        Long excludeUserId = msg.getSenderId();
        Long total;
        if ("read".equals(status)) {
            total = readReceiptMapper.countReadMembers(tenantId, chat.getGroupId(), chat.getId(), excludeUserId, seq);
        } else {
            total = readReceiptMapper.countUnreadMembers(tenantId, chat.getGroupId(), chat.getId(), excludeUserId, seq);
        }
        if (total == null) {
            total = 0L;
        }

        return new PageResult<>(
                readReceiptMapper.selectDetailPage(tenantId, chat.getGroupId(), chat.getId(), excludeUserId, seq, status, offset, pageSize),
                total
        );
    }

}
