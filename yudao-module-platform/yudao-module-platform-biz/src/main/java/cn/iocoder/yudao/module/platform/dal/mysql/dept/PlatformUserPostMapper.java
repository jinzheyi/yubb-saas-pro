package cn.iocoder.yudao.module.platform.dal.mysql.dept;

import cn.iocoder.yudao.framework.mybatis.core.mapper.BaseMapperX;
import cn.iocoder.yudao.framework.mybatis.core.query.LambdaQueryWrapperX;
import cn.iocoder.yudao.module.platform.dal.dataobject.dept.PlatformUserPostDO;
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
