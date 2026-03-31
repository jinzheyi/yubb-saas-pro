package com.shengyu.module.platform.dal.mysql.permission;

import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.mybatis.core.dataobject.BaseDO;
import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.module.platform.controller.platform.permission.vo.role.RoleExportReqVO;
import com.shengyu.module.platform.controller.platform.permission.vo.role.RolePageReqVO;
import com.shengyu.module.platform.dal.dataobject.permission.PlatformRoleDO;
import org.apache.ibatis.annotations.Mapper;
import org.springframework.lang.Nullable;

import java.util.Collection;
import java.util.List;

@Mapper
public interface PlatformRoleMapper extends BaseMapperX<PlatformRoleDO> {

    default PageResult<PlatformRoleDO> selectPage(RolePageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<PlatformRoleDO>()
                .likeIfPresent(PlatformRoleDO::getName, reqVO.getName())
                .likeIfPresent(PlatformRoleDO::getCode, reqVO.getCode())
                .eqIfPresent(PlatformRoleDO::getStatus, reqVO.getStatus())
                .betweenIfPresent(BaseDO::getCreateTime, reqVO.getCreateTime())
                .orderByDesc(PlatformRoleDO::getCreateTime));
    }

    default List<PlatformRoleDO> selectList(RoleExportReqVO reqVO) {
        return selectList(new LambdaQueryWrapperX<PlatformRoleDO>()
                .likeIfPresent(PlatformRoleDO::getName, reqVO.getName())
                .likeIfPresent(PlatformRoleDO::getCode, reqVO.getCode())
                .eqIfPresent(PlatformRoleDO::getStatus, reqVO.getStatus())
                .betweenIfPresent(BaseDO::getCreateTime, reqVO.getCreateTime()));
    }

    default PlatformRoleDO selectByName(String name) {
        return selectOne(PlatformRoleDO::getName, name);
    }

    default PlatformRoleDO selectByCode(String code) {
        return selectOne(PlatformRoleDO::getCode, code);
    }

    default List<PlatformRoleDO> selectListByStatus(@Nullable Collection<Integer> statuses) {
        return selectList(PlatformRoleDO::getStatus, statuses);
    }

}
