package cn.iocoder.yudao.module.platform.convert.tenant;

import cn.iocoder.yudao.module.platform.controller.platform.tenant.vo.tenant.TenantCreateReqVO;
import cn.iocoder.yudao.module.system.api.user.dto.AdminUserCreateReqDTO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

/**
 * 租户 Convert
 *
 * @author 圣钰科技
 */
@Mapper
public interface TenantConvert {

    TenantConvert INSTANCE = Mappers.getMapper(TenantConvert.class);

    default AdminUserCreateReqDTO convert02(TenantCreateReqVO bean) {
        AdminUserCreateReqDTO reqVO = new AdminUserCreateReqDTO();
        reqVO.setUsername(bean.getUsername());
        reqVO.setPassword(bean.getPassword());
        reqVO.setNickname(bean.getContactName()).setMobile(bean.getContactMobile());
        return reqVO;
    }

}
