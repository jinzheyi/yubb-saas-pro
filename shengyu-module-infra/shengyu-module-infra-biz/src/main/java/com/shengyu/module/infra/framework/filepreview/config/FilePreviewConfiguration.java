package com.shengyu.module.infra.framework.filepreview.config;

import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration(proxyBeanMethods = false)
@EnableConfigurationProperties(ImFilePreviewProperties.class)
public class FilePreviewConfiguration {
}
