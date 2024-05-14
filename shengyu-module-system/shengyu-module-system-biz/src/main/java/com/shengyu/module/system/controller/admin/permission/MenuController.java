package com.shengyu.module.system.controller.admin.permission;

import static com.shengyu.framework.common.pojo.CommonResult.success;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.module.platform.api.tenant.dto.menu.TenantMenuRespDTO;
import com.shengyu.module.system.controller.admin.permission.vo.menu.MenuSimpleRespVO;
import com.shengyu.module.system.service.permission.PermissionService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.Comparator;
import java.util.List;
import javax.annotation.Resource;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "管理后台 - 菜单")
@RestController
@RequestMapping("/system/menu")
@Validated
public class MenuController {

    @Resource
    private PermissionService permissionService;

    @GetMapping({"/list-all-simple", "/simple-list"})
    @Operation(summary = "租户创建角色时获取菜单精简信息列表", description = "只包含被开启的菜单，用于【角色分配菜单】功能的选项。")
    public CommonResult<List<MenuSimpleRespVO>> getSimpleMenuList() {
        // 获得菜单列表，只要开启状态的
        List<TenantMenuRespDTO> list = permissionService.getAdminTenantPackageAndPlugMenu();
        // 排序后，返回给前端
        list.sort(Comparator.comparing(TenantMenuRespDTO::getSort));
        return success(BeanUtils.toBean(list, MenuSimpleRespVO.class));
    }

}
