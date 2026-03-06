package com.shengyu.module.infra.controller.app.file.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Schema(description = "用户 App - 获取文件预签名地址（读取）Response VO")
@Data
public class AppFilePresignedGetUrlRespVO {

    @Schema(description = "预签名 URL", requiredMode = Schema.RequiredMode.REQUIRED,
            example = "https://example.com/xxx.png?X-Amz-Expires=600&X-Amz-Signature=...")
    private String url;

    @Schema(description = "过期时间戳（毫秒）", requiredMode = Schema.RequiredMode.REQUIRED, example = "1710000000000")
    private Long expiresAt;

}
