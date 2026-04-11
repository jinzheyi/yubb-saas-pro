package com.shengyu.module.system.controller.app.im.vo.favorite;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.Max;
import javax.validation.constraints.Min;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Size;

@Schema(description = "移动端 - IM 收藏搜索 Request VO")
@Data
public class AppImFavoriteSearchReqVO {

    @Schema(description = "关键词", example = "报表")
    @NotBlank(message = "关键词不能为空")
    @Size(min = 2, max = 64, message = "关键词长度需在 2~64")
    private String keyword;

    @Schema(description = "筛选标签：default|normal|media|file", example = "media")
    @Size(max = 20, message = "tab 长度不能超过 20")
    private String tab;

    @Schema(description = "页码", example = "1")
    @Min(value = 1, message = "页码最小为 1")
    private Integer pageNo;

    @Schema(description = "每页数量", example = "20")
    @Min(value = 1, message = "每页数量最小为 1")
    @Max(value = 50, message = "每页数量最大为 50")
    private Integer pageSize;
}
