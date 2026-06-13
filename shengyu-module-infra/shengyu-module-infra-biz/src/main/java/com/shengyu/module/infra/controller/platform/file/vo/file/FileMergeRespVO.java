package com.shengyu.module.infra.controller.platform.file.vo.file;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Schema(description = "管理后台 - 合并分片 Response VO")
@Data
public class FileMergeRespVO {

    @Schema(description = "分片上传标识", requiredMode = Schema.RequiredMode.REQUIRED, example = "abc123")
    private String uploadId;

    @Schema(description = "文件访问地址", requiredMode = Schema.RequiredMode.REQUIRED, example = "https://www.iocoder.cn/shengyu.mp4")
    private String url;

    @Schema(description = "文件记录ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1024")
    private Long fileId;

}
