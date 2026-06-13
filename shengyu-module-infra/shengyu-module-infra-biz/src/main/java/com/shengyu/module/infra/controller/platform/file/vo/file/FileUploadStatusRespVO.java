package com.shengyu.module.infra.controller.platform.file.vo.file;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Schema(description = "管理后台 - 查询上传进度 Response VO")
@Data
public class FileUploadStatusRespVO {

    @Schema(description = "分片上传标识", requiredMode = Schema.RequiredMode.REQUIRED, example = "abc123")
    private String uploadId;

    @Schema(description = "上传状态：0-初始化，1-上传中，2-已完成，3-已取消，4-已过期", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    private Integer status;

    @Schema(description = "已上传分片数", requiredMode = Schema.RequiredMode.REQUIRED, example = "3")
    private Integer uploadedChunks;

    @Schema(description = "总分片数", requiredMode = Schema.RequiredMode.REQUIRED, example = "10")
    private Integer totalChunks;

    @Schema(description = "上传进度（0.0-1.0）", requiredMode = Schema.RequiredMode.REQUIRED, example = "0.3")
    private Double progress;

}
