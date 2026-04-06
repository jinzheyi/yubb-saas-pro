package com.shengyu.module.system.controller.app.im.vo.favorite;

import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import com.fasterxml.jackson.databind.ser.std.ToStringSerializer;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.time.LocalDateTime;

@Schema(description = "移动端 - IM 收藏消息 Response VO")
@Data
public class AppImFavoriteRespVO {

    @Schema(description = "收藏ID", example = "10001")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long favoriteId;

    @Schema(description = "消息ID", example = "20001")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long messageId;

    @Schema(description = "会话ID", example = "30001")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long chatId;

    @Schema(description = "消息类型", example = "1")
    private Integer messageType;

    @Schema(description = "消息预览", example = "你好")
    private String messagePreview;

    @Schema(description = "消息内容快照")
    private String messageContent;

    @Schema(description = "消息扩展快照(JSON)")
    private String messageExtra;

    @Schema(description = "完整消息快照(JSON)")
    private String messageSnapshot;

    @Schema(description = "来源消息发送时间")
    private LocalDateTime sendTime;

    @Schema(description = "收藏记录创建时间")
    private LocalDateTime favoriteTime;

}
