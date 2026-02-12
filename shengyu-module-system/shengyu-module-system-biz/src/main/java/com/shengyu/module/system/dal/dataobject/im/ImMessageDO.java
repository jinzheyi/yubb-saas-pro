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
 * IM 消息 DO
 * 
 * 对应表: im_message
 * 功能: 存储所有聊天消息(单聊/群聊)
 *
 * @author 圣钰科技
 */
@TableName(value = "im_message", autoResultMap = true)
@KeySequence("im_message_seq")
@Data
@EqualsAndHashCode(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ImMessageDO extends TenantBaseDO {

    /**
     * 消息ID
     */
    @TableId
    private Long id;

    /**
     * 会话ID
     */
    private Long conversationId;

    /**
     * 发送者ID
     */
    private Long senderId;

    /**
     * 接收者ID(单聊有值,群聊为NULL)
     */
    private Long receiverId;

    /**
     * 群ID(群聊有值,单聊为NULL)
     */
    private Long groupId;

    /**
     * 消息类型
     * 
     * 枚举: {@link com.shengyu.module.system.enums.im.ImMessageTypeEnum}
     * 1-文本, 2-图片, 3-语音, 4-视频, 5-文件, 6-位置, 7-表情包, 8-自定义贴纸, 10-系统消息
     */
    private Integer messageType;

    /**
     * 消息内容
     */
    private String content;

    /**
     * 扩展信息(JSON格式,存储文件URL、时长、大小等)
     */
    private String extra;

    /**
     * 发送时间
     */
    private LocalDateTime sendTime;

    /**
     * 消息状态
     * 
     * 枚举: {@link com.shengyu.module.system.enums.im.ImMessageStatusEnum}
     * 1-发送中, 2-已发送, 3-已送达, 4-已读, 5-发送失败, 6-已撤回
     */
    private Integer status;

    /**
     * 撤回时间
     */
    private LocalDateTime recallTime;

    /**
     * 撤回人ID
     */
    private Long recallBy;

    /**
     * 引用消息ID
     */
    private Long quoteMessageId;

}
