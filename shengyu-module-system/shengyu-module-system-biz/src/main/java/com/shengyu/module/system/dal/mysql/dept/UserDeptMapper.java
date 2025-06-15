package com.shengyu.module.system.dal.mysql.dept;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.framework.mybatis.core.query.MPJLambdaWrapperX;
import com.shengyu.module.system.controller.admin.dept.vo.dept.UserDeptRespVO;
import com.shengyu.module.system.dal.dataobject.dept.DeptDO;
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

    default List<UserDeptRespVO> selectListByUserIds(Collection<Long> userIds) {
        return selectJoinList(UserDeptRespVO.class, new MPJLambdaWrapperX<UserDeptDO>()
                .select(UserDeptDO::getId, UserDeptDO::getUserId, UserDeptDO::getDeptId)
                .select(DeptDO::getParentId, DeptDO::getSort, DeptDO::getLeaderUserId, DeptDO::getPhone, DeptDO::getEmail, DeptDO::getStatus)
                .selectAs(DeptDO::getName, UserDeptRespVO::getDeptName)
                .leftJoin(DeptDO.class, DeptDO::getId, UserDeptDO::getDeptId)
                .in(UserDeptDO::getUserId, userIds)
        );
    }

}
