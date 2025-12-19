package com.shengyu.module.system.controller.admin.im.vo.message;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotNull;
import javax.validation.constraints.Pattern;

/**
 * 撤回消息请求 VO
 *
 * @author zhusy
 * @since 2025/12/19
 */
@Data
@Schema(description = "撤回消息请求")
public class ImChatRecallReqVO {

    @Schema(description = "接收人/群id", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @NotNull(message = "接收人/群id不能为空")
    private Long to_id;

    @Schema(description = "接收类型", requiredMode = Schema.RequiredMode.REQUIRED, example = "user", allowableValues = {"user", "group"})
    @Pattern(regexp = "^(user|group)$", message = "接收类型必须是user或group")
    private String chat_type;

    @Schema(description = "消息id", requiredMode = Schema.RequiredMode.REQUIRED, example = "1234567890123")
    @NotNull(message = "消息id不能为空")
    private Long id;
}
