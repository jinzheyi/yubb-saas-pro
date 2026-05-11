package com.shengyu.module.infra.controller.app.file.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Schema(description = "用户 App - 获取文件打开策略（预览或下载）Response VO")
@Data
public class AppFileOpenStrategyRespVO {

    @Schema(description = "动作：PREVIEW 或 DOWNLOAD", requiredMode = Schema.RequiredMode.REQUIRED, example = "PREVIEW")
    private String action;

    @Schema(description = "渲染策略，例如 native_pdf/native_image/native_video/native_audio/native_text/native_markdown/embedded_office_viewer/download_only")
    private String renderStrategy;

    @Schema(description = "文件 MIME 类型")
    private String contentType;

    @Schema(description = "预览 URL（当 action=PREVIEW 时返回）")
    private String previewUrl;

    @Schema(description = "嵌入式文档查看 URL（例如 Office 在线预览）")
    private String viewerUrl;

    @Schema(description = "服务端转换后的 PDF URL（预留）")
    private String convertedPdfUrl;

    @Schema(description = "下载 URL（兜底用）", requiredMode = Schema.RequiredMode.REQUIRED)
    private String downloadUrl;

    @Schema(description = "过期时间戳（毫秒）")
    private Long expiresAt;

    @Schema(description = "是否不稳定预览格式（例如 ppt/pptx）")
    private Boolean unstable;

    @Schema(description = "提示文案（可选）")
    private String message;
}
