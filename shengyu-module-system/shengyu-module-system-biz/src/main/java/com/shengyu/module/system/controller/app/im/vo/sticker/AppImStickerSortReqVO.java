package com.shengyu.module.system.controller.app.im.vo.sticker;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.Valid;
import javax.validation.constraints.NotEmpty;
import javax.validation.constraints.NotNull;
import java.util.List;

@Schema(description = "移动端 - IM 表情排序 Request VO")
@Data
public class AppImStickerSortReqVO {

    @Schema(description = "排序项")
    @NotEmpty(message = "排序项不能为空")
    @Valid
    private List<Item> items;

    @Schema(description = "排序项")
    @Data
    public static class Item {

        @Schema(description = "表情ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1001")
        @NotNull(message = "表情ID不能为空")
        private Long stickerId;

        @Schema(description = "排序号", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
        @NotNull(message = "排序号不能为空")
        private Integer sortNo;
    }
}
