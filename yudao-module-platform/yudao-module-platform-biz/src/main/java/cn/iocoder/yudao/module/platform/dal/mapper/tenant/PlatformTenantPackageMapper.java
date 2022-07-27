package cn.iocoder.yudao.module.platform.dal.mapper.tenant;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.mybatis.core.mapper.BaseMapperX;
import cn.iocoder.yudao.framework.mybatis.core.query.LambdaQueryWrapperX;
import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.packages.TenantPackagePageReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.tenant.PlatformTenantPackageDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * 租户套餐 Mapper
 *
 * @author 芋道源码
 */
@Mapper
public interface PlatformTenantPackageMapper extends BaseMapperX<PlatformTenantPackageDO> {

    default PageResult<PlatformTenantPackageDO> selectPage(TenantPackagePageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<PlatformTenantPackageDO>()
                .likeIfPresent(PlatformTenantPackageDO::getName, reqVO.getName())
                .eqIfPresent(PlatformTenantPackageDO::getStatus, reqVO.getStatus())
                .likeIfPresent(PlatformTenantPackageDO::getRemark, reqVO.getRemark())
                .betweenIfPresent(PlatformTenantPackageDO::getCreateTime, reqVO.getBeginCreateTime(), reqVO.getEndCreateTime())
                .orderByDesc(PlatformTenantPackageDO::getId));
    }

    default List<PlatformTenantPackageDO> selectListByStatus(Integer status) {
        return selectList(PlatformTenantPackageDO::getStatus, status);
    }
}
