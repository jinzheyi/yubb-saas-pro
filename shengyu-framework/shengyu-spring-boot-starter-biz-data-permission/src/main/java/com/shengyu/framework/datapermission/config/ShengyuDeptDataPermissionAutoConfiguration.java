package com.shengyu.framework.datapermission.config;

import com.shengyu.framework.datapermission.core.rule.dept.*;
import com.shengyu.framework.security.core.LoginUser;
import com.shengyu.module.platform.api.permission.PlatformPermissionApi;
import com.shengyu.module.system.api.permission.PermissionApi;
import org.springframework.boot.autoconfigure.AutoConfiguration;
import org.springframework.boot.autoconfigure.condition.ConditionalOnBean;
import org.springframework.boot.autoconfigure.condition.ConditionalOnClass;
import org.springframework.context.annotation.Bean;

import java.util.ArrayList;
import java.util.List;

/**
 * 基于部门的数据权限 AutoConfiguration
 * 
 * 重构说明：支持平台端和租户端各自的数据权限配置
 *
 * @author 圣钰科技
 */
@AutoConfiguration
@ConditionalOnClass(LoginUser.class)
@ConditionalOnBean(value = {DeptDataPermissionRuleCustomizer.class})
public class ShengyuDeptDataPermissionAutoConfiguration {

    /**
     * 租户端（System）数据权限提供者
     */
    @Bean
    @ConditionalOnBean(PermissionApi.class)
    public SystemDeptDataPermissionProvider systemDeptDataPermissionProvider(PermissionApi permissionApi) {
        return new SystemDeptDataPermissionProvider(permissionApi);
    }

    /**
     * 平台端（Platform）数据权限提供者
     */
    @Bean
    @ConditionalOnBean(PlatformPermissionApi.class)
    public PlatformDeptDataPermissionProvider platformDeptDataPermissionProvider(PlatformPermissionApi platformPermissionApi) {
        return new PlatformDeptDataPermissionProvider(platformPermissionApi);
    }

    /**
     * 部门数据权限规则
     */
    @Bean
    public DeptDataPermissionRule deptDataPermissionRule(List<DeptDataPermissionProvider> providers,
                                                         List<DeptDataPermissionRuleCustomizer> customizers) {
        // 创建 DeptDataPermissionRule 对象，传入所有可用的提供者
        DeptDataPermissionRule rule = new DeptDataPermissionRule(providers);
        // 补全表配置
        customizers.forEach(customizer -> customizer.customize(rule));
        return rule;
    }

}
