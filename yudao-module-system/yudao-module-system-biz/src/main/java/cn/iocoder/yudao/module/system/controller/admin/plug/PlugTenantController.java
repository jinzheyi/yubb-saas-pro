package cn.iocoder.yudao.module.system.controller.admin.plug;

import cn.iocoder.yudao.framework.common.pojo.CommonResult;
import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.module.system.controller.admin.plug.vo.tenant.PlugTenantPageReqVO;
import cn.iocoder.yudao.module.system.controller.admin.plug.vo.tenant.PlugTenantRespVO;
import cn.iocoder.yudao.module.system.controller.admin.plug.vo.tenant.PlugTenantUpdateReqVO;
import cn.iocoder.yudao.module.system.service.plug.PlugTenantService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.validation.Valid;

import static cn.iocoder.yudao.framework.common.pojo.CommonResult.success;

@Tag(name = "管理后台 - 租户应用")
@RestController
@RequestMapping("/plug/tenant")
@Validated
public class PlugTenantController {

    @Resource
    private PlugTenantService tenantService;

    @PutMapping("/update-status")
    @Operation(summary = "租户应用上下架")
    @PreAuthorize("@ss.hasPermission('plug:tenant:update-status')")
    public CommonResult<Boolean> updateTenant(@Valid @RequestBody PlugTenantUpdateReqVO updateReqVO) {
        tenantService.updateTenant(updateReqVO);
        return success(true);
    }

    @GetMapping("/get")
    @Operation(summary = "获得租户应用")
    @Parameter(name = "id", description = "编号", required = true, example = "1024")
    @PreAuthorize("@ss.hasPermission('plug:tenant:query')")
    public CommonResult<PlugTenantRespVO> getTenant(@RequestParam("id") Long id) {
        return success(tenantService.getTenant(id));
    }

    @GetMapping("/page")
    @Operation(summary = "获得租户应用分页")
    @PreAuthorize("@ss.hasPermission('plug:tenant:list')")
    public CommonResult<PageResult<PlugTenantRespVO>> getTenantPage(@Valid PlugTenantPageReqVO pageVO) {
        return success(tenantService.getTenantPage(pageVO));
    }

}
