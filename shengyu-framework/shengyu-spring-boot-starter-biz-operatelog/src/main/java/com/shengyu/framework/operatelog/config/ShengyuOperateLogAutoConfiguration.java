package com.shengyu.framework.operatelog.config;

import com.shengyu.framework.operatelog.core.aop.OperateLogAspect;
import com.shengyu.framework.operatelog.core.service.OperateLogFrameworkService;
import com.shengyu.framework.operatelog.core.service.OperateLogFrameworkServiceImpl;
import com.shengyu.module.platform.api.logger.PlatformOperateLogApi;
import com.shengyu.module.system.api.logger.OperateLogApi;
import org.springframework.boot.autoconfigure.AutoConfiguration;
import org.springframework.context.annotation.Bean;

@AutoConfiguration
public class ShengyuOperateLogAutoConfiguration {

    @Bean
    public OperateLogAspect operateLogAspect() {
        return new OperateLogAspect();
    }

    @Bean
    public OperateLogFrameworkService operateLogFrameworkService(OperateLogApi operateLogApi, PlatformOperateLogApi platformOperateLogApi) {
        return new OperateLogFrameworkServiceImpl(operateLogApi, platformOperateLogApi);
    }

}
