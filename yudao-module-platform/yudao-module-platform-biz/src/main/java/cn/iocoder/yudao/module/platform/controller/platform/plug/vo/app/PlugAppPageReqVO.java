package cn.iocoder.yudao.module.platform.controller.platform.plug.vo.app;

import cn.iocoder.yudao.framework.common.pojo.PageParam;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.ToString;
import org.springframework.format.annotation.DateTimeFormat;

import java.time.LocalDateTime;

import static cn.iocoder.yudao.framework.common.util.date.DateUtils.FORMAT_YEAR_MONTH_DAY_HOUR_MINUTE_SECOND;

@Schema(description = "管理后台 - 插件应用分页 Request VO")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
public class PlugAppPageReqVO extends PageParam {

    @Schema(description = "应用名称", example = "名称")
    private String name;

    @Schema(description = "条码")
    private String appSn;

    @Schema(description = "状态（0上架 1下架）", example = "0")
    private Integer status;

    @Schema(description = "状态（0启用 1停用）平台端操作，停用后租户不能使用该插件")
    private Integer enable;

    @Schema(description = "创建时间")
    @DateTimeFormat(pattern = FORMAT_YEAR_MONTH_DAY_HOUR_MINUTE_SECOND)
    private LocalDateTime[] createTime;

}
