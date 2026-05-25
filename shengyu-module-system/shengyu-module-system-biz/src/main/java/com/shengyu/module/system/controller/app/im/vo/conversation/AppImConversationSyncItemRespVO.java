package com.shengyu.module.system.controller.app.im.vo.conversation;

import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import com.fasterxml.jackson.databind.ser.std.ToStringSerializer;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.time.LocalDateTime;

@Schema(description = "移动端 - IM 会话增量同步 Item")
@Data
public class AppImConversationSyncItemRespVO {

    @Schema(description = "ChatID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long chatId;

    @Schema(description = "目标ID(单聊为对方用户ID,群聊为群ID)", requiredMode = Schema.RequiredMode.REQUIRED, example = "100")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long targetId;

    @Schema(description = "会话类型(1-单聊 2-群聊)", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    private Integer conversationType;

    @Schema(description = "用户维度游标版本号", requiredMode = Schema.RequiredMode.REQUIRED, example = "1000")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long cursorVersion;

    @Schema(description = "会话级版本号", requiredMode = Schema.RequiredMode.REQUIRED, example = "10")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long conversationVersion;

    @Schema(description = "未读消息数", requiredMode = Schema.RequiredMode.REQUIRED, example = "5")
    private Integer unreadCount;

    @Schema(description = "最后一条消息序列号水位", example = "100")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long lastMessageSequence;

    @Schema(description = "最后已读序列号水位", example = "90")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long lastReadSequence;

    @Schema(description = "最后一条消息类型(同 im_chat_message.message_type)", example = "2")
    private Integer lastMessageType;

    @Schema(description = "最后一条消息内容", example = "你好")
    private String lastMessageContent;

    @Schema(description = "最后一条消息是否@了我（用于会话列表[有人@我]标记）", example = "false")
    private Boolean lastMessageHasAtMe;

    @Schema(description = "最后一条消息时间", example = "2026-02-11 10:30:00")
    private LocalDateTime lastMessageTime;

    @Schema(description = "是否置顶", requiredMode = Schema.RequiredMode.REQUIRED, example = "false")
    private Boolean isPinned;

    @Schema(description = "是否免打扰", requiredMode = Schema.RequiredMode.REQUIRED, example = "false")
    private Boolean noDisturb;

    @Schema(description = "草稿内容", example = "xxx")
    private String draft;

    @Schema(description = "用户是否删除会话", requiredMode = Schema.RequiredMode.REQUIRED, example = "false")
    private Boolean deletedByUser;

    @Schema(description = "目标名称(对方名称或群名)", example = "张三")
    private String targetName;

    @Schema(description = "目标头像", example = "https://...")
    private String targetAvatar;

    @Schema(description = "群成员数量(群聊时有值)", example = "10")
    private Integer groupMemberCount;

    @Schema(description = "群成员信息列表(群聊时返回,最多4个,用于组合头像)", example = "[{\"userId\":1,\"name\":\"张三\",\"avatar\":\"url1\"}]")
    private java.util.List<AppImConversationSyncGroupMemberItem> groupMemberItems;

    @Data
    @Schema(description = "群成员信息项(用于组合头像)")
    public static class AppImConversationSyncGroupMemberItem {
        @Schema(description = "用户ID")
        private Long userId;
        @Schema(description = "用户名称")
        private String name;
        @Schema(description = "用户头像")
        private String avatar;
    }
}
