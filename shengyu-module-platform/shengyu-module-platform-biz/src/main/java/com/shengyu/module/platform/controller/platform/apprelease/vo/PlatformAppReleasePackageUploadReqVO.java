package com.shengyu.module.platform.controller.platform.apprelease.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import org.springframework.web.multipart.MultipartFile;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;

@Schema(description = "平台管理后台 - 应用版本安装包上传 Request VO")
@Data
public class PlatformAppReleasePackageUploadReqVO {

    @Schema(description = "应用标识", requiredMode = Schema.RequiredMode.REQUIRED, example = "yuxin")
    @NotBlank(message = "应用标识不能为空")
    @Size(max = 64, message = "应用标识不能超过 64 个字符")
    private String appKey;

    @Schema(description = "平台", requiredMode = Schema.RequiredMode.REQUIRED, example = "android")
    @NotBlank(message = "平台不能为空")
    @Size(max = 32, message = "平台不能超过 32 个字符")
    private String platform;

    @Schema(description = "渠道", requiredMode = Schema.RequiredMode.REQUIRED, example = "prod")
    @NotBlank(message = "渠道不能为空")
    @Size(max = 32, message = "渠道不能超过 32 个字符")
    private String channel;

    @Schema(description = "安装包", requiredMode = Schema.RequiredMode.REQUIRED)
    @NotNull(message = "安装包不能为空")
    private MultipartFile file;

}
