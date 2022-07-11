package cn.iocoder.yudao.module.platform.controller.center.permission.vo.role;

import cn.iocoder.yudao.framework.common.enums.CommonStatusEnum;
import cn.iocoder.yudao.module.platform.enums.permission.PlatformDataScopeEnum;
import cn.iocoder.yudao.module.platform.enums.permission.PlatformRoleTypeEnum;
import io.swagger.annotations.ApiModel;
import io.swagger.annotations.ApiModelProperty;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

import java.util.Date;
import java.util.Set;

@ApiModel("管理后台 - 角色信息 Response VO")
@Data
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode(callSuper = true)
public class RoleRespVO extends RoleBaseVO {

    @ApiModelProperty(value = "角色编号", required = true, example = "1")
    private Long id;

    /**
     * 数据范围 {@link PlatformDataScopeEnum}
     */
    @ApiModelProperty(value = "数据范围", required = true, example = "1", notes = "参见 PlatformDataScopeEnum 枚举类")
    private Integer dataScope;

    @ApiModelProperty(value = "数据范围(指定部门数组)", example = "1")
    private Set<Long> dataScopeDeptIds;

    /**
     * 状态 {@link CommonStatusEnum}
     */
    @ApiModelProperty(value = "状态", required = true, example = "1", notes = "参见 CommonStatusEnum 枚举类")
    private Integer status;

    /**
     * 角色类型 {@link PlatformRoleTypeEnum}
     */
    @ApiModelProperty(value = "角色类型", required = true, example = "1", notes = "参见 PlatformRoleTypeEnum 枚举类")
    private Integer type;

    @ApiModelProperty(value = "创建时间", required = true, example = "时间戳格式")
    private Date createTime;

}
