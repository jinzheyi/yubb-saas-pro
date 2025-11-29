package com.shengyu.module.im.config;

import org.springframework.context.annotation.Configuration;

/**
 * IM配置类
 * 暂时注释掉@Configuration注解，避免Spring自动扫描
 *
 * @author 圣钰科技
 */
@Configuration
public class ImConfig {

    // 移除了ImMessageHandler的Bean定义，因为ImMessageHandler类已经使用了@Component注解
    // Spring会自动扫描并创建这个Bean

}
