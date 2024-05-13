package com.shengyu.framework.datapermission.config;

import com.shengyu.framework.datapermission.core.aop.DataPermissionAnnotationAdvisor;
import com.shengyu.framework.datapermission.core.db.DataPermissionDatabaseInterceptor;
import com.shengyu.framework.datapermission.core.rule.DataPermissionRule;
import com.shengyu.framework.datapermission.core.rule.DataPermissionRuleFactory;
import com.shengyu.framework.datapermission.core.rule.DataPermissionRuleFactoryImpl;
import com.shengyu.framework.mybatis.core.util.MyBatisUtils;
import com.baomidou.mybatisplus.extension.plugins.MybatisPlusInterceptor;
import org.springframework.boot.autoconfigure.AutoConfiguration;
import org.springframework.context.annotation.Bean;

import java.util.List;

/**
 * 数据权限的自动配置类
 *
 * @author 圣钰科技
 */
@AutoConfiguration
public class ShengyuDataPermissionAutoConfiguration {

    @Bean
    public DataPermissionRuleFactory dataPermissionRuleFactory(List<DataPermissionRule> rules) {
        return new DataPermissionRuleFactoryImpl(rules);
    }

    @Bean
    public DataPermissionDatabaseInterceptor dataPermissionDatabaseInterceptor(MybatisPlusInterceptor interceptor,
                                                                               DataPermissionRuleFactory ruleFactory) {
        // 创建 DataPermissionDatabaseInterceptor 拦截器
        DataPermissionDatabaseInterceptor inner = new DataPermissionDatabaseInterceptor(ruleFactory);
        // 添加到 interceptor 中
        // 需要加在首个，主要是为了在分页插件前面。这个是 MyBatis Plus 的规定
        MyBatisUtils.addInterceptor(interceptor, inner, 0);
        return inner;
    }

    @Bean
    public DataPermissionAnnotationAdvisor dataPermissionAnnotationAdvisor() {
        return new DataPermissionAnnotationAdvisor();
    }

}
