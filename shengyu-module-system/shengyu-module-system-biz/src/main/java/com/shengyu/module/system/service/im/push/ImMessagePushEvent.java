package com.shengyu.module.system.service.im.push;

/** A persisted IM message became visible; delivery is handled after commit. */
public class ImMessagePushEvent {
    private final Long tenantId;
    private final Long senderId;
    private final Long groupId;
    private final Long receiverId;
    private final Long chatId;
    private final Long messageId;
    private final long sentAt;

    public ImMessagePushEvent(Long tenantId, Long senderId, Long groupId, Long receiverId,
                              Long chatId, Long messageId, long sentAt) {
        this.tenantId = tenantId;
        this.senderId = senderId;
        this.groupId = groupId;
        this.receiverId = receiverId;
        this.chatId = chatId;
        this.messageId = messageId;
        this.sentAt = sentAt;
    }
    public Long getTenantId() { return tenantId; }
    public Long getSenderId() { return senderId; }
    public Long getGroupId() { return groupId; }
    public Long getReceiverId() { return receiverId; }
    public Long getChatId() { return chatId; }
    public Long getMessageId() { return messageId; }
    public long getSentAt() { return sentAt; }
}
