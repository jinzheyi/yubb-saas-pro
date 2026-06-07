package com.shengyu.module.system.dal.dataobject.im;

import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.framework.tenant.core.db.TenantBaseDO;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@TableName(value = "im_conversation_user_state", autoResultMap = true)
@KeySequence("im_conversation_user_state_seq")
@Data
@EqualsAndHashCode(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ImConversationUserStateDO extends TenantBaseDO {

    @TableId
    private Long id;

    private Long chatId;

    private Long userId;

    private Long cursorVersion;

    private Long conversationVersion;

    private Integer unreadCount;

    private Long lastReadSequence;

    private LocalDateTime lastReadTime;

    private Long lastMessageId;

    private Long lastMessageSequence;

    /**
     * 最后一条消息发送者ID（冗余字段，避免回表查询 im_chat_message）
     */
    private Long lastMessageSenderId;

    private Integer lastMessageType;

    private String lastMessageContent;

    /**
     * 最后一条消息是否@了我（用于会话列表 [有人@我] 标记）
     */
    private Boolean lastMessageHasAtMe;

    private LocalDateTime lastMessageTime;

    private Boolean isPinned;

    private Boolean noDisturb;

    private String draft;

    private Boolean deletedByUser;

    /**
     * 群组成员状态：
     * 0 = 正常（在群内）
     * 1 = 已退出（主动退群）
     * 2 = 已被踢（被群主/管理员踢出）
     * 3 = 群已解散
     */
    private Integer groupMemberStatus;

    /**
     * 离群时间（被踢/退群时间，用于限制只能查询离群前的消息）
     */
    private LocalDateTime leftAt;

    /**
     * 群组快照数据JSON（被踢/退群/解散时冻结，用于会话列表和聊天页展示）
     */
    private String snapshotData;
}
