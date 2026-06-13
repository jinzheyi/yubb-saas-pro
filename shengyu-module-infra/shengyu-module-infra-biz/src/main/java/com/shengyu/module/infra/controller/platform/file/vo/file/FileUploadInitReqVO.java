package com.shengyu.module.infra.controller.platform.file.vo.file;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;

@Schema(description = "管理后台 - 初始化分片上传 Request VO")
@Data
public class FileUploadInitReqVO {

    @Schema(description = "原始文件名", requiredMode = Schema.RequiredMode.REQUIRED, example = "test.mp4")
    @NotBlank(message = "原始文件名不能为空")
    private String name;

    @Schema(description = "文件总大小（字节）", requiredMode = Schema.RequiredMode.REQUIRED, example = "10485760")
    @NotNull(message = "文件总大小不能为空")
    private Long size;

    @Schema(description = "MIME类型", example = "video/mp4")
    private String type;

    @Schema(description = "存储目录", example = "video/2024/01")
    private String directory;

    @Schema(description = "分片大小（字节），默认5MB", example = "5242880")
    private Integer chunkSize;

}
