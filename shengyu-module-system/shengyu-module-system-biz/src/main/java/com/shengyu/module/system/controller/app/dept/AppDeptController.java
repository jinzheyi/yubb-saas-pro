package com.shengyu.module.system.controller.app.dept;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.util.StrUtil;
import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.framework.datapermission.core.annotation.DataPermission;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.module.system.controller.admin.dept.vo.dept.DeptListReqVO;
import com.shengyu.module.system.controller.admin.dept.vo.post.UserPostRespVO;
import com.shengyu.module.system.controller.app.dept.vo.AppDeptTreeRespVO;
import com.shengyu.module.system.controller.app.user.vo.AppUserSimpleRespVO;
import com.shengyu.module.system.dal.dataobject.dept.DeptDO;
import com.shengyu.module.system.dal.dataobject.dept.UserDeptDO;
import com.shengyu.module.system.dal.dataobject.user.AdminUserDO;
import com.shengyu.module.system.dal.mysql.dept.UserDeptMapper;
import com.shengyu.module.system.service.dept.DeptService;
import com.shengyu.module.system.service.dept.PostService;
import com.shengyu.module.system.service.user.AdminUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import java.util.*;
import java.util.stream.Collectors;

import static com.shengyu.framework.common.pojo.CommonResult.success;

/**
 * 移动端 - 部门 Controller
 *
 * @author 圣钰科技
 */
@Tag(name = "移动端 - 部门")
@RestController
@RequestMapping("/system/dept")
@Validated
@DataPermission(enable = false)
public class AppDeptController {

    @Resource
    private DeptService deptService;
    
    @Resource
    private UserDeptMapper userDeptMapper;
    
    @Resource
    private AdminUserService adminUserService;
    
    @Resource
    private PostService postService;

    @GetMapping("/my-dept-tree")
    @Operation(summary = "获取我的部门树", description = "获取当前用户所属的所有部门树形结构（包含成员数量，不包含成员详细数据）")
    public CommonResult<List<AppDeptTreeRespVO>> getMyDeptTree() {
        // 1. 获取当前登录用户
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        
        // 2. 通过用户部门关联表查询用户所属的所有部门
        List<UserDeptDO> userDepts = userDeptMapper.selectListByUserId(userId);
        if (CollUtil.isEmpty(userDepts)) {
            return success(new ArrayList<>());
        }
        
        // 3. 获取用户所属的部门ID集合
        Set<Long> userDeptIds = userDepts.stream()
                .map(UserDeptDO::getDeptId)
                .collect(Collectors.toSet());
        
        // 4. 查询用户所属的部门信息
        List<DeptDO> userDeptList = deptService.getDeptList(userDeptIds);
        if (CollUtil.isEmpty(userDeptList)) {
            return success(new ArrayList<>());
        }
        
        // 5. 收集所有部门及其父级部门
        Map<Long, DeptDO> allDeptsMap = new HashMap<>();
        for (DeptDO dept : userDeptList) {
            allDeptsMap.put(dept.getId(), dept);
            // 向上遍历，收集所有父级部门
            DeptDO currentDept = dept;
            while (currentDept != null && currentDept.getParentId() != null && currentDept.getParentId() != 0) {
                if (!allDeptsMap.containsKey(currentDept.getParentId())) {
                    DeptDO parentDept = deptService.getDept(currentDept.getParentId());
                    if (parentDept != null) {
                        allDeptsMap.put(parentDept.getId(), parentDept);
                        currentDept = parentDept;
                    } else {
                        break;
                    }
                } else {
                    break;
                }
            }
        }
        
        // 6. 查询每个部门的成员数量
        Map<Long, Integer> deptMemberCountMap = new HashMap<>();
        for (Long deptId : allDeptsMap.keySet()) {
            List<UserDeptDO> deptUsers = userDeptMapper.selectListByDeptIds(Collections.singletonList(deptId));
            deptMemberCountMap.put(deptId, CollUtil.isEmpty(deptUsers) ? 0 : deptUsers.size());
        }
        
        // 7. 转换为VO（包含成员数量，不包含用户详细数据）
        List<AppDeptTreeRespVO> result = new ArrayList<>();
        for (DeptDO dept : allDeptsMap.values()) {
            AppDeptTreeRespVO vo = BeanUtils.toBean(dept, AppDeptTreeRespVO.class);
            vo.setMemberCount(deptMemberCountMap.getOrDefault(dept.getId(), 0));
            result.add(vo);
        }
        
        // 8. 按照层级排序
        result.sort(Comparator
                .comparing(AppDeptTreeRespVO::getParentId, Comparator.nullsFirst(Long::compareTo))
                .thenComparing(AppDeptTreeRespVO::getSort, Comparator.nullsFirst(Integer::compareTo))
                .thenComparing(AppDeptTreeRespVO::getId));
        
        return success(result);
    }

    @GetMapping("/dept-members")
    @Operation(summary = "获取部门成员", description = "获取指定部门的成员列表，支持搜索")
    public CommonResult<List<AppUserSimpleRespVO>> getDeptMembers(
            @RequestParam("deptId") Long deptId,
            @RequestParam(value = "keyword", required = false) String keyword) {
        
        // 1. 查询部门成员
        List<UserDeptDO> deptUsers = userDeptMapper.selectListByDeptIds(Collections.singletonList(deptId));
        if (CollUtil.isEmpty(deptUsers)) {
            return success(new ArrayList<>());
        }
        
        // 2. 获取用户ID列表
        List<Long> userIds = deptUsers.stream()
                .map(UserDeptDO::getUserId)
                .collect(Collectors.toList());
        
        // 3. 查询用户信息
        List<AdminUserDO> users = adminUserService.getUserList(userIds);
        
        // 4. 如果有搜索关键词，过滤用户
        if (StrUtil.isNotBlank(keyword)) {
            users = users.stream()
                    .filter(user -> StrUtil.containsIgnoreCase(user.getNickname(), keyword))
                    .collect(Collectors.toList());
        }
        
        if (CollUtil.isEmpty(users)) {
            return success(new ArrayList<>());
        }
        
        // 5. 获取用户的岗位信息
        Set<Long> allUserIds = users.stream()
                .map(AdminUserDO::getId)
                .collect(Collectors.toSet());
        Map<Long, List<UserPostRespVO>> userPostMap = postService.getUserPostMap(allUserIds);
        
        // 6. 查询部门信息用于填充部门名称
        DeptDO dept = deptService.getDept(deptId);
        
        // 7. 转换为VO
        List<AppUserSimpleRespVO> result = users.stream().map(user -> {
            AppUserSimpleRespVO userVO = BeanUtils.toBean(user, AppUserSimpleRespVO.class);
            
            // 设置部门信息
            if (dept != null) {
                userVO.setDeptName(dept.getName());
            }
            
            // 设置岗位信息（取第一个岗位名称）
            List<UserPostRespVO> userPosts = userPostMap.get(user.getId());
            if (CollUtil.isNotEmpty(userPosts)) {
                userVO.setPostName(userPosts.get(0).getName());
            }
            
            return userVO;
        }).collect(Collectors.toList());
        
        return success(result);
    }

    @GetMapping("/org-tree")
    @Operation(summary = "获取组织结构树", description = "获取完整的组织结构树（包含成员数量，不包含成员详细数据）")
    public CommonResult<List<AppDeptTreeRespVO>> getOrgTree() {
        // 1. 获取所有部门
        List<DeptDO> allDepts = deptService.getDeptList(new DeptListReqVO());
        if (CollUtil.isEmpty(allDepts)) {
            return success(new ArrayList<>());
        }
        
        // 2. 查询每个部门的成员数量
        Map<Long, Integer> deptMemberCountMap = new HashMap<>();
        for (DeptDO dept : allDepts) {
            List<UserDeptDO> deptUsers = userDeptMapper.selectListByDeptIds(Collections.singletonList(dept.getId()));
            deptMemberCountMap.put(dept.getId(), CollUtil.isEmpty(deptUsers) ? 0 : deptUsers.size());
        }
        
        // 3. 转换为VO（包含成员数量，不包含用户详细数据）
        List<AppDeptTreeRespVO> result = new ArrayList<>();
        for (DeptDO dept : allDepts) {
            AppDeptTreeRespVO vo = BeanUtils.toBean(dept, AppDeptTreeRespVO.class);
            vo.setMemberCount(deptMemberCountMap.getOrDefault(dept.getId(), 0));
            result.add(vo);
        }
        
        // 4. 按照层级排序：先按parentId分组，然后按sort排序
        result.sort(Comparator
                .comparing(AppDeptTreeRespVO::getParentId, Comparator.nullsFirst(Long::compareTo))
                .thenComparing(AppDeptTreeRespVO::getSort, Comparator.nullsFirst(Integer::compareTo))
                .thenComparing(AppDeptTreeRespVO::getId));
        
        return success(result);
    }

}
