package com.shengyu.module.system.dal.mysql.dept;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.module.system.dal.dataobject.dept.UserDeptDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.Collection;
import java.util.List;

@Mapper
public interface UserDeptMapper extends BaseMapperX<UserDeptDO> {

    default List<UserDeptDO> selectListByUserId(Long userId) {
        return selectList(UserDeptDO::getUserId, userId);
    }

    default void deleteListByUserIdAndDeptIdIds(Long userId, Collection<Long> deptIds) {
        delete(new LambdaQueryWrapper<UserDeptDO>()
                .eq(UserDeptDO::getUserId, userId)
                .in(UserDeptDO::getDeptId, deptIds));
    }

    default void deleteListByUserId(Long userId) {
        delete(new LambdaQueryWrapper<UserDeptDO>().eq(UserDeptDO::getUserId, userId));
    }

    default void deleteListByRoleId(Long deptId) {
        delete(new LambdaQueryWrapper<UserDeptDO>().eq(UserDeptDO::getDeptId, deptId));
    }

    default List<UserDeptDO> selectListByDeptIds(Collection<Long> deptIds) {
        return selectList(UserDeptDO::getDeptId, deptIds);
    }

}
