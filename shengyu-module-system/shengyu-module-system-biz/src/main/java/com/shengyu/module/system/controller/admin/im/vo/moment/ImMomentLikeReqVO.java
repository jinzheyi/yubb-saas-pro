package com.shengyu.module.system.controller.admin.im.vo.moment;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotNull;

/**
 * 朋友圈点赞请求VO
 *
 * @author 朱述勇
 * @since 2025/12/20
 */
@Data
@Schema(description = "朋友圈点赞请求VO")
public class ImMomentLikeReqVO {

    @Schema(description = "朋友圈id", required = true, example = "1")
    @NotNull(message = "朋友圈id不能为空")
    private Long id;
}