package com.shengyu.module.system.controller.admin.im.vo.group;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotNull;

/**
 * 踢出群成员请求VO
 *
 * @author 朱述勇
 * @since 2025/12/20
 */
@Data
@Schema(description = "踢出群成员请求VO")
public class ImGroupKickoffReqVO {

    @Schema(description = "群组ID")
    @NotNull(message = "群组ID不能为空")
    private Long id;

    @Schema(description = "用户ID")
    @NotNull(message = "用户ID不能为空")
    private Long userId;
}
