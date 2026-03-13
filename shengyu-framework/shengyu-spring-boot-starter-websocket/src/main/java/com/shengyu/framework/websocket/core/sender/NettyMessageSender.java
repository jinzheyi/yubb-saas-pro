package com.shengyu.framework.websocket.core.sender;

import cn.hutool.core.util.StrUtil;
import cn.hutool.json.JSONObject;
import cn.hutool.json.JSONUtil;
import com.shengyu.framework.websocket.core.protocol.ImMessage;
import com.shengyu.framework.websocket.core.protocol.FileMessage;
import com.shengyu.framework.websocket.core.protocol.MessageHeader;
import com.shengyu.framework.websocket.core.protocol.MessageType;
import com.shengyu.framework.websocket.core.service.ConversationSnapshotService;
import com.shengyu.framework.websocket.core.session.NettySession;
import com.shengyu.framework.websocket.core.session.NettySessionManager;
import com.shengyu.framework.common.util.json.JsonUtils;
import com.shengyu.framework.tenant.core.context.TenantContextHolder;
import com.shengyu.framework.tenant.core.util.TenantUtils;
import com.google.protobuf.ByteString;
import com.google.protobuf.MessageLite;
import io.netty.channel.Channel;
import io.netty.handler.codec.http.websocketx.TextWebSocketFrame;
import io.netty.handler.codec.http.websocketx.WebSocketServerProtocolHandler;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.HashMap;
import java.util.Map;

/**
 * Netty 消息发送器
 * 提供各种消息发送方法
 *
 * @author 圣钰科技
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class NettyMessageSender {

    private final NettySessionManager sessionManager;

    @org.springframework.beans.factory.annotation.Autowired(required = false)
    private ConversationSnapshotService conversationSnapshotService;

    /**
     * 发送消息给指定用户
     *
     * @param userId      用户ID
     * @param messageType 消息类型
     * @param body        消息体
     */
    public void sendToUser(Long userId, MessageType messageType, MessageLite body) {
        sendToUser(userId, messageType, body, null);
    }

    /**
     * 发送消息给指定用户
     *
     * @param userId      用户ID
     * @param messageType 消息类型
     * @param body        消息体
     * @param senderId    发送者ID
     */
    public void sendToUser(Long userId, MessageType messageType, MessageLite body, Long senderId, Long tenantId) {
        // 兼容旧调用：默认 receiverId=userId，groupId=null，messageId=null（由发送器生成）
        sendToUser(userId, messageType, body, senderId, userId, null, tenantId, null);
    }

    /**
     * 发送消息给指定用户（可显式指定 receiverId/groupId/messageId）
     *
     * 说明：部分业务（如群聊）需要依赖 groupId 进行前端会话路由；同时 messageId 需要与业务消息 ID 保持一致，
     * 以便前端去重/对齐历史消息。
     */
    public void sendToUser(Long userId, MessageType messageType, MessageLite body,
                           Long senderId, Long receiverId, Long groupId, Long tenantId, Long messageId) {
        sendToUser(userId, messageType, body, senderId, receiverId, groupId, tenantId, messageId, null);
    }

    /**
     * 发送消息给指定用户（可显式指定 receiverId/groupId/messageId/sequence）
     */
    public void sendToUser(Long userId, MessageType messageType, MessageLite body,
                           Long senderId, Long receiverId, Long groupId, Long tenantId, Long messageId, Long sequence) {
        sendToUser(userId, messageType, body, senderId, receiverId, groupId, tenantId, messageId, sequence, null);
    }

    /**
     * 发送消息给指定用户（可显式指定 receiverId/groupId/messageId/sequence/chatId）
     */
    public void sendToUser(Long userId, MessageType messageType, MessageLite body,
                           Long senderId, Long receiverId, Long groupId, Long tenantId, Long messageId, Long sequence, Long chatId) {
        sendToUser(userId, messageType, body, senderId, receiverId, groupId, tenantId, messageId, sequence, chatId, null, null);
    }

    /**
     * 发送消息给指定用户（可显式指定 receiverId/groupId/messageId/sequence/chatId/cursorVersion/conversationVersion）
     *
     * 说明：当 cursorVersion/conversationVersion 由业务侧已知时，可透传到 WS payload，避免为 gap 检测额外查库构建 snapshot。
     */
    public void sendToUser(Long userId, MessageType messageType, MessageLite body,
                           Long senderId, Long receiverId, Long groupId, Long tenantId, Long messageId, Long sequence, Long chatId,
                           Long cursorVersion, Long conversationVersion) {
        TenantUtils.execute(tenantId, () -> {
            List<NettySession> sessions = sessionManager.getSessionsByUserId(userId);
            if (sessions.isEmpty()) {
                log.info("[MessageSender] 用户不在线: userId={}, type={}, messageId={}, senderId={}, receiverId={}, groupId={}, tenantId={}",
                        userId, messageType, messageId, senderId, receiverId, groupId, tenantId);
                return;
            }

            if (log.isInfoEnabled()) {
                log.info("[MessageSender] sendToUser begin: userId={}, type={}, messageId={}, senderId={}, receiverId={}, groupId={}, tenantId={}, sessions={}",
                        userId, messageType, messageId, senderId, receiverId, groupId, tenantId, sessions.size());
            }

            ImMessage protobufMessage = buildMessage(messageType, body, senderId, receiverId, groupId, tenantId, messageId, sequence);
            String jsonPayload = buildJsonPayload(messageType, body, senderId, receiverId, groupId, tenantId, messageId, sequence, chatId, userId,
                    cursorVersion, conversationVersion);

            int successCount = 0;
            for (NettySession session : sessions) {
                if (session.isActive()) {
                    Channel channel = session.getChannel();
                    if (channel != null) {
                        boolean ws = isWebSocketChannel(channel);
                        if (log.isInfoEnabled()) {
                            log.info("[MessageSender] write: userId={}, sessionUserId={}, deviceType={}, active={}, ws={}, channelId={}, messageId={}, type={}",
                                    userId,
                                    session.getUserId(),
                                    session.getDeviceType(),
                                    session.isActive(),
                                    ws,
                                    channel.id(),
                                    messageId,
                                    messageType);
                        }

                        if (ws) {
                            channel.writeAndFlush(new TextWebSocketFrame(jsonPayload)).addListener(f -> {
                                if (!f.isSuccess()) {
                                    log.warn("[MessageSender] ws write failed: userId={}, channelId={}, messageId={}, type={}",
                                            userId, channel.id(), messageId, messageType, f.cause());
                                }
                            });
                        } else {
                            channel.writeAndFlush(protobufMessage).addListener(f -> {
                                if (!f.isSuccess()) {
                                    log.warn("[MessageSender] protobuf write failed: userId={}, channelId={}, messageId={}, type={}",
                                            userId, channel.id(), messageId, messageType, f.cause());
                                }
                            });
                        }
                    }
                    successCount++;
                } else {
                    if (log.isInfoEnabled()) {
                        log.info("[MessageSender] session inactive skip: targetUserId={}, sessionUserId={}, deviceType={}, messageId={}, type={}",
                                userId, session.getUserId(), session.getDeviceType(), messageId, messageType);
                    }
                }
            }

            log.info("[MessageSender] sendToUser done: userId={}, type={}, messageId={}, devices={}, activeWritten={}",
                    userId, messageType, messageId, sessions.size(), successCount);
        });
    }

    /**
     * 发送消息给指定用户（显式指定 header.extra，用于最终态事件携带 rev/操作人/时间等元数据）
     */
    public void sendToUserWithExtra(Long userId, MessageType messageType, MessageLite body,
                                    Long senderId, Long receiverId, Long groupId, Long tenantId, Long messageId, Long sequence, Long chatId,
                                    Long cursorVersion, Long conversationVersion, String headerExtra) {
        TenantUtils.execute(tenantId, () -> {
            List<NettySession> sessions = sessionManager.getSessionsByUserId(userId);
            if (sessions.isEmpty()) {
                log.info("[MessageSender] 用户不在线: userId={}, type={}, messageId={}, senderId={}, receiverId={}, groupId={}, tenantId={}",
                        userId, messageType, messageId, senderId, receiverId, groupId, tenantId);
                return;
            }

            if (log.isInfoEnabled()) {
                log.info("[MessageSender] sendToUserWithExtra begin: userId={}, type={}, messageId={}, senderId={}, receiverId={}, groupId={}, tenantId={}, sessions={}",
                        userId, messageType, messageId, senderId, receiverId, groupId, tenantId, sessions.size());
            }

            ImMessage protobufMessage = buildMessageWithExtra(messageType, body, senderId, receiverId, groupId, tenantId, messageId, sequence, headerExtra);
            String jsonPayload = buildJsonPayloadWithExtra(messageType, body, senderId, receiverId, groupId, tenantId, messageId, sequence, chatId, userId,
                    cursorVersion, conversationVersion, headerExtra);

            int successCount = 0;
            for (NettySession session : sessions) {
                if (session.isActive()) {
                    Channel channel = session.getChannel();
                    if (channel != null) {
                        boolean ws = isWebSocketChannel(channel);
                        if (log.isInfoEnabled()) {
                            log.info("[MessageSender] write: userId={}, sessionUserId={}, deviceType={}, active={}, ws={}, channelId={}, messageId={}, type={}",
                                    userId,
                                    session.getUserId(),
                                    session.getDeviceType(),
                                    session.isActive(),
                                    ws,
                                    channel.id(),
                                    messageId,
                                    messageType);
                        }

                        if (ws) {
                            channel.writeAndFlush(new TextWebSocketFrame(jsonPayload)).addListener(f -> {
                                if (!f.isSuccess()) {
                                    log.warn("[MessageSender] ws write failed: userId={}, channelId={}, messageId={}, type={}",
                                            userId, channel.id(), messageId, messageType, f.cause());
                                }
                            });
                        } else {
                            channel.writeAndFlush(protobufMessage).addListener(f -> {
                                if (!f.isSuccess()) {
                                    log.warn("[MessageSender] protobuf write failed: userId={}, channelId={}, messageId={}, type={}",
                                            userId, channel.id(), messageId, messageType, f.cause());
                                }
                            });
                        }
                    }
                    successCount++;
                }
            }

            log.info("[MessageSender] sendToUserWithExtra done: userId={}, type={}, messageId={}, devices={}, activeWritten={}",
                    userId, messageType, messageId, sessions.size(), successCount);
        });
    }

    /**
     * 发送消息给指定用户（重载，自动获取租户ID）
     *
     * @param userId      用户ID
     * @param messageType 消息类型
     * @param body        消息体
     * @param senderId    发送者ID
     */
    public void sendToUser(Long userId, MessageType messageType, MessageLite body, Long senderId) {
        // 尝试从当前上下文获取租户ID
        Long tenantId = null;
        try {
            tenantId = TenantContextHolder.getTenantId();
        } catch (Exception e) {
            log.debug("[MessageSender] 无法获取当前租户ID，将不使用租户上下文");
        }
        sendToUser(userId, messageType, body, senderId, tenantId);
    }

    /**
     * 发送消息给指定租户的所有用户
     *
     * @param tenantId    租户ID
     * @param messageType 消息类型
     * @param body        消息体
     */
    public void sendToTenant(Long tenantId, MessageType messageType, MessageLite body) {
        // 使用租户上下文执行
        TenantUtils.execute(tenantId, () -> {
            List<NettySession> sessions = sessionManager.getSessionsByTenantId(tenantId);
            if (sessions.isEmpty()) {
                log.debug("[MessageSender] 租户无在线用户: {}", tenantId);
                return;
            }

            ImMessage protobufMessage = buildMessage(messageType, body, null, null, null, tenantId, null, null);
            String jsonPayload = buildJsonPayload(messageType, body, null, null, null, tenantId, null, null, null, null);

            int successCount = 0;
            for (NettySession session : sessions) {
                if (!session.isActive()) {
                    continue;
                }
                Channel channel = session.getChannel();
                if (channel == null) {
                    continue;
                }
                if (isWebSocketChannel(channel)) {
                    channel.writeAndFlush(new TextWebSocketFrame(jsonPayload));
                } else {
                    channel.writeAndFlush(protobufMessage);
                }
                successCount++;
            }

            log.debug("[MessageSender] 发送消息给租户: {}, 用户数: {}, 成功: {}",
                    tenantId, sessions.size(), successCount);
        });
    }

    /**
     * 广播消息给所有在线用户
     *
     * @param messageType 消息类型
     * @param body        消息体
     */
    public void broadcast(MessageType messageType, MessageLite body) {
        List<NettySession> sessions = sessionManager.getAllSessions();
        if (sessions.isEmpty()) {
            log.debug("[MessageSender] 无在线用户");
            return;
        }

        ImMessage message = buildMessage(messageType, body, null, null, null, null);
        
        int successCount = 0;
        for (NettySession session : sessions) {
            if (session.isActive()) {
                session.getChannel().writeAndFlush(message);
                successCount++;
            }
        }

        log.debug("[MessageSender] 广播消息, 总用户数: {}, 成功: {}", 
            sessions.size(), successCount);
    }

    /**
     * 发送消息给指定用户的指定设备
     *
     * @param userId      用户ID
     * @param deviceId    设备ID
     * @param messageType 消息类型
     * @param body        消息体
     */
    public void sendToDevice(Long userId, String deviceId, MessageType messageType, MessageLite body) {
        List<NettySession> sessions = sessionManager.getSessionsByUserId(userId);
        
        for (NettySession session : sessions) {
            if (deviceId.equals(session.getDeviceId()) && session.isActive()) {
                Long tenantId = session.getTenantId();
                // 使用租户上下文执行
                TenantUtils.execute(tenantId, () -> {
                    ImMessage message = buildMessage(messageType, body, null, userId, null, tenantId);
                    session.getChannel().writeAndFlush(message);
                });
                log.debug("[MessageSender] 发送消息给设备: userId={}, deviceId={}", userId, deviceId);
                return;
            }
        }

        log.debug("[MessageSender] 设备不在线: userId={}, deviceId={}", userId, deviceId);
    }

    /**
     * 构建 IM 消息
     */
    private ImMessage buildMessage(MessageType messageType, MessageLite body,
                                   Long senderId, Long receiverId, Long groupId, Long tenantId) {
        return buildMessage(messageType, body, senderId, receiverId, groupId, tenantId, null, null);
    }

    private ImMessage buildMessage(MessageType messageType, MessageLite body,
                                   Long senderId, Long receiverId, Long groupId, Long tenantId, Long messageId) {
        return buildMessage(messageType, body, senderId, receiverId, groupId, tenantId, messageId, null);
    }

    private ImMessage buildMessage(MessageType messageType, MessageLite body,
                                   Long senderId, Long receiverId, Long groupId, Long tenantId, Long messageId, Long sequence) {
        MessageHeader.Builder headerBuilder = MessageHeader.newBuilder()
                .setMessageId(messageId != null ? messageId : generateMessageId())
                .setMessageType(messageType)
                .setTimestamp(System.currentTimeMillis());

        if (sequence != null) {
            headerBuilder.setSequence(sequence);
        }

        String derivedExtra = deriveHeaderExtra(messageType, body);
        if (StrUtil.isNotBlank(derivedExtra)) {
            headerBuilder.setExtra(derivedExtra);
        }

        if (senderId != null) {
            headerBuilder.setSenderId(senderId);
        }
        if (receiverId != null) {
            headerBuilder.setReceiverId(receiverId);
        }
        if (groupId != null) {
            headerBuilder.setGroupId(groupId);
        }
        if (tenantId != null) {
            headerBuilder.setTenantId(tenantId);
        }

        ImMessage.Builder messageBuilder = ImMessage.newBuilder()
                .setHeader(headerBuilder.build());

        if (body != null) {
            messageBuilder.setBody(ByteString.copyFrom(body.toByteArray()));
        }

        return messageBuilder.build();
    }

    private ImMessage buildMessageWithExtra(MessageType messageType, MessageLite body,
                                           Long senderId, Long receiverId, Long groupId, Long tenantId, Long messageId, Long sequence,
                                           String explicitExtra) {
        MessageHeader.Builder headerBuilder = MessageHeader.newBuilder()
                .setMessageId(messageId != null ? messageId : generateMessageId())
                .setMessageType(messageType)
                .setTimestamp(System.currentTimeMillis());

        if (sequence != null) {
            headerBuilder.setSequence(sequence);
        }

        String derivedExtra = deriveHeaderExtra(messageType, body);
        String finalExtra = StrUtil.isNotBlank(explicitExtra) ? explicitExtra : derivedExtra;
        if (StrUtil.isNotBlank(finalExtra)) {
            headerBuilder.setExtra(finalExtra);
        }

        if (senderId != null) {
            headerBuilder.setSenderId(senderId);
        }
        if (receiverId != null) {
            headerBuilder.setReceiverId(receiverId);
        }
        if (groupId != null) {
            headerBuilder.setGroupId(groupId);
        }
        if (tenantId != null) {
            headerBuilder.setTenantId(tenantId);
        }

        ImMessage.Builder messageBuilder = ImMessage.newBuilder()
                .setHeader(headerBuilder.build());

        if (body != null) {
            messageBuilder.setBody(ByteString.copyFrom(body.toByteArray()));
        }

        return messageBuilder.build();
    }

    private boolean isWebSocketChannel(Channel channel) {
        try {
            return channel.pipeline().get(WebSocketServerProtocolHandler.class) != null;
        } catch (Exception e) {
            return false;
        }
    }

    private String buildJsonPayload(MessageType messageType, MessageLite body,
                                   Long senderId, Long receiverId, Long groupId, Long tenantId, Long messageId, Long sequence,
                                   Long chatId, Long toUserId) {
        return buildJsonPayload(messageType, body, senderId, receiverId, groupId, tenantId, messageId, sequence,
                chatId, toUserId, null, null);
    }

    private String buildJsonPayload(MessageType messageType, MessageLite body,
                                   Long senderId, Long receiverId, Long groupId, Long tenantId, Long messageId, Long sequence,
                                   Long chatId, Long toUserId, Long cursorVersion, Long conversationVersion) {
        Map<String, Object> root = new HashMap<>();
        Map<String, Object> header = new HashMap<>();
        header.put("messageId", messageId != null ? String.valueOf(messageId) : String.valueOf(generateMessageId()));
        header.put("messageType", messageType != null ? messageType.getNumber() : null);
        header.put("timestamp", System.currentTimeMillis());
        header.put("senderId", senderId != null ? String.valueOf(senderId) : "0");
        header.put("receiverId", receiverId != null ? String.valueOf(receiverId) : "0");
        header.put("groupId", groupId != null ? String.valueOf(groupId) : "0");
        header.put("tenantId", tenantId != null ? String.valueOf(tenantId) : "0");
        if (chatId != null) {
            header.put("chatId", String.valueOf(chatId));
        }
        if (sequence != null) {
            header.put("sequence", String.valueOf(sequence));
        }

        String derivedExtra = deriveHeaderExtra(messageType, body);
        if (StrUtil.isNotBlank(derivedExtra)) {
            header.put("extra", derivedExtra);
        }
        root.put("header", header);
        root.put("body", buildJsonBody(messageType, body));

        if (cursorVersion != null) {
            root.put("cursorVersion", String.valueOf(cursorVersion));
        }
        if (conversationVersion != null) {
            root.put("conversationVersion", String.valueOf(conversationVersion));
        }

        // 当 cursorVersion 已透传，端侧可基于 cursorVersion 做 gap 检测并走增量补偿，同步状态由 /conversation/sync 保证
        // 这里默认不再额外查库构建 snapshot，以降低写扩散下的 DB 压力
        if (cursorVersion == null && chatId != null && toUserId != null && conversationSnapshotService != null) {
            try {
                Map<String, Object> snapshot = conversationSnapshotService.buildSnapshot(toUserId, chatId);
                if (snapshot != null && !snapshot.isEmpty()) {
                    root.put("conversationSnapshot", snapshot);
                }
            } catch (Exception e) {
                log.warn("[MessageSender] buildSnapshot failed: toUserId={}, chatId={}, messageId={}, type={}",
                        toUserId, chatId, messageId, messageType, e);
            }
        }
        return JsonUtils.toJsonString(root);
    }

    private String buildJsonPayloadWithExtra(MessageType messageType, MessageLite body,
                                            Long senderId, Long receiverId, Long groupId, Long tenantId, Long messageId, Long sequence,
                                            Long chatId, Long toUserId, Long cursorVersion, Long conversationVersion, String explicitExtra) {
        Map<String, Object> root = new HashMap<>();
        Map<String, Object> header = new HashMap<>();
        header.put("messageId", messageId != null ? String.valueOf(messageId) : String.valueOf(generateMessageId()));
        header.put("messageType", messageType != null ? messageType.getNumber() : null);
        header.put("timestamp", System.currentTimeMillis());
        header.put("senderId", senderId != null ? String.valueOf(senderId) : "0");
        header.put("receiverId", receiverId != null ? String.valueOf(receiverId) : "0");
        header.put("groupId", groupId != null ? String.valueOf(groupId) : "0");
        header.put("tenantId", tenantId != null ? String.valueOf(tenantId) : "0");
        if (chatId != null) {
            header.put("chatId", String.valueOf(chatId));
        }
        if (sequence != null) {
            header.put("sequence", String.valueOf(sequence));
        }

        String derivedExtra = deriveHeaderExtra(messageType, body);
        String finalExtra = StrUtil.isNotBlank(explicitExtra) ? explicitExtra : derivedExtra;
        if (StrUtil.isNotBlank(finalExtra)) {
            header.put("extra", finalExtra);
        }
        root.put("header", header);
        root.put("body", buildJsonBody(messageType, body));

        if (cursorVersion != null) {
            root.put("cursorVersion", String.valueOf(cursorVersion));
        }
        if (conversationVersion != null) {
            root.put("conversationVersion", String.valueOf(conversationVersion));
        }

        if (cursorVersion == null && chatId != null && toUserId != null && conversationSnapshotService != null) {
            try {
                Map<String, Object> snapshot = conversationSnapshotService.buildSnapshot(toUserId, chatId);
                if (snapshot != null && !snapshot.isEmpty()) {
                    root.put("conversationSnapshot", snapshot);
                }
            } catch (Exception e) {
                log.warn("[MessageSender] buildSnapshot failed: toUserId={}, chatId={}, messageId={}, type={}",
                        toUserId, chatId, messageId, messageType, e);
            }
        }
        return JsonUtils.toJsonString(root);
    }

    private String deriveHeaderExtra(MessageType messageType, MessageLite body) {
        if (messageType != MessageType.FILE) {
            return null;
        }
        if (!(body instanceof FileMessage)) {
            return null;
        }
        try {
            FileMessage m = (FileMessage) body;
            JSONObject obj = JSONUtil.createObj();
            obj.set("url", m.getUrl());
            obj.set("fileName", m.getFileName());
            obj.set("size", m.getSize());
            obj.set("fileType", m.getFileType());
            return obj.toString();
        } catch (Exception e) {
            return null;
        }
    }

    private Object buildJsonBody(MessageType messageType, MessageLite body) {
        if (messageType == null) {
            return new HashMap<>();
        }
        Map<String, Object> json = new HashMap<>();
        switch (messageType) {
            case TEXT:
                if (body instanceof com.shengyu.framework.websocket.core.protocol.TextMessage) {
                    com.shengyu.framework.websocket.core.protocol.TextMessage m = (com.shengyu.framework.websocket.core.protocol.TextMessage) body;
                    json.put("content", m.getContent());
                    json.put("atUserIds", m.getAtUserIdsList());
                }
                return json;
            case IMAGE:
                if (body instanceof com.shengyu.framework.websocket.core.protocol.ImageMessage) {
                    com.shengyu.framework.websocket.core.protocol.ImageMessage m = (com.shengyu.framework.websocket.core.protocol.ImageMessage) body;
                    json.put("url", m.getUrl());
                    json.put("thumbnailUrl", m.getThumbnailUrl());
                    json.put("width", m.getWidth());
                    json.put("height", m.getHeight());
                    json.put("size", m.getSize());
                }
                return json;
            case VOICE:
                if (body instanceof com.shengyu.framework.websocket.core.protocol.VoiceMessage) {
                    com.shengyu.framework.websocket.core.protocol.VoiceMessage m = (com.shengyu.framework.websocket.core.protocol.VoiceMessage) body;
                    json.put("url", m.getUrl());
                    json.put("duration", m.getDuration());
                    json.put("size", m.getSize());
                }
                return json;
            case VIDEO:
                if (body instanceof com.shengyu.framework.websocket.core.protocol.VideoMessage) {
                    com.shengyu.framework.websocket.core.protocol.VideoMessage m = (com.shengyu.framework.websocket.core.protocol.VideoMessage) body;
                    json.put("url", m.getUrl());
                    json.put("coverUrl", m.getCoverUrl());
                    json.put("duration", m.getDuration());
                    json.put("width", m.getWidth());
                    json.put("height", m.getHeight());
                    json.put("size", m.getSize());
                }
                return json;
            case FILE:
                if (body instanceof com.shengyu.framework.websocket.core.protocol.FileMessage) {
                    com.shengyu.framework.websocket.core.protocol.FileMessage m = (com.shengyu.framework.websocket.core.protocol.FileMessage) body;
                    json.put("url", m.getUrl());
                    json.put("fileName", m.getFileName());
                    json.put("size", m.getSize());
                    json.put("fileType", m.getFileType());
                }
                return json;
            case LOCATION:
                if (body instanceof com.shengyu.framework.websocket.core.protocol.LocationMessage) {
                    com.shengyu.framework.websocket.core.protocol.LocationMessage m = (com.shengyu.framework.websocket.core.protocol.LocationMessage) body;
                    json.put("latitude", m.getLatitude());
                    json.put("longitude", m.getLongitude());
                    json.put("address", m.getAddress());
                }
                return json;
            case QUOTE_REPLY:
                if (body instanceof com.shengyu.framework.websocket.core.protocol.QuoteReplyMessage) {
                    com.shengyu.framework.websocket.core.protocol.QuoteReplyMessage m = (com.shengyu.framework.websocket.core.protocol.QuoteReplyMessage) body;
                    json.put("content", m.getReplyContent());
                    json.put("quotedMessageId", String.valueOf(m.getQuoteMessageId()));
                    json.put("quotedContent", m.getQuoteContent());
                    json.put("quotedSenderName", m.getQuoteSenderName());
                    json.put("atUserIds", m.getAtUserIdsList());
                }
                return json;
            case READ_RECEIPT:
                if (body instanceof com.shengyu.framework.websocket.core.protocol.ReadReceiptMessage) {
                    com.shengyu.framework.websocket.core.protocol.ReadReceiptMessage m = (com.shengyu.framework.websocket.core.protocol.ReadReceiptMessage) body;
                    json.put("messageIds", m.getMessageIdsList());
                }
                return json;
            case RECALL:
                if (body instanceof com.shengyu.framework.websocket.core.protocol.RecallMessage) {
                    com.shengyu.framework.websocket.core.protocol.RecallMessage m = (com.shengyu.framework.websocket.core.protocol.RecallMessage) body;
                    json.put("messageId", String.valueOf(m.getMessageId()));
                }
                return json;
            case TYPING:
                if (body instanceof com.shengyu.framework.websocket.core.protocol.TypingMessage) {
                    com.shengyu.framework.websocket.core.protocol.TypingMessage m = (com.shengyu.framework.websocket.core.protocol.TypingMessage) body;
                    json.put("isTyping", m.getIsTyping());
                }
                return json;
            case BADGE_UPDATE:
                if (body instanceof com.shengyu.framework.websocket.core.protocol.BadgeUpdateMessage) {
                    com.shengyu.framework.websocket.core.protocol.BadgeUpdateMessage m = (com.shengyu.framework.websocket.core.protocol.BadgeUpdateMessage) body;
                    json.put("unreadCount", m.getUnreadCount());
                    java.util.List<java.util.Map<String, Object>> conversationBadges = new java.util.ArrayList<>();
                    for (com.shengyu.framework.websocket.core.protocol.ConversationBadge b : m.getConversationBadgesList()) {
                        java.util.Map<String, Object> item = new java.util.HashMap<>();
                        item.put("conversationId", String.valueOf(b.getConversationId()));
                        item.put("unreadCount", b.getUnreadCount());
                        conversationBadges.add(item);
                    }
                    json.put("conversationBadges", conversationBadges);

                    java.util.List<java.util.Map<String, Object>> menuBadges = new java.util.ArrayList<>();
                    for (com.shengyu.framework.websocket.core.protocol.MenuBadge b : m.getMenuBadgesList()) {
                        java.util.Map<String, Object> item = new java.util.HashMap<>();
                        item.put("menuId", b.getMenuId());
                        item.put("count", b.getBadgeCount());
                        menuBadges.add(item);
                    }
                    json.put("menuBadges", menuBadges);
                }
                return json;
            default:
                if (body instanceof com.shengyu.framework.websocket.core.protocol.TextMessage) {
                    json.put("content", ((com.shengyu.framework.websocket.core.protocol.TextMessage) body).getContent());
                }
                return json;
        }
    }

    /**
     * 生成消息ID（雪花算法）
     * TODO: 集成实际的ID生成器
     */
    private long generateMessageId() {
        return System.currentTimeMillis();
    }
}
