package cn.iocoder.yudao.module.platform.controller.platform.tenant;

import static cn.iocoder.yudao.framework.common.pojo.CommonResult.success;

import cn.iocoder.yudao.framework.common.enums.CommonStatusEnum;
import cn.iocoder.yudao.framework.common.pojo.CommonResult;
import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.common.util.object.BeanUtils;
import cn.iocoder.yudao.module.platform.controller.platform.tenant.vo.packages.TenantPackageCreateReqVO;
import cn.iocoder.yudao.module.platform.controller.platform.tenant.vo.packages.TenantPackagePageReqVO;
import cn.iocoder.yudao.module.platform.controller.platform.tenant.vo.packages.TenantPackageRespVO;
import cn.iocoder.yudao.module.platform.controller.platform.tenant.vo.packages.TenantPackageSimpleRespVO;
import cn.iocoder.yudao.module.platform.controller.platform.tenant.vo.packages.TenantPackageUpdateReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.tenant.TenantPackageDO;
import cn.iocoder.yudao.module.platform.service.tenant.TenantPackageService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.List;
import javax.annotation.Resource;
import javax.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "管理后台 - 租户套餐")
@RestController
@RequestMapping("/system/tenant-package")
@Validated
public class TenantPackageController {

    @Resource
    private TenantPackageService tenantPackageService;

    @PostMapping("/create")
    @Operation(summary = "创建租户套餐")
    @PreAuthorize("@ps.hasPermission('system:tenant-package:create')")
    public CommonResult<Long> createTenantPackage(@Valid @RequestBody TenantPackageCreateReqVO createReqVO) {
        return success(tenantPackageService.createTenantPackage(createReqVO));
    }

    @PutMapping("/update")
    @Operation(summary = "更新租户套餐")
    @PreAuthorize("@ps.hasPermission('system:tenant-package:update')")
    public CommonResult<Boolean> updateTenantPackage(@Valid @RequestBody TenantPackageUpdateReqVO updateReqVO) {
        tenantPackageService.updateTenantPackage(updateReqVO);
        return success(true);
    }

    @DeleteMapping("/delete")
    @Operation(summary = "删除租户套餐")
    @Parameter(name = "id", description = "编号", required = true)
    @PreAuthorize("@ps.hasPermission('system:tenant-package:delete')")
    public CommonResult<Boolean> deleteTenantPackage(@RequestParam("id") Long id) {
        tenantPackageService.deleteTenantPackage(id);
        return success(true);
    }

    @GetMapping("/get")
    @Operation(summary = "获得租户套餐")
    @Parameter(name = "id", description = "编号", required = true, example = "1024")
    @PreAuthorize("@ps.hasPermission('system:tenant-package:query')")
    public CommonResult<TenantPackageRespVO> getTenantPackage(@RequestParam("id") Long id) {
        TenantPackageDO tenantPackage = tenantPackageService.getTenantPackage(id);
        return success(BeanUtils.toBean(tenantPackage, TenantPackageRespVO.class));
    }

    @GetMapping("/page")
    @Operation(summary = "获得租户套餐分页")
    @PreAuthorize("@ps.hasPermission('system:tenant-package:query')")
    public CommonResult<PageResult<TenantPackageRespVO>> getTenantPackagePage(@Valid TenantPackagePageReqVO pageVO) {
        PageResult<TenantPackageDO> pageResult = tenantPackageService.getTenantPackagePage(pageVO);
        return success(BeanUtils.toBean(pageResult, TenantPackageRespVO.class));
    }

    @GetMapping("/get-simple-list")
    @Operation(summary = "获取租户套餐精简信息列表", description = "只包含被开启的租户套餐，主要用于前端的下拉选项")
    public CommonResult<List<TenantPackageSimpleRespVO>> getTenantPackageList() {
        // 获得角色列表，只要开启状态的
        List<TenantPackageDO> list = tenantPackageService.getTenantPackageListByStatus(CommonStatusEnum.ENABLE.getStatus());
        return success(BeanUtils.toBean(list, TenantPackageSimpleRespVO.class));
    }

}
