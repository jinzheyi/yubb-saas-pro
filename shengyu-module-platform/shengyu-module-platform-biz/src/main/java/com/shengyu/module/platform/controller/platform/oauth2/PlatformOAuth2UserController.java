package com.shengyu.module.platform.controller.platform.oauth2;

import static com.shengyu.framework.common.pojo.CommonResult.success;
import static com.shengyu.framework.security.core.util.SecurityFrameworkUtils.getPlatformLoginUserId;

import cn.hutool.core.collection.CollUtil;
import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.module.platform.controller.platform.dept.vo.post.UserPostRespVO;
import com.shengyu.module.platform.controller.platform.oauth2.vo.user.OAuth2UserInfoRespVO;
import com.shengyu.module.platform.controller.platform.oauth2.vo.user.OAuth2UserUpdateReqVO;
import com.shengyu.module.platform.controller.platform.user.vo.profile.UserProfileUpdateReqVO;
import com.shengyu.module.platform.dal.dataobject.dept.PlatformDeptDO;
import com.shengyu.module.platform.dal.dataobject.dept.PlatformPostDO;
import com.shengyu.module.platform.dal.dataobject.user.PlatformUserDO;
import com.shengyu.module.platform.service.dept.PlatformDeptService;
import com.shengyu.module.platform.service.dept.PlatformPostService;
import com.shengyu.module.platform.service.user.PlatformUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;

import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;
import javax.annotation.Resource;
import javax.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 提供给外部应用调用为主
 *
 * 1. 在 getUserInfo 方法上，添加 @PreAuthorize("@ps.hasScope('user.read')") 注解，声明需要满足 scope = user.read
 * 2. 在 updateUserInfo 方法上，添加 @PreAuthorize("@ps.hasScope('user.write')") 注解，声明需要满足 scope = user.write
 *
 * @author 圣钰科技
 */
@Tag(name = "管理后台 - OAuth2.0 用户")
@RestController
@RequestMapping("/system/oauth2/user")
@Validated
@Slf4j
public class PlatformOAuth2UserController {

    @Resource
    private PlatformUserService platformUserService;
    @Resource
    private PlatformDeptService platformDeptService;
    @Resource
    private PlatformPostService platformPostService;

    @GetMapping("/get")
    @Operation(summary = "获得用户基本信息")
    @PreAuthorize("@ps.hasScope('user.read')") //
    public CommonResult<OAuth2UserInfoRespVO> getUserInfo() {
        // 获得用户基本信息
        PlatformUserDO user = platformUserService.getUser(getPlatformLoginUserId());
        OAuth2UserInfoRespVO resp = BeanUtils.toBean(user, OAuth2UserInfoRespVO.class);
        // 获得部门信息
        if (user.getDeptId() != null) {
            PlatformDeptDO dept = platformDeptService.getDept(user.getDeptId());
            resp.setDept(BeanUtils.toBean(dept, OAuth2UserInfoRespVO.Dept.class));
        }
        // 获得岗位信息
        List<UserPostRespVO> userPostRespVOList = platformPostService.getUserPostMap(Collections.singleton(user.getId())).get(user.getId());
        if (CollUtil.isNotEmpty(userPostRespVOList)) {
            List<PlatformPostDO> posts = platformPostService.getPostList(userPostRespVOList.stream().map(UserPostRespVO::getPostId).collect(Collectors.toSet()));
            resp.setPosts(BeanUtils.toBean(posts, OAuth2UserInfoRespVO.Post.class));
        }
        return success(resp);
    }

    @PutMapping("/update")
    @Operation(summary = "更新用户基本信息")
    @PreAuthorize("@ps.hasScope('user.write')")
    public CommonResult<Boolean> updateUserInfo(@Valid @RequestBody OAuth2UserUpdateReqVO reqVO) {
        // 这里将 UserProfileUpdateReqVO =》UserProfileUpdateReqVO 对象，实现接口的复用。
        // 主要是，AdminUserService 没有自己的 BO 对象，所以复用只能这么做
        platformUserService.updateUserProfile(getPlatformLoginUserId(), BeanUtils.toBean(reqVO,
          UserProfileUpdateReqVO.class));
        return success(true);
    }

}
