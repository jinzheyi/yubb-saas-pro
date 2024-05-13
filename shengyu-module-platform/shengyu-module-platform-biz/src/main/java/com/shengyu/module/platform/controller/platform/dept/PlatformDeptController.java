package com.shengyu.module.platform.controller.platform.dept;

import static com.shengyu.framework.common.pojo.CommonResult.success;

import com.shengyu.framework.common.enums.CommonStatusEnum;
import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.module.platform.controller.platform.dept.vo.dept.DeptCreateReqVO;
import com.shengyu.module.platform.controller.platform.dept.vo.dept.DeptListReqVO;
import com.shengyu.module.platform.controller.platform.dept.vo.dept.DeptRespVO;
import com.shengyu.module.platform.controller.platform.dept.vo.dept.DeptSimpleRespVO;
import com.shengyu.module.platform.controller.platform.dept.vo.dept.DeptUpdateReqVO;
import com.shengyu.module.platform.dal.dataobject.dept.PlatformDeptDO;
import com.shengyu.module.platform.service.dept.PlatformDeptService;
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

@Tag(name = "管理后台 - 部门")
@RestController
@RequestMapping("/system/dept")
@Validated
public class PlatformDeptController {

    @Resource
    private PlatformDeptService platformDeptService;

    @PostMapping("create")
    @Operation(summary = "创建部门")
    @PreAuthorize("@ps.hasPermission('system:dept:create')")
    public CommonResult<Long> createDept(@Valid @RequestBody DeptCreateReqVO reqVO) {
        Long deptId = platformDeptService.createDept(reqVO);
        return success(deptId);
    }

    @PutMapping("update")
    @Operation(summary = "更新部门")
    @PreAuthorize("@ps.hasPermission('system:dept:update')")
    public CommonResult<Boolean> updateDept(@Valid @RequestBody DeptUpdateReqVO reqVO) {
        platformDeptService.updateDept(reqVO);
        return success(true);
    }

    @DeleteMapping("delete")
    @Operation(summary = "删除部门")
    @Parameter(name = "id", description = "编号", required = true, example = "1024")
    @PreAuthorize("@ps.hasPermission('system:dept:delete')")
    public CommonResult<Boolean> deleteDept(@RequestParam("id") Long id) {
        platformDeptService.deleteDept(id);
        return success(true);
    }

    @GetMapping("/list")
    @Operation(summary = "获取部门列表")
    @PreAuthorize("@ps.hasPermission('system:dept:query')")
    public CommonResult<List<DeptRespVO>> getDeptList(DeptListReqVO reqVO) {
        List<PlatformDeptDO> list = platformDeptService.getDeptList(reqVO);
        list.sort(Comparator.comparing(PlatformDeptDO::getSort));
        return success(BeanUtils.toBean(list, DeptRespVO.class));
    }

    @GetMapping("/list-all-simple")
    @Operation(summary = "获取部门精简信息列表", description = "只包含被开启的部门，主要用于前端的下拉选项")
    public CommonResult<List<DeptSimpleRespVO>> getSimpleDeptList() {
        // 获得部门列表，只要开启状态的
        DeptListReqVO reqVO = new DeptListReqVO();
        reqVO.setStatus(CommonStatusEnum.ENABLE.getStatus());
        List<PlatformDeptDO> list = platformDeptService.getDeptList(reqVO);
        // 排序后，返回给前端
        list.sort(Comparator.comparing(PlatformDeptDO::getSort));
        return success(BeanUtils.toBean(list, DeptSimpleRespVO.class));
    }

    @GetMapping("/get")
    @Operation(summary = "获得部门信息")
    @Parameter(name = "id", description = "编号", required = true, example = "1024")
    @PreAuthorize("@ps.hasPermission('system:dept:query')")
    public CommonResult<DeptRespVO> getDept(@RequestParam("id") Long id) {
        return success(BeanUtils.toBean(platformDeptService.getDept(id), DeptRespVO.class));
    }

}
