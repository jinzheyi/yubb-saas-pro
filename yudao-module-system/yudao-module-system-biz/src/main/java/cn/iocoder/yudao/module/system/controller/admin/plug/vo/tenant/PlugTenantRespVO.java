package cn.iocoder.yudao.module.system.controller.admin.plug.vo.tenant;

import cn.iocoder.yudao.framework.common.enums.CommonStatusEnum;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.time.LocalDateTime;

@Schema(description = "管理后台 - 租户应用 Response VO")
@Data
public class PlugTenantRespVO {

    @Schema(description = "id", requiredMode = Schema.RequiredMode.REQUIRED, example = "30424")
    private Long id;

    /**
     * 插件应用id
     */
    @Schema(description = "插件应用id", requiredMode = Schema.RequiredMode.REQUIRED, example = "30424")
    private Long plugAppId;

    /**
     * 条码
     */
    @Schema(description = "插件应用条码，业务使用", requiredMode = Schema.RequiredMode.REQUIRED, example = "30424")
    private String appSn;

    /**
     * 应用名称
     */
    @Schema(description = "应用名称", requiredMode = Schema.RequiredMode.REQUIRED, example = "30424")
    private String name;

    /**
     * 状态（0上架 1下架）
     */
    @Schema(description = "状态（0上架 1下架）", requiredMode = Schema.RequiredMode.REQUIRED, example = "30424")
    private Integer status;

    /**
     * 状态（0启用 1停用）平台端操作，停用后租户不能使用该插件
     *
     * 枚举 {@link CommonStatusEnum}
     */
    @Schema(description = "状态（0启用 1停用）", requiredMode = Schema.RequiredMode.REQUIRED, example = "30424")
    private Integer enable;

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

    @Schema(description = "创建时间", requiredMode = Schema.RequiredMode.REQUIRED)
    private LocalDateTime createTime;

}
