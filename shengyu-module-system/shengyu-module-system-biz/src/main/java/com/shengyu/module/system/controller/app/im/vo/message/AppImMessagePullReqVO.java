package com.shengyu.module.system.controller.app.im.vo.message;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotNull;

@Schema(description = "移动端 - IM 增量拉取消息（断线补偿） Request VO")
@Data
public class AppImMessagePullReqVO {

    @Schema(description = "ChatID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @NotNull(message = "{validation.im.chat_id.required}")
    private Long chatId;

    @Schema(description = "最后拉取的 sequence（水位），拉取 sequence > lastSequence 的消息", requiredMode = Schema.RequiredMode.REQUIRED, example = "0")
    private Long lastSequence;

    @Schema(description = "拉取条数（默认200，最大500）", example = "200")
    private Integer limit;

}
