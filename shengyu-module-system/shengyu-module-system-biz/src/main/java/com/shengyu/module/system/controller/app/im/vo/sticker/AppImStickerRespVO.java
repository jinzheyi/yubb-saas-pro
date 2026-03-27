package com.shengyu.module.system.controller.app.im.vo.sticker;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Schema(description = "移动端 - IM 自定义表情 Response VO")
@Data
public class AppImStickerRespVO {

    @Schema(description = "表情ID", example = "1001")
    private Long stickerId;

    @Schema(description = "原图文件ID", example = "2001")
    private Long fileId;

    @Schema(description = "缩略图文件ID", example = "2002")
    private Long thumbFileId;

    @Schema(description = "显示名称", example = "开心")
    private String name;

    @Schema(description = "图片地址", example = "https://cdn.example.com/im/sticker/a.png")
    private String url;

    @Schema(description = "缩略图地址", example = "https://cdn.example.com/im/sticker/a_thumb.png")
    private String thumbUrl;

    @Schema(description = "文件MD5", example = "e4d909c290d0fb1ca068ffaddf22cbd0")
    private String md5;

    @Schema(description = "宽度", example = "160")
    private Integer width;

    @Schema(description = "高度", example = "160")
    private Integer height;

    @Schema(description = "媒体类型", example = "image/png")
    private String mimeType;

    @Schema(description = "来源类型", example = "1")
    private Integer sourceType;

    @Schema(description = "排序号", example = "1")
    private Integer sortNo;

    @Schema(description = "是否重复收藏", example = "false")
    private Boolean duplicated;
}
