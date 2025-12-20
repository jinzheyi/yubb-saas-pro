package com.shengyu.module.system.controller.admin.im.vo.group;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;

/**
 * 群聊重命名请求VO
 *
 * @author 朱述勇
 * @since 2025/12/20
 */
@Data
@Schema(description = "群聊重命名请求VO")
public class ImGroupRenameReqVO {

    @Schema(description = "群组ID")
    @NotNull(message = "群组ID不能为空")
    private Long id;

    @Schema(description = "群名称")
    @NotNull(message = "群名称不能为空")
    @Size(max = 50, message = "群名称不能超过50个字符")
    private String name;
}
