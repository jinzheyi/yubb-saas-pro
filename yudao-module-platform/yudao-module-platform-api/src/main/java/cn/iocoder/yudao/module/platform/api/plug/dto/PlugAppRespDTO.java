package cn.iocoder.yudao.module.platform.api.plug.dto;

import cn.iocoder.yudao.framework.common.enums.CommonStatusEnum;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * @Description 插件对象
 * @Author zhusy
 * @Date 2023/4/13 11:02
 * @Version 1.0
 **/
@Data
public class PlugAppRespDTO {

    private Long id;

    /**
     * 条码
     */
    private String appSn;

    /**
     * 应用名称
     */
    private String name;

    /**
     * 状态（0上架 1下架）
     */
    private Integer status;

    /**
     * 状态（0启用 1停用）平台端操作，停用后租户不能使用该插件
     *
     * 枚举 {@link CommonStatusEnum}
     */
    private Integer enable;

    /**
     * 应用主图地址
     */
    private String mainPic;

    /**
     * 概要描述
     */
    private String outline;

    /**
     * 描述
     */
    private String description;

    /**
     * 创建时间
     */
    private LocalDateTime createTime;

}
