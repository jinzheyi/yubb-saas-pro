package com.shengyu.module.system.api.plug.dto.order;

import lombok.Data;

@Data
public class PlugOrderItemRespDTO {

    /**
     * 订单项id
     */
    private Long id;

    /**
     * 应用图片
     */
    private String appPic;

    /**
     * 应用名称
     */
    private String appName;

    /**
     * 应用条码
     */
    private String appSn;

}
