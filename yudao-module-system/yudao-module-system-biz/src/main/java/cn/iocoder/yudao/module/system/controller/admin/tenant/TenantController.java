package cn.iocoder.yudao.module.system.controller.admin.tenant;

import cn.iocoder.yudao.framework.common.pojo.CommonResult;
import cn.iocoder.yudao.module.platform.api.tenant.dto.tenant.TenantRespDTO;
import cn.iocoder.yudao.module.system.service.tenant.TenantService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiImplicitParam;
import io.swagger.annotations.ApiOperation;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import javax.annotation.Resource;
import javax.annotation.security.PermitAll;

import static cn.iocoder.yudao.framework.common.pojo.CommonResult.success;

@Api(tags = "管理后台 - 租户")
@RestController
@RequestMapping("/system/tenant")
public class TenantController {

    @Resource
    private TenantService tenantService;

    @GetMapping("/get-id-by-name")
    @PermitAll
    @ApiOperation(value = "使用租户名，获得租户编号", notes = "登录界面，根据用户的租户名，获得租户编号")
    @ApiImplicitParam(name = "name", value = "租户名", required = true, example = "1024", dataTypeClass = Long.class)
    public CommonResult<Long> getTenantIdByName(@RequestParam("name") String name) {
        TenantRespDTO tenantRespDTO = tenantService.getTenantByName(name);
        return success(tenantRespDTO != null ? tenantRespDTO.getId() : null);
    }

}
