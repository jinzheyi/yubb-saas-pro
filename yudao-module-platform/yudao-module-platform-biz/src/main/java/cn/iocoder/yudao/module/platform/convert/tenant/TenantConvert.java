package cn.iocoder.yudao.module.platform.convert.tenant;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.tenant.TenantCreateReqVO;
import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.tenant.TenantExcelVO;
import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.tenant.TenantRespVO;
import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.tenant.TenantUpdateReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.tenant.PlatformTenantDO;
import cn.iocoder.yudao.module.system.api.user.dto.AdminUserCreateReqDTO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

import java.util.List;

/**
 * 租户 Convert
 *
 * @author 芋道源码
 */
@Mapper
public interface TenantConvert {

    TenantConvert INSTANCE = Mappers.getMapper(TenantConvert.class);

    PlatformTenantDO convert(TenantCreateReqVO bean);

    PlatformTenantDO convert(TenantUpdateReqVO bean);

    TenantRespVO convert(PlatformTenantDO bean);

    List<TenantRespVO> convertList(List<PlatformTenantDO> list);

    PageResult<TenantRespVO> convertPage(PageResult<PlatformTenantDO> page);

    List<TenantExcelVO> convertList02(List<PlatformTenantDO> list);

    default AdminUserCreateReqDTO convert02(TenantCreateReqVO bean) {
        AdminUserCreateReqDTO reqVO = new AdminUserCreateReqDTO();
        reqVO.setUsername(bean.getUsername());
        reqVO.setPassword(bean.getPassword());
        reqVO.setNickname(bean.getContactName())
                .setMobile(bean.getContactMobile());
        return reqVO;
    }

}
