package cn.iocoder.yudao.module.platform.dal.mysql.dept;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.mybatis.core.mapper.BaseMapperX;
import cn.iocoder.yudao.framework.mybatis.core.query.QueryWrapperX;
import cn.iocoder.yudao.module.platform.controller.center.dept.vo.post.PostExportReqVO;
import cn.iocoder.yudao.module.platform.controller.center.dept.vo.post.PostPageReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.dept.PlatformPostDO;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import org.apache.ibatis.annotations.Mapper;

import java.util.Collection;
import java.util.List;

@Mapper
public interface PlatformPostMapper extends BaseMapperX<PlatformPostDO> {

    default List<PlatformPostDO> selectList(Collection<Long> ids, Collection<Integer> statuses) {
        return selectList(new QueryWrapperX<PlatformPostDO>().inIfPresent("id", ids)
                .inIfPresent("status", statuses));
    }

    default PageResult<PlatformPostDO> selectPage(PostPageReqVO reqVO) {
        return selectPage(reqVO, new QueryWrapperX<PlatformPostDO>()
                .likeIfPresent("code", reqVO.getCode())
                .likeIfPresent("name", reqVO.getName())
                .eqIfPresent("status", reqVO.getStatus())
                .orderByDesc("id"));
    }

    default List<PlatformPostDO> selectList(PostExportReqVO reqVO) {
        return selectList(new QueryWrapperX<PlatformPostDO>()
                .likeIfPresent("code", reqVO.getCode())
                .likeIfPresent("name", reqVO.getName())
                .eqIfPresent("status", reqVO.getStatus()));
    }

    default PlatformPostDO selectByName(String name) {
        return selectOne(new QueryWrapper<PlatformPostDO>().eq("name", name));
    }

    default PlatformPostDO selectByCode(String code) {
        return selectOne(new QueryWrapper<PlatformPostDO>().eq("code", code));
    }

}
