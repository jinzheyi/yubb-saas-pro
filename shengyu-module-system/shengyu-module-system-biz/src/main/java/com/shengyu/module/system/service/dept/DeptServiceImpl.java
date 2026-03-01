package com.shengyu.module.system.service.dept;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.util.ObjectUtil;
import com.baomidou.mybatisplus.core.toolkit.CollectionUtils;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.google.common.annotations.VisibleForTesting;
import com.shengyu.framework.common.enums.CommonStatusEnum;
import com.shengyu.framework.common.enums.dept.DeptIdEnum;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.framework.datapermission.core.annotation.DataPermission;
import com.shengyu.module.system.controller.admin.dept.vo.dept.DeptListReqVO;
import com.shengyu.module.system.controller.admin.dept.vo.dept.DeptRespVO;
import com.shengyu.module.system.controller.admin.dept.vo.dept.DeptSaveReqVO;
import com.shengyu.module.system.controller.admin.dept.vo.dept.UserDeptRespVO;
import com.shengyu.module.system.controller.admin.user.vo.user.UserRespVO;
import com.shengyu.module.system.dal.dataobject.dept.DeptDO;
import com.shengyu.module.system.dal.mysql.dept.DeptMapper;
import com.shengyu.module.system.dal.mysql.dept.UserDeptMapper;
import com.shengyu.module.system.dal.mysql.user.AdminUserMapper;
import com.shengyu.module.system.dal.redis.RedisKeyConstants;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

import javax.annotation.Resource;
import java.util.*;
import java.util.function.Function;
import java.util.stream.Collectors;

import static com.shengyu.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.shengyu.framework.common.util.collection.CollectionUtils.convertSet;
import static com.shengyu.module.system.enums.ErrorCodeConstants.*;

/**
 * 部门 Service 实现类
 *
 * @author 圣钰科技
 */
@Service
@Validated
@Slf4j
public class DeptServiceImpl implements DeptService {

    @Resource
    private DeptMapper deptMapper;

    @Resource
    private AdminUserMapper adminUserMapper;

    @Resource
    private UserDeptMapper userDeptMapper;

    @Override
    @CacheEvict(cacheNames = RedisKeyConstants.DEPT_CHILDREN_ID_LIST,
            allEntries = true) // allEntries 清空所有缓存，因为操作一个部门，涉及到多个缓存
    public Long createDept(DeptSaveReqVO createReqVO) {
        if (createReqVO.getParentId() == null) {
            createReqVO.setParentId(DeptIdEnum.ROOT.getId());
        }
        // 校验父部门的有效性
        validateParentDept(null, createReqVO.getParentId());
        // 校验部门名的唯一性
        validateDeptNameUnique(null, createReqVO.getParentId(), createReqVO.getName());

        // 插入部门
        DeptDO dept = BeanUtils.toBean(createReqVO, DeptDO.class);
        deptMapper.insert(dept);
        return dept.getId();
    }

    @Override
    @CacheEvict(cacheNames = RedisKeyConstants.DEPT_CHILDREN_ID_LIST,
            allEntries = true) // allEntries 清空所有缓存，因为操作一个部门，涉及到多个缓存
    public void updateDept(DeptSaveReqVO updateReqVO) {
        if (updateReqVO.getParentId() == null) {
            updateReqVO.setParentId(DeptIdEnum.ROOT.getId());
        }
        // 校验自己存在
        validateDeptExists(updateReqVO.getId());
        // 校验父部门的有效性
        validateParentDept(updateReqVO.getId(), updateReqVO.getParentId());
        // 校验部门名的唯一性
        validateDeptNameUnique(updateReqVO.getId(), updateReqVO.getParentId(), updateReqVO.getName());

        // 更新部门
        DeptDO updateObj = BeanUtils.toBean(updateReqVO, DeptDO.class);
        deptMapper.updateById(updateObj);
    }

    @Override
    @CacheEvict(cacheNames = RedisKeyConstants.DEPT_CHILDREN_ID_LIST,
            allEntries = true) // allEntries 清空所有缓存，因为操作一个部门，涉及到多个缓存
    public void deleteDept(Long id) {
        // 校验是否存在
        validateDeptExists(id);
        // 校验是否有子部门
        if (deptMapper.selectCountByParentId(id) > 0) {
            throw exception(DEPT_EXITS_CHILDREN);
        }
        // 删除部门
        deptMapper.deleteById(id);
    }

    @VisibleForTesting
    void validateDeptExists(Long id) {
        if (id == null) {
            return;
        }
        DeptDO dept = deptMapper.selectById(id);
        if (dept == null) {
            throw exception(DEPT_NOT_FOUND);
        }
    }

    @VisibleForTesting
    void validateParentDept(Long id, Long parentId) {
        if (parentId == null || DeptIdEnum.ROOT.getId().equals(parentId)) {
            return;
        }
        // 1. 不能设置自己为父部门
        if (Objects.equals(id, parentId)) {
            throw exception(DEPT_PARENT_ERROR);
        }
        // 2. 父部门不存在
        DeptDO parentDept = deptMapper.selectById(parentId);
        if (parentDept == null) {
            throw exception(DEPT_PARENT_NOT_EXITS);
        }
        // 3. 递归校验父部门，如果父部门是自己的子部门，则报错，避免形成环路
        if (id == null) { // id 为空，说明新增，不需要考虑环路
            return;
        }
        for (int i = 0; i < Short.MAX_VALUE; i++) {
            // 3.1 校验环路
            parentId = parentDept.getParentId();
            if (Objects.equals(id, parentId)) {
                throw exception(DEPT_PARENT_IS_CHILD);
            }
            // 3.2 继续递归下一级父部门
            if (parentId == null || DeptIdEnum.ROOT.getId().equals(parentId)) {
                break;
            }
            parentDept = deptMapper.selectById(parentId);
            if (parentDept == null) {
                break;
            }
        }
    }

    @VisibleForTesting
    void validateDeptNameUnique(Long id, Long parentId, String name) {
        DeptDO dept = deptMapper.selectByParentIdAndName(parentId, name);
        if (dept == null) {
            return;
        }
        // 如果 id 为空，说明不用比较是否为相同 id 的部门
        if (id == null) {
            throw exception(DEPT_NAME_DUPLICATE);
        }
        if (ObjectUtil.notEqual(dept.getId(), id)) {
            throw exception(DEPT_NAME_DUPLICATE);
        }
    }

    @Override
    public DeptDO getDept(Long id) {
        return deptMapper.selectById(id);
    }

    @Override
    public List<DeptDO> getDeptList(Collection<Long> ids) {
        if (CollUtil.isEmpty(ids)) {
            return Collections.emptyList();
        }
        return deptMapper.selectBatchIds(ids);
    }

    @Override
    public List<DeptDO> getDeptList(DeptListReqVO reqVO) {
        List<DeptDO> list = deptMapper.selectList(reqVO);
        list.sort(Comparator.comparing(DeptDO::getSort));
        return list;
    }

    @Override
    public List<DeptRespVO> listTree(DeptListReqVO reqVO) {
        List<DeptDO> sysDepartmentList = deptMapper.selectList(reqVO);
        if (CollectionUtils.isEmpty(sysDepartmentList)) {
            return null;
        }
        return sysDepartmentList.stream().filter(e -> Objects.equals(0L, e.getParentId())).map(e -> {
            DeptRespVO vo = BeanUtils.toBean(e, DeptRespVO.class);
            vo.setPid(vo.getParentId());
            vo.setHeadId(vo.getLeaderUserId());
            if (Objects.nonNull(vo.getLeaderUserId())) {
                Optional.ofNullable(adminUserMapper.selectById(vo.getLeaderUserId())).ifPresent(user -> vo.setHeadName(user.getNickname()));
            }
            vo.setChildren(this.getChild(vo.getId(), vo.getName(), sysDepartmentList));
            return vo;
        }).collect(Collectors.toList());
    }

    /**
     * 获取子节点
     */
    private List<DeptRespVO> getChild(Long id, String parentName, List<DeptDO> sysDepartmentList) {
        // 遍历所有节点，将所有菜单的父id与传过来的根节点的id比较
        List<DeptDO> childList = sysDepartmentList.stream().filter(e -> Objects.equals(id, e.getParentId())).collect(Collectors.toList());
        if (childList.isEmpty()) {
            // 没有子节点，返回一个空 List（递归退出）
            return null;
        }
        // 递归
        return childList.stream().map(e -> {
            DeptRespVO vo = BeanUtils.toBean(e, DeptRespVO.class);
            vo.setParentName(parentName);
            vo.setPid(vo.getParentId());
            vo.setHeadId(vo.getLeaderUserId());
            if (Objects.nonNull(vo.getLeaderUserId())) {
                Optional.ofNullable(adminUserMapper.selectById(vo.getLeaderUserId())).ifPresent(user -> vo.setHeadName(user.getNickname()));
            }
            vo.setChildren(this.getChild(vo.getId(), vo.getName(), sysDepartmentList));
            return vo;
        }).collect(Collectors.toList());
    }

    @Override
    @DataPermission(enable = false)
    public Map<Long, List<UserDeptRespVO>> getUserDeptMap(Collection<Long> ids) {
        if (CollUtil.isEmpty(ids)) {
            return Collections.emptyMap();
        }
        List<UserDeptRespVO> userDeptRespVOList = userDeptMapper.selectListByUserIds(ids);
        if (CollUtil.isEmpty(userDeptRespVOList)) {
            return Collections.emptyMap();
        }
       return userDeptRespVOList.stream()
                .collect(Collectors.groupingBy(UserDeptRespVO::getUserId));
    }

    @Override
    public List<DeptDO> getChildDeptList(Long id) {
        List<DeptDO> children = new LinkedList<>();
        // 遍历每一层
        Collection<Long> parentIds = Collections.singleton(id);
        for (int i = 0; i < Short.MAX_VALUE; i++) { // 使用 Short.MAX_VALUE 避免 bug 场景下，存在死循环
            // 查询当前层，所有的子部门
            List<DeptDO> depts = deptMapper.selectListByParentId(parentIds);
            // 1. 如果没有子部门，则结束遍历
            if (CollUtil.isEmpty(depts)) {
                break;
            }
            // 2. 如果有子部门，继续遍历
            children.addAll(depts);
            parentIds = convertSet(depts, DeptDO::getId);
        }
        return children;
    }

    @Override
    @DataPermission(enable = false) // 禁用数据权限，避免建立不正确的缓存
    @Cacheable(cacheNames = RedisKeyConstants.DEPT_CHILDREN_ID_LIST, key = "#id")
    public Set<Long> getChildDeptIdListFromCache(Long id) {
        List<DeptDO> children = getChildDeptList(id);
        return convertSet(children, DeptDO::getId);
    }

    @Override
    public void validateDeptList(Collection<Long> ids) {
        if (CollUtil.isEmpty(ids)) {
            return;
        }
        // 获得科室信息
        Map<Long, DeptDO> deptMap = getDeptMap(ids);
        // 校验
        ids.forEach(id -> {
            DeptDO dept = deptMap.get(id);
            if (dept == null) {
                throw exception(DEPT_NOT_FOUND);
            }
            if (!CommonStatusEnum.ENABLE.getStatus().equals(dept.getStatus())) {
                throw exception(DEPT_NOT_ENABLE, dept.getName());
            }
        });
    }

     public Map<Long, DeptDO> getDeptMap() {
        return deptMapper.selectList(DeptDO::getStatus, CommonStatusEnum.ENABLE.getStatus()).stream()
                .collect(Collectors.toMap(
                        DeptDO::getId,
                        Function.identity(),
                        (oldValue, newValue) -> newValue  // 冲突时保留新值
                ));
    }

    /**
     * 获取指定部门的所有上级部门负责人
      * @param departmentId 指定部门ID
     * @return 获取指定部门的所有上级部门负责人
     */
    @Override
    public List<UserRespVO> getAllAncestorLeaders(Long departmentId) {
        List<UserRespVO> leaders = new ArrayList<>();
        Map<Long, DeptDO> departmentMap = getDeptMap();
        DeptDO current = departmentMap.get(departmentId);
        if (current == null) {
            return Collections.emptyList();
        }
        if (Objects.nonNull(current.getLeaderUserId())) {
            leaders.add(adminUserMapper.selectJoinOne(current.getLeaderUserId()));
        }
        while (current.getParentId() != null) {
            DeptDO parent = departmentMap.get(current.getParentId());
            if (parent != null) {
                if (Objects.nonNull(parent.getLeaderUserId())) {
                    leaders.add(adminUserMapper.selectJoinOne(parent.getLeaderUserId()));
                }
                current = parent;
            } else {
                break; // Parent not found
            }
        }
        return leaders;
    }

    @Override
    public List<UserRespVO> getAncestorLeadersUpToLevel(Long departmentId, int maxLevels) {
        List<UserRespVO> leaders = new ArrayList<>();
        Map<Long, DeptDO> departmentMap = getDeptMap();
        DeptDO current = departmentMap.get(departmentId);
        if (current == null) {
            return Collections.emptyList();
        }
        if (Objects.nonNull(current.getLeaderUserId())) {
            leaders.add(adminUserMapper.selectJoinOne(current.getLeaderUserId()));
        }
        //因为maxLevels默认等于1，所以这里从1开始计算，避免多算本身自己的部门
        int level = 1;
        while (current.getParentId() != null && level < maxLevels) {
            DeptDO parent = departmentMap.get(current.getParentId());
            if (parent != null) {
                if (Objects.nonNull(parent.getLeaderUserId())) {
                    leaders.add(adminUserMapper.selectJoinOne(parent.getLeaderUserId()));
                }
                current = parent;
                level++;
            } else {
                break; // Parent not found
            }
        }
        return leaders;
    }

}
