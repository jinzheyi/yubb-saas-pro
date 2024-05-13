package com.shengyu.module.platform.framework.datapermission.config;

import com.shengyu.module.platform.dal.dataobject.dept.PlatformDeptDO;
import com.shengyu.module.platform.dal.dataobject.user.PlatformUserDO;
import com.shengyu.framework.datapermission.core.rule.dept.DeptDataPermissionRuleCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * platform 模块的数据权限 Configuration
 *
 * @author 圣钰科技
 */
@Configuration(proxyBeanMethods = false)
public class PlatformDataPermissionConfiguration {

    @Bean
    public DeptDataPermissionRuleCustomizer psDeptDataPermissionRuleCustomizer() {
        return rule -> {
            // dept
            rule.addDeptColumn(PlatformUserDO.class);
            rule.addDeptColumn(PlatformDeptDO.class, "id");
            // user
            rule.addUserColumn(PlatformUserDO.class, "id");
        };
    }

}
