package com.shengyu.module.system.dal.dataobject.im;

import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.framework.mybatis.core.dataobject.BaseDO;
import lombok.*;

import java.time.LocalDateTime;

/**
 * IM 通话参与者 DO
 * 用于群组通话场景，记录每个参与者的信息
 *
 * @author 圣钰科技
 */
@TableName("im_call_participant")
@KeySequence("im_call_participant_seq")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ImCallParticipantDO extends BaseDO {

    /**
     * 主键ID
     */
    @TableId
    private Long id;

    /**
     * 通话ID
     */
    private String callId;

    /**
     * 参与者用户ID
     */
    private Long userId;

    /**
     * 设备ID
     */
    private String deviceId;

    /**
     * 角色：1-主叫 2-被叫
     */
    private Integer role;

    /**
     * 加入时间
     */
    private LocalDateTime joinTime;

    /**
     * 离开时间
     */
    private LocalDateTime leaveTime;

    /**
     * 状态：1-在线 2-离线 3-已离开
     */
    private Integer status;
}
