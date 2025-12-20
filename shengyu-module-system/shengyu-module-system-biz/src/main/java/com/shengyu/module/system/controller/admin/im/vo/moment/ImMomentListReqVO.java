package com.shengyu.module.system.controller.admin.im.vo.moment;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

/**
 * 用户朋友圈列表请求VO
 *
 * @author 朱述勇
 * @since 2025/12/20
 */
@Data
@Schema(description = "用户朋友圈列表请求VO")
public class ImMomentListReqVO {

    @Schema(description = "用户id", example = "1")
    private Long userId;

    @Schema(description = "页码", example = "1", defaultValue = "1")
    private Integer page = 1;

    @Schema(description = "每页数量", example = "10", defaultValue = "10")
    private Integer limit = 10;
}