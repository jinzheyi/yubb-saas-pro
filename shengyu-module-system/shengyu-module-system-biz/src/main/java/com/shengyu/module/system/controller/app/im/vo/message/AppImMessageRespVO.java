package com.shengyu.module.system.controller.app.im.vo.message;

import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import com.fasterxml.jackson.databind.ser.std.ToStringSerializer;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.time.LocalDateTime;

@Schema(description = "移动端 - IM 消息 Response VO")
@Data
public class AppImMessageRespVO {

    @Schema(description = "消息ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long id;

    @Schema(description = "ChatID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long chatId;

    @Schema(description = "会话内序列号（单调递增，用于排序与断线补偿）", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long sequence;

    @Schema(description = "发送者ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long senderId;

    @Schema(description = "接收者ID(单聊有值,群聊为NULL)", example = "100")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long receiverId;

    @Schema(description = "群ID(群聊有值,单聊为NULL)", example = "10")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long groupId;

    @Schema(description = "消息类型(1-文本 2-图片 3-语音 4-视频 5-文件 6-位置 7-表情包 8-自定义贴纸 10-系统消息)", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    private Integer messageType;

    @Schema(description = "消息内容", requiredMode = Schema.RequiredMode.REQUIRED, example = "你好")
    private String content;

    @Schema(description = "扩展信息(JSON格式)", example = "{\"url\":\"https://...\"}")
    private String extra;

    @Schema(description = "发送时间", requiredMode = Schema.RequiredMode.REQUIRED)
    private LocalDateTime sendTime;

    @Schema(description = "消息状态(1-发送中 2-已发送 3-已送达 4-已读 5-发送失败 6-已撤回)", requiredMode = Schema.RequiredMode.REQUIRED, example = "2")
    private Integer status;

    @Schema(description = "撤回时间")
    private LocalDateTime recallTime;

    @Schema(description = "引用消息ID", example = "100")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long quoteMessageId;

    @Schema(description = "发送者昵称", example = "张三")
    private String senderNickname;

    @Schema(description = "发送者头像", example = "https://...")
    private String senderAvatar;

    @Schema(description = "是否自己发送", requiredMode = Schema.RequiredMode.REQUIRED, example = "true")
    private Boolean isSelf;

}
