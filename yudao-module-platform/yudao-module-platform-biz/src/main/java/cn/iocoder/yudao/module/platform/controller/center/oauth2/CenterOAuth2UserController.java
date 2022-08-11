package cn.iocoder.yudao.module.platform.controller.center.oauth2;

import cn.hutool.core.collection.CollUtil;
import cn.iocoder.yudao.framework.common.pojo.CommonResult;
import cn.iocoder.yudao.module.platform.controller.center.oauth2.vo.user.OAuth2UserInfoRespVO;
import cn.iocoder.yudao.module.platform.controller.center.oauth2.vo.user.OAuth2UserUpdateReqVO;
import cn.iocoder.yudao.module.platform.convert.oauth2.OAuth2UserConvert;
import cn.iocoder.yudao.module.platform.dal.dataobject.dept.PlatformDeptDO;
import cn.iocoder.yudao.module.platform.dal.dataobject.dept.PlatformPostDO;
import cn.iocoder.yudao.module.platform.dal.dataobject.user.PlatformUserDO;
import cn.iocoder.yudao.module.platform.service.dept.PlatformDeptService;
import cn.iocoder.yudao.module.platform.service.dept.PlatformPostService;
import cn.iocoder.yudao.module.platform.service.user.PlatformUserService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.validation.Valid;
import java.util.List;

import static cn.iocoder.yudao.framework.common.pojo.CommonResult.success;
import static cn.iocoder.yudao.framework.security.core.util.SecurityFrameworkUtils.getLoginUserId;

/**
 * 提供给外部应用调用为主
 *
 * 1. 在 getUserInfo 方法上，添加 @PreAuthorize("@ss.hasScope('user.read')") 注解，声明需要满足 scope = user.read
 * 2. 在 updateUserInfo 方法上，添加 @PreAuthorize("@ss.hasScope('user.write')") 注解，声明需要满足 scope = user.write
 *
 * @author 芋道源码
 */
@Api(tags = "管理后台 - OAuth2.0 用户")
@RestController
@RequestMapping("/center/oauth2/user")
@Validated
@Slf4j
public class CenterOAuth2UserController {

    @Resource
    private PlatformUserService userService;
    @Resource
    private PlatformDeptService platformDeptService;
    @Resource
    private PlatformPostService platformPostService;

    @GetMapping("/get")
    @ApiOperation("获得用户基本信息")
    @PreAuthorize("@ss.hasScope('user.read')") //
    public CommonResult<OAuth2UserInfoRespVO> getUserInfo() {
        // 获得用户基本信息
        PlatformUserDO user = userService.getUser(getLoginUserId());
        OAuth2UserInfoRespVO resp = OAuth2UserConvert.INSTANCE.convert(user);
        // 获得部门信息
        if (user.getDeptId() != null) {
            PlatformDeptDO dept = platformDeptService.getDept(user.getDeptId());
            resp.setDept(OAuth2UserConvert.INSTANCE.convert(dept));
        }
        // 获得岗位信息
        if (CollUtil.isNotEmpty(user.getPostIds())) {
            List<PlatformPostDO> posts = platformPostService.getPosts(user.getPostIds());
            resp.setPosts(OAuth2UserConvert.INSTANCE.convertList(posts));
        }
        return success(resp);
    }

    @PutMapping("/update")
    @ApiOperation("更新用户基本信息")
    @PreAuthorize("@ss.hasScope('user.write')")
    public CommonResult<Boolean> updateUserInfo(@Valid @RequestBody OAuth2UserUpdateReqVO reqVO) {
        // 这里将 UserProfileUpdateReqVO =》UserProfileUpdateReqVO 对象，实现接口的复用。
        // 主要是，AdminUserService 没有自己的 BO 对象，所以复用只能这么做
        userService.updateUserProfile(getLoginUserId(), OAuth2UserConvert.INSTANCE.convert(reqVO));
        return success(true);
    }

}
