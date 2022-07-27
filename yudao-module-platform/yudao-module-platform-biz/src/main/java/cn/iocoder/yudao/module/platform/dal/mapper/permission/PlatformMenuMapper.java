package cn.iocoder.yudao.module.platform.dal.mapper.permission;

import cn.iocoder.yudao.framework.mybatis.core.mapper.BaseMapperX;
import cn.iocoder.yudao.framework.mybatis.core.query.LambdaQueryWrapperX;
import cn.iocoder.yudao.module.platform.controller.center.permission.vo.menu.MenuListReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.permission.PlatformMenuDO;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import org.apache.ibatis.annotations.Mapper;

import java.util.Date;
import java.util.List;

@Mapper
public interface PlatformMenuMapper extends BaseMapperX<PlatformMenuDO> {

    default PlatformMenuDO selectByParentIdAndName(Long parentId, String name) {
        return selectOne(new LambdaQueryWrapper<PlatformMenuDO>().eq(PlatformMenuDO::getParentId, parentId)
                .eq(PlatformMenuDO::getName, name));
    }

    default Long selectCountByParentId(Long parentId) {
        return selectCount(PlatformMenuDO::getParentId, parentId);
    }

    default List<PlatformMenuDO> selectList(MenuListReqVO reqVO) {
        return selectList(new LambdaQueryWrapperX<PlatformMenuDO>().likeIfPresent(PlatformMenuDO::getName, reqVO.getName())
                .eqIfPresent(PlatformMenuDO::getStatus, reqVO.getStatus()));
    }

    // TODO 看测试情况，是否能这么改，先标记一下
    //@Select("SELECT COUNT(*) FROM system_menu WHERE update_time > #{maxUpdateTime}")
    default Long selectCountByUpdateTimeGt(Date maxUpdateTime){
        return selectCount(new LambdaQueryWrapperX<PlatformMenuDO>()
                .gt(PlatformMenuDO::getUpdateTime, maxUpdateTime));
    };

}
