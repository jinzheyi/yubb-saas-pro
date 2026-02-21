package com.shengyu.module.system.controller.app.dept;

import cn.hutool.core.collection.CollUtil;
import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
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

}
