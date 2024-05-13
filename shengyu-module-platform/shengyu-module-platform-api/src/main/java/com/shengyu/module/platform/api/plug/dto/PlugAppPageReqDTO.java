package com.shengyu.module.platform.api.plug.dto;

import com.shengyu.framework.common.pojo.PageParam;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.ToString;

/**
 * @Description 外部接口调用插件分页入参
 * @Author zhusy
 * @Date 2023/4/13 11:28
 * @Version 1.0
 **/
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
public class PlugAppPageReqDTO extends PageParam {

    /**
     * 应用名称
     */
    private String name;

    /**
     * 条码
     */
    private String appSn;

}
