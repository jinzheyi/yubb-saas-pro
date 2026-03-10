package com.shengyu.module.system.service.im.spi;

import com.shengyu.framework.websocket.core.service.ConversationSnapshotService;
import com.shengyu.module.system.controller.app.im.vo.conversation.AppImConversationRespVO;
import com.shengyu.module.system.service.im.ImConversationService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class ImConversationSnapshotServiceImpl implements ConversationSnapshotService {

    private final ImConversationService conversationService;

    @Override
    public Map<String, Object> buildSnapshot(Long userId, Long chatId) {
        if (userId == null || userId <= 0 || chatId == null || chatId <= 0) {
            return null;
        }
        AppImConversationRespVO detail = conversationService.getConversationDetail(userId, chatId);
        if (detail == null) {
            return null;
        }
        Map<String, Object> map = new HashMap<>();
        map.put("chatId", detail.getChatId() != null ? String.valueOf(detail.getChatId()) : null);
        map.put("targetId", detail.getTargetId() != null ? String.valueOf(detail.getTargetId()) : null);
        map.put("conversationType", detail.getConversationType());
        map.put("unreadCount", detail.getUnreadCount());
        map.put("lastMessageSequence", detail.getLastMessageSequence() != null ? String.valueOf(detail.getLastMessageSequence()) : null);
        map.put("lastReadSequence", detail.getLastReadSequence() != null ? String.valueOf(detail.getLastReadSequence()) : null);
        map.put("lastMessageContent", detail.getLastMessageContent());
        map.put("lastMessageTime", detail.getLastMessageTime());
        map.put("isPinned", detail.getIsPinned());
        map.put("noDisturb", detail.getNoDisturb());
        map.put("targetName", detail.getTargetName());
        map.put("targetAvatar", detail.getTargetAvatar());
        map.put("groupMemberCount", detail.getGroupMemberCount());
        return map;
    }

}
