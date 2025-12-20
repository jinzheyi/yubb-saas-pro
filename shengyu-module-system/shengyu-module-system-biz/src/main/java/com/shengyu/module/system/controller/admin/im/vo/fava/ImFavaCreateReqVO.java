package com.shengyu.module.system.controller.admin.im.vo.fava;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Pattern;

/**
 * 创建收藏请求VO
 *
 * @author 朱述勇
 * @since 2025/12/20
 */
@Data
@Schema(description = "创建收藏请求VO")
public class ImFavaCreateReqVO {

    @Schema(description = "消息类型", required = true, example = "text")
    @NotBlank(message = "消息类型不能为空")
    @Pattern(regexp = "^(text|image|video|audio|emoticon|card)$", message = "消息类型只能是 text, image, video, audio, emoticon, card 中的一种")
    private String type;

    @Schema(description = "消息内容", required = true, example = "这是一条收藏内容")
    @NotBlank(message = "消息内容不能为空")
    private String data;

    @Schema(description = "其他参数", required = true, example = "{}")
    @NotBlank(message = "其他参数不能为空")
    private String options;
}