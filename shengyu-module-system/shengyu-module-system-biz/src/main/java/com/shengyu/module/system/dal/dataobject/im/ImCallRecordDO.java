package com.shengyu.module.system.dal.dataobject.im;

import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.framework.mybatis.core.dataobject.BaseDO;
import lombok.*;

import java.time.LocalDateTime;

/**
 * IM 通话记录 DO
 *
 * @author 圣钰科技
 */
@TableName("im_call_record")
@KeySequence("im_call_record_seq")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ImCallRecordDO extends BaseDO {

    /**
     * 通话记录ID
     */
    @TableId
    private Long id;

    /**
     * 通话ID(唯一标识)
     */
    private String callId;

    /**
     * 通话类型
     * 1-语音通话
     * 2-视频通话
     */
    private Integer callType;

    /**
     * 呼叫者ID
     */
    private Long callerId;

    /**
     * 被叫者ID
     */
    private Long calleeId;

    /**
     * 通话开始时间
     */
    private LocalDateTime startTime;

    /**
     * 通话结束时间
     */
    private LocalDateTime endTime;

    /**
     * 通话时长(秒)
     */
    private Integer duration;

    /**
     * 通话状态
     * 1-未接听
     * 2-已接听
     * 3-已拒绝
     * 4-忙线
     * 5-已取消
     */
    private Integer status;

}
