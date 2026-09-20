package com.shengyu.module.platform.controller.platform.dashboard;

import static com.shengyu.framework.common.pojo.CommonResult.success;

import com.shengyu.framework.common.enums.CommonStatusEnum;
import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.security.core.service.SecurityFrameworkService;
import com.shengyu.framework.tenant.core.util.TenantUtils;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.module.platform.dal.dataobject.notice.PlatformNoticeDO;
import com.shengyu.module.platform.dal.dataobject.tenant.TenantDO;
import com.shengyu.module.platform.dal.dataobject.user.PlatformUserDO;
import com.shengyu.module.platform.dal.mysql.notice.PlatformNoticeMapper;
import com.shengyu.module.platform.dal.mysql.dashboard.PlatformDashboardTenantUserMapper;
import com.shengyu.module.platform.dal.mysql.tenant.TenantMapper;
import com.shengyu.module.platform.dal.mysql.user.PlatformUserMapper;
import com.shengyu.module.platform.dal.mysql.oauth2.PlatformOAuth2AccessTokenMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.List;
import java.time.LocalDateTime;
import java.util.concurrent.atomic.AtomicReference;
import javax.annotation.Resource;
import lombok.Data;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "管理后台 - 平台工作台")
@RestController
@RequestMapping("/system/dashboard")
public class PlatformDashboardController {
    @Resource private TenantMapper tenantMapper;
    @Resource private PlatformUserMapper platformUserMapper;
    @Resource private PlatformNoticeMapper platformNoticeMapper;
    @Resource private PlatformDashboardTenantUserMapper tenantUserMapper;
    @Resource private PlatformOAuth2AccessTokenMapper accessTokenMapper;
    @Resource(name = "ps") private SecurityFrameworkService securityFrameworkService;

    @GetMapping("/platform-overview")
    @Operation(summary = "获得平台工作台概览")
    public CommonResult<PlatformOverviewRespVO> getPlatformOverview() {
        PlatformOverviewRespVO resp = new PlatformOverviewRespVO();
        LocalDateTime now = LocalDateTime.now();
        if (securityFrameworkService.hasPermission("system:tenant:query")) {
            List<TenantDO> tenants = tenantMapper.selectList();
            resp.setTenantCount((long) tenants.size());
            resp.setEnabledTenantCount(tenants.stream().filter(t -> CommonStatusEnum.ENABLE.getStatus().equals(t.getStatus())).count());
            // 平台端有明确的上下文绕过机制。仅在该只读聚合中临时绕过，finally 会恢复调用方上下文。
            AtomicReference<Long> tenantUserCount = new AtomicReference<>(0L);
            TenantUtils.executeIgnore(() -> tenantUserCount.set(tenantUserMapper.selectTenantUserCount()));
            resp.setTenantUserCount(tenantUserCount.get());
            AtomicReference<Long> tenantOnlineCount = new AtomicReference<>(0L);
            TenantUtils.executeIgnore(() -> tenantOnlineCount.set(tenantUserMapper.selectOnlineTenantUserCount(now)));
            resp.setTenantOnlineCount(tenantOnlineCount.get());
            resp.setRecentTenants(tenantMapper.selectList(new LambdaQueryWrapperX<TenantDO>()
                    .orderByDesc(TenantDO::getCreateTime).last("LIMIT 6")));
        }
        if (securityFrameworkService.hasPermission("system:user:query")) {
            resp.setPlatformUserCount(platformUserMapper.selectCount());
            resp.setPlatformOnlineCount(accessTokenMapper.selectOnlineUserCount(now));
        }
        if (securityFrameworkService.hasPermission("system:notice:query")) {
            resp.setRecentNotices(platformNoticeMapper.selectList(new LambdaQueryWrapperX<PlatformNoticeDO>()
                    .eq(PlatformNoticeDO::getStatus, CommonStatusEnum.ENABLE.getStatus())
                    .orderByDesc(PlatformNoticeDO::getCreateTime).last("LIMIT 5")));
        }
        return success(resp);
    }

    @Data
    public static class PlatformOverviewRespVO {
        private Long tenantCount;
        private Long enabledTenantCount;
        /** 全租户实际成员数，不使用套餐/额度等配置值 */
        private Long tenantUserCount;
        private Long platformUserCount;
        /** 当前未过期 OAuth2 access token 的去重在线用户数 */
        private Long platformOnlineCount;
        private Long tenantOnlineCount;
        private List<TenantDO> recentTenants;
        private List<PlatformNoticeDO> recentNotices;
    }
}
