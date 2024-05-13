package com.shengyu.module.platform.controller.platform.plug.vo.order;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Data
public class PlugOrderItemRespVO {

    /**
     * 订单项id
     */
    @Schema(description = "订单项id", requiredMode = Schema.RequiredMode.REQUIRED, example = "857")
    private Long id;

    /**
     * 应用图片
     */
    @Schema(description = "应用图片")
    private String appPic;

    /**
     * 应用名称
     */
    @Schema(description = "应用名称")
    private String appName;

    /**
     * 应用条码
     */
    @Schema(description = "应用条码")
    private String appSn;

}
