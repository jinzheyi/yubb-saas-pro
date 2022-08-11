package cn.iocoder.yudao.module.platform.dal.mysql.permission;

import cn.iocoder.yudao.framework.mybatis.core.mapper.BaseMapperX;
import cn.iocoder.yudao.module.platform.dal.dataobject.permission.PlatformUserRoleDO;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

import java.util.Collection;
import java.util.Date;
import java.util.List;

@Mapper
public interface PlatformUserRoleMapper extends BaseMapperX<PlatformUserRoleDO> {

    default List<PlatformUserRoleDO> selectListByUserId(Long userId) {
        return selectList(new QueryWrapper<PlatformUserRoleDO>().eq("user_id", userId));
    }

    default List<PlatformUserRoleDO> selectListByRoleId(Long roleId) {
        return selectList(new QueryWrapper<PlatformUserRoleDO>().eq("role_id", roleId));
    }

    default void deleteListByUserIdAndRoleIdIds(Long userId, Collection<Long> roleIds) {
        delete(new QueryWrapper<PlatformUserRoleDO>().eq("user_id", userId)
                .in("role_id", roleIds));
    }

    default void deleteListByUserId(Long userId) {
        delete(new QueryWrapper<PlatformUserRoleDO>().eq("user_id", userId));
    }

    default void deleteListByRoleId(Long roleId) {
        delete(new QueryWrapper<PlatformUserRoleDO>().eq("role_id", roleId));
    }


    default List<PlatformUserRoleDO> selectListByRoleIds(Collection<Long> roleIds) {
        return selectList(PlatformUserRoleDO::getRoleId, roleIds);
    }

    @Select("SELECT COUNT(*) FROM platform_user_role WHERE update_time > #{maxUpdateTime}")
    Long selectCountByUpdateTimeGt(Date maxUpdateTime);

}
