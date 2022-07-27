package cn.iocoder.yudao.module.platform.dal.mapper.permission;

import cn.iocoder.yudao.framework.mybatis.core.mapper.BaseMapperX;
import cn.iocoder.yudao.framework.mybatis.core.query.LambdaQueryWrapperX;
import cn.iocoder.yudao.module.platform.controller.center.permission.vo.menu.MenuListReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.permission.PlatformMenuDO;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

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

    @Select("SELECT COUNT(*) FROM platform_menu WHERE update_time > #{maxUpdateTime}")
    Long selectCountByUpdateTimeGt(Date maxUpdateTime);

}
