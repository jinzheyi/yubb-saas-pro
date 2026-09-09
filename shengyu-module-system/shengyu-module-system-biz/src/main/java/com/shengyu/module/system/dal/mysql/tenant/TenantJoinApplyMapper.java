package com.shengyu.module.system.dal.mysql.tenant;

import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.module.system.dal.dataobject.tenant.TenantJoinApplyDO;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface TenantJoinApplyMapper extends BaseMapperX<TenantJoinApplyDO> {
    default TenantJoinApplyDO selectByTenantAndSaasUser(Long tenantId, Long saasUserId) {
        return selectOne(new LambdaQueryWrapperX<TenantJoinApplyDO>().eq(TenantJoinApplyDO::getTenantId, tenantId).eq(TenantJoinApplyDO::getSaasUserId, saasUserId));
    }
}
