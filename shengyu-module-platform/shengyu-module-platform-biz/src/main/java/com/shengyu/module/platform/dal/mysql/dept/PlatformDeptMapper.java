package com.shengyu.module.platform.dal.mysql.dept;

import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.module.platform.controller.platform.dept.vo.dept.DeptListReqVO;
import com.shengyu.module.platform.dal.dataobject.dept.PlatformDeptDO;
import java.util.Collection;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

@Mapper
public interface PlatformDeptMapper extends BaseMapperX<PlatformDeptDO> {

    default List<PlatformDeptDO> selectList(DeptListReqVO reqVO) {
        return selectList(new LambdaQueryWrapperX<PlatformDeptDO>()
                .likeIfPresent(PlatformDeptDO::getName, reqVO.getName())
                .eqIfPresent(PlatformDeptDO::getStatus, reqVO.getStatus()));
    }

    default PlatformDeptDO selectByParentIdAndName(Long parentId, String name) {
        return selectOne(PlatformDeptDO::getParentId, parentId, PlatformDeptDO::getName, name);
    }

    default Long selectCountByParentId(Long parentId) {
        return selectCount(PlatformDeptDO::getParentId, parentId);
    }

    default List<PlatformDeptDO> selectListByParentId(Collection<Long> parentIds) {
        return selectList(PlatformDeptDO::getParentId, parentIds);
    }

}
