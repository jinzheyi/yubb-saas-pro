package com.shengyu.module.system.controller.app.im.vo.group;

import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import com.fasterxml.jackson.databind.ser.std.ToStringSerializer;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.time.LocalDateTime;

@Schema(description = "移动端 - IM 群加群申请 Response VO")
@Data
public class AppImGroupJoinRequestRespVO {

    @Schema(description = "申请单ID", example = "10001")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long id;

    @Schema(description = "群组ID", example = "123456")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long groupId;

    @Schema(description = "申请人用户ID", example = "20001")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long applicantUserId;

    @Schema(description = "申请人昵称", example = "张三")
    private String applicantNickname;

    @Schema(description = "申请人头像", example = "https://...")
    private String applicantAvatar;

    @Schema(description = "状态(1-待审批 2-已通过 3-已拒绝)", example = "1")
    private Integer status;

    @Schema(description = "拒绝原因", example = "群已满")
    private String rejectReason;

    @Schema(description = "处理人ID", example = "30001")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long handledBy;

    @Schema(description = "处理人昵称", example = "李四")
    private String handledByNickname;

    @Schema(description = "申请时间")
    private LocalDateTime createTime;

    @Schema(description = "处理时间")
    private LocalDateTime handledTime;
}
