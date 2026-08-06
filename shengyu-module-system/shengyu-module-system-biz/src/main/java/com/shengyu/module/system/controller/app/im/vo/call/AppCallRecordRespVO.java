package com.shengyu.module.system.controller.app.im.vo.call;

import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import com.fasterxml.jackson.databind.ser.std.ToStringSerializer;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.time.LocalDateTime;

@Schema(description = "移动端 - IM 通话记录 Response VO")
@Data
public class AppCallRecordRespVO {

    @Schema(description = "通话记录ID", example = "10001")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long id;

    @Schema(description = "通话ID（全局唯一）", example = "call_abc123")
    private String callId;

    @Schema(description = "通话类型：1-语音 2-视频", example = "1")
    private Integer callType;

    @Schema(description = "主叫方ID", example = "40001")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long callerId;

    @Schema(description = "主叫方昵称", example = "张三")
    private String callerName;

    @Schema(description = "主叫方头像", example = "http://...")
    private String callerAvatar;

    @Schema(description = "被叫方ID", example = "40002")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long calleeId;

    @Schema(description = "被叫方昵称", example = "李四")
    private String calleeName;

    @Schema(description = "被叫方头像", example = "http://...")
    private String calleeAvatar;

    @Schema(description = "会话ID", example = "30001")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long chatId;

    @Schema(description = "通话状态：1-未接听 2-已接听 3-已拒绝 4-忙线 5-已取消", example = "2")
    private Integer status;

    @Schema(description = "状态机状态：INIT/RINGING/CONNECTING/CONNECTED/ENDED", example = "CONNECTED")
    private String state;

    @Schema(description = "结束原因：HANGUP/REJECT/TIMEOUT/BUSY/CANCEL/CALLEE_OFFLINE/ERROR", example = "HANGUP")
    private String endReason;

    @Schema(description = "通话时长（秒）", example = "120")
    private Integer duration;

    @Schema(description = "通话开始时间")
    private LocalDateTime startTime;

    @Schema(description = "通话结束时间")
    private LocalDateTime endTime;

    @Schema(description = "创建时间")
    private LocalDateTime createTime;

    @Schema(description = "是否是主叫方", example = "true")
    private Boolean isCaller;
}
