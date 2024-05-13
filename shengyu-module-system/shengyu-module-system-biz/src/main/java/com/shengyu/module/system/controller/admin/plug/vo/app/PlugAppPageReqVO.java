package com.shengyu.module.system.controller.admin.plug.vo.app;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

/**
 * @Description 外部接口调用插件分页入参
 * @Author zhusy
 * @Date 2023/4/13 11:28
 * @Version 1.0
 **/
@Data
public class PlugAppPageReqVO {

    /**
     * 应用名称
     */
    @Schema(description = "应用名称")
    private String name;

    /**
     * 条码
     */
    @Schema(description = "条码")
    private String appSn;

}
