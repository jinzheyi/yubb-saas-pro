package com.shengyu.module.im;

import org.springframework.context.annotation.Configuration;

/**
 * IM模块自动配置类
 *
 * @author 圣钰科技
 */
@Configuration
public class ImAutoConfiguration {

    // 移除了@ComponentScan注解，因为Spring Boot会自动扫描组件
    // 移除了手动创建的bean定义，因为ImNettyServer和ImMessageHandler类已经使用了@Component注解
    // Spring会自动扫描并创建这些bean

}
