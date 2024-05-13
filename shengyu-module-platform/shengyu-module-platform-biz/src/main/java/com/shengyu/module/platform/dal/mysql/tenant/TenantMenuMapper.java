package com.shengyu.module.platform.dal.mysql.tenant;

import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.module.platform.controller.platform.tenant.vo.menu.TenantMenuListReqVO;
import com.shengyu.module.platform.dal.dataobject.tenant.TenantMenuDO;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface TenantMenuMapper extends BaseMapperX<TenantMenuDO> {

    default TenantMenuDO selectByParentIdAndName(Long parentId, String name) {
        return selectOne(TenantMenuDO::getParentId, parentId, TenantMenuDO::getName, name);
    }

    default Long selectCountByParentId(Long parentId) {
        return selectCount(TenantMenuDO::getParentId, parentId);
    }

    default List<TenantMenuDO> selectList(TenantMenuListReqVO reqVO) {
        return selectList(new LambdaQueryWrapperX<TenantMenuDO>()
                .inIfPresent(TenantMenuDO::getId, reqVO.getIds())
                .likeIfPresent(TenantMenuDO::getName, reqVO.getName())
                .eqIfPresent(TenantMenuDO::getStatus, reqVO.getStatus())
                .eqIfPresent(TenantMenuDO::getDimension, reqVO.getDimension())
                .eqIfPresent(TenantMenuDO::getPlugAppSn, reqVO.getPlugAppSn())
                .inIfPresent(TenantMenuDO::getPlugAppSn, reqVO.getPlugAppSns()));
    }

    default List<TenantMenuDO> selectListByPermission(String permission) {
        return selectList(TenantMenuDO::getPermission, permission);
    }

}
