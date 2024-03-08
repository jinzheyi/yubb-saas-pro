package cn.iocoder.yudao.module.platform.dal.mysql.permission;

import cn.iocoder.yudao.framework.mybatis.core.mapper.BaseMapperX;
import cn.iocoder.yudao.module.platform.dal.dataobject.permission.PlatformRoleMenuDO;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import java.util.Collection;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface PlatformRoleMenuMapper extends BaseMapperX<PlatformRoleMenuDO> {

    default List<PlatformRoleMenuDO> selectListByRoleId(Long roleId) {
        return selectList(PlatformRoleMenuDO::getRoleId, roleId);
    }

    default List<PlatformRoleMenuDO> selectListByRoleId(Collection<Long> roleIds) {
        return selectList(PlatformRoleMenuDO::getRoleId, roleIds);
    }

    default List<PlatformRoleMenuDO> selectListByMenuId(Long menuId) {
        return selectList(PlatformRoleMenuDO::getMenuId, menuId);
    }

    default void deleteListByRoleIdAndMenuIds(Long roleId, Collection<Long> menuIds) {
        delete(new LambdaQueryWrapper<PlatformRoleMenuDO>()
                .eq(PlatformRoleMenuDO::getRoleId, roleId)
                .in(PlatformRoleMenuDO::getMenuId, menuIds));
    }

    default void deleteListByMenuId(Long menuId) {
        delete(new LambdaQueryWrapper<PlatformRoleMenuDO>().eq(PlatformRoleMenuDO::getMenuId, menuId));
    }

    default void deleteListByRoleId(Long roleId) {
        delete(new LambdaQueryWrapper<PlatformRoleMenuDO>().eq(PlatformRoleMenuDO::getRoleId, roleId));
    }

}
