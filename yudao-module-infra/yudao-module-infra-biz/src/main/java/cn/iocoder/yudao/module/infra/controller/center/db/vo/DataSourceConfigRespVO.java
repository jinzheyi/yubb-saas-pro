package cn.iocoder.yudao.module.infra.controller.center.db.vo;

import lombok.*;
import java.util.*;
import io.swagger.annotations.*;

@ApiModel("管理后台 - 数据源配置 Response VO")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
public class DataSourceConfigRespVO extends DataSourceConfigBaseVO {

    @ApiModelProperty(value = "主键编号", required = true, example = "1024")
    private Long id;

    @ApiModelProperty(value = "创建时间", required = true)
    private Date createTime;

}
