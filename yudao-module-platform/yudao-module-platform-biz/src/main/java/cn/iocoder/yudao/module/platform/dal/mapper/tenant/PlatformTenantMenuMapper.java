package cn.iocoder.yudao.module.platform.dal.mapper.tenant;

import cn.iocoder.yudao.framework.mybatis.core.mapper.BaseMapperX;
import cn.iocoder.yudao.framework.mybatis.core.query.LambdaQueryWrapperX;
import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.menu.TenantMenuListReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.tenant.PlatformTenantMenuDO;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

import java.util.Date;
import java.util.List;

@Mapper
public interface PlatformTenantMenuMapper extends BaseMapperX<PlatformTenantMenuDO> {

    default PlatformTenantMenuDO selectByParentIdAndName(Long parentId, String name) {
        return selectOne(new LambdaQueryWrapper<PlatformTenantMenuDO>().eq(PlatformTenantMenuDO::getParentId, parentId)
                .eq(PlatformTenantMenuDO::getName, name));
    }

    default Long selectCountByParentId(Long parentId) {
        return selectCount(PlatformTenantMenuDO::getParentId, parentId);
    }

    default List<PlatformTenantMenuDO> selectList(TenantMenuListReqVO reqVO) {
        return selectList(new LambdaQueryWrapperX<PlatformTenantMenuDO>().likeIfPresent(PlatformTenantMenuDO::getName, reqVO.getName())
                .eqIfPresent(PlatformTenantMenuDO::getStatus, reqVO.getStatus()));
    }

    @Select("SELECT COUNT(*) FROM tenant_menu WHERE update_time > #{maxUpdateTime}")
    Long selectCountByUpdateTimeGt(Date maxUpdateTime);

}
