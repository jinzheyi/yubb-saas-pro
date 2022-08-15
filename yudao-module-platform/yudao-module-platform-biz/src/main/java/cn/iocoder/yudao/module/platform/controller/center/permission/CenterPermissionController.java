package cn.iocoder.yudao.module.platform.controller.center.permission;

import cn.iocoder.yudao.framework.common.pojo.CommonResult;
import cn.iocoder.yudao.module.platform.controller.center.permission.vo.permission.PermissionAssignRoleDataScopeReqVO;
import cn.iocoder.yudao.module.platform.controller.center.permission.vo.permission.PermissionAssignRoleMenuReqVO;
import cn.iocoder.yudao.module.platform.controller.center.permission.vo.permission.PermissionAssignUserRoleReqVO;
import cn.iocoder.yudao.module.platform.service.permission.PlatformPermissionService;
import cn.iocoder.yudao.module.platform.service.tenant.PlatformTenantService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiImplicitParam;
import io.swagger.annotations.ApiOperation;
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
 * @author 芋道源码
 */
@Api(tags = "管理后台 - 权限")
@RestController
@RequestMapping("/center/permission")
public class CenterPermissionController {

    @Resource
    private PlatformPermissionService platformPermissionService;
    @Resource
    private PlatformTenantService platformTenantService;

    @ApiOperation("获得角色拥有的菜单编号")
    @ApiImplicitParam(name = "roleId", value = "角色编号", required = true, dataTypeClass = Long.class)
    @GetMapping("/list-role-resources")
    @PreAuthorize("@cs.hasPermission('center:permission:assign-role-menu')")
    public CommonResult<Set<Long>> listRoleMenus(Long roleId) {
        return success(platformPermissionService.getRoleMenuIds(roleId));
    }

    @PostMapping("/assign-role-menu")
    @ApiOperation("赋予角色菜单")
    @PreAuthorize("@cs.hasPermission('center:permission:assign-role-menu')")
    public CommonResult<Boolean> assignRoleMenu(@Validated @RequestBody PermissionAssignRoleMenuReqVO reqVO) {
        // 执行菜单的分配
        platformPermissionService.assignRoleMenu(reqVO.getRoleId(), reqVO.getMenuIds());
        return success(true);
    }

    @PostMapping("/assign-role-data-scope")
    @ApiOperation("赋予角色数据权限")
    @PreAuthorize("@cs.hasPermission('center:permission:assign-role-data-scope')")
    public CommonResult<Boolean> assignRoleDataScope(@Valid @RequestBody PermissionAssignRoleDataScopeReqVO reqVO) {
        platformPermissionService.assignRoleDataScope(reqVO.getRoleId(), reqVO.getDataScope(), reqVO.getDataScopeDeptIds());
        return success(true);
    }

    @ApiOperation("获得管理员拥有的角色编号列表")
    @ApiImplicitParam(name = "userId", value = "用户编号", required = true, dataTypeClass = Long.class)
    @GetMapping("/list-user-roles")
    @PreAuthorize("@cs.hasPermission('center:permission:assign-user-role')")
    public CommonResult<Set<Long>> listAdminRoles(@RequestParam("userId") Long userId) {
        return success(platformPermissionService.getUserRoleIdListByUserId(userId));
    }

    @ApiOperation("赋予用户角色")
    @PostMapping("/assign-user-role")
    @PreAuthorize("@cs.hasPermission('center:permission:assign-user-role')")
    public CommonResult<Boolean> assignUserRole(@Validated @RequestBody PermissionAssignUserRoleReqVO reqVO) {
        platformPermissionService.assignUserRole(reqVO.getUserId(), reqVO.getRoleIds());
        return success(true);
    }

}
