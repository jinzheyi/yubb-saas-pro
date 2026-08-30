package com.shengyu.module.system.service.im.push;

import com.shengyu.framework.websocket.core.session.NettySessionManager;
import com.shengyu.module.system.service.im.ImGroupService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

import java.util.Collections;
import java.util.List;

/** Publishes only after the message transaction commits; FCM is never called in a DB transaction. */
@Slf4j
@Component
@RequiredArgsConstructor
public class ImNotificationEventPublisher {
    private final ApplicationEventPublisher applicationEventPublisher;
    private final ImGroupService imGroupService;
    private final NettySessionManager sessionManager;
    private final ImPushDispatcher dispatcher;

    public void publishMessageCommitted(Long tenantId, Long senderId, Long groupId, Long receiverId,
                                        Long chatId, Long messageId, long sentAt) {
        if (tenantId == null || senderId == null || chatId == null || messageId == null) return;
        applicationEventPublisher.publishEvent(new ImMessagePushEvent(
                tenantId, senderId, groupId, receiverId, chatId, messageId, sentAt));
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void dispatchAfterCommit(ImMessagePushEvent event) {
        List<Long> recipients = event.getGroupId() != null && event.getGroupId() > 0
                ? imGroupService.getGroupMemberIds(event.getGroupId())
                : Collections.singletonList(event.getReceiverId());
        if (recipients == null) return;
        for (Long userId : recipients) {
            if (userId == null || userId.equals(event.getSenderId())) continue;
            // P0 deliberately pushes only when the user has no authenticated
            // WebSocket session.  It is a noise-reduction heuristic, not a
            // delivery guarantee or a substitute for conversation sync.
            if (!sessionManager.getSessionsByUserId(userId).isEmpty()) continue;
            FcmDispatchStatus status = dispatcher.dispatchMessage(event.getTenantId(), userId,
                    String.valueOf(event.getChatId()), String.valueOf(event.getMessageId()), event.getSentAt());
            log.info("[ImPush] offline message dispatch tenantId={}, userId={}, deviceId=multiple, eventId={}, status={}",
                    event.getTenantId(), userId, event.getMessageId(), status);
        }
    }
}
