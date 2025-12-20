package com.shengyu.module.system.controller.admin.im.vo.moment;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;

/**
 * 朋友圈评论请求VO
 *
 * @author 朱述勇
 * @since 2025/12/20
 */
@Data
@Schema(description = "朋友圈评论请求VO")
public class ImMomentCommentReqVO {

    @Schema(description = "朋友圈id", required = true, example = "1")
    @NotNull(message = "朋友圈id不能为空")
    private Long id;

    @Schema(description = "评论内容", required = true, example = "这条朋友圈很有意思")
    @NotBlank(message = "评论内容不能为空")
    private String content;

    @Schema(description = "回复id", example = "0", defaultValue = "0")
    private Long reply_id = 0L;
}