package cn.iocoder.yudao.module.system.api.plug.dto.tenant;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class PlugTenantRespDTO {

    /**
     * id
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

    /**
     * 状态（0上架 1下架）
     */
    private Integer status;

    /**
     * 创建时间
     */
    private LocalDateTime createTime;

}
