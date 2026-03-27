package com.shengyu.module.system.controller.app.im.vo.sticker;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotNull;

@Schema(description = "移动端 - IM 收藏为表情 Request VO")
@Data
public class AppImStickerCollectReqVO {

    @Schema(description = "消息ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "10001")
    @NotNull(message = "消息ID不能为空")
    private Long messageId;
}
