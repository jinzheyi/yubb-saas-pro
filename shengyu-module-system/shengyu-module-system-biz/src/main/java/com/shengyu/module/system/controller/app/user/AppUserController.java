package com.shengyu.module.system.controller.app.user;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.module.system.controller.admin.user.vo.user.UserRespVO;
import com.shengyu.module.system.controller.app.user.vo.AppUserDetailRespVO;
import com.shengyu.module.system.convert.user.UserConvert;
import com.shengyu.module.system.dal.dataobject.dept.DeptDO;
import com.shengyu.module.system.dal.dataobject.dept.PostDO;
import com.shengyu.module.system.service.dept.DeptService;
import com.shengyu.module.system.service.dept.PostService;
import com.shengyu.module.system.service.user.AdminUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import java.util.List;

import static com.shengyu.framework.common.pojo.CommonResult.success;

/**
 * 移动端 - 用户 Controller
 *
 * @author 圣钰科技
 */
@Tag(name = "移动端 - 用户")
@RestController
@RequestMapping("/system/user")
@Validated
public class AppUserController {

    @Resource
    private AdminUserService userService;
    
    @Resource
    private DeptService deptService;
    
    @Resource
    private PostService postService;

    @GetMapping("/get")
    @Operation(summary = "获取用户详情")
    @Parameter(name = "id", description = "用户ID", required = true, example = "1")
    public CommonResult<AppUserDetailRespVO> getUserDetail(@RequestParam("id") Long id) {
        // 1. 获取用户基本信息
        UserRespVO user = userService.getUser(id);
        if (user == null) {
            return success(null);
        }

        // 2. 转换为移动端VO
        AppUserDetailRespVO respVO = new AppUserDetailRespVO();
        respVO.setId(user.getId());
        respVO.setNickname(user.getNickname());
        respVO.setRealName(user.getRealName());
        respVO.setMobile(user.getMobile());
        respVO.setEmail(user.getEmail());
        respVO.setAvatar(user.getAvatar());
        respVO.setSex(user.getSex());
        respVO.setDeptId(user.getDeptId());
        respVO.setDeptName(user.getDeptName());
        respVO.setRemark(user.getRemark());

        // 3. 获取岗位信息
        if (user.getPostIds() != null && !user.getPostIds().isEmpty()) {
            Long firstPostId = user.getPostIds().iterator().next();
            PostDO post = postService.getPost(firstPostId);
            if (post != null) {
                respVO.setPostName(post.getName());
            }
        }

        // 4. 获取公司名称（从部门的顶级部门获取）
        if (user.getDeptId() != null) {
            DeptDO dept = deptService.getDept(user.getDeptId());
            if (dept != null) {
                // 获取顶级部门作为公司名称
                DeptDO topDept = getTopDept(dept);
                if (topDept != null) {
                    respVO.setCompanyName(topDept.getName());
                }
            }
        }

        return success(respVO);
    }

    @GetMapping("/get-profile")
    @Operation(summary = "获取当前用户详情")
    public CommonResult<AppUserDetailRespVO> getCurrentUserDetail() {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return getUserDetail(userId);
    }

    /**
     * 获取顶级部门
     */
    private DeptDO getTopDept(DeptDO dept) {
        if (dept.getParentId() == null || dept.getParentId() == 0) {
            return dept;
        }
        DeptDO parentDept = deptService.getDept(dept.getParentId());
        if (parentDept == null) {
            return dept;
        }
        return getTopDept(parentDept);
    }

}
