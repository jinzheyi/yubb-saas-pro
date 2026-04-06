package com.shengyu.module.system.controller.app.im.vo.favorite;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotNull;

@Schema(description = "移动端 - IM 收藏消息转发 Request VO")
@Data
public class AppImFavoriteResendReqVO {

    @Schema(description = "收藏ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "10001")
    @NotNull(message = "收藏ID不能为空")
    private Long favoriteId;

    @Schema(description = "目标会话ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "30001")
    @NotNull(message = "目标会话ID不能为空")
    private Long targetChatId;
}
