package cn.iocoder.yudao.module.platform.controller.center.user;

import cn.hutool.core.collection.CollUtil;
import cn.iocoder.yudao.framework.common.enums.UserTypeEnum;
import cn.iocoder.yudao.framework.common.exception.util.ServiceExceptionUtil;
import cn.iocoder.yudao.framework.common.pojo.CommonResult;
import cn.iocoder.yudao.framework.datapermission.core.annotation.DataPermission;
import cn.iocoder.yudao.module.platform.controller.center.user.vo.profile.UserProfileRespVO;
import cn.iocoder.yudao.module.platform.controller.center.user.vo.profile.UserProfileUpdatePasswordReqVO;
import cn.iocoder.yudao.module.platform.controller.center.user.vo.profile.UserProfileUpdateReqVO;
import cn.iocoder.yudao.module.platform.convert.user.UserConvert;
import cn.iocoder.yudao.module.platform.dal.dataobject.dept.PlatformDeptDO;
import cn.iocoder.yudao.module.platform.dal.dataobject.dept.PlatformPostDO;
import cn.iocoder.yudao.module.platform.dal.dataobject.permission.PlatformRoleDO;
import cn.iocoder.yudao.module.platform.dal.dataobject.social.PlatformSocialUserDO;
import cn.iocoder.yudao.module.platform.dal.dataobject.user.PlatformUserDO;
import cn.iocoder.yudao.module.platform.service.dept.PlatformDeptService;
import cn.iocoder.yudao.module.platform.service.dept.PlatformPostService;
import cn.iocoder.yudao.module.platform.service.permission.PlatformPermissionService;
import cn.iocoder.yudao.module.platform.service.permission.PlatformRoleService;
import cn.iocoder.yudao.module.platform.service.social.PlatformSocialUserService;
import cn.iocoder.yudao.module.platform.service.user.PlatformUserService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import lombok.extern.slf4j.Slf4j;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import javax.annotation.Resource;
import javax.validation.Valid;
import java.util.List;

import static cn.iocoder.yudao.framework.common.pojo.CommonResult.success;
import static cn.iocoder.yudao.framework.security.core.util.SecurityFrameworkUtils.getLoginUserId;
import static cn.iocoder.yudao.module.infra.enums.ErrorCodeConstants.FILE_IS_EMPTY;

@Api(tags = "管理后台 - 用户个人中心")
@RestController
@RequestMapping("/center/user/profile")
@Validated
@Slf4j
public class CenterUserProfileController {

    @Resource
    private PlatformUserService userService;
    @Resource
    private PlatformDeptService platformDeptService;
    @Resource
    private PlatformPostService platformPostService;
    @Resource
    private PlatformPermissionService platformPermissionService;
    @Resource
    private PlatformRoleService platformRoleService;
    @Resource
    private PlatformSocialUserService socialService;

    @GetMapping("/get")
    @ApiOperation("获得登录用户信息")
    @DataPermission(enable = false) // 关闭数据权限，避免只查看自己时，查询不到部门。
    public CommonResult<UserProfileRespVO> profile() {
        // 获得用户基本信息
        PlatformUserDO user = userService.getUser(getLoginUserId());
        UserProfileRespVO resp = UserConvert.INSTANCE.convert03(user);
        // 获得用户角色
        List<PlatformRoleDO> userRoles = platformRoleService.getRolesFromCache(platformPermissionService.getUserRoleIdListByUserId(user.getId()));
        resp.setRoles(UserConvert.INSTANCE.convertList(userRoles));
        // 获得部门信息
        if (user.getDeptId() != null) {
            PlatformDeptDO dept = platformDeptService.getDept(user.getDeptId());
            resp.setDept(UserConvert.INSTANCE.convert02(dept));
        }
        // 获得岗位信息
        if (CollUtil.isNotEmpty(user.getPostIds())) {
            List<PlatformPostDO> posts = platformPostService.getPosts(user.getPostIds());
            resp.setPosts(UserConvert.INSTANCE.convertList02(posts));
        }
        // 获得社交用户信息
        List<PlatformSocialUserDO> socialUsers = socialService.getSocialUserList(user.getId(), UserTypeEnum.CENTER.getValue());
        resp.setSocialUsers(UserConvert.INSTANCE.convertList03(socialUsers));
        return success(resp);
    }

    @PutMapping("/update")
    @ApiOperation("修改用户个人信息")
    public CommonResult<Boolean> updateUserProfile(@Valid @RequestBody UserProfileUpdateReqVO reqVO) {
        userService.updateUserProfile(getLoginUserId(), reqVO);
        return success(true);
    }

    @PutMapping("/update-password")
    @ApiOperation("修改用户个人密码")
    public CommonResult<Boolean> updateUserProfilePassword(@Valid @RequestBody UserProfileUpdatePasswordReqVO reqVO) {
        userService.updateUserPassword(getLoginUserId(), reqVO);
        return success(true);
    }

    @RequestMapping(value = "/update-avatar", method = {RequestMethod.POST, RequestMethod.PUT}) // 解决 uni-app 不支持 Put 上传文件的问题
    @ApiOperation("上传用户个人头像")
    public CommonResult<String> updateUserAvatar(@RequestParam("avatarFile") MultipartFile file) throws Exception {
        if (file.isEmpty()) {
            throw ServiceExceptionUtil.exception(FILE_IS_EMPTY);
        }
        String avatar = userService.updateUserAvatar(getLoginUserId(), file.getInputStream());
        return success(avatar);
    }

}
