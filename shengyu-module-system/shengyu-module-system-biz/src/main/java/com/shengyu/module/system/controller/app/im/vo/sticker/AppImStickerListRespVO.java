package com.shengyu.module.system.controller.app.im.vo.sticker;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.util.List;

@Schema(description = "移动端 - IM 自定义表情列表 Response VO")
@Data
public class AppImStickerListRespVO {

    @Schema(description = "版本号", example = "1743050000000")
    private Long version;

    @Schema(description = "最近使用")
    private List<AppImStickerRespVO> recent;

    @Schema(description = "收藏列表")
    private List<AppImStickerRespVO> favorites;
}
