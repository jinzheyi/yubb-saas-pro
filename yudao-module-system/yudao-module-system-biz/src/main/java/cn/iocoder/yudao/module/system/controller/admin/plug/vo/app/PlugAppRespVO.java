package cn.iocoder.yudao.module.system.controller.admin.plug.vo.app;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * @Description 插件对象
 * @Author zhusy
 * @Date 2023/4/13 11:02
 * @Version 1.0
 **/
@Schema(description = "管理后台 - 插件市场插件对象 Response VO")
@Data
public class PlugAppRespVO {

    @Schema(description = "id", requiredMode = Schema.RequiredMode.REQUIRED, example = "14004")
    private Long id;

    /**
     * 条码
     */
    @Schema(description = "条码", requiredMode = Schema.RequiredMode.REQUIRED, example = "14004")
    private String appSn;

    /**
     * 应用名称
     */
    @Schema(description = "应用名称", requiredMode = Schema.RequiredMode.REQUIRED, example = "14004")
    private String name;

    /**
     * 状态（0上架 1下架）
     */
    @Schema(description = "应用主图地址 状态（0上架 1下架）", requiredMode = Schema.RequiredMode.REQUIRED)
    private Integer status;

    /**
     * 应用主图地址
     */
    @Schema(description = "应用主图地址")
    private String mainPic;

    /**
     * 概要描述
     */
    @Schema(description = "概要描述")
    private String outline;

    /**
     * 描述
     */
    @Schema(description = "描述")
    private String description;

    /**
     * 创建时间
     */
    @Schema(description = "创建时间", requiredMode = Schema.RequiredMode.REQUIRED)
    private LocalDateTime createTime;

}
