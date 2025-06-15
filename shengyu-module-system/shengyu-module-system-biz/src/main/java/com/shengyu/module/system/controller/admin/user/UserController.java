package com.shengyu.module.system.controller.admin.user;

import cn.hutool.core.collection.CollUtil;
import com.shengyu.framework.common.enums.CommonStatusEnum;
import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.common.pojo.PageParam;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.framework.common.util.validation.ValidGroup;
import com.shengyu.framework.excel.core.util.ExcelUtils;
import com.shengyu.framework.operatelog.core.annotations.OperateLog;
import com.shengyu.module.system.controller.admin.dept.vo.dept.UserDeptRespVO;
import com.shengyu.module.system.controller.admin.dept.vo.post.UserPostRespVO;
import com.shengyu.module.system.controller.admin.user.vo.user.*;
import com.shengyu.module.system.convert.user.UserConvert;
import com.shengyu.module.system.dal.dataobject.dept.DeptDO;
import com.shengyu.module.system.dal.dataobject.user.AdminUserDO;
import com.shengyu.framework.common.enums.common.SexEnum;
import com.shengyu.module.system.service.dept.DeptService;
import com.shengyu.module.system.service.dept.PostService;
import com.shengyu.module.system.service.user.AdminUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.Parameters;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletResponse;
import javax.validation.Valid;
import java.io.IOException;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import static com.shengyu.framework.common.pojo.CommonResult.success;
import static com.shengyu.framework.common.util.collection.CollectionUtils.convertList;
import static com.shengyu.framework.operatelog.core.enums.OperateTypeEnum.EXPORT;

@Tag(name = "管理后台 - 用户")
@RestController
@RequestMapping("/system/user")
@Validated
public class UserController {

    @Resource
    private AdminUserService userService;
    @Resource
    private DeptService deptService;
    @Resource
    private PostService postService;

    @PostMapping("/create")
    @Operation(summary = "新增用户")
    @PreAuthorize("@ss.hasPermission('system:user:create')")
    public CommonResult<Long> createUser(@Valid @RequestBody UserSaveReqVO reqVO) {
        Long id = userService.createUser(reqVO);
        return success(id);
    }

    @PutMapping("update")
    @Operation(summary = "修改用户")
    @PreAuthorize("@ss.hasPermission('system:user:update')")
    public CommonResult<Boolean> updateUser(@Valid @RequestBody UserUpdateReqVO reqVO) {
        userService.updateUser(reqVO);
        return success(true);
    }

    @DeleteMapping("/delete")
    @Operation(summary = "删除用户")
    @Parameter(name = "id", description = "编号", required = true, example = "1024")
    @PreAuthorize("@ss.hasPermission('system:user:delete')")
    public CommonResult<Boolean> deleteUser(@RequestParam("id") Long id) {
        userService.deleteUser(id);
        return success(true);
    }

    @PutMapping("/update-status")
    @Operation(summary = "修改用户状态")
    @PreAuthorize("@ss.hasPermission('system:user:update')")
    public CommonResult<Boolean> updateUserStatus(@Valid @RequestBody UserUpdateStatusReqVO reqVO) {
        userService.updateUserStatus(reqVO.getId(), reqVO.getStatus());
        return success(true);
    }

    @GetMapping("/page")
    @Operation(summary = "获得用户分页列表")
    @PreAuthorize("@ss.hasPermission('system:user:list')")
    public CommonResult<PageResult<UserRespVO>> getUserPage(@Valid UserPageReqVO pageReqVO) {
        // 获得用户分页列表
        PageResult<UserRespVO> pageResult = userService.getUserPage(pageReqVO);
        if (CollUtil.isEmpty(pageResult.getList())) {
            return success(new PageResult<>(pageResult.getTotal()));
        }
        // 拼接数据
        Map<Long, List<UserDeptRespVO>> userDeptMap = deptService.getUserDeptMap(
                convertList(pageResult.getList(), UserRespVO::getId));
        return success(new PageResult<>(UserConvert.INSTANCE.convertList(pageResult.getList(), userDeptMap),
                pageResult.getTotal()));
    }

    @GetMapping({"/list-all-simple", "/simple-list"})
    @Operation(summary = "获取用户精简信息列表", description = "只包含被开启的用户，主要用于前端的下拉选项")
    public CommonResult<List<UserSimpleRespVO>> getSimpleUserList() {
        List<AdminUserDO> list = userService.getUserListByStatus(CommonStatusEnum.ENABLE.getStatus());
        // 拼接数据
        Map<Long, List<UserDeptRespVO>> userDeptMap = deptService.getUserDeptMap(
                convertList(list, AdminUserDO::getId));
        return success(UserConvert.INSTANCE.convertSimpleList(list, userDeptMap));
    }

    @GetMapping("/get-myTenant-list")
    @Operation(summary = "获取当前用户的全部租户列表")
    public CommonResult<List<MyTenantRespVO>> getMyTenantList() {
        return success(userService.getMyTenantList());
    }

    @GetMapping("/get-myEnableDept-list")
    @Operation(summary = "获取当前用户的已启用部门列表")
    public CommonResult<List<UserDeptRespVO>> getMyEnableDeptList() {
        return success(userService.getMyEnableDeptList());
    }

    @GetMapping("/get")
    @Operation(summary = "获得用户详情")
    @Parameter(name = "id", description = "编号", required = true, example = "1024")
    @PreAuthorize("@ss.hasPermission('system:user:query')")
    public CommonResult<UserRespVO> getUser(@RequestParam("id") Long id) {
        UserRespVO user = userService.getUser(id);
        // 拼接数据
        List<UserPostRespVO> userPostRespVOList = postService.getUserPostMap(Collections.singleton(user.getId())).get(user.getId());
        if (CollUtil.isNotEmpty(userPostRespVOList)) {
            user.setPostIds(userPostRespVOList.stream().map(UserPostRespVO::getPostId).collect(Collectors.toSet()));
        }
        List<UserDeptRespVO> userDeptList = deptService.getUserDeptMap(Collections.singleton(user.getId())).get(user.getId());
        return success(UserConvert.INSTANCE.convert(user, userDeptList));
    }

    @GetMapping("/export")
    @Operation(summary = "导出用户")
    @PreAuthorize("@ss.hasPermission('system:user:export')")
    @OperateLog(type = EXPORT)
    public void exportUserList(@Validated UserPageReqVO exportReqVO,
                               HttpServletResponse response) throws IOException {
        exportReqVO.setPageSize(PageParam.PAGE_SIZE_NONE);
        List<UserRespVO> list = userService.getUserPage(exportReqVO).getList();
        // 输出 Excel
        Map<Long, List<UserDeptRespVO>> userDeptMap = deptService.getUserDeptMap(
                convertList(list, UserRespVO::getId));
        ExcelUtils.write(response, "用户数据.xls", "数据", UserRespVO.class,
                UserConvert.INSTANCE.convertList(list, userDeptMap));
    }

//    @GetMapping("/get-import-template")
//    @Operation(summary = "获得导入用户模板")
//    public void importTemplate(HttpServletResponse response) throws IOException {
//        // 手动创建导出 demo
//        List<UserImportExcelVO> list = Arrays.asList(
//                UserImportExcelVO.builder().username("shengyu").deptId(1L).email("jin_zheyicn@qq.com").mobile("15170435653")
//                        .nickname("圣钰科技").status(CommonStatusEnum.ENABLE.getStatus()).sex(SexEnum.MALE.getSex()).build(),
//                UserImportExcelVO.builder().username("shengyu").deptId(2L).email("jin_zheyicn@qq.com").mobile("15170435653")
//                        .nickname("源码").status(CommonStatusEnum.DISABLE.getStatus()).sex(SexEnum.FEMALE.getSex()).build()
//        );
//        // 输出
//        ExcelUtils.write(response, "用户导入模板.xls", "用户列表", UserImportExcelVO.class, list);
//    }
//
//    @PostMapping("/import")
//    @Operation(summary = "导入用户")
//    @Parameters({
//            @Parameter(name = "file", description = "Excel 文件", required = true),
//            @Parameter(name = "updateSupport", description = "是否支持更新，默认为 false", example = "true")
//    })
//    @PreAuthorize("@ss.hasPermission('system:user:import')")
//    public CommonResult<UserImportRespVO> importExcel(@RequestParam("file") MultipartFile file,
//                                                      @RequestParam(value = "updateSupport", required = false, defaultValue = "false") Boolean updateSupport) throws Exception {
//        List<UserImportExcelVO> list = ExcelUtils.read(file, UserImportExcelVO.class);
//        return success(userService.importUserList(list, updateSupport));
//    }

}
