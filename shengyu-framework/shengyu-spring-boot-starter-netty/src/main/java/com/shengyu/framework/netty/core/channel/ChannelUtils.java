package com.shengyu.framework.netty.core.channel;

import cn.hutool.extra.spring.SpringUtil;
import com.shengyu.framework.netty.core.Attributes;
import io.netty.channel.Channel;
import org.springframework.data.redis.core.RedisTemplate;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class ChannelUtils {

    private static final Map<String, Channel> userIdChannelMap = new ConcurrentHashMap<>();

////    private static RedisTemplate<String, Object> redisTemplate;
////
////    @Resource
////    public void setRedisTemplate(RedisTemplate<String, Object> redisTemplate) {
////        ChannelUtils.redisTemplate = redisTemplate;
////    }
//
//    private static RedisTemplate<String, Object> redisTemplate = SpringUtil.getBean(RedisTemplate.class);

    /**
     * 双向绑定
     * @param userId 用户数据
     * @param channel 通道
     */
    public static void bindUser(String userId, Channel channel) {
        userIdChannelMap.put(userId, channel);
        //redisTemplate.opsForValue().set(userId, channel);
        channel.attr(Attributes.userId).set(userId);
    }

    /**
     * 双向解绑
     * @param channel 通道
     */
    public static void unBindUser(Channel channel) {
        if (hasLogin(channel)) {
            userIdChannelMap.remove(getUserId(channel));
            //redisTemplate.delete(getUserId(channel));
            channel.attr(Attributes.userId).set(null);
        }
    }

    /**
     * 判断当前channel通道是否已绑定用户
     * @param channel 通道
     * @return 布尔结果
     */
    public static boolean hasLogin(Channel channel) {
        return channel.hasAttr(Attributes.userId);
    }

    /**
     * 通过channel通道获取当前通道绑定的用户数据
     * @param channel 通道
     * @return 用户数据
     */
    public static String getUserId(Channel channel) {
        return channel.attr(Attributes.userId).get();
    }

    /**
     * 通过用户ID获取用户对应的channel通道
     * @param userId 用户ID
     * @return 通道
     */
    public static Channel getChannel(String userId) {
        //return (Channel) redisTemplate.opsForValue().get(userId);
        return userIdChannelMap.get(userId);
    }

}
