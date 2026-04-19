package com.shengyu.module.system.service.im;

import cn.hutool.json.JSONUtil;
import com.shengyu.framework.websocket.core.protocol.MessageType;
import com.shengyu.framework.websocket.core.protocol.TextMessage;
import com.shengyu.framework.websocket.core.sender.NettyMessageSender;
import com.shengyu.module.system.dal.mysql.im.ImChatMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.util.Collections;
import java.util.List;

/**
 * IM 在线状态变更推送服务
 */
@Service
@Slf4j
public class ImPresencePushService {

    public static final String ACTION_PRESENCE_UPDATE = "presence_update";

    @Resource
    private ImChatMapper chatMapper;

    @Resource
    private ObjectProvider<NettyMessageSender> nettyMessageSenderProvider;

    public void pushPresenceUpdate(Long targetUserId, ImPresenceSnapshot snapshot) {
        if (targetUserId == null || targetUserId <= 0L || snapshot == null) {
            return;
        }
        NettyMessageSender nettyMessageSender = nettyMessageSenderProvider.getIfAvailable();
        if (nettyMessageSender == null) {
            log.warn("[ImPresencePush] skip push because NettyMessageSender is unavailable, targetUserId: {}",
                    targetUserId);
            return;
        }
        List<Long> peerUserIds = chatMapper.selectSingleChatPeerUserIds(targetUserId);
        if (peerUserIds == null || peerUserIds.isEmpty()) {
            return;
        }

        String extra = JSONUtil.createObj()
                .set("action", ACTION_PRESENCE_UPDATE)
                .set("targetUserId", String.valueOf(targetUserId))
                .set("online", Boolean.TRUE.equals(snapshot.getOnline()))
                .set("onlineDeviceTypes", snapshot.getOnlineDeviceTypes() != null
                        ? snapshot.getOnlineDeviceTypes() : Collections.emptyList())
                .set("lastActiveTime", snapshot.getLastActiveTime())
                .toString();

        TextMessage body = TextMessage.newBuilder()
                .setContent("")
                .build();

        for (Long peerUserId : peerUserIds) {
            if (peerUserId == null || peerUserId <= 0L) {
                continue;
            }
            try {
                nettyMessageSender.sendToUserWithExtra(peerUserId, MessageType.SYSTEM_NOTIFY, body,
                        targetUserId, peerUserId, 0L, null, null, null, null,
                        null, null, extra);
            } catch (Exception e) {
                log.warn("[ImPresencePush] push failed, targetUserId: {}, peerUserId: {}, error: {}",
                        targetUserId, peerUserId, e.getMessage());
            }
        }
    }
}
