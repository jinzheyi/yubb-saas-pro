package com.shengyu.module.system.controller.app.im.vo.favorite;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.util.Collections;
import java.util.List;

@Schema(description = "移动端 - IM 收藏搜索 Response VO")
@Data
public class AppImFavoriteSearchRespVO {

    @Schema(description = "结果列表")
    private List<AppImFavoriteRespVO> list = Collections.emptyList();

    @Schema(description = "总条数", example = "42")
    private Long total = 0L;

    @Schema(description = "当前页码", example = "1")
    private Integer pageNo = 1;

    @Schema(description = "每页大小", example = "20")
    private Integer pageSize = 20;

    @Schema(description = "是否还有更多", example = "false")
    private Boolean hasMore = false;

    @Schema(description = "服务端搜索耗时（毫秒）", example = "35")
    private Long costMs = 0L;

    @Schema(description = "各类型命中统计")
    private Facets facets = new Facets();

    @Data
    public static class Facets {
        @Schema(description = "综合命中数")
        private Long all = 0L;
        @Schema(description = "普通消息命中数")
        private Long normal = 0L;
        @Schema(description = "图片与视频命中数")
        private Long media = 0L;
        @Schema(description = "文件命中数")
        private Long file = 0L;
    }
}
