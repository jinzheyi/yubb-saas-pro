package cn.iocoder.yudao.module.platform.dal.mapper.tenant;

import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.tenant.TenantExportReqVO;
import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.tenant.TenantPageReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.tenant.TenantDO;
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
public interface PlatformTenantMapper extends BaseMapperX<TenantDO> {

    default PageResult<TenantDO> selectPage(TenantPageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<TenantDO>()
                .likeIfPresent(TenantDO::getName, reqVO.getName())
                .likeIfPresent(TenantDO::getContactName, reqVO.getContactName())
                .likeIfPresent(TenantDO::getContactMobile, reqVO.getContactMobile())
                .eqIfPresent(TenantDO::getStatus, reqVO.getStatus())
                .betweenIfPresent(TenantDO::getCreateTime, reqVO.getBeginCreateTime(), reqVO.getEndCreateTime())
                .orderByDesc(TenantDO::getId));
    }

    default List<TenantDO> selectList(TenantExportReqVO reqVO) {
        return selectList(new LambdaQueryWrapperX<TenantDO>()
                .likeIfPresent(TenantDO::getName, reqVO.getName())
                .likeIfPresent(TenantDO::getContactName, reqVO.getContactName())
                .likeIfPresent(TenantDO::getContactMobile, reqVO.getContactMobile())
                .eqIfPresent(TenantDO::getStatus, reqVO.getStatus())
                .betweenIfPresent(TenantDO::getCreateTime, reqVO.getBeginCreateTime(), reqVO.getEndCreateTime())
                .orderByDesc(TenantDO::getId));
    }

    default TenantDO selectByName(String name) {
        return selectOne(TenantDO::getName, name);
    }

    default Long selectCountByPackageId(Long packageId) {
        return selectCount(TenantDO::getPackageId, packageId);
    }

    default List<TenantDO> selectListByPackageId(Long packageId) {
        return selectList(TenantDO::getPackageId, packageId);
    }

    //TODO 群友说这块改成mybatis-plus会有乐观锁字段的概念，需要后续研究下问题所在(经过查找，文档中写了为啥一定要写原生sql，后续优化再根据文档来)
    @Select("SELECT COUNT(*) FROM system_tenant WHERE update_time > #{maxUpdateTime}")
    Long selectCountByUpdateTimeGt(Date maxUpdateTime);

}
