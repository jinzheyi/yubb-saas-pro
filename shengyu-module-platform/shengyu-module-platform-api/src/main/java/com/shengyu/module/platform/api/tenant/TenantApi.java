package com.shengyu.module.platform.api.tenant;

import com.shengyu.module.platform.api.tenant.dto.tenant.TenantRespDTO;

import java.util.Collection;
import java.util.List;

/**
 * 多租户的 API 接口
 *
 * @author 圣钰科技
 */
public interface TenantApi {

    /**
     * 获得所有租户
     *
     * @return 租户编号数组
     */
    List<Long> getTenantIdList();

    /**
     * 校验租户是否合法
     *
     * @param id 租户编号
     */
    void validateTenant(Long id);

    /**
     * 通过租户 ID 查询租户
     *
     * @param id 租户ID
     * @return 租户对象信息
     */
    TenantRespDTO getTenant(Long id);

    /**
     * 获得租户列表
     * @param ids 租户ID集合
     * @return 租户列表
     */
    List<TenantRespDTO> getTenantList(Collection<Long> ids);

    /**
     * 获得名字对应的租户
     *
     * @param name 组户名
     * @return 租户
     */
    TenantRespDTO getTenantByName(String name);

    /**
     * 获得域名对应的租户
     *
     * @param website 域名
     * @return 租户
     */
    TenantRespDTO getTenantByWebsite(String website);

}
