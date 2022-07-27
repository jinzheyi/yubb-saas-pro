package cn.iocoder.yudao.module.platform.dal.mapper.dept;

import cn.iocoder.yudao.framework.mybatis.core.mapper.BaseMapperX;
import cn.iocoder.yudao.framework.mybatis.core.query.LambdaQueryWrapperX;
import cn.iocoder.yudao.module.platform.controller.center.dept.vo.dept.DeptListReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.dept.PlatformDeptDO;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import org.apache.ibatis.annotations.Mapper;

import java.util.Date;
import java.util.List;

@Mapper
public interface PlatformDeptMapper extends BaseMapperX<PlatformDeptDO> {

    default List<PlatformDeptDO> selectList(DeptListReqVO reqVO) {
        return selectList(new LambdaQueryWrapperX<PlatformDeptDO>()
                .likeIfPresent(PlatformDeptDO::getName, reqVO.getName())
                .eqIfPresent(PlatformDeptDO::getStatus, reqVO.getStatus()));
    }

    default PlatformDeptDO selectByParentIdAndName(Long parentId, String name) {
        return selectOne(new LambdaQueryWrapper<PlatformDeptDO>()
                .eq(PlatformDeptDO::getParentId, parentId)
                .eq(PlatformDeptDO::getName, name));
    }

    default Long selectCountByParentId(Long parentId) {
        return selectCount(PlatformDeptDO::getParentId, parentId);
    }

    //TODO 看测试效果，是否能这么改
    //@Select("SELECT COUNT(*) FROM system_dept WHERE update_time > #{maxUpdateTime}")
    default Long selectCountByUpdateTimeGt(Date maxUpdateTime) {
        return selectCount(new LambdaQueryWrapperX<PlatformDeptDO>()
                .gt(PlatformDeptDO::getUpdateTime, maxUpdateTime));
    };

}
