package cn.iocoder.yudao.module.platform.controller.center.permission.vo.role;

import cn.iocoder.yudao.framework.common.enums.CommonStatusEnum;
import io.swagger.annotations.ApiModel;
import io.swagger.annotations.ApiModelProperty;
import lombok.Data;

import javax.validation.constraints.NotNull;

@ApiModel("管理后台 - 角色更新状态 Request VO")
@Data
public class RoleUpdateStatusReqVO {

    @ApiModelProperty(value = "角色编号", required = true, example = "1024")
    @NotNull(message = "角色编号不能为空")
    private Long id;

    /**
     * 状态 {@link CommonStatusEnum}
     */
    @ApiModelProperty(value = "状态", required = true, example = "1", notes = "见 CommonStatusEnum 枚举")
    @NotNull(message = "状态不能为空")
    private Integer status;

}
