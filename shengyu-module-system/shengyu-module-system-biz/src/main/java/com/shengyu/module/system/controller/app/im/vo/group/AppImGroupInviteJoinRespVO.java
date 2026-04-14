package com.shengyu.module.system.controller.app.im.vo.group;

import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import com.fasterxml.jackson.databind.ser.std.ToStringSerializer;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Schema(description = "移动端 - IM 通过邀请码加入群 Response VO")
@Data
public class AppImGroupInviteJoinRespVO {

    @Schema(description = "加入结果(1-直接入群 2-已提交申请)", example = "1")
    private Integer resultType;

    @Schema(description = "提示文案", example = "加入成功")
    private String message;

    @Schema(description = "群组ID", example = "123456")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long groupId;

    @Schema(description = "申请单ID(resultType=2时返回)", example = "10001")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long requestId;
}
