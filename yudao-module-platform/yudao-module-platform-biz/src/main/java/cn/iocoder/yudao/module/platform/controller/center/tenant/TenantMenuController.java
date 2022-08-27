package cn.iocoder.yudao.module.platform.controller.center.tenant;

import cn.iocoder.yudao.framework.common.enums.CommonStatusEnum;
import cn.iocoder.yudao.framework.common.pojo.CommonResult;
import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.menu.*;
import cn.iocoder.yudao.module.platform.convert.tenant.TenantMenuConvert;
import cn.iocoder.yudao.module.platform.dal.dataobject.tenant.TenantMenuDO;
import cn.iocoder.yudao.module.platform.service.tenant.PlatformTenantMenuService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiImplicitParam;
import io.swagger.annotations.ApiOperation;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.validation.Valid;
import java.util.Comparator;
import java.util.List;

import static cn.iocoder.yudao.framework.common.pojo.CommonResult.success;

@Api(tags = "管理后台 - 菜单")
@RestController
@RequestMapping("/center/tenant-menu")
@Validated
public class TenantMenuController {

    @Resource
    private PlatformTenantMenuService platformTenantMenuService;

    @PostMapping("/create")
    @ApiOperation("创建菜单")
    @PreAuthorize("@cs.hasPermission('center:tenant-man-menu:create')")
    public CommonResult<Long> createMenu(@Valid @RequestBody TenantMenuCreateReqVO reqVO) {
        Long menuId = platformTenantMenuService.createMenu(reqVO);
        return success(menuId);
    }

    @PutMapping("/update")
    @ApiOperation("修改菜单")
    @PreAuthorize("@cs.hasPermission('center:tenant-man-menu:update')")
    public CommonResult<Boolean> updateMenu(@Valid @RequestBody TenantMenuUpdateReqVO reqVO) {
        platformTenantMenuService.updateMenu(reqVO);
        return success(true);
    }

    @DeleteMapping("/delete")
    @ApiOperation("删除菜单")
    @ApiImplicitParam(name = "id", value = "角色编号", required= true, example = "1024", dataTypeClass = Long.class)
    @PreAuthorize("@cs.hasPermission('center:tenant-man-menu:delete')")
    public CommonResult<Boolean> deleteMenu(@RequestParam("id") Long id) {
        platformTenantMenuService.deleteMenu(id);
        return success(true);
    }

    @GetMapping("/list")
    @ApiOperation(value = "获取菜单列表", notes = "用于【菜单管理】界面")
    @PreAuthorize("@cs.hasPermission('center:tenant-man-menu:list')")
    public CommonResult<List<TenantMenuRespVO>> getMenus(TenantMenuListReqVO reqVO) {
        List<TenantMenuDO> list = platformTenantMenuService.getMenus(reqVO);
        list.sort(Comparator.comparing(TenantMenuDO::getSort));
        return success(TenantMenuConvert.INSTANCE.convertList(list));
    }

    @GetMapping("/list-all-simple")
    @ApiOperation(value = "获取菜单精简信息列表", notes = "只包含被开启的菜单，用于【角色分配菜单】功能的选项。")
    public CommonResult<List<TenantMenuSimpleRespVO>> getSimpleMenus() {
        // 获得菜单列表，只要开启状态的
        TenantMenuListReqVO reqVO = new TenantMenuListReqVO();
        reqVO.setStatus(CommonStatusEnum.ENABLE.getStatus());
        List<TenantMenuDO> list = platformTenantMenuService.getMenus(reqVO);
        // 排序后，返回给前端
        list.sort(Comparator.comparing(TenantMenuDO::getSort));
        return success(TenantMenuConvert.INSTANCE.convertList02(list));
    }

    @GetMapping("/get")
    @ApiOperation("获取菜单信息")
    @PreAuthorize("@cs.hasPermission('center:tenant-man-menu:query')")
    public CommonResult<TenantMenuRespVO> getMenu(Long id) {
        TenantMenuDO menu = platformTenantMenuService.getMenu(id);
        return success(TenantMenuConvert.INSTANCE.convert(menu));
    }

}
