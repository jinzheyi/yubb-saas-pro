package com.shengyu.module.system.dal.mysql.tenant;

import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.module.system.dal.dataobject.tenant.TenantInviteDO;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface TenantInviteMapper extends BaseMapperX<TenantInviteDO> {
    default TenantInviteDO selectByCode(String code) { return selectOne(TenantInviteDO::getInviteCode, code); }
}
