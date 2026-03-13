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

}
