package com.shengyu.framework.idempotent.config;

import com.shengyu.framework.idempotent.core.aop.IdempotentAspect;
import com.shengyu.framework.idempotent.core.keyresolver.impl.DefaultIdempotentKeyResolver;
import com.shengyu.framework.idempotent.core.keyresolver.impl.ExpressionIdempotentKeyResolver;
import com.shengyu.framework.idempotent.core.keyresolver.IdempotentKeyResolver;
import com.shengyu.framework.idempotent.core.redis.IdempotentRedisDAO;
import org.springframework.boot.autoconfigure.AutoConfiguration;
import com.shengyu.framework.redis.config.ShengyuRedisAutoConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.data.redis.core.StringRedisTemplate;

import java.util.List;

@AutoConfiguration(after = ShengyuRedisAutoConfiguration.class)
public class ShengyuIdempotentConfiguration {

    @Bean
    public IdempotentAspect idempotentAspect(List<IdempotentKeyResolver> keyResolvers, IdempotentRedisDAO idempotentRedisDAO) {
        return new IdempotentAspect(keyResolvers, idempotentRedisDAO);
    }

    @Bean
    public IdempotentRedisDAO idempotentRedisDAO(StringRedisTemplate stringRedisTemplate) {
        return new IdempotentRedisDAO(stringRedisTemplate);
    }

    // ========== 各种 IdempotentKeyResolver Bean ==========

    @Bean
    public DefaultIdempotentKeyResolver defaultIdempotentKeyResolver() {
        return new DefaultIdempotentKeyResolver();
    }

    @Bean
    public ExpressionIdempotentKeyResolver expressionIdempotentKeyResolver() {
        return new ExpressionIdempotentKeyResolver();
    }

}
