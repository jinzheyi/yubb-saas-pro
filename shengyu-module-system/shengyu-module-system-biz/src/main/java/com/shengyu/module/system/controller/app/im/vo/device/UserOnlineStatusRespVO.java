package com.shengyu.module.system.controller.app.im.vo.device;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import com.fasterxml.jackson.databind.ser.std.ToStringSerializer;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.experimental.Accessors;

import java.util.List;

@Schema(description = "移动端 - IM 用户在线状态 Response VO")
@Data
@Accessors(chain = true)
@JsonInclude(JsonInclude.Include.NON_NULL)
public class UserOnlineStatusRespVO {

    @Schema(description = "用户ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long userId;

    @Schema(description = "是否在线", requiredMode = Schema.RequiredMode.REQUIRED, example = "true")
    private Boolean online;

    @Schema(description = "在线设备类型列表(1-Web 2-iOS 3-Android 4-小程序)", example = "[1, 3]")
    private List<Integer> deviceTypes;
}
