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

/**
 * IM 会话 DO
 * 
 * 对应表: im_conversation
 * 功能: 存储用户的会话列表(单聊/群聊)
 *
 * @author 圣钰科技
 */
@TableName(value = "im_conversation", autoResultMap = true)
@KeySequence("im_conversation_seq")
@Data
@EqualsAndHashCode(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ImConversationDO extends TenantBaseDO {

    /**
     * 会话ID
     */
    @TableId
    private Long id;

    /**
     * 用户ID
     */
    private Long userId;

    /**
     * 目标ID(单聊为对方用户ID,群聊为群ID)
     */
    private Long targetId;

    /**
     * 会话类型
     * 
     * 枚举: {@link com.shengyu.module.system.enums.im.ImConversationTypeEnum}
     * 1-单聊, 2-群聊
     */
    private Integer conversationType;

    /**
     * 未读消息数
     */
    private Integer unreadCount;

    /**
     * 最后一条消息ID
     */
    private Long lastMessageId;

    /**
     * 最后一条消息内容
     */
    private String lastMessageContent;

    /**
     * 最后一条消息时间
     */
    private LocalDateTime lastMessageTime;

    /**
     * 是否置顶
     */
    private Boolean isPinned;

    /**
     * 是否免打扰
     */
    private Boolean noDisturb;

    /**
     * 用户是否删除会话
     */
    private Boolean deletedByUser;

}
