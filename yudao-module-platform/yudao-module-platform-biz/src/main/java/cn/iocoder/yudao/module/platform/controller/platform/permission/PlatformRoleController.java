package cn.iocoder.yudao.module.platform.controller.platform.permission;

import static cn.iocoder.yudao.framework.common.pojo.CommonResult.success;
import static cn.iocoder.yudao.framework.operatelog.core.enums.OperateTypeEnum.EXPORT;
import static java.util.Collections.singleton;

import cn.iocoder.yudao.framework.common.enums.CommonStatusEnum;
import cn.iocoder.yudao.framework.common.pojo.CommonResult;
import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.common.util.object.BeanUtils;
import cn.iocoder.yudao.framework.excel.core.util.ExcelUtils;
import cn.iocoder.yudao.framework.operatelog.core.annotations.OperateLog;
import cn.iocoder.yudao.module.platform.controller.platform.permission.vo.role.RoleCreateReqVO;
import cn.iocoder.yudao.module.platform.controller.platform.permission.vo.role.RoleExcelVO;
import cn.iocoder.yudao.module.platform.controller.platform.permission.vo.role.RoleExportReqVO;
import cn.iocoder.yudao.module.platform.controller.platform.permission.vo.role.RolePageReqVO;
import cn.iocoder.yudao.module.platform.controller.platform.permission.vo.role.RoleRespVO;
import cn.iocoder.yudao.module.platform.controller.platform.permission.vo.role.RoleSimpleRespVO;
import cn.iocoder.yudao.module.platform.controller.platform.permission.vo.role.RoleUpdateReqVO;
import cn.iocoder.yudao.module.platform.controller.platform.permission.vo.role.RoleUpdateStatusReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.permission.PlatformRoleDO;
import cn.iocoder.yudao.module.platform.service.permission.PlatformRoleService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.io.IOException;
import java.util.Comparator;
import java.util.List;
import javax.annotation.Resource;
import javax.servlet.http.HttpServletResponse;
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

@Tag(name = "管理后台 - 角色")
@RestController
@RequestMapping("/system/role")
@Validated
public class PlatformRoleController {

    @Resource
    private PlatformRoleService platformRoleService;

    @PostMapping("/create")
    @Operation(summary = "创建角色")
    @PreAuthorize("@ps.hasPermission('system:role:create')")
    public CommonResult<Long> createRole(@Valid @RequestBody RoleCreateReqVO reqVO) {
        return success(platformRoleService.createRole(reqVO, null));
    }

    @PutMapping("/update")
    @Operation(summary = "修改角色")
    @PreAuthorize("@ps.hasPermission('system:role:update')")
    public CommonResult<Boolean> updateRole(@Valid @RequestBody RoleUpdateReqVO reqVO) {
        platformRoleService.updateRole(reqVO);
        return success(true);
    }

    @PutMapping("/update-status")
    @Operation(summary = "修改角色状态")
    @PreAuthorize("@ps.hasPermission('system:role:update')")
    public CommonResult<Boolean> updateRoleStatus(@Valid @RequestBody RoleUpdateStatusReqVO reqVO) {
        platformRoleService.updateRoleStatus(reqVO.getId(), reqVO.getStatus());
        return success(true);
    }

    @DeleteMapping("/delete")
    @Operation(summary = "删除角色")
    @Parameter(name = "id", description = "角色编号", required = true, example = "1024")
    @PreAuthorize("@ps.hasPermission('system:role:delete')")
    public CommonResult<Boolean> deleteRole(@RequestParam("id") Long id) {
        platformRoleService.deleteRole(id);
        return success(true);
    }

    @GetMapping("/get")
    @Operation(summary = "获得角色信息")
    @PreAuthorize("@ps.hasPermission('system:role:query')")
    public CommonResult<RoleRespVO> getRole(@RequestParam("id") Long id) {
        PlatformRoleDO role = platformRoleService.getRole(id);
        return success(BeanUtils.toBean(role, RoleRespVO.class));
    }

    @GetMapping("/page")
    @Operation(summary = "获得角色分页")
    @PreAuthorize("@ps.hasPermission('system:role:query')")
    public CommonResult<PageResult<PlatformRoleDO>> getRolePage(RolePageReqVO reqVO) {
        return success(platformRoleService.getRolePage(reqVO));
    }

    @GetMapping("/list-all-simple")
    @Operation(summary = "获取角色精简信息列表", description = "只包含被开启的角色，主要用于前端的下拉选项")
    public CommonResult<List<RoleSimpleRespVO>> getSimpleRoleList() {
        // 获得角色列表，只要开启状态的
        List<PlatformRoleDO> list = platformRoleService.getRoleListByStatus(singleton(CommonStatusEnum.ENABLE.getStatus()));
        // 排序后，返回给前端
        list.sort(Comparator.comparing(PlatformRoleDO::getSort));
        return success(BeanUtils.toBean(list, RoleSimpleRespVO.class));
    }

    @GetMapping("/export")
    @OperateLog(type = EXPORT)
    @PreAuthorize("@ps.hasPermission('system:role:export')")
    public void export(HttpServletResponse response, @Validated RoleExportReqVO reqVO) throws IOException {
        List<PlatformRoleDO> list = platformRoleService.getRoleList(reqVO);
        List<RoleExcelVO> data = BeanUtils.toBean(list, RoleExcelVO.class);
        // 输出
        ExcelUtils.write(response, "角色数据.xls", "角色列表", RoleExcelVO.class, data);
    }

}
