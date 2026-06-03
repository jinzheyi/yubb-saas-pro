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
     * 群组快照数据JSON（被踢/退群/解散时冻结，包含群名称、公告、成员列表关键信息等）
     */
    private String snapshotData;
}
