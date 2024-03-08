package cn.iocoder.yudao.module.platform.dal.mysql.dept;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.mybatis.core.mapper.BaseMapperX;
import cn.iocoder.yudao.framework.mybatis.core.query.LambdaQueryWrapperX;
import cn.iocoder.yudao.module.platform.controller.platform.dept.vo.post.PostExportReqVO;
import cn.iocoder.yudao.module.platform.controller.platform.dept.vo.post.PostPageReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.dept.PlatformPostDO;
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
