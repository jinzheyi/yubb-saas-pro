package com.shengyu.framework.mq.redis.config;

import com.shengyu.framework.mq.redis.core.RedisMQTemplate;
import com.shengyu.framework.mq.redis.core.interceptor.RedisMessageInterceptor;
import com.shengyu.framework.redis.config.ShengyuRedisAutoConfiguration;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.AutoConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.data.redis.core.StringRedisTemplate;

import java.util.List;

/**
 * Redis 消息队列 Producer 配置类
 *
 * @author 圣钰科技
 */
@Slf4j
@AutoConfiguration(after = ShengyuRedisAutoConfiguration.class)
public class ShengyuRedisMQProducerAutoConfiguration {

    @Bean
    public RedisMQTemplate redisMQTemplate(StringRedisTemplate redisTemplate,
                                           List<RedisMessageInterceptor> interceptors) {
        RedisMQTemplate redisMQTemplate = new RedisMQTemplate(redisTemplate);
        // 添加拦截器
        interceptors.forEach(redisMQTemplate::addInterceptor);
        return redisMQTemplate;
    }

}
