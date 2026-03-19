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

@TableName(value = "im_chat_message", autoResultMap = true)
@KeySequence("im_chat_message_seq")
@Data
@EqualsAndHashCode(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ImChatMessageDO extends TenantBaseDO {

    @TableId
    private Long id;

    private Long chatId;

    private Long sequence;

    private Long senderId;

    private Integer messageType;

    private String content;

    private String extra;

    private LocalDateTime sendTime;

    private Long rev;

    private Integer status;

    private LocalDateTime recallTime;

    private Long recallBy;

    private Long quoteMessageId;

    /**
     * 转发来源信息(JSON格式)
     * 结构: {originalMessageId, originalChatId, originalSenderId, originalSenderName, forwardTime}
     */
    private String forwardedFrom;

    /**
     * 客户端消息ID(幂等键，用于重发)
     * 端侧生成的唯一标识，同一clientMessageId多次发送返回同一结果
     */
    private String clientMessageId;

    /**
     * 被@提及用户列表(JSON格式)
     * 结构: [{userId, nickname}]
     * 被提及用户会收到强提醒推送（即使群免打扰）
     */
    private String mentions;

}
