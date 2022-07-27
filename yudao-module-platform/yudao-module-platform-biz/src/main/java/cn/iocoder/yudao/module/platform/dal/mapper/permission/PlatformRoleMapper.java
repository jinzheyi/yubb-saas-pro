package cn.iocoder.yudao.module.platform.dal.mapper.permission;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.mybatis.core.dataobject.BaseDO;
import cn.iocoder.yudao.framework.mybatis.core.mapper.BaseMapperX;
import cn.iocoder.yudao.framework.mybatis.core.query.LambdaQueryWrapperX;
import cn.iocoder.yudao.module.platform.controller.center.permission.vo.role.RoleExportReqVO;
import cn.iocoder.yudao.module.platform.controller.center.permission.vo.role.RolePageReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.permission.PlatformRoleDO;
import org.apache.ibatis.annotations.Mapper;
import org.springframework.lang.Nullable;

import java.util.Collection;
import java.util.Date;
import java.util.List;

@Mapper
public interface PlatformRoleMapper extends BaseMapperX<PlatformRoleDO> {

    default PageResult<PlatformRoleDO> selectPage(RolePageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<PlatformRoleDO>()
                .likeIfPresent(PlatformRoleDO::getName, reqVO.getName())
                .likeIfPresent(PlatformRoleDO::getCode, reqVO.getCode())
                .eqIfPresent(PlatformRoleDO::getStatus, reqVO.getStatus())
                .betweenIfPresent(BaseDO::getCreateTime, reqVO.getBeginTime(), reqVO.getEndTime())
                .orderByDesc(PlatformRoleDO::getId));
    }

    default List<PlatformRoleDO> selectList(RoleExportReqVO reqVO) {
        return selectList(new LambdaQueryWrapperX<PlatformRoleDO>()
                .likeIfPresent(PlatformRoleDO::getName, reqVO.getName())
                .likeIfPresent(PlatformRoleDO::getCode, reqVO.getCode())
                .eqIfPresent(PlatformRoleDO::getStatus, reqVO.getStatus())
                .betweenIfPresent(BaseDO::getCreateTime, reqVO.getBeginTime(), reqVO.getEndTime()));
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

    // TODO 看测试情况，是否能这么改，先标记一下
    //@Select("SELECT COUNT(*) FROM system_role WHERE update_time > #{maxUpdateTime}")
    default Long selectCountByUpdateTimeGt(Date maxUpdateTime){
        return selectCount(new LambdaQueryWrapperX<PlatformRoleDO>()
                .gt(PlatformRoleDO::getUpdateTime, maxUpdateTime));
    };

}
