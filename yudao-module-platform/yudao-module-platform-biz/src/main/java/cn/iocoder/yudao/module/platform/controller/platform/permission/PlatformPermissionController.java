package cn.iocoder.yudao.module.platform.controller.platform.permission;

import cn.iocoder.yudao.framework.common.pojo.CommonResult;
import cn.iocoder.yudao.module.platform.controller.platform.permission.vo.permission.PermissionAssignRoleDataScopeReqVO;
import cn.iocoder.yudao.module.platform.controller.platform.permission.vo.permission.PermissionAssignRoleMenuReqVO;
import cn.iocoder.yudao.module.platform.controller.platform.permission.vo.permission.PermissionAssignUserRoleReqVO;
import cn.iocoder.yudao.module.platform.service.permission.PlatformPermissionService;
import io.swagger.v3.oas.annotations.tags.Tag;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.Operation;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.validation.Valid;
import java.util.Set;

import static cn.iocoder.yudao.framework.common.pojo.CommonResult.success;

/**
 * 权限 Controller，提供赋予用户、角色的权限的 API 接口
 *
 * @author 圣钰科技
 */
@Tag(name = "管理后台 - 权限")
@RestController
@RequestMapping("/system/permission")
public class PlatformPermissionController {

    @Resource
    private PlatformPermissionService platformPermissionService;

    @Operation(summary = "获得角色拥有的所有类型菜单编号")
    @Parameter(name = "roleId", description = "角色编号", required = true)
    @GetMapping("/list-role-menus")
    @PreAuthorize("@ps.hasPermission('system:permission:assign-role-menu')")
    public CommonResult<Set<Long>> getRoleMenuList(Long roleId) {
        return success(platformPermissionService.getRoleMenuListByRoleId(roleId));
    }

    @PostMapping("/assign-role-menu")
    @Operation(summary = "赋予角色菜单")
    @PreAuthorize("@ps.hasPermission('system:permission:assign-role-menu')")
    public CommonResult<Boolean> assignRoleMenu(@Validated @RequestBody PermissionAssignRoleMenuReqVO reqVO) {
        // 执行菜单的分配
        platformPermissionService.assignRoleMenu(reqVO.getRoleId(), reqVO.getMenuIds());
        return success(true);
    }

    @PostMapping("/assign-role-data-scope")
    @Operation(summary = "赋予角色数据权限")
    @PreAuthorize("@ps.hasPermission('system:permission:assign-role-data-scope')")
    public CommonResult<Boolean> assignRoleDataScope(@Valid @RequestBody PermissionAssignRoleDataScopeReqVO reqVO) {
        platformPermissionService.assignRoleDataScope(reqVO.getRoleId(), reqVO.getDataScope(), reqVO.getDataScopeDeptIds());
        return success(true);
    }

    @Operation(summary = "获得管理员拥有的角色编号列表")
    @Parameter(name = "userId", description = "用户编号", required = true)
    @GetMapping("/list-user-roles")
    @PreAuthorize("@ps.hasPermission('system:permission:assign-user-role')")
    public CommonResult<Set<Long>> listAdminRoles(@RequestParam("userId") Long userId) {
        return success(platformPermissionService.getUserRoleIdListByUserId(userId));
    }

    @Operation(summary = "赋予用户角色")
    @PostMapping("/assign-user-role")
    @PreAuthorize("@ps.hasPermission('system:permission:assign-user-role')")
    public CommonResult<Boolean> assignUserRole(@Validated @RequestBody PermissionAssignUserRoleReqVO reqVO) {
        platformPermissionService.assignUserRole(reqVO.getUserId(), reqVO.getRoleIds());
        return success(true);
    }

}
