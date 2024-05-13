package com.shengyu.module.platform.dal.mysql.dept;

import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.module.platform.dal.dataobject.dept.PlatformUserPostDO;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import org.apache.ibatis.annotations.Mapper;

import java.util.Collection;
import java.util.List;

@Mapper
public interface PlatformUserPostMapper extends BaseMapperX<PlatformUserPostDO> {

    default List<PlatformUserPostDO> selectListByUserId(Long userId) {
        return selectList(PlatformUserPostDO::getUserId, userId);
    }

    default void deleteByUserIdAndPostId(Long userId, Collection<Long> postIds) {
        delete(new LambdaQueryWrapperX<PlatformUserPostDO>()
                .eq(PlatformUserPostDO::getUserId, userId)
                .in(PlatformUserPostDO::getPostId, postIds));
    }

    default List<PlatformUserPostDO> selectListByPostIds(Collection<Long> postIds) {
        return selectList(PlatformUserPostDO::getPostId, postIds);
    }

    default void deleteByUserId(Long userId) {
        delete(Wrappers.lambdaUpdate(PlatformUserPostDO.class).eq(PlatformUserPostDO::getUserId, userId));
    }
}
