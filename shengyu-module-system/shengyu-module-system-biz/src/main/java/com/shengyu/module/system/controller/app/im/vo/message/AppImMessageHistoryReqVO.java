package com.shengyu.module.system.controller.app.im.vo.message;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotNull;

@Schema(description = "移动端 - IM 更早历史消息 Request VO")
@Data
public class AppImMessageHistoryReqVO {

    @Schema(description = "ChatID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @NotNull(message = "ChatID不能为空")
    private Long chatId;

    @Schema(description = "向上翻历史的起始序列号，返回 sequence < beforeSequence 的最近一段消息", requiredMode = Schema.RequiredMode.REQUIRED, example = "880")
    @NotNull(message = "beforeSequence不能为空")
    private Long beforeSequence;

    @Schema(description = "拉取条数（默认30，最大50）", example = "30")
    private Integer limit;

}
