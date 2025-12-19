package com.shengyu.framework.netty.service.impl;

import com.shengyu.framework.common.util.json.JsonUtils;
import com.shengyu.framework.netty.service.NettyMessageService;
import io.netty.channel.Channel;
import io.netty.channel.group.ChannelGroup;
import io.netty.channel.group.DefaultChannelGroup;
import io.netty.handler.codec.http.websocketx.TextWebSocketFrame;
import io.netty.util.concurrent.GlobalEventExecutor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Netty消息发送服务实现类
 *
 * @author zhusy
 * @since 2024/12/19
 */
@Slf4j
@Service
public class NettyMessageServiceImpl implements NettyMessageService {

    /**
     * 存储在线用户通道
     */
    private static final Map<String, Channel> USER_CHANNEL_MAP = new ConcurrentHashMap<>();

    /**
     * 存储所有在线通道
     */
    private static final ChannelGroup CHANNEL_GROUP = new DefaultChannelGroup(GlobalEventExecutor.INSTANCE);

    @Override
    public boolean sendToUser(String userId, Object message) {
        Channel channel = USER_CHANNEL_MAP.get(userId);
        if (channel != null && channel.isActive()) {
            sendToChannel(channel, message);
            return true;
        }
        return false;
    }

    @Override
    public void sendToUsers(List<String> userIds, Object message) {
        for (String userId : userIds) {
            sendToUser(userId, message);
        }
    }

    @Override
    public void sendToAll(Object message) {
        String jsonMessage = JsonUtils.toJsonString(message);
        TextWebSocketFrame frame = new TextWebSocketFrame(jsonMessage);
        CHANNEL_GROUP.writeAndFlush(frame);
    }

    @Override
    public void sendToChannel(Channel channel, Object message) {
        if (channel != null && channel.isActive()) {
            String jsonMessage = JsonUtils.toJsonString(message);
            TextWebSocketFrame frame = new TextWebSocketFrame(jsonMessage);
            channel.writeAndFlush(frame);
        }
    }

    @Override
    public void closeUserChannel(String userId) {
        Channel channel = USER_CHANNEL_MAP.remove(userId);
        if (channel != null) {
            channel.close();
            CHANNEL_GROUP.remove(channel);
        }
    }

    @Override
    public Channel getUserChannel(String userId) {
        return USER_CHANNEL_MAP.get(userId);
    }

    @Override
    public int getOnlineUserCount() {
        return USER_CHANNEL_MAP.size();
    }

    @Override
    public boolean isUserOnline(String userId) {
        Channel channel = USER_CHANNEL_MAP.get(userId);
        return channel != null && channel.isActive();
    }

    @Override
    public void addUserChannel(String userId, Channel channel) {
        USER_CHANNEL_MAP.put(userId, channel);
        CHANNEL_GROUP.add(channel);
    }

    @Override
    public void removeUserChannel(String userId) {
        Channel channel = USER_CHANNEL_MAP.remove(userId);
        if (channel != null) {
            CHANNEL_GROUP.remove(channel);
        }
    }

    /**
     * 根据通道获取用户ID
     *
     * @param channel 通道对象
     * @return 用户ID
     */
    public String getUserIdByChannel(Channel channel) {
        for (Map.Entry<String, Channel> entry : USER_CHANNEL_MAP.entrySet()) {
            if (entry.getValue().equals(channel)) {
                return entry.getKey();
            }
        }
        return null;
    }
}
