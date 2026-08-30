package com.shengyu.module.system.dal.dataobject.im;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/** 通话业务事件事务 outbox；媒体信令不允许写入此表。 */
@Data
@TableName("im_call_event_outbox")
public class ImCallEventOutboxDO {
    @TableId
    private Long id;
    private Long tenantId;
    private String callId;
    private String eventType;
    private Integer eventVersion;
    private Long recipientId;
    @TableField("payload")
    private String payload;
    private String status;
    private Integer retryCount;
    private LocalDateTime nextRetryAt;
    private LocalDateTime publishedAt;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
