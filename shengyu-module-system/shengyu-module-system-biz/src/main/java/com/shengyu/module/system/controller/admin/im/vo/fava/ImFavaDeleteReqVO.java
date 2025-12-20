package com.shengyu.module.system.controller.admin.im.vo.fava;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotNull;

/**
 * 删除收藏请求VO
 *
 * @author 朱述勇
 * @since 2025/12/20
 */
@Data
@Schema(description = "删除收藏请求VO")
public class ImFavaDeleteReqVO {

    @Schema(description = "收藏ID", required = true, example = "1")
    @NotNull(message = "收藏ID不能为空")
    private Long id;
}