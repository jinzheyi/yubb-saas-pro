package com.shengyu.module.system.dal.dataobject.im;

import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.*;

import java.time.LocalDateTime;

/**
 * IM 通话事件 DO
 *
 * @author 圣钰科技
 */
@TableName("im_call_event")
@KeySequence("im_call_event_seq")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ImCallEventDO {

    /**
     * 事件ID
     */
    @TableId
    private Long id;

    /**
     * 通话ID
     */
    private String callId;

    /**
     * 事件ID（messageId，用于幂等）
     */
    private String eventId;

    /**
     * 信令类型
     * 1-呼叫
     * 2-接听
     * 3-拒绝
     * 4-挂断
     * 5-忙线
     * 6-切换摄像头
     */
    private Integer signalType;

    /**
     * 发送者用户ID
     */
    private Long senderId;

    /**
     * 设备ID
     */
    private String deviceId;

    /**
     * 事件载荷（extraData，JSON格式）
     */
    private String payloadJson;

    /**
     * 创建时间
     */
    private LocalDateTime createTime;

    /**
     * 租户编号
     */
    private Long tenantId;

}
