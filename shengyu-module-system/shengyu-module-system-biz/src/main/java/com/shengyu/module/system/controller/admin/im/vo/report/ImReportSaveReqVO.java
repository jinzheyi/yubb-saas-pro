package com.shengyu.module.system.controller.admin.im.vo.report;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Pattern;

/**
 * 举报保存请求VO
 *
 * @author 朱述勇
 * @since 2025/12/20
 */
@Data
@Schema(description = "举报保存请求VO")
public class ImReportSaveReqVO {

    @Schema(description = "被举报人id/群组id", required = true, example = "1")
    @NotNull(message = "被举报人id/群组id不能为空")
    private Long reported_id;

    @Schema(description = "举报类型", required = true, example = "user")
    @NotBlank(message = "举报类型不能为空")
    @Pattern(regexp = "^(user|group)$", message = "举报类型只能是 user 或 group")
    private String reported_type;

    @Schema(description = "举报内容", required = true, example = "该用户发布违规内容")
    @NotBlank(message = "举报内容不能为空")
    private String content;

    @Schema(description = "分类", required = true, example = "违规内容")
    @NotBlank(message = "分类不能为空")
    private String category;
}