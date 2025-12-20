package com.shengyu.module.system.controller.admin.im.vo.group;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotNull;

/**
 * 退出群聊请求VO
 *
 * @author 朱述勇
 * @since 2025/12/20
 */
@Data
@Schema(description = "退出群聊请求VO")
public class ImGroupQuitReqVO {

    @Schema(description = "群组ID")
    @NotNull(message = "群组ID不能为空")
    private Long id;
}
