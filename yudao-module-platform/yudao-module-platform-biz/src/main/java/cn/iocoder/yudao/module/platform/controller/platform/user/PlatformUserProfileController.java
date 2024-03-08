package cn.iocoder.yudao.module.platform.controller.platform.user;

import static cn.iocoder.yudao.framework.common.exception.util.ServiceExceptionUtil.exception;
import static cn.iocoder.yudao.framework.common.pojo.CommonResult.success;
import static cn.iocoder.yudao.framework.security.core.util.SecurityFrameworkUtils.getPlatformLoginUserId;
import static cn.iocoder.yudao.module.infra.enums.ErrorCodeConstants.FILE_IS_EMPTY;

import cn.hutool.core.collection.CollUtil;
import cn.iocoder.yudao.framework.common.pojo.CommonResult;
import cn.iocoder.yudao.framework.common.util.object.BeanUtils;
import cn.iocoder.yudao.framework.datapermission.core.annotation.DataPermission;
import cn.iocoder.yudao.module.platform.controller.platform.user.vo.profile.UserProfileRespVO;
import cn.iocoder.yudao.module.platform.controller.platform.user.vo.profile.UserProfileUpdatePasswordReqVO;
import cn.iocoder.yudao.module.platform.controller.platform.user.vo.profile.UserProfileUpdateReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.dept.PlatformDeptDO;
import cn.iocoder.yudao.module.platform.dal.dataobject.dept.PlatformPostDO;
import cn.iocoder.yudao.module.platform.dal.dataobject.permission.PlatformRoleDO;
import cn.iocoder.yudao.module.platform.dal.dataobject.user.PlatformUserDO;
import cn.iocoder.yudao.module.platform.service.dept.PlatformDeptService;
import cn.iocoder.yudao.module.platform.service.dept.PlatformPostService;
import cn.iocoder.yudao.module.platform.service.permission.PlatformPermissionService;
import cn.iocoder.yudao.module.platform.service.permission.PlatformRoleService;
import cn.iocoder.yudao.module.platform.service.user.PlatformUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.List;
import javax.annotation.Resource;
import javax.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@Tag(name = "管理后台 - 用户个人中心")
@RestController
@RequestMapping("/system/user/profile")
@Validated
@Slf4j
public class PlatformUserProfileController {

    @Resource
    private PlatformUserService platformUserService;
    @Resource
    private PlatformDeptService platformDeptService;
    @Resource
    private PlatformPostService platformPostService;
    @Resource
    private PlatformPermissionService platformPermissionService;
    @Resource
    private PlatformRoleService platformRoleService;

    @GetMapping("/get")
    @Operation(summary = "获得登录用户信息")
    @DataPermission(enable = false) // 关闭数据权限，避免只查看自己时，查询不到部门。
    public CommonResult<UserProfileRespVO> profile() {
        // 获得用户基本信息
        PlatformUserDO user = platformUserService.getUser(getPlatformLoginUserId());
        UserProfileRespVO resp = BeanUtils.toBean(user, UserProfileRespVO.class);
        // 获得用户角色
        List<PlatformRoleDO> userRoles = platformRoleService.getRoleListFromCache(platformPermissionService.getUserRoleIdListByUserId(user.getId()));
        resp.setRoles(BeanUtils.toBean(userRoles, UserProfileRespVO.Role.class));
        // 获得部门信息
        if (user.getDeptId() != null) {
            PlatformDeptDO dept = platformDeptService.getDept(user.getDeptId());
            resp.setDept(BeanUtils.toBean(dept, UserProfileRespVO.Dept.class));
        }
        // 获得岗位信息
        if (CollUtil.isNotEmpty(user.getPostIds())) {
            List<PlatformPostDO> posts = platformPostService.getPostList(user.getPostIds());
            resp.setPosts(BeanUtils.toBean(posts, UserProfileRespVO.Post.class));
        }
        return success(resp);
    }

    @PutMapping("/update")
    @Operation(summary = "修改用户个人信息")
    public CommonResult<Boolean> updateUserProfile(@Valid @RequestBody UserProfileUpdateReqVO reqVO) {
        platformUserService.updateUserProfile(getPlatformLoginUserId(), reqVO);
        return success(true);
    }

    @PutMapping("/update-password")
    @Operation(summary = "修改用户个人密码")
    public CommonResult<Boolean> updateUserProfilePassword(@Valid @RequestBody UserProfileUpdatePasswordReqVO reqVO) {
        platformUserService.updateUserPassword(getPlatformLoginUserId(), reqVO);
        return success(true);
    }

    @RequestMapping(value = "/update-avatar", method = {RequestMethod.POST, RequestMethod.PUT}) // 解决 uni-app 不支持 Put 上传文件的问题
    @Operation(summary = "上传用户个人头像")
    public CommonResult<String> updateUserAvatar(@RequestParam("avatarFile") MultipartFile file) throws Exception {
        if (file.isEmpty()) {
            throw exception(FILE_IS_EMPTY);
        }
        String avatar = platformUserService.updateUserAvatar(getPlatformLoginUserId(), file.getInputStream());
        return success(avatar);
    }

}
