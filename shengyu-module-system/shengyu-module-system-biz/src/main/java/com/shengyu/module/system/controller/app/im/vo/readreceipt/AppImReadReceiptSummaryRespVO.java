package com.shengyu.module.system.controller.app.im.vo.readreceipt;

import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import com.fasterxml.jackson.databind.ser.std.ToStringSerializer;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Schema(description = "移动端 - IM 群聊已读聚合摘要 Response VO")
@Data
public class AppImReadReceiptSummaryRespVO {

    @Schema(description = "消息ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long messageId;

    @Schema(description = "ChatID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long chatId;

    @Schema(description = "消息序列号(sequence)", requiredMode = Schema.RequiredMode.REQUIRED, example = "10")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long sequence;

    @Schema(description = "已读人数", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long readCount;

    @Schema(description = "未读人数", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long unreadCount;

    @Schema(description = "总人数", requiredMode = Schema.RequiredMode.REQUIRED, example = "2")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long totalCount;

    @Schema(description = "消息类型(1=text,2=image,3=voice...)", requiredMode = Schema.RequiredMode.REQUIRED, example = "3")
    private Integer messageType;

    @Schema(description = "已读统计口径：conversation_read_watermark", requiredMode = Schema.RequiredMode.REQUIRED, example = "conversation_read_watermark")
    private String readBasis;

}
