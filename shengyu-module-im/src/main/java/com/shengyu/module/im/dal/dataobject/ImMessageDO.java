package com.shengyu.module.im.dal.dataobject;

import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.framework.tenant.core.db.TenantBaseDO;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.util.Date;

/**
 * IM消息DO
 *
 * @author 圣钰科技
 */
@TableName("im_message")
@KeySequence("im_message_seq") // 用于 Oracle、PostgreSQL、Kingbase、DB2、H2 数据库的主键自增。如果是 MySQL 等数据库，可不写。
@Data
@EqualsAndHashCode(callSuper = true)
public class ImMessageDO extends TenantBaseDO {

    /**
     * 消息ID
     */
    @TableId
    private Long id;

    /**
     * 消息唯一标识
     */
    private String messageId;

    /**
     * 消息类型
     */
    private Integer type;

    /**
     * 发送者ID
     */
    private Long senderId;

    /**
     * 接收者ID（单聊为用户ID，群聊为群组ID）
     */
    private Long receiverId;

    /**
     * 消息内容
     */
    private String content;

    /**
     * 消息状态：0-未读，1-已读，2-已删除
     */
    private Integer status;

    /**
     * 扩展字段
     */
    private String ext;

}
