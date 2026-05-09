package com.shengyu.module.system.controller.app.im.vo.message;

import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import com.fasterxml.jackson.databind.ser.std.ToStringSerializer;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.time.LocalDateTime;

@Schema(description = "移动端 - 聊天媒体文件 Response VO")
@Data
public class AppImChatMediaRespVO {

    @Schema(description = "消息ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long messageId;

    @Schema(description = "ChatID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long chatId;

    @Schema(description = "群ID(群聊有值)", example = "10")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long groupId;

    @Schema(description = "发送者ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long senderId;

    @Schema(description = "发送者昵称", example = "张三")
    private String senderNickname;

    @Schema(description = "媒体分类(image|video|file)", example = "image")
    private String mediaType;

    @Schema(description = "文件ID(V2 媒体消息可返回)", example = "100")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long fileId;

    @Schema(description = "文件名", example = "会议纪要.docx")
    private String fileName;

    @Schema(description = "文件地址", example = "https://example.com/file.docx")
    private String fileUrl;

    @Schema(description = "缩略图文件ID(视频/图片可返回)", example = "101")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long thumbFileId;

    @Schema(description = "缩略图地址", example = "https://example.com/file_thumb.jpg")
    private String thumbnailUrl;

    @Schema(description = "文件 MIME 类型", example = "application/pdf")
    private String fileMimeType;

    @Schema(description = "文件大小(字节)", example = "102400")
    private Long fileSize;

    @Schema(description = "发送时间", requiredMode = Schema.RequiredMode.REQUIRED)
    private LocalDateTime sendTime;
}
