package cn.iocoder.yudao.module.platform.dal.mapper.permission;

import cn.iocoder.yudao.framework.mybatis.core.mapper.BaseMapperX;
import cn.iocoder.yudao.framework.mybatis.core.query.LambdaQueryWrapperX;
import cn.iocoder.yudao.module.platform.dal.dataobject.permission.UserRoleDO;
import org.apache.ibatis.annotations.Mapper;
import java.util.Collection;
import java.util.Date;
import java.util.List;

@Mapper
public interface PlatformUserRoleMapper extends BaseMapperX<UserRoleDO> {

    default List<UserRoleDO> selectListByUserId(Long userId) {
        return selectList(new LambdaQueryWrapperX<UserRoleDO>().eq(UserRoleDO::getUserId, userId));
    }

    default List<UserRoleDO> selectListByRoleId(Long roleId) {
        return selectList(new LambdaQueryWrapperX<UserRoleDO>().eq(UserRoleDO::getRoleId, roleId));
    }

    default void deleteListByUserIdAndRoleIdIds(Long userId, Collection<Long> roleIds) {
        delete(new LambdaQueryWrapperX<UserRoleDO>().eq(UserRoleDO::getUserId, userId)
                .in(UserRoleDO::getRoleId, roleIds));
    }

    default void deleteListByUserId(Long userId) {
        delete(new LambdaQueryWrapperX<UserRoleDO>().eq(UserRoleDO::getUserId, userId));
    }

    default void deleteListByRoleId(Long roleId) {
        delete(new LambdaQueryWrapperX<UserRoleDO>().eq(UserRoleDO::getRoleId, roleId));
    }


    default List<UserRoleDO> selectListByRoleIds(Collection<Long> roleIds) {
        return selectList(UserRoleDO::getRoleId, roleIds);
    }

    // TODO 看测试情况，是否能这么改，先标记一下
    //@Select("SELECT COUNT(*) FROM system_user_role WHERE update_time > #{maxUpdateTime}")
    default Long selectCountByUpdateTimeGt(Date maxUpdateTime) {
        return selectCount(new LambdaQueryWrapperX<UserRoleDO>()
                .gt(UserRoleDO::getUpdateTime, maxUpdateTime));
    };

}
