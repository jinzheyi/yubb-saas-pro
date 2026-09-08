package com.shengyu.module.platform.controller.platform.apprelease.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Schema(description = "平台管理后台 - 应用版本安装包上传 Response VO")
@Data
public class PlatformAppReleasePackageUploadRespVO {

    @Schema(description = "安装包访问地址")
    private String packageUrl;

    @Schema(description = "安装包原始文件名")
    private String fileName;

    @Schema(description = "安装包字节大小")
    private Long packageSize;

    @Schema(description = "安装包 SHA-256")
    private String sha256;

}
