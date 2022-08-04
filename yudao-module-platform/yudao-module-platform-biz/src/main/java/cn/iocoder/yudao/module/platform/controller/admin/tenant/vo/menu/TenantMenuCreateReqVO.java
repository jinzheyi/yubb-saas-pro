package cn.iocoder.yudao.module.platform.controller.admin.tenant.vo.menu;

import io.swagger.annotations.ApiModel;
import lombok.Data;
import lombok.EqualsAndHashCode;

@ApiModel("管理后台 - 菜单创建 Request VO")
@Data
@EqualsAndHashCode(callSuper = true)
public class TenantMenuCreateReqVO extends TenantMenuBaseVO {
}
