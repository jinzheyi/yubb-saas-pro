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
    @NotEmpty(message = "{validation.im.sort_items.required}")
    @Valid
    private List<Item> items;

    @Schema(description = "排序项")
    @Data
    public static class Item {

        @Schema(description = "表情ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1001")
        @NotNull(message = "{validation.im.sticker_id.required}")
        private Long stickerId;

        @Schema(description = "排序号", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
        @NotNull(message = "{validation.im.sort_no.required}")
        private Integer sortNo;
    }
}
