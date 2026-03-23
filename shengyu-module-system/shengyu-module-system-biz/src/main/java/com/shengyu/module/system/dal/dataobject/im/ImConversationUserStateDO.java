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
}
