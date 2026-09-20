package com.shengyu.module.platform.dal.mysql.dashboard;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

import java.time.LocalDateTime;

/**
 * 平台工作台跨租户只读聚合。
 *
 * <p>平台模块不依赖 system 业务模块；此 Mapper 只读取公共租户用户表，调用方必须在
 * {@code TenantUtils.executeIgnore} 的受控范围内执行，避免把当前平台登录态误当成租户条件。</p>
 */
@Mapper
public interface PlatformDashboardTenantUserMapper {

    @Select("SELECT COUNT(*) FROM system_users WHERE deleted = 0")
    Long selectTenantUserCount();

    /** 当前未过期 OAuth2 令牌对应的跨租户去重在线用户数。 */
    @Select("SELECT COUNT(DISTINCT user_id) FROM system_oauth2_access_token "
            + "WHERE deleted = 0 AND expires_time > #{now}")
    Long selectOnlineTenantUserCount(LocalDateTime now);
}
