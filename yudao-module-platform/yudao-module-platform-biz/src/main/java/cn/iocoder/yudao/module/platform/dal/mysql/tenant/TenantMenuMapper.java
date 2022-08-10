package cn.iocoder.yudao.module.platform.dal.mysql.tenant;

import cn.iocoder.yudao.framework.mybatis.core.mapper.BaseMapperX;
import cn.iocoder.yudao.framework.mybatis.core.query.LambdaQueryWrapperX;
import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.menu.TenantMenuListReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.tenant.TenantMenuDO;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

import java.util.Date;
import java.util.List;

@Mapper
public interface TenantMenuMapper extends BaseMapperX<TenantMenuDO> {

    default TenantMenuDO selectByParentIdAndName(Long parentId, String name) {
        return selectOne(new LambdaQueryWrapper<TenantMenuDO>().eq(TenantMenuDO::getParentId, parentId)
                .eq(TenantMenuDO::getName, name));
    }

    default Long selectCountByParentId(Long parentId) {
        return selectCount(TenantMenuDO::getParentId, parentId);
    }

    default List<TenantMenuDO> selectList(TenantMenuListReqVO reqVO) {
        return selectList(new LambdaQueryWrapperX<TenantMenuDO>().likeIfPresent(TenantMenuDO::getName, reqVO.getName())
                .eqIfPresent(TenantMenuDO::getStatus, reqVO.getStatus()));
    }

    @Select("SELECT COUNT(*) FROM tenant_menu WHERE update_time > #{maxUpdateTime}")
    Long selectCountByUpdateTimeGt(Date maxUpdateTime);

}
