package com.shengyu.module.infra.controller.platform.file.vo.file;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotBlank;

@Schema(description = "管理后台 - 合并分片 Request VO")
@Data
public class FileMergeReqVO {

    @Schema(description = "分片上传标识", requiredMode = Schema.RequiredMode.REQUIRED, example = "abc123")
    @NotBlank(message = "分片上传标识不能为空")
    private String uploadId;

}
