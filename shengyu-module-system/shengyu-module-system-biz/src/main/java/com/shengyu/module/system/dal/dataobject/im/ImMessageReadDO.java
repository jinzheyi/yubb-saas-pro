package com.shengyu.module.system.dal.dataobject.im;

import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.framework.mybatis.core.dataobject.BaseDO;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * IM 消息已读 DO
 * 
 * 对应表: im_message_read
 * 功能: 存储群聊消息的已读状态(单聊通过 im_chat_message.status 字段判断)
 * 说明: 仅用于群聊消息已读回执
 *
 * @author 圣钰科技
 */
@TableName(value = "im_message_read", autoResultMap = true)
@KeySequence("im_message_read_seq")
@Data
@EqualsAndHashCode(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ImMessageReadDO extends BaseDO {

    /**
     * 已读ID
     */
    @TableId
    private Long id;

    /**
     * 消息ID
     */
    private Long messageId;

    /**
     * 用户ID
     */
    private Long userId;

    /**
     * 已读时间
     */
    private LocalDateTime readTime;

    /**
     * 租户编号
     */
    private Long tenantId;

}
