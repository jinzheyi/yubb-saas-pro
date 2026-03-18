package com.shengyu.module.system.mq.consumer.im;

import com.shengyu.framework.mq.redis.core.stream.AbstractRedisStreamMessageListener;
import com.shengyu.framework.websocket.core.protocol.MessageType;
import com.shengyu.framework.websocket.core.protocol.TextMessage;
import com.shengyu.framework.websocket.core.sender.NettyMessageSender;
import com.shengyu.framework.tenant.core.context.TenantContextHolder;
import com.shengyu.module.system.controller.app.im.vo.conversation.AppImConversationCreateReqVO;
import com.shengyu.module.system.controller.app.im.vo.conversation.AppImConversationRespVO;
import com.shengyu.module.system.enums.im.ImConversationTypeEnum;
import com.shengyu.module.system.mq.message.im.ImGroupConversationRefreshMessage;
import com.shengyu.module.system.service.im.ImConversationService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;
import java.util.List;

@Slf4j
@Component
public class ImGroupConversationRefreshConsumer extends AbstractRedisStreamMessageListener<ImGroupConversationRefreshMessage> {

    public static final String ACTION_UPSERT = "UPSERT";
    public static final String ACTION_DELETE = "DELETE";

    @Resource
    private ImConversationService conversationService;

    @Resource
    private NettyMessageSender messageSender;

    @Override
    public void onMessage(ImGroupConversationRefreshMessage message) {
        if (message == null) {
            return;
        }
        List<Long> memberIds = message.getMemberIds();
        if (memberIds == null || memberIds.isEmpty()) {
            return;
        }
        if (message.getGroupId() == null) {
            return;
        }
        Integer conversationType = message.getConversationType() != null
                ? message.getConversationType()
                : ImConversationTypeEnum.GROUP.getType();

        if (ACTION_DELETE.equalsIgnoreCase(message.getAction())) {
            for (Long memberId : memberIds) {
                if (memberId == null) {
                    continue;
                }
                try {
                    conversationService.deleteConversationByTarget(memberId, message.getGroupId(), conversationType);
                } catch (Exception e) {
                    log.warn("[ImGroupConversationRefreshConsumer] deleteConversation failed, groupId={}, memberId={}, error={}",
                            message.getGroupId(), memberId, e.getMessage());
                }
                sendConversationUpsert(message, memberId);
            }
            return;
        }

        for (Long memberId : memberIds) {
            if (memberId == null) {
                continue;
            }
            try {
                AppImConversationCreateReqVO reqVO = new AppImConversationCreateReqVO();
                reqVO.setTargetId(message.getGroupId());
                reqVO.setConversationType(conversationType);
                AppImConversationRespVO resp = conversationService.createOrGetConversation(memberId, reqVO);
                if (resp != null && resp.getChatId() != null) {
                    message.setChatId(resp.getChatId());
                }
            } catch (Exception e) {
                log.warn("[ImGroupConversationRefreshConsumer] createOrGetConversation failed, groupId={}, memberId={}, error={}",
                        message.getGroupId(), memberId, e.getMessage(), e);
            }
            sendConversationUpsert(message, memberId);
        }
    }

    private void sendConversationUpsert(ImGroupConversationRefreshMessage message, Long receiverUserId) {
        try {
            Long tenantId = TenantContextHolder.getTenantId();
            messageSender.sendToUser(receiverUserId,
                    MessageType.SYSTEM_NOTIFY,
                    TextMessage.newBuilder().setContent("CONVERSATION_UPSERT").build(),
                    message.getOperatorUserId(),
                    receiverUserId,
                    message.getGroupId(),
                    tenantId,
                    null,
                    null,
                    message.getChatId());
        } catch (Exception e) {
            log.warn("[ImGroupConversationRefreshConsumer] push CONVERSATION_UPSERT failed, groupId={}, receiverUserId={}, error={}",
                    message.getGroupId(), receiverUserId, e.getMessage());
        }
    }

}
