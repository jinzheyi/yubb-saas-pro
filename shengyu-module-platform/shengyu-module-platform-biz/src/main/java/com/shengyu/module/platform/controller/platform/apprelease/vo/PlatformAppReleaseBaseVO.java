package com.shengyu.module.platform.controller.platform.apprelease.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.Min;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;

@Data
public class PlatformAppReleaseBaseVO {

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

    @Schema(description = "版本名", requiredMode = Schema.RequiredMode.REQUIRED, example = "1.0.4")
    @NotBlank(message = "版本名不能为空")
    @Size(max = 32, message = "版本名不能超过 32 个字符")
    private String versionName;

    @Schema(description = "构建号", requiredMode = Schema.RequiredMode.REQUIRED, example = "104")
    @NotNull(message = "构建号不能为空")
    @Min(value = 1, message = "构建号必须大于 0")
    private Integer versionCode;

    @Schema(description = "最低可用构建号", requiredMode = Schema.RequiredMode.REQUIRED, example = "100")
    @NotNull(message = "最低可用构建号不能为空")
    @Min(value = 1, message = "最低可用构建号必须大于 0")
    private Integer minSupportedVersionCode;

    @Schema(description = "更新类型", requiredMode = Schema.RequiredMode.REQUIRED, example = "FULL")
    @NotBlank(message = "更新类型不能为空")
    private String updateType;

    @Schema(description = "是否强制更新", requiredMode = Schema.RequiredMode.REQUIRED, example = "false")
    @NotNull(message = "是否强制更新不能为空")
    private Boolean forceUpdate;

    @Schema(description = "更新标题", requiredMode = Schema.RequiredMode.REQUIRED, example = "钰信更新")
    @NotBlank(message = "更新标题不能为空")
    @Size(max = 100, message = "更新标题不能超过 100 个字符")
    private String title;

    @Schema(description = "更新日志", requiredMode = Schema.RequiredMode.REQUIRED)
    @NotBlank(message = "更新日志不能为空")
    private String changelog;

    @Schema(description = "下载或跳转地址")
    @Size(max = 500, message = "下载或跳转地址不能超过 500 个字符")
    private String packageUrl;

    @Schema(description = "包大小")
    private Long packageSize;

    @Schema(description = "Android APK SHA-256")
    @Size(max = 128, message = "SHA-256 不能超过 128 个字符")
    private String sha256;

    @Schema(description = "备注")
    @Size(max = 500, message = "备注不能超过 500 个字符")
    private String remark;

    @Schema(description = "补丁提供商", example = "shorebird")
    private String patchProvider;

    @Schema(description = "补丁基线版本")
    private String patchReleaseId;

    @Schema(description = "补丁号")
    private Integer patchNo;

}
