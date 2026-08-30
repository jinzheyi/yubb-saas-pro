package com.shengyu.module.system.dal.dataobject.im;

import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.framework.tenant.core.db.TenantBaseDO;
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
public class ImCallRecordDO extends TenantBaseDO {

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

    /**
     * 状态机状态
     * INIT - 初始状态
     * RINGING - 响铃中
     * CONNECTING - 连接中
     * CONNECTED - 已连接
     * ENDED - 已结束
     */
    private String state;

    /**
     * 结束原因
     * HANGUP - 正常挂断
     * REJECT - 拒绝
     * TIMEOUT - 超时
     * BUSY - 忙线
     * CANCEL - 取消
     * CALLEE_OFFLINE - 被叫离线
     * ERROR - 错误
     */
    private String endReason;

    /**
     * 接听设备ID（CAS 裁决写入，用于多设备唯一接听与重连校验）
     */
    private String acceptedDeviceId;

    /**
     * 关联会话ID（通话结束时填入）
     */
    private Long chatId;

    /**
     * 群组ID（群通话时使用）
     */
    private Long groupId;

    /**
     * 通话记录消息ID（CALL_RECORD=209 生成后回填）
     */
    private Long recordMessageId;

    /**
     * 主叫方昵称（冗余字段，避免联表查询）
     */
    private String callerName;

    /**
     * 主叫方头像（冗余字段，避免联表查询）
     */
    private String callerAvatar;

    /**
     * 被叫方昵称（冗余字段，避免联表查询）
     */
    private String calleeName;

    /**
     * 被叫方头像（冗余字段，避免联表查询）
     */
    private String calleeAvatar;

    /** RTC 服务提供方，当前唯一合法值为 LIVEKIT。 */
    private String provider;

    /** DIRECT（单聊）或 GROUP（群聊）。 */
    private String callMode;

    /** 通话拥有者；群通话由创建者结束全体通话。 */
    private Long ownerId;

    /** LiveKit 房间名；不向客户端暴露任何服务端密钥。 */
    private String livekitRoom;

    /** 首次实际接入媒体的时间，用于计算通话时长。 */
    private LocalDateTime connectedAt;

    /** 单调递增的业务事件版本，供客户端去重和状态对账。 */
    private Integer stateVersion;

}
