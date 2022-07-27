package cn.iocoder.yudao.module.platform.dal.mapper.tenant;

import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.tenant.TenantExportReqVO;
import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.tenant.TenantPageReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.tenant.PlatformTenantDO;
import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.mybatis.core.mapper.BaseMapperX;
import cn.iocoder.yudao.framework.mybatis.core.query.LambdaQueryWrapperX;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

import java.util.Date;
import java.util.List;

/**
 * 租户 Mapper
 *
 * @author 芋道源码
 */
@Mapper
public interface PlatformTenantMapper extends BaseMapperX<PlatformTenantDO> {

    default PageResult<PlatformTenantDO> selectPage(TenantPageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<PlatformTenantDO>()
                .likeIfPresent(PlatformTenantDO::getName, reqVO.getName())
                .likeIfPresent(PlatformTenantDO::getContactName, reqVO.getContactName())
                .likeIfPresent(PlatformTenantDO::getContactMobile, reqVO.getContactMobile())
                .eqIfPresent(PlatformTenantDO::getStatus, reqVO.getStatus())
                .betweenIfPresent(PlatformTenantDO::getCreateTime, reqVO.getBeginCreateTime(), reqVO.getEndCreateTime())
                .orderByDesc(PlatformTenantDO::getId));
    }

    default List<PlatformTenantDO> selectList(TenantExportReqVO reqVO) {
        return selectList(new LambdaQueryWrapperX<PlatformTenantDO>()
                .likeIfPresent(PlatformTenantDO::getName, reqVO.getName())
                .likeIfPresent(PlatformTenantDO::getContactName, reqVO.getContactName())
                .likeIfPresent(PlatformTenantDO::getContactMobile, reqVO.getContactMobile())
                .eqIfPresent(PlatformTenantDO::getStatus, reqVO.getStatus())
                .betweenIfPresent(PlatformTenantDO::getCreateTime, reqVO.getBeginCreateTime(), reqVO.getEndCreateTime())
                .orderByDesc(PlatformTenantDO::getId));
    }

    default PlatformTenantDO selectByName(String name) {
        return selectOne(PlatformTenantDO::getName, name);
    }

    default Long selectCountByPackageId(Long packageId) {
        return selectCount(PlatformTenantDO::getPackageId, packageId);
    }

    default List<PlatformTenantDO> selectListByPackageId(Long packageId) {
        return selectList(PlatformTenantDO::getPackageId, packageId);
    }

    //TODO 群友说这块改成mybatis-plus会有乐观锁字段的概念，需要后续研究下问题所在(经过查找，文档中写了为啥一定要写原生sql，后续优化再根据文档来)
    @Select("SELECT COUNT(*) FROM system_tenant WHERE update_time > #{maxUpdateTime}")
    Long selectCountByUpdateTimeGt(Date maxUpdateTime);

}
