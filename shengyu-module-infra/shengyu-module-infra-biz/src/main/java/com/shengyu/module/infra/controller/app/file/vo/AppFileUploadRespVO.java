package com.shengyu.module.infra.controller.app.file.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Schema(description = "用户 App - 上传文件（返回 fileId）Response VO")
@Data
public class AppFileUploadRespVO {

    @Schema(description = "文件ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "123")
    private Long fileId;

    @Schema(description = "文件访问 URL（兼容字段，短期可用于预览）", example = "https://example.com/xxx.png")
    private String url;

    @Schema(description = "原文件名", requiredMode = Schema.RequiredMode.REQUIRED, example = "image.png")
    private String name;

    @Schema(description = "文件大小（字节）", requiredMode = Schema.RequiredMode.REQUIRED, example = "1024")
    private Integer size;

    @Schema(description = "文件 MIME 类型", example = "image/png")
    private String mimeType;

    @Schema(description = "文件 MD5（可选）", example = "d41d8cd98f00b204e9800998ecf8427e")
    private String md5;

    @Schema(description = "缩略图文件ID（可选）", example = "124")
    private Long thumbFileId;

}
