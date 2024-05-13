package com.shengyu.module.platform.dal.mysql.dept;

import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.module.platform.controller.platform.dept.vo.post.PostExportReqVO;
import com.shengyu.module.platform.controller.platform.dept.vo.post.PostPageReqVO;
import com.shengyu.module.platform.dal.dataobject.dept.PlatformPostDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.Collection;
import java.util.List;

@Mapper
public interface PlatformPostMapper extends BaseMapperX<PlatformPostDO> {

    default List<PlatformPostDO> selectList(Collection<Long> ids, Collection<Integer> statuses) {
        return selectList(new LambdaQueryWrapperX<PlatformPostDO>()
                .inIfPresent(PlatformPostDO::getId, ids)
                .inIfPresent(PlatformPostDO::getStatus, statuses));
    }

    default PageResult<PlatformPostDO> selectPage(PostPageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<PlatformPostDO>()
                .likeIfPresent(PlatformPostDO::getCode, reqVO.getCode())
                .likeIfPresent(PlatformPostDO::getName, reqVO.getName())
                .eqIfPresent(PlatformPostDO::getStatus, reqVO.getStatus())
                .orderByDesc(PlatformPostDO::getId));
    }

    default List<PlatformPostDO> selectList(PostExportReqVO reqVO) {
        return selectList(new LambdaQueryWrapperX<PlatformPostDO>()
                .likeIfPresent(PlatformPostDO::getCode, reqVO.getCode())
                .likeIfPresent(PlatformPostDO::getName, reqVO.getName())
                .eqIfPresent(PlatformPostDO::getStatus, reqVO.getStatus()));
    }

    default PlatformPostDO selectByName(String name) {
        return selectOne(PlatformPostDO::getName, name);
    }

    default PlatformPostDO selectByCode(String code) {
        return selectOne(PlatformPostDO::getCode, code);
    }

}
