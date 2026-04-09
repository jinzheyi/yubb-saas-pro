package com.shengyu.module.system.controller.app.im.vo.search;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.util.Collections;
import java.util.List;
import java.util.Map;

@Schema(description = "移动端 - IM 全局搜索 Response VO")
@Data
public class AppImGlobalSearchRespVO {

    @Schema(description = "统一结果列表")
    private List<Item> list = Collections.emptyList();

    @Schema(description = "各类型命中统计")
    private Facets facets = new Facets();

    @Schema(description = "总条数", example = "42")
    private Long total = 0L;

    @Schema(description = "当前页码", example = "1")
    private Integer pageNo = 1;

    @Schema(description = "每页大小", example = "20")
    private Integer pageSize = 20;

    @Schema(description = "是否还有更多", example = "false")
    private Boolean hasMore = false;

    @Schema(description = "下一游标（预留）", example = "")
    private String nextCursor = "";

    @Data
    public static class Facets {
        @Schema(description = "综合命中数")
        private Long all = 0L;
        @Schema(description = "消息命中数")
        private Long message = 0L;
        @Schema(description = "联系人命中数")
        private Long contact = 0L;
        @Schema(description = "群聊命中数")
        private Long group = 0L;
        @Schema(description = "文件与媒体命中数")
        private Long media = 0L;
    }

    @Data
    public static class Item {
        @Schema(description = "统一结果ID")
        private String id;
        @Schema(description = "类型(message|contact|group|media)")
        private String type;
        @Schema(description = "主标题")
        private String title;
        @Schema(description = "副标题")
        private String subTitle;
        @Schema(description = "摘要")
        private String snippet;
        @Schema(description = "时间戳毫秒")
        private Long time;
        @Schema(description = "相关性分数")
        private Integer score;
        @Schema(description = "会话ID")
        private String chatId;
        @Schema(description = "消息ID")
        private String messageId;
        @Schema(description = "消息序号")
        private String sequence;
        @Schema(description = "扩展数据")
        private Map<String, Object> meta;
    }
}

