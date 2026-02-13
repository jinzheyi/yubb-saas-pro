package com.shengyu.module.system.controller.app.im.vo.message;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotNull;

@Schema(description = "移动端 - IM 消息发送 Request VO")
@Data
public class AppImMessageSendReqVO {

    @Schema(description = "会话ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @NotNull(message = "会话ID不能为空")
    private Long conversationId;

    @Schema(description = "接收者ID(单聊有值,群聊为NULL)", example = "100")
    private Long receiverId;

    @Schema(description = "群ID(群聊有值,单聊为NULL)", example = "10")
    private Long groupId;

    @Schema(description = "消息类型(1-文本 2-图片 3-语音 4-视频 5-文件 6-位置 7-表情包 8-自定义贴纸)", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @NotNull(message = "消息类型不能为空")
    private Integer messageType;

    @Schema(description = "消息内容", requiredMode = Schema.RequiredMode.REQUIRED, example = "你好")
    @NotNull(message = "消息内容不能为空")
    private String content;

    @Schema(description = "扩展信息(JSON格式)", example = "{\"url\":\"https://...\"}")
    private String extra;

    @Schema(description = "引用消息ID", example = "100")
    private Long quoteMessageId;

}
