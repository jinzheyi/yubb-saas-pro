package com.shengyu.module.platform.convert.tenant;

import com.shengyu.module.platform.controller.platform.tenant.vo.tenant.TenantCreateReqVO;
import com.shengyu.module.system.api.user.dto.AdminUserCreateReqDTO;
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
