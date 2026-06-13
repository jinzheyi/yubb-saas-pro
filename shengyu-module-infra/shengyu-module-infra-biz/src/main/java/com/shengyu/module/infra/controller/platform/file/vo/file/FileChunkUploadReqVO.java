package com.shengyu.module.infra.controller.platform.file.vo.file;

import com.fasterxml.jackson.annotation.JsonIgnore;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import org.springframework.web.multipart.MultipartFile;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;

@Schema(description = "管理后台 - 上传分片 Request VO")
@Data
public class FileChunkUploadReqVO {

    @Schema(description = "分片上传标识", requiredMode = Schema.RequiredMode.REQUIRED, example = "abc123")
    @NotBlank(message = "分片上传标识不能为空")
    private String uploadId;

    @Schema(description = "分片序号（从1开始）", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @NotNull(message = "分片序号不能为空")
    private Integer chunkNumber;

    @Schema(description = "分片文件", requiredMode = Schema.RequiredMode.REQUIRED)
    @NotNull(message = "分片文件不能为空")
    @JsonIgnore  // 防止序列化时出现 FileNotFoundException
    private MultipartFile chunk;

}
