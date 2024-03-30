package cn.iocoder.yudao.module.system.controller.admin.oauth2;

import static cn.iocoder.yudao.framework.common.pojo.CommonResult.success;
import static cn.iocoder.yudao.framework.security.core.util.SecurityFrameworkUtils.getLoginUserId;

import cn.hutool.core.collection.CollUtil;
import cn.iocoder.yudao.framework.common.pojo.CommonResult;
import cn.iocoder.yudao.framework.common.util.object.BeanUtils;
import cn.iocoder.yudao.module.system.controller.admin.oauth2.vo.user.OAuth2UserInfoRespVO;
import cn.iocoder.yudao.module.system.controller.admin.oauth2.vo.user.OAuth2UserUpdateReqVO;
import cn.iocoder.yudao.module.system.controller.admin.user.vo.profile.UserProfileUpdateReqVO;
import cn.iocoder.yudao.module.system.controller.admin.user.vo.user.UserRespVO;
import cn.iocoder.yudao.module.system.dal.dataobject.dept.DeptDO;
import cn.iocoder.yudao.module.system.dal.dataobject.dept.PostDO;
import cn.iocoder.yudao.module.system.dal.dataobject.user.AdminUserDO;
import cn.iocoder.yudao.module.system.service.dept.DeptService;
import cn.iocoder.yudao.module.system.service.dept.PostService;
import cn.iocoder.yudao.module.system.service.user.AdminUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.List;
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
 * 1. 在 getUserInfo 方法上，添加 @PreAuthorize("@ss.hasScope('user.read')") 注解，声明需要满足 scope = user.read
 * 2. 在 updateUserInfo 方法上，添加 @PreAuthorize("@ss.hasScope('user.write')") 注解，声明需要满足 scope = user.write
 *
 * @author 圣钰科技
 */
@Tag(name = "管理后台 - OAuth2.0 用户")
@RestController
@RequestMapping("/system/oauth2/user")
@Validated
@Slf4j
public class OAuth2UserController {

    @Resource
    private AdminUserService adminUserService;
    @Resource
    private DeptService deptService;
    @Resource
    private PostService postService;

    @GetMapping("/get")
    @Operation(summary = "获得用户基本信息")
    @PreAuthorize("@ss.hasScope('user.read')") //
    public CommonResult<OAuth2UserInfoRespVO> getUserInfo() {
        // 获得用户基本信息
        UserRespVO user = adminUserService.getUser(getLoginUserId());
        OAuth2UserInfoRespVO resp = BeanUtils.toBean(user, OAuth2UserInfoRespVO.class);
        // 获得部门信息
        if (user.getDeptId() != null) {
            DeptDO dept = deptService.getDept(user.getDeptId());
            resp.setDept(BeanUtils.toBean(dept, OAuth2UserInfoRespVO.Dept.class));
        }
        // 获得岗位信息
        if (CollUtil.isNotEmpty(user.getPostIds())) {
            List<PostDO> posts = postService.getPostList(user.getPostIds());
            resp.setPosts(BeanUtils.toBean(posts, OAuth2UserInfoRespVO.Post.class));
        }
        return success(resp);
    }

    @PutMapping("/update")
    @Operation(summary = "更新用户基本信息")
    @PreAuthorize("@ss.hasScope('user.write')")
    public CommonResult<Boolean> updateUserInfo(@Valid @RequestBody OAuth2UserUpdateReqVO reqVO) {
        // 这里将 UserProfileUpdateReqVO =》UserProfileUpdateReqVO 对象，实现接口的复用。
        // 主要是，AdminUserService 没有自己的 BO 对象，所以复用只能这么做
        //todo 修改邮箱或手机号需要发送邮件或短信进行验证
        adminUserService.updateUserProfile(getLoginUserId(), BeanUtils.toBean(reqVO, UserProfileUpdateReqVO.class));
        return success(true);
    }

}
