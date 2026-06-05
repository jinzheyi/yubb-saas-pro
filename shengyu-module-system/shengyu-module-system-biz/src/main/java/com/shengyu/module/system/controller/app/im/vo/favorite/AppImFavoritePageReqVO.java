package com.shengyu.module.system.controller.app.im.vo.favorite;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Schema(description = "移动端 - IM 收藏消息分页 Request VO")
@Data
public class AppImFavoritePageReqVO {

    @Schema(description = "页码", example = "1")
    private Integer pageNo;

    @Schema(description = "每页数量", example = "20")
    private Integer pageSize;

    @Schema(description = "类型筛选：default(全部)/normal(文字)/media(图片视频)/file(文件)", example = "default")
    private String tab;
}
