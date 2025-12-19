package com.shengyu.module.system.controller.admin.im.vo.message;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotNull;
import javax.validation.constraints.Pattern;

/**
 * 发送消息请求 VO
 *
 * @author zhusy
 * @since 2025/12/19
 */
@Data
@Schema(description = "发送消息请求")
public class ImChatSendReqVO {

    @Schema(description = "接收人/群id", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @NotNull(message = "接收人/群id不能为空")
    private Long to_id;

    @Schema(description = "接收类型", requiredMode = Schema.RequiredMode.REQUIRED, example = "user", allowableValues = {"user", "group"})
    @Pattern(regexp = "^(user|group)$", message = "接收类型必须是user或group")
    private String chat_type;

    @Schema(description = "消息类型", requiredMode = Schema.RequiredMode.REQUIRED, example = "text", allowableValues = {"text", "image", "video", "audio", "emoticon", "card"})
    @Pattern(regexp = "^(text|image|video|audio|emoticon|card)$", message = "消息类型必须是text、image、video、audio、emoticon或card")
    private String type;

    @Schema(description = "消息内容", requiredMode = Schema.RequiredMode.REQUIRED, example = "Hello World")
    @NotNull(message = "消息内容不能为空")
    private String data;

    @Schema(description = "其他参数", requiredMode = Schema.RequiredMode.REQUIRED, example = "{}")
    private String options;
}
