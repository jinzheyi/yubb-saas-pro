package com.shengyu.module.platform.controller.platform.tenant;

import static com.shengyu.framework.common.pojo.CommonResult.success;

import com.shengyu.framework.common.enums.CommonConstants;
import com.shengyu.framework.common.enums.CommonConstants.MenuDimensionEnum;
import com.shengyu.framework.common.enums.CommonStatusEnum;
import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.module.platform.controller.platform.tenant.vo.menu.TenantMenuCreateReqVO;
import com.shengyu.module.platform.controller.platform.tenant.vo.menu.TenantMenuListReqVO;
import com.shengyu.module.platform.controller.platform.tenant.vo.menu.TenantMenuRespVO;
import com.shengyu.module.platform.controller.platform.tenant.vo.menu.TenantMenuSimpleRespVO;
import com.shengyu.module.platform.controller.platform.tenant.vo.menu.TenantMenuUpdateReqVO;
import com.shengyu.module.platform.dal.dataobject.tenant.TenantMenuDO;
import com.shengyu.module.platform.service.tenant.TenantMenuService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.Comparator;
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

@Tag(name = "管理后台 - 租户菜单,普通菜单和插件菜单在一起管理。创建租户套餐时选择的是普通菜单。")
@RestController
@RequestMapping("/system/tenant-menu")
@Validated
public class TenantMenuController {

    @Resource
    private TenantMenuService tenantMenuService;

    @PostMapping("/create")
    @Operation(summary = "创建菜单")
    @PreAuthorize("@ps.hasPermission('system:tenant-menu:create')")
    public CommonResult<Long> createMenu(@Valid @RequestBody TenantMenuCreateReqVO reqVO) {
        Long menuId = tenantMenuService.createMenu(reqVO);
        return success(menuId);
    }

    @PutMapping("/update")
    @Operation(summary = "修改菜单")
    @PreAuthorize("@ps.hasPermission('system:tenant-menu:update')")
    public CommonResult<Boolean> updateMenu(@Valid @RequestBody TenantMenuUpdateReqVO reqVO) {
        tenantMenuService.updateMenu(reqVO);
        return success(true);
    }

    @DeleteMapping("/delete")
    @Operation(summary = "删除菜单")
    @Parameter(name = "id", description = "角色编号", required= true, example = "1024")
    @PreAuthorize("@ps.hasPermission('system:tenant-menu:delete')")
    public CommonResult<Boolean> deleteMenu(@RequestParam("id") Long id) {
        tenantMenuService.deleteMenu(id);
        return success(true);
    }

    @GetMapping("/list")
    @Operation(summary = "获取菜单列表", description = "用于【菜单管理】界面")
    @PreAuthorize("@ps.hasPermission('system:tenant-menu:query')")
    public CommonResult<List<TenantMenuRespVO>> getMenuList(TenantMenuListReqVO reqVO) {
        List<TenantMenuDO> list = tenantMenuService.getMenuList(reqVO);
        list.sort(Comparator.comparing(TenantMenuDO::getSort));
        return success(BeanUtils.toBean(list, TenantMenuRespVO.class));
    }

    @GetMapping("/list-all-simple")
    @Operation(summary = "获取普通菜单精简信息列表，创建租户套餐时选择菜单使用", description = "只包含被开启的菜单，用于【角色分配菜单】功能的选项。")
    public CommonResult<List<TenantMenuSimpleRespVO>> getSimpleMenuList() {
        // 获得菜单列表，只要开启状态的
        TenantMenuListReqVO reqVO = new TenantMenuListReqVO();
        reqVO.setStatus(CommonStatusEnum.ENABLE.getStatus());
        reqVO.setDimension(CommonConstants.MenuDimensionEnum.MENU.getCode());
        List<TenantMenuDO> list = tenantMenuService.getMenuList(reqVO);
        // 排序后，返回给前端
        list.sort(Comparator.comparing(TenantMenuDO::getSort));
        return success(BeanUtils.toBean(list, TenantMenuSimpleRespVO.class));
    }

    @GetMapping("/list-all-plug-simple")
    @Operation(summary = "获取插件菜单精简信息列表，创建租户应用菜单使用", description = "只包含被开启的插件菜单，用于应用插件菜单分配功能的选项。")
    public CommonResult<List<TenantMenuSimpleRespVO>> getSimpleMenuPlugList(String plugAppSn) {
        // 获得菜单列表，只要开启状态的
        TenantMenuListReqVO reqVO = new TenantMenuListReqVO();
        reqVO.setStatus(CommonStatusEnum.ENABLE.getStatus());
        reqVO.setDimension(CommonConstants.MenuDimensionEnum.PLUG.getCode());
        reqVO.setPlugAppSn(plugAppSn);
        List<TenantMenuDO> list = tenantMenuService.getMenuList(reqVO);
        // 排序后，返回给前端
        list.sort(Comparator.comparing(TenantMenuDO::getSort));
        return success(BeanUtils.toBean(list, TenantMenuSimpleRespVO.class));
    }

    @GetMapping("/get")
    @Operation(summary = "获取菜单信息")
    @PreAuthorize("@ps.hasPermission('system:tenant-menu:query')")
    public CommonResult<TenantMenuRespVO> getMenu(Long id) {
        TenantMenuDO menu = tenantMenuService.getMenu(id);
        return success(BeanUtils.toBean(menu, TenantMenuRespVO.class));
    }

}
