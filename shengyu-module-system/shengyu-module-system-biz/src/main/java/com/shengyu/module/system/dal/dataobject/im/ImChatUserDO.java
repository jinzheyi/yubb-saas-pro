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

@TableName(value = "im_chat_user", autoResultMap = true)
@KeySequence("im_chat_user_seq")
@Data
@EqualsAndHashCode(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ImChatUserDO extends TenantBaseDO {

    @TableId
    private Long id;

    private Long chatId;

    private Long userId;

    private Integer unreadCount;

    private Long lastReadMessageId;

    private Long lastReadSequence;

    private Long lastMessageId;

    private Long lastMessageSequence;

    private Integer lastMessageType;

    private String lastMessageContent;

    private LocalDateTime lastMessageTime;

    private Boolean isPinned;

    private Boolean noDisturb;

    private String draft;

    private Boolean deletedByUser;

}
