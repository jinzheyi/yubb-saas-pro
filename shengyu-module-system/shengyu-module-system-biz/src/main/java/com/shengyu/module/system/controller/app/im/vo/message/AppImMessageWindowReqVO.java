package com.shengyu.module.system.controller.app.im.vo.message;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotNull;

@Schema(description = "移动端 - IM 消息窗口 Request VO")
@Data
public class AppImMessageWindowReqVO {

    @Schema(description = "ChatID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @NotNull(message = "ChatID不能为空")
    private Long chatId;

    @Schema(description = "窗口模式（latest）", example = "latest")
    private String mode;

    @Schema(description = "锚点序列号，优先级高于 anchorMessageId", example = "880")
    private Long anchorSequence;

    @Schema(description = "锚点消息ID，仅在 anchorSequence 为空时生效", example = "2033741860720664701")
    private Long anchorMessageId;

    @Schema(description = "最近窗口条数（默认30，最大50）", example = "30")
    private Integer limit;

    @Schema(description = "锚点前窗口大小（默认15，最大30）", example = "15")
    private Integer beforeLimit;

    @Schema(description = "锚点后窗口大小（默认10，最大20）", example = "10")
    private Integer afterLimit;

}
