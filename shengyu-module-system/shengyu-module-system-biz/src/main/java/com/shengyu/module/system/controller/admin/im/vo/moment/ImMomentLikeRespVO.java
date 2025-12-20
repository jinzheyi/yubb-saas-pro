package com.shengyu.module.system.controller.admin.im.vo.moment;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

/**
 * 朋友圈点赞响应VO
 *
 * @author 朱述勇
 * @since 2025/12/20
 */
@Data
@Schema(description = "朋友圈点赞响应VO")
public class ImMomentLikeRespVO {

    @Schema(description = "用户id", example = "1")
    private Long id;

    @Schema(description = "用户名称", example = "张三")
    private String name;
}