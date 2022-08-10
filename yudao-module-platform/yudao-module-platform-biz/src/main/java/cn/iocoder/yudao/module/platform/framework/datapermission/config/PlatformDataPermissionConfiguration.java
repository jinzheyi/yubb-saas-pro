package cn.iocoder.yudao.module.platform.framework.datapermission.config;

import cn.iocoder.yudao.module.platform.dal.dataobject.dept.DeptDO;
import cn.iocoder.yudao.module.platform.dal.dataobject.user.AdminUserDO;
import cn.iocoder.yudao.framework.datapermission.core.rule.dept.DeptDataPermissionRuleCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * system 模块的数据权限 Configuration
 *
 * @author 芋道源码
 */
@Configuration(proxyBeanMethods = false)
public class PlatformDataPermissionConfiguration {

    @Bean
    public DeptDataPermissionRuleCustomizer PlatformDeptDataPermissionRuleCustomizer() {
        return rule -> {
            // dept
            rule.addDeptColumn(AdminUserDO.class);
            rule.addDeptColumn(DeptDO.class, "id");
            // user
            rule.addUserColumn(AdminUserDO.class, "id");
        };
    }

}
