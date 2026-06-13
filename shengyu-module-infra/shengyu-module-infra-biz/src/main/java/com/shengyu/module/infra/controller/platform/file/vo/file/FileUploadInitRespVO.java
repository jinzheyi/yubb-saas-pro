package com.shengyu.module.infra.controller.platform.file.vo.file;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Schema(description = "管理后台 - 初始化分片上传 Response VO")
@Data
public class FileUploadInitRespVO {

    @Schema(description = "分片上传唯一标识", requiredMode = Schema.RequiredMode.REQUIRED, example = "abc123")
    private String uploadId;

    @Schema(description = "分片大小（字节）", requiredMode = Schema.RequiredMode.REQUIRED, example = "5242880")
    private Integer chunkSize;

    @Schema(description = "总分片数", requiredMode = Schema.RequiredMode.REQUIRED, example = "10")
    private Integer totalChunks;

}
