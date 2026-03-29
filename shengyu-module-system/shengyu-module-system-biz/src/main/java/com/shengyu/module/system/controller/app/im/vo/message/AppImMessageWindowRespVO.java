package com.shengyu.module.system.controller.app.im.vo.message;

import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import com.fasterxml.jackson.databind.ser.std.ToStringSerializer;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.util.ArrayList;
import java.util.List;

@Schema(description = "移动端 - IM 消息窗口 Response VO")
@Data
public class AppImMessageWindowRespVO {

    @Schema(description = "窗口模式", requiredMode = Schema.RequiredMode.REQUIRED, example = "latest")
    private String mode;

    @Schema(description = "ChatID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long chatId;

    @Schema(description = "锚点是否找到", requiredMode = Schema.RequiredMode.REQUIRED, example = "true")
    private Boolean anchorFound;

    @Schema(description = "锚点序列号", example = "880")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long anchorSequence;

    @Schema(description = "窗口最老 sequence", example = "865")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long oldestSequence;

    @Schema(description = "窗口最新 sequence", example = "890")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long newestSequence;

    @Schema(description = "是否还有更早消息", requiredMode = Schema.RequiredMode.REQUIRED, example = "true")
    private Boolean hasOlder;

    @Schema(description = "是否还有更新消息", requiredMode = Schema.RequiredMode.REQUIRED, example = "false")
    private Boolean hasNewer;

    @Schema(description = "当前窗口内首条未读消息 sequence", example = "925")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long firstUnreadSequence;

    @Schema(description = "消息列表", requiredMode = Schema.RequiredMode.REQUIRED)
    private List<AppImMessageRespVO> items = new ArrayList<>();

}
