package com.shengyu.module.system.controller.admin.im.vo.mail;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Size;

/**
 * @author zhusy
 * @since 2025/12/19
 */
@Schema(description = "设置备注和标签 Request VO")
@Data
public class ImMailRemarkTagReqVO {

    @Schema(description = "昵称备注", example = "小王")
    @Size(max = 30, message = "昵称备注不能超过30个字符")
    private String nickname;

    @Schema(description = "标签列表，用逗号分隔", required = true, example = "同事,朋友")
    @NotBlank(message = "标签不能为空")
    private String tags;

}
