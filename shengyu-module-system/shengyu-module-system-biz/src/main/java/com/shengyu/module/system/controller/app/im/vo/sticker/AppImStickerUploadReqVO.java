package com.shengyu.module.system.controller.app.im.vo.sticker;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotNull;

@Schema(description = "移动端 - IM 自定义表情上传 Request VO")
@Data
public class AppImStickerUploadReqVO {

    @Schema(description = "文件ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "2001")
    @NotNull(message = "文件ID不能为空")
    private Long fileId;

    @Schema(description = "兼容展示URL", example = "https://cdn.example.com/im/sticker/a.png")
    private String url;

    @Schema(description = "文件MD5", example = "e4d909c290d0fb1ca068ffaddf22cbd0")
    private String md5;

    @Schema(description = "图片宽度", example = "160")
    private Integer width;

    @Schema(description = "图片高度", example = "160")
    private Integer height;

    @Schema(description = "媒体类型", example = "image/png")
    private String mimeType;

    @Schema(description = "显示名称", example = "开心")
    private String name;
}
