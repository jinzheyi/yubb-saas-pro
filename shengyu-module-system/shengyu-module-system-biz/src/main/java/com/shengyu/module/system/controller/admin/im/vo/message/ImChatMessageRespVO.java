package com.shengyu.module.system.controller.admin.im.vo.message;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.util.Map;

/**
 * 消息响应 VO
 *
 * @author zhusy
 * @since 2025/12/19
 */
@Data
@Schema(description = "消息响应")
public class ImChatMessageRespVO {

    @Schema(description = "唯一id", requiredMode = Schema.RequiredMode.REQUIRED, example = "1234567890123")
    private Long id;

    @Schema(description = "发送者头像", example = "https://example.com/avatar.jpg")
    private String from_avatar;

    @Schema(description = "发送者昵称", example = "张三")
    private String from_name;

    @Schema(description = "发送者id", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    private Long from_id;

    @Schema(description = "接收人/群 id", requiredMode = Schema.RequiredMode.REQUIRED, example = "2")
    private Long to_id;

    @Schema(description = "接收人/群 名称", example = "李四")
    private String to_name;

    @Schema(description = "接收人/群 头像", example = "https://example.com/avatar.jpg")
    private String to_avatar;

    @Schema(description = "接收类型", requiredMode = Schema.RequiredMode.REQUIRED, example = "user", allowableValues = {"user", "group"})
    private String chat_type;

    @Schema(description = "消息类型", requiredMode = Schema.RequiredMode.REQUIRED, example = "text", allowableValues = {"text", "image", "video", "audio", "emoticon", "card"})
    private String type;

    @Schema(description = "消息内容", requiredMode = Schema.RequiredMode.REQUIRED, example = "Hello World")
    private String data;

    @Schema(description = "其他参数", example = "{}")
    private Map<String, Object> options;

    @Schema(description = "创建时间", requiredMode = Schema.RequiredMode.REQUIRED, example = "1234567890123")
    private Long create_time;

    @Schema(description = "是否撤回", requiredMode = Schema.RequiredMode.REQUIRED, example = "0")
    private Integer isremove;
}
