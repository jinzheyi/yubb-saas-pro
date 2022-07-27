package cn.iocoder.yudao.module.platform.dal.mapper.permission;

import cn.iocoder.yudao.framework.mybatis.core.mapper.BaseMapperX;
import cn.iocoder.yudao.framework.mybatis.core.query.LambdaQueryWrapperX;
import cn.iocoder.yudao.module.platform.dal.dataobject.permission.PlatformRoleMenuDO;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.apache.ibatis.annotations.Mapper;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.Date;
import java.util.List;

@Mapper
public interface PlatformRoleMenuMapper extends BaseMapperX<PlatformRoleMenuDO> {

    @Repository
    class BatchInsertMapper extends ServiceImpl<PlatformRoleMenuMapper, PlatformRoleMenuDO> {
    }

    default List<PlatformRoleMenuDO> selectListByRoleId(Long roleId) {
        return selectList(new LambdaQueryWrapperX<PlatformRoleMenuDO>().eq(PlatformRoleMenuDO::getRoleId, roleId));
    }

    default void deleteListByRoleIdAndMenuIds(Long roleId, Collection<Long> menuIds) {
        delete(new LambdaQueryWrapperX<PlatformRoleMenuDO>().eq(PlatformRoleMenuDO::getRoleId, roleId)
                .in(PlatformRoleMenuDO::getMenuId, menuIds));
    }

    default void deleteListByMenuId(Long menuId) {
        delete(new LambdaQueryWrapperX<PlatformRoleMenuDO>().eq(PlatformRoleMenuDO::getMenuId, menuId));
    }

    default void deleteListByRoleId(Long roleId) {
        delete(new LambdaQueryWrapperX<PlatformRoleMenuDO>().eq(PlatformRoleMenuDO::getRoleId, roleId));
    }

    // TODO 看测试情况，是否能这么改，先标记一下
    //@Select("SELECT COUNT(*) FROM system_role_menu WHERE update_time > #{maxUpdateTime}")
    default Long selectCountByUpdateTimeGt(Date maxUpdateTime){
        return selectCount(new LambdaQueryWrapperX<PlatformRoleMenuDO>()
                .gt(PlatformRoleMenuDO::getUpdateTime, maxUpdateTime));
    };

}
