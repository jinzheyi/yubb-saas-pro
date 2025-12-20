package com.shengyu.module.system.controller.admin.im.vo.tag;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

/**
 * 标签列表响应VO
 *
 * @author 朱述勇
 * @since 2025/12/20
 */
@Data
@Schema(description = "标签列表响应VO")
public class ImTagListRespVO {

    @Schema(description = "标签ID", example = "1")
    private Long id;

    @Schema(description = "标签名称", example = "好友")
    private String name;
}