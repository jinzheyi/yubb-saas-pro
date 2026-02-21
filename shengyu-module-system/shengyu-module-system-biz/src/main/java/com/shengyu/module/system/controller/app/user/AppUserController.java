package com.shengyu.module.system.controller.app.user;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.util.StrUtil;
import com.shengyu.framework.common.enums.CommonStatusEnum;
import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.module.system.controller.admin.user.vo.user.UserPageReqVO;
import com.shengyu.module.system.controller.admin.user.vo.user.UserRespVO;
import com.shengyu.module.system.controller.app.user.vo.AppUserDetailRespVO;
import com.shengyu.module.system.controller.app.user.vo.AppUserListReqVO;
import com.shengyu.module.system.controller.app.user.vo.AppUserSimpleRespVO;
import com.shengyu.module.system.controller.admin.dept.vo.dept.UserDeptRespVO;
import com.shengyu.module.system.controller.admin.dept.vo.post.UserPostRespVO;
import com.shengyu.module.system.convert.user.UserConvert;
import com.shengyu.module.system.dal.dataobject.user.AdminUserDO;
import com.shengyu.module.system.service.dept.DeptService;
import com.shengyu.module.system.service.dept.PostService;
import com.shengyu.module.system.service.user.AdminUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import java.util.*;
import java.util.stream.Collectors;

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

        // 2. 拼接岗位数据（参考 PC 端逻辑）
        List<UserPostRespVO> userPostRespVOList = postService.getUserPostMap(Collections.singleton(user.getId())).get(user.getId());
        if (CollUtil.isNotEmpty(userPostRespVOList)) {
            user.setPostIds(userPostRespVOList.stream().map(UserPostRespVO::getPostId).collect(Collectors.toSet()));
        }

        // 3. 拼接部门数据（参考 PC 端逻辑）
        List<UserDeptRespVO> userDeptList = deptService.getUserDeptMap(Collections.singleton(user.getId())).get(user.getId());

        // 4. 转换为移动端VO
        AppUserDetailRespVO respVO = new AppUserDetailRespVO();
        respVO.setId(user.getId());
        respVO.setNickname(user.getNickname());
        respVO.setMobile(user.getMobile());
        respVO.setEmail(user.getEmail());
        respVO.setAvatar(user.getAvatar());
        respVO.setSex(user.getSex());
        respVO.setDeptId(user.getDeptId());
        respVO.setRemark(user.getRemark());

        // 5. 构建部门层级路径（使用 > 分隔）
        if (CollUtil.isNotEmpty(userDeptList)) {
            String deptPath = userDeptList.stream()
                    .map(this::buildDeptPath)
                    .collect(Collectors.joining(", "));
            respVO.setDeptName(deptPath);
        }

        // 6. 获取岗位名称（多个岗位用逗号分隔）
        if (CollUtil.isNotEmpty(userPostRespVOList)) {
            String postNames = userPostRespVOList.stream()
                    .map(UserPostRespVO::getName)
                    .collect(Collectors.joining(", "));
            respVO.setPostName(postNames);
        }

        return success(respVO);
    }

    @GetMapping("/get-profile")
    @Operation(summary = "获取当前用户详情")
    public CommonResult<AppUserDetailRespVO> getCurrentUserDetail() {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return getUserDetail(userId);
    }

    @GetMapping("/list")
    @Operation(summary = "获取用户列表（按部门）")
    public CommonResult<List<AppUserSimpleRespVO>> getUserList(AppUserListReqVO reqVO) {
        // 1. 构建查询条件
        UserPageReqVO pageReqVO = new UserPageReqVO();
        pageReqVO.setDeptId(reqVO.getDeptId());
        pageReqVO.setStatus(reqVO.getStatus() != null ? reqVO.getStatus() : CommonStatusEnum.ENABLE.getStatus());
        pageReqVO.setPageSize(1000); // 移动端不分页，一次性返回所有数据
        
        // 2. 支持关键词搜索（姓名或手机号）
        if (StrUtil.isNotBlank(reqVO.getKeyword())) {
            // 先按手机号搜索
            pageReqVO.setMobile(reqVO.getKeyword());
        }
        
        // 3. 查询用户列表
        List<UserRespVO> userList = userService.getUserPage(pageReqVO).getList();
        
        // 4. 如果按手机号没找到，再按用户名搜索
        if (CollUtil.isEmpty(userList) && StrUtil.isNotBlank(reqVO.getKeyword())) {
            pageReqVO.setMobile(null);
            pageReqVO.setUsername(reqVO.getKeyword());
            userList = userService.getUserPage(pageReqVO).getList();
        }
        
        if (CollUtil.isEmpty(userList)) {
            return success(Collections.emptyList());
        }
        
        // 5. 获取用户ID集合
        Set<Long> userIds = userList.stream().map(UserRespVO::getId).collect(Collectors.toSet());
        
        // 6. 批量获取部门信息
        Map<Long, List<UserDeptRespVO>> userDeptMap = deptService.getUserDeptMap(userIds);
        
        // 7. 批量获取岗位信息
        Map<Long, List<UserPostRespVO>> userPostMap = postService.getUserPostMap(userIds);
        
        // 8. 转换为移动端VO
        List<AppUserSimpleRespVO> result = userList.stream().map(user -> {
            AppUserSimpleRespVO vo = new AppUserSimpleRespVO();
            vo.setId(user.getId());
            vo.setNickname(user.getNickname());
            vo.setAvatar(user.getAvatar());
            vo.setMobile(user.getMobile());
            vo.setEmail(user.getEmail());
            vo.setSex(user.getSex());
            vo.setDeptId(user.getDeptId());
            vo.setStatus(user.getStatus());
            
            // 构建部门层级路径
            List<UserDeptRespVO> deptList = userDeptMap.get(user.getId());
            if (CollUtil.isNotEmpty(deptList)) {
                String deptPath = deptList.stream()
                        .map(this::buildDeptPath)
                        .collect(Collectors.joining(", "));
                vo.setDeptName(deptPath);
            }
            
            // 获取岗位名称（多个岗位用逗号分隔）
            List<UserPostRespVO> postList = userPostMap.get(user.getId());
            if (CollUtil.isNotEmpty(postList)) {
                String postNames = postList.stream()
                        .map(UserPostRespVO::getName)
                        .collect(Collectors.joining(", "));
                vo.setPostName(postNames);
            }
            
            return vo;
        }).collect(Collectors.toList());
        
        return success(result);
    }

    /**
     * 构建部门层级路径
     * 例如：一级部门 > 二级部门 > 三级部门
     */
    private String buildDeptPath(UserDeptRespVO userDept) {
        if (userDept == null || userDept.getDeptId() == null) {
            return "";
        }

        List<String> deptNames = new java.util.ArrayList<>();
        Long currentDeptId = userDept.getDeptId();

        // 从当前部门向上遍历到根部门
        while (currentDeptId != null && currentDeptId != 0) {
            com.shengyu.module.system.dal.dataobject.dept.DeptDO dept = deptService.getDept(currentDeptId);
            if (dept == null) {
                break;
            }
            deptNames.add(0, dept.getName()); // 添加到列表开头，保持从上到下的顺序
            currentDeptId = dept.getParentId();
        }

        return String.join(" > ", deptNames);
    }

}
