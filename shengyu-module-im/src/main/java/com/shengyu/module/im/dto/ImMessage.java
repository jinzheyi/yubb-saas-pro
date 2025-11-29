package com.shengyu.module.im.dto;

import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;
import java.util.Date;

/**
 * IM消息基础结构
 *
 * @author 圣钰科技
 */
@Data
public class ImMessage implements Serializable {
    private static final long serialVersionUID = 1L;

    /**
     * 消息ID
     */
    private String messageId;

    /**
     * 消息类型
     * @see com.shengyu.framework.common.enums.im.ImMessageTypeEnum
     */
    private int type;

    /**
     * 发送者ID
     */
    private Long senderId;

    /**
     * 接收者ID
     * 单聊：用户ID
     * 群聊：群组ID
     */
    private Long receiverId;

    /**
     * 消息内容
     */
    private String content;

    /**
     * 消息时间戳
     */
    private LocalDateTime timestamp;

    /**
     * 消息状态
     */
    private int status;

    /**
     * 扩展字段
     */
    private String ext;

}
