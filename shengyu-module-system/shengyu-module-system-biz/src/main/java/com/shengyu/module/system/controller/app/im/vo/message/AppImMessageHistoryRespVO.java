package com.shengyu.module.system.controller.app.im.vo.message;

import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import com.fasterxml.jackson.databind.ser.std.ToStringSerializer;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.util.ArrayList;
import java.util.List;

@Schema(description = "移动端 - IM 更早历史消息 Response VO")
@Data
public class AppImMessageHistoryRespVO {

    @Schema(description = "ChatID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long chatId;

    @Schema(description = "窗口最老 sequence", example = "835")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long oldestSequence;

    @Schema(description = "窗口最新 sequence", example = "864")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long newestSequence;

    @Schema(description = "是否还有更早消息", requiredMode = Schema.RequiredMode.REQUIRED, example = "true")
    private Boolean hasOlder;

    @Schema(description = "消息列表", requiredMode = Schema.RequiredMode.REQUIRED)
    private List<AppImMessageRespVO> items = new ArrayList<>();

}
