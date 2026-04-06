package com.shengyu.module.system.controller.app.im.vo.message;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.Max;
import javax.validation.constraints.Min;

@Schema(description = "移动端 - IM 位置检索 Request VO")
@Data
public class AppImLocationSearchReqVO {

    @Schema(description = "检索关键词（为空时按坐标检索附近地点）", example = "万达广场")
    private String keyword;

    @Schema(description = "当前位置纬度（可选）", example = "28.6837")
    private Double latitude;

    @Schema(description = "当前位置经度（可选）", example = "115.8579")
    private Double longitude;

    @Schema(description = "返回条数（1-20）", example = "20")
    @Min(value = 1, message = "pageSize 不能小于 1")
    @Max(value = 20, message = "pageSize 不能大于 20")
    private Integer pageSize = 20;

}
