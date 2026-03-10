package com.shengyu.module.system.controller.app.im.vo.file;

import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import com.fasterxml.jackson.databind.ser.std.ToStringSerializer;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.time.LocalDateTime;

@Schema(description = "移动端 - IM 群文件 Response VO")
@Data
public class AppImGroupFileRespVO {

    @Schema(description = "主键ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long id;

    @Schema(description = "群组ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long groupId;

    @Schema(description = "文件ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long fileId;

    @Schema(description = "上传者ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long uploaderId;

    @Schema(description = "上传者名称", example = "张三")
    private String uploaderName;

    // ========== 文件信息（来自 infra_file） ==========

    @Schema(description = "文件名", example = "会议纪要.docx")
    private String fileName;

    @Schema(description = "文件URL", example = "http://example.com/file.docx")
    private String fileUrl;

    @Schema(description = "文件类型", example = "application/vnd.openxmlformats-officedocument.wordprocessingml.document")
    private String fileType;

    @Schema(description = "文件大小(字节)", example = "102400")
    private Integer fileSize;

    // ========== 统计信息 ==========

    @Schema(description = "下载次数", example = "10")
    private Integer downloadCount;

    @Schema(description = "创建时间", requiredMode = Schema.RequiredMode.REQUIRED)
    private LocalDateTime createTime;

}
