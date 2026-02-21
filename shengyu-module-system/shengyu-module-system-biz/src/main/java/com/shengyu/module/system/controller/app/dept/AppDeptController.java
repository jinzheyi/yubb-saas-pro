package com.shengyu.module.system.controller.app.dept;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.util.StrUtil;
import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.common.util.object.BeanUtils;
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
    @Operation(summary = "获取我的部门树", description = "获取当前用户所属的所有部门树形结构")
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
        
        // 6. 查询用户所属部门的成员（只查询用户直接所属的部门）
        Map<Long, List<AdminUserDO>> deptUsersMap = new HashMap<>();
        for (Long deptId : userDeptIds) {
            List<UserDeptDO> deptUsers = userDeptMapper.selectListByDeptIds(Collections.singletonList(deptId));
            if (CollUtil.isNotEmpty(deptUsers)) {
                List<Long> userIds = deptUsers.stream()
                        .map(UserDeptDO::getUserId)
                        .collect(Collectors.toList());
                List<AdminUserDO> users = adminUserService.getUserList(userIds);
                deptUsersMap.put(deptId, users);
            }
        }
        
        // 7. 获取所有用户的岗位信息
        Set<Long> allUserIds = deptUsersMap.values().stream()
                .flatMap(List::stream)
                .map(AdminUserDO::getId)
                .collect(Collectors.toSet());
        Map<Long, List<UserPostRespVO>> userPostMap = postService.getUserPostMap(allUserIds);
        
        // 8. 获取部门名称映射
        Map<Long, DeptDO> deptMap = allDeptsMap;
        
        // 9. 转换为VO
        List<AppDeptTreeRespVO> result = new ArrayList<>();
        for (DeptDO dept : allDeptsMap.values()) {
            AppDeptTreeRespVO vo = BeanUtils.toBean(dept, AppDeptTreeRespVO.class);
            
            // 只有用户直接所属的部门才添加成员列表
            if (userDeptIds.contains(dept.getId())) {
                List<AdminUserDO> users = deptUsersMap.get(dept.getId());
                if (CollUtil.isNotEmpty(users)) {
                    List<AppUserSimpleRespVO> userVOs = users.stream().map(user -> {
                        AppUserSimpleRespVO userVO = BeanUtils.toBean(user, AppUserSimpleRespVO.class);
                        
                        // 设置部门信息
                        if (user.getDeptId() != null) {
                            DeptDO userDept = deptMap.get(user.getDeptId());
                            if (userDept != null) {
                                userVO.setDeptName(userDept.getName());
                            }
                        }
                        
                        // 设置岗位信息（取第一个岗位名称）
                        List<UserPostRespVO> userPosts = userPostMap.get(user.getId());
                        if (CollUtil.isNotEmpty(userPosts)) {
                            userVO.setPostName(userPosts.get(0).getName());
                        }
                        
                        return userVO;
                    }).collect(Collectors.toList());
                    
                    vo.setUsers(userVOs);
                }
            }
            
            result.add(vo);
        }
        
        // 10. 按照层级排序：先按parentId分组，然后按sort排序
        result.sort(Comparator
                .comparing(AppDeptTreeRespVO::getParentId, Comparator.nullsFirst(Long::compareTo))
                .thenComparing(AppDeptTreeRespVO::getSort, Comparator.nullsFirst(Integer::compareTo))
                .thenComparing(AppDeptTreeRespVO::getId));
        
        return success(result);
    }

    @GetMapping("/org-tree")
    @Operation(summary = "获取组织结构树", description = "获取完整的组织结构树，包含所有部门和成员")
    public CommonResult<List<AppDeptTreeRespVO>> getOrgTree(@RequestParam(value = "keyword", required = false) String keyword) {
        // 1. 获取所有部门
        List<DeptDO> allDepts = deptService.getDeptList(new DeptListReqVO());
        if (CollUtil.isEmpty(allDepts)) {
            return success(new ArrayList<>());
        }
        
        // 2. 查询每个部门的成员
        Map<Long, List<AdminUserDO>> deptUsersMap = new HashMap<>();
        Set<Long> matchedDeptIds = new HashSet<>(); // 记录包含匹配用户的部门
        
        for (DeptDO dept : allDepts) {
            List<UserDeptDO> deptUsers = userDeptMapper.selectListByDeptIds(Collections.singletonList(dept.getId()));
            if (CollUtil.isNotEmpty(deptUsers)) {
                List<Long> userIds = deptUsers.stream()
                        .map(UserDeptDO::getUserId)
                        .collect(Collectors.toList());
                List<AdminUserDO> users = adminUserService.getUserList(userIds);
                
                // 如果有搜索关键词，过滤用户
                if (StrUtil.isNotBlank(keyword)) {
                    users = users.stream()
                            .filter(user -> StrUtil.containsIgnoreCase(user.getNickname(), keyword))
                            .collect(Collectors.toList());
                    
                    // 如果过滤后还有用户，记录这个部门
                    if (CollUtil.isNotEmpty(users)) {
                        matchedDeptIds.add(dept.getId());
                    }
                }
                
                if (CollUtil.isNotEmpty(users)) {
                    deptUsersMap.put(dept.getId(), users);
                }
            }
        }
        
        // 3. 如果有搜索关键词，只返回包含匹配用户的部门及其父级部门
        List<DeptDO> filteredDepts = allDepts;
        if (StrUtil.isNotBlank(keyword) && CollUtil.isNotEmpty(matchedDeptIds)) {
            Set<Long> deptIdsToShow = new HashSet<>(matchedDeptIds);
            
            // 创建部门ID到部门对象的映射，方便快速查找
            Map<Long, DeptDO> deptIdMap = allDepts.stream()
                    .collect(Collectors.toMap(DeptDO::getId, dept -> dept));
            
            // 添加所有匹配部门的父级部门
            for (Long deptId : matchedDeptIds) {
                DeptDO dept = deptIdMap.get(deptId);
                if (dept != null) {
                    // 向上遍历添加所有父级部门
                    Long currentParentId = dept.getParentId();
                    while (currentParentId != null && currentParentId != 0) {
                        deptIdsToShow.add(currentParentId);
                        DeptDO parentDept = deptIdMap.get(currentParentId);
                        if (parentDept != null) {
                            currentParentId = parentDept.getParentId();
                        } else {
                            break;
                        }
                    }
                }
            }
            
            filteredDepts = allDepts.stream()
                    .filter(dept -> deptIdsToShow.contains(dept.getId()))
                    .collect(Collectors.toList());
        }
        
        // 4. 获取所有用户的岗位信息
        Set<Long> allUserIds = deptUsersMap.values().stream()
                .flatMap(List::stream)
                .map(AdminUserDO::getId)
                .collect(Collectors.toSet());
        Map<Long, List<UserPostRespVO>> userPostMap = postService.getUserPostMap(allUserIds);
        
        // 5. 创建部门映射
        Map<Long, DeptDO> deptMap = filteredDepts.stream()
                .collect(Collectors.toMap(DeptDO::getId, dept -> dept));
        
        // 6. 转换为VO
        List<AppDeptTreeRespVO> result = new ArrayList<>();
        for (DeptDO dept : filteredDepts) {
            AppDeptTreeRespVO vo = BeanUtils.toBean(dept, AppDeptTreeRespVO.class);
            
            // 添加成员列表
            List<AdminUserDO> users = deptUsersMap.get(dept.getId());
            if (CollUtil.isNotEmpty(users)) {
                List<AppUserSimpleRespVO> userVOs = users.stream().map(user -> {
                    AppUserSimpleRespVO userVO = BeanUtils.toBean(user, AppUserSimpleRespVO.class);
                    
                    // 设置部门信息
                    if (user.getDeptId() != null) {
                        DeptDO userDept = deptMap.get(user.getDeptId());
                        if (userDept != null) {
                            userVO.setDeptName(userDept.getName());
                        }
                    }
                    
                    // 设置岗位信息（取第一个岗位名称）
                    List<UserPostRespVO> userPosts = userPostMap.get(user.getId());
                    if (CollUtil.isNotEmpty(userPosts)) {
                        userVO.setPostName(userPosts.get(0).getName());
                    }
                    
                    return userVO;
                }).collect(Collectors.toList());
                
                vo.setUsers(userVOs);
            }
            
            result.add(vo);
        }
        
        // 7. 按照层级排序：先按parentId分组，然后按sort排序
        result.sort(Comparator
                .comparing(AppDeptTreeRespVO::getParentId, Comparator.nullsFirst(Long::compareTo))
                .thenComparing(AppDeptTreeRespVO::getSort, Comparator.nullsFirst(Integer::compareTo))
                .thenComparing(AppDeptTreeRespVO::getId));
        
        return success(result);
    }

}
