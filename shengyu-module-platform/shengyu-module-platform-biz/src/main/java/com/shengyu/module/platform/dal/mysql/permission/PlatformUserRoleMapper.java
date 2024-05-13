package com.shengyu.module.platform.dal.mysql.permission;

import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.module.platform.dal.dataobject.permission.PlatformUserRoleDO;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import org.apache.ibatis.annotations.Mapper;

import java.util.Collection;
import java.util.List;

@Mapper
public interface PlatformUserRoleMapper extends BaseMapperX<PlatformUserRoleDO> {

    default List<PlatformUserRoleDO> selectListByUserId(Long userId) {
        return selectList(PlatformUserRoleDO::getUserId, userId);
    }

    default void deleteListByUserIdAndRoleIdIds(Long userId, Collection<Long> roleIds) {
        delete(new LambdaQueryWrapper<PlatformUserRoleDO>()
                .eq(PlatformUserRoleDO::getUserId, userId)
                .in(PlatformUserRoleDO::getRoleId, roleIds));
    }

    default void deleteListByUserId(Long userId) {
        delete(new LambdaQueryWrapper<PlatformUserRoleDO>().eq(PlatformUserRoleDO::getUserId, userId));
    }

    default void deleteListByRoleId(Long roleId) {
        delete(new LambdaQueryWrapper<PlatformUserRoleDO>().eq(PlatformUserRoleDO::getRoleId, roleId));
    }

    default List<PlatformUserRoleDO> selectListByRoleIds(Collection<Long> roleIds) {
        return selectList(PlatformUserRoleDO::getRoleId, roleIds);
    }

}
