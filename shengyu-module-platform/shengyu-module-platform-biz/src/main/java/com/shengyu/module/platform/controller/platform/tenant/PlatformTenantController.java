package com.shengyu.module.platform.controller.platform.tenant;

import static com.shengyu.framework.common.pojo.CommonResult.success;
import static com.shengyu.framework.operatelog.core.enums.OperateTypeEnum.EXPORT;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.framework.excel.core.util.ExcelUtils;
import com.shengyu.framework.operatelog.core.annotations.OperateLog;
import com.shengyu.module.platform.controller.platform.tenant.vo.tenant.TenantCreateReqVO;
import com.shengyu.module.platform.controller.platform.tenant.vo.tenant.TenantExcelVO;
import com.shengyu.module.platform.controller.platform.tenant.vo.tenant.TenantExportReqVO;
import com.shengyu.module.platform.controller.platform.tenant.vo.tenant.TenantPageReqVO;
import com.shengyu.module.platform.controller.platform.tenant.vo.tenant.TenantRespVO;
import com.shengyu.module.platform.controller.platform.tenant.vo.tenant.TenantUpdateReqVO;
import com.shengyu.module.platform.dal.dataobject.tenant.TenantDO;
import com.shengyu.module.platform.service.tenant.PlatformTenantService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.io.IOException;
import java.util.List;
import javax.annotation.Resource;
import javax.annotation.security.PermitAll;
import javax.servlet.http.HttpServletResponse;
import javax.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "管理后台 - 租户")
@RestController
@RequestMapping("/system/tenant")
public class PlatformTenantController {

    @Resource
    private PlatformTenantService platformTenantService;

    @GetMapping("/get-id-by-name")
    @PermitAll
    @Operation(summary = "使用租户名，获得租户编号", description = "登录界面，根据用户的租户名，获得租户编号")
    @Parameter(name = "name", description = "租户名", required = true, example = "1024")
    public CommonResult<Long> getTenantIdByName(@RequestParam("name") String name) {
        TenantDO tenantDO = platformTenantService.getTenantByName(name);
        return success(tenantDO != null ? tenantDO.getId() : null);
    }

    @PostMapping("/create")
    @Operation(summary = "创建租户")
    @PreAuthorize("@ps.hasPermission('system:tenant:create')")
    public CommonResult<Long> createTenant(@Valid @RequestBody TenantCreateReqVO createReqVO) {
        return success(platformTenantService.createTenant(createReqVO));
    }

    @PutMapping("/update")
    @Operation(summary = "更新租户")
    @PreAuthorize("@ps.hasPermission('system:tenant:update')")
    public CommonResult<Boolean> updateTenant(@Valid @RequestBody TenantUpdateReqVO updateReqVO) {
        platformTenantService.updateTenant(updateReqVO);
        return success(true);
    }

    @DeleteMapping("/delete")
    @Operation(summary = "删除租户")
    @Parameter(name = "id", description = "编号", required = true, example = "1024")
    @PreAuthorize("@ps.hasPermission('system:tenant:delete')")
    public CommonResult<Boolean> deleteTenant(@RequestParam("id") Long id) {
        platformTenantService.deleteTenant(id);
        return success(true);
    }

    @GetMapping("/get")
    @Operation(summary = "获得租户")
    @Parameter(name = "id", description = "编号", required = true, example = "1024")
    @PreAuthorize("@ps.hasPermission('system:tenant:query')")
    public CommonResult<TenantRespVO> getTenant(@RequestParam("id") Long id) {
        TenantDO tenant = platformTenantService.getTenant(id);
        return success(BeanUtils.toBean(tenant, TenantRespVO.class));
    }

    @GetMapping("/page")
    @Operation(summary = "获得租户分页")
    @PreAuthorize("@ps.hasPermission('system:tenant:query')")
    public CommonResult<PageResult<TenantRespVO>> getTenantPage(@Valid TenantPageReqVO pageVO) {
        PageResult<TenantDO> pageResult = platformTenantService.getTenantPage(pageVO);
        return success(BeanUtils.toBean(pageResult, TenantRespVO.class));
    }

    @GetMapping("/export-excel")
    @Operation(summary = "导出租户 Excel")
    @PreAuthorize("@ps.hasPermission('system:tenant:export')")
    @OperateLog(type = EXPORT)
    public void exportTenantExcel(@Valid TenantExportReqVO exportReqVO,
                                  HttpServletResponse response) throws IOException {
        List<TenantDO> list = platformTenantService.getTenantList(exportReqVO);
        // 导出 Excel
        List<TenantExcelVO> datas = BeanUtils.toBean(list, TenantExcelVO.class);
        ExcelUtils.write(response, "租户.xls", "数据", TenantExcelVO.class, datas);
    }


}
