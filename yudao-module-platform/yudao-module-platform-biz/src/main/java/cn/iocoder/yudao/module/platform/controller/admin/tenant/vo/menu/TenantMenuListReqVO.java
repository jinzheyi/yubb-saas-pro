package cn.iocoder.yudao.module.platform.controller.admin.tenant.vo.menu;

import io.swagger.annotations.ApiModel;
import io.swagger.annotations.ApiModelProperty;
import lombok.Data;

@ApiModel("管理后台 - 菜单列表 Request VO")
@Data
public class TenantMenuListReqVO {

    @ApiModelProperty(value = "菜单名称", example = "芋道", notes = "模糊匹配")
    private String name;

    @ApiModelProperty(value = "展示状态", example = "1", notes = "参见 CommonStatusEnum 枚举类")
    private Integer status;

}
