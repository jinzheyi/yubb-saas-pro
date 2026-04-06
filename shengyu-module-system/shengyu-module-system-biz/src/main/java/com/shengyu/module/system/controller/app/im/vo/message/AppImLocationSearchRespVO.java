package com.shengyu.module.system.controller.app.im.vo.message;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.util.ArrayList;
import java.util.List;

@Schema(description = "移动端 - IM 位置检索 Response VO")
@Data
public class AppImLocationSearchRespVO {

    @Schema(description = "检索是否启用", example = "true")
    private Boolean enabled;

    @Schema(description = "检索供应商", example = "tencent")
    private String provider;

    @Schema(description = "提示信息", example = "地图服务额度已用完，请联系管理员")
    private String message;

    @Schema(description = "地点列表")
    private List<PoiItem> pois = new ArrayList<>();

    @Schema(description = "地点项")
    @Data
    public static class PoiItem {

        @Schema(description = "地点 ID", example = "16722496785401115395")
        private String poiId;

        @Schema(description = "地点名称", example = "万达广场")
        private String name;

        @Schema(description = "地点地址", example = "南昌市红谷滩区会展路")
        private String address;

        @Schema(description = "纬度", example = "28.6837")
        private Double latitude;

        @Schema(description = "经度", example = "115.8579")
        private Double longitude;

        @Schema(description = "供应商", example = "tencent")
        private String provider;

    }

}
