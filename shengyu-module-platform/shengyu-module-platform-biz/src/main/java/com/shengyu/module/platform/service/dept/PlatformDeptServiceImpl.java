package com.shengyu.module.platform.service.dept;

import static com.shengyu.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.shengyu.framework.common.util.collection.CollectionUtils.convertSet;
import static com.shengyu.module.system.enums.ErrorCodeConstants.DEPT_EXITS_CHILDREN;
import static com.shengyu.module.system.enums.ErrorCodeConstants.DEPT_NAME_DUPLICATE;
import static com.shengyu.module.system.enums.ErrorCodeConstants.DEPT_NOT_ENABLE;
import static com.shengyu.module.system.enums.ErrorCodeConstants.DEPT_NOT_FOUND;
import static com.shengyu.module.system.enums.ErrorCodeConstants.DEPT_PARENT_ERROR;
import static com.shengyu.module.system.enums.ErrorCodeConstants.DEPT_PARENT_IS_CHILD;
import static com.shengyu.module.system.enums.ErrorCodeConstants.DEPT_PARENT_NOT_EXITS;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.util.ObjectUtil;
import com.shengyu.framework.common.enums.CommonStatusEnum;
import com.shengyu.framework.common.enums.dept.DeptIdEnum;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.framework.datapermission.core.annotation.DataPermission;
import com.shengyu.module.platform.controller.platform.dept.vo.dept.DeptCreateReqVO;
import com.shengyu.module.platform.controller.platform.dept.vo.dept.DeptListReqVO;
import com.shengyu.module.platform.controller.platform.dept.vo.dept.DeptUpdateReqVO;
import com.shengyu.module.platform.dal.dataobject.dept.PlatformDeptDO;
import com.shengyu.module.platform.dal.mysql.dept.PlatformDeptMapper;
import com.shengyu.module.platform.dal.redis.RedisKeyConstants;
import com.google.common.annotations.VisibleForTesting;
import java.util.Collection;
import java.util.Collections;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import javax.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

/**
 * 部门 Service 实现类
 *
 * @author 圣钰科技
 */
@Service
@Validated
@Slf4j
public class PlatformDeptServiceImpl implements PlatformDeptService {

    @Resource
    private PlatformDeptMapper platformDeptMapper;

    @Override
    @CacheEvict(cacheNames = RedisKeyConstants.DEPT_CHILDREN_ID_LIST,
        allEntries = true) // allEntries 清空所有缓存，因为操作一个部门，涉及到多个缓存
    public Long createDept(DeptCreateReqVO reqVO) {
        // 校验正确性
        if (reqVO.getParentId() == null) {
            reqVO.setParentId(DeptIdEnum.ROOT.getId());
        }
        validateForCreateOrUpdate(null, reqVO.getParentId(), reqVO.getName());
        // 插入部门
        PlatformDeptDO dept = BeanUtils.toBean(reqVO, PlatformDeptDO.class);
        platformDeptMapper.insert(dept);
        return dept.getId();
    }

    @Override
    @CacheEvict(cacheNames = RedisKeyConstants.DEPT_CHILDREN_ID_LIST,
        allEntries = true) // allEntries 清空所有缓存，因为操作一个部门，涉及到多个缓存
    public void updateDept(DeptUpdateReqVO reqVO) {
        // 校验正确性
        if (reqVO.getParentId() == null) {
            reqVO.setParentId(DeptIdEnum.ROOT.getId());
        }
        validateForCreateOrUpdate(reqVO.getId(), reqVO.getParentId(), reqVO.getName());
        // 更新部门
        PlatformDeptDO updateObj = BeanUtils.toBean(reqVO, PlatformDeptDO.class);
        platformDeptMapper.updateById(updateObj);
    }

    @Override
    @CacheEvict(cacheNames = RedisKeyConstants.DEPT_CHILDREN_ID_LIST,
        allEntries = true) // allEntries 清空所有缓存，因为操作一个部门，涉及到多个缓存
    public void deleteDept(Long id) {
        // 校验是否存在
        validateDeptExists(id);
        // 校验是否有子部门
        if (platformDeptMapper.selectCountByParentId(id) > 0) {
            throw exception(DEPT_EXITS_CHILDREN);
        }
        // 删除部门
        platformDeptMapper.deleteById(id);
    }

    private void validateForCreateOrUpdate(Long id, Long parentId, String name) {
        // 校验自己存在
        validateDeptExists(id);
        // 校验父部门的有效性
        validateParentDept(id, parentId);
        // 校验部门名的唯一性
        validateDeptNameUnique(id, parentId, name);
    }

    @VisibleForTesting
    void validateDeptExists(Long id) {
        if (id == null) {
            return;
        }
        PlatformDeptDO dept = platformDeptMapper.selectById(id);
        if (dept == null) {
            throw exception(DEPT_NOT_FOUND);
        }
    }

    @VisibleForTesting
    void validateParentDept(Long id, Long parentId) {
        if (parentId == null || DeptIdEnum.ROOT.getId().equals(parentId)) {
            return;
        }
        // 不能设置自己为父部门
        if (parentId.equals(id)) {
            throw exception(DEPT_PARENT_ERROR);
        }
        // 父岗位不存在
        PlatformDeptDO dept = platformDeptMapper.selectById(parentId);
        if (dept == null) {
            throw exception(DEPT_PARENT_NOT_EXITS);
        }
        // 父部门不能是原来的子部门
        List<PlatformDeptDO> children = getChildDeptList(id);
        if (children.stream().anyMatch(dept1 -> dept1.getId().equals(parentId))) {
            throw exception(DEPT_PARENT_IS_CHILD);
        }
    }

    @VisibleForTesting
    void validateDeptNameUnique(Long id, Long parentId, String name) {
        PlatformDeptDO dept = platformDeptMapper.selectByParentIdAndName(parentId, name);
        if (dept == null) {
            return;
        }
        // 如果 id 为空，说明不用比较是否为相同 id 的岗位
        if (id == null) {
            throw exception(DEPT_NAME_DUPLICATE);
        }
        if (ObjectUtil.notEqual(dept.getId(), id)) {
            throw exception(DEPT_NAME_DUPLICATE);
        }
    }

    @Override
    public PlatformDeptDO getDept(Long id) {
        return platformDeptMapper.selectById(id);
    }

    @Override
    public List<PlatformDeptDO> getDeptList(Collection<Long> ids) {
        if (CollUtil.isEmpty(ids)) {
            return Collections.emptyList();
        }
        return platformDeptMapper.selectBatchIds(ids);
    }

    @Override
    public List<PlatformDeptDO> getDeptList(DeptListReqVO reqVO) {
        return platformDeptMapper.selectList(reqVO);
    }

    @Override
    public List<PlatformDeptDO> getChildDeptList(Long id) {
        List<PlatformDeptDO> children = new LinkedList<>();
        // 遍历每一层
        Collection<Long> parentIds = Collections.singleton(id);
        for (int i = 0; i < Short.MAX_VALUE; i++) { // 使用 Short.MAX_VALUE 避免 bug 场景下，存在死循环
            // 查询当前层，所有的子部门
            List<PlatformDeptDO> depts = platformDeptMapper.selectListByParentId(parentIds);
            // 1. 如果没有子部门，则结束遍历
            if (CollUtil.isEmpty(depts)) {
                break;
            }
            // 2. 如果有子部门，继续遍历
            children.addAll(depts);
            parentIds = convertSet(depts, PlatformDeptDO::getId);
        }
        return children;
    }

    @Override
    @DataPermission(enable = false) // 禁用数据权限，避免建立不正确的缓存
    @Cacheable(cacheNames = RedisKeyConstants.DEPT_CHILDREN_ID_LIST, key = "#id")
    public Set<Long> getChildDeptIdListFromCache(Long id) {
        List<PlatformDeptDO> children = getChildDeptList(id);
        return convertSet(children, PlatformDeptDO::getId);
    }

    @Override
    public void validateDeptList(Collection<Long> ids) {
        if (CollUtil.isEmpty(ids)) {
            return;
        }
        // 获得科室信息
        Map<Long, PlatformDeptDO> deptMap = getDeptMap(ids);
        // 校验
        ids.forEach(id -> {
            PlatformDeptDO dept = deptMap.get(id);
            if (dept == null) {
                throw exception(DEPT_NOT_FOUND);
            }
            if (!CommonStatusEnum.ENABLE.getStatus().equals(dept.getStatus())) {
                throw exception(DEPT_NOT_ENABLE, dept.getName());
            }
        });
    }

}
