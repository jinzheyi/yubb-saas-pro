package com.shengyu.module.platform.controller.app.apprelease.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Schema(description = "移动端 - 应用版本检查 Response VO")
@Data
public class AppReleaseCheckRespVO {

    private Boolean hasUpdate;

    private String updateType;

    private Boolean forceUpdate;

    private String versionName;

    private Integer versionCode;

    private Integer minSupportedVersionCode;

    private String title;

    private String changelog;

    private String packageUrl;

    private Long packageSize;

    private String sha256;

    private String patchProvider;

    private String patchReleaseId;

    private Integer patchNo;

    private String promptStrategy;

}
