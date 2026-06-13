package com.shengyu.module.infra.controller.platform.file.vo.file;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Schema(description = "管理后台 - 上传分片 Response VO")
@Data
public class FileChunkUploadRespVO {

    @Schema(description = "分片上传标识", requiredMode = Schema.RequiredMode.REQUIRED, example = "abc123")
    private String uploadId;

    @Schema(description = "分片序号", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    private Integer chunkNumber;

    @Schema(description = "分片标识（ETag）", requiredMode = Schema.RequiredMode.REQUIRED, example = "\"etag123\"")
    private String etag;

    @Schema(description = "已上传分片数", requiredMode = Schema.RequiredMode.REQUIRED, example = "3")
    private Integer uploadedChunks;

    @Schema(description = "总分片数", requiredMode = Schema.RequiredMode.REQUIRED, example = "10")
    private Integer totalChunks;

    @Schema(description = "是否全部上传完成", requiredMode = Schema.RequiredMode.REQUIRED, example = "false")
    private Boolean completed;

}
