package com.shengyu.module.infra.api.websocket;

import com.shengyu.framework.websocket.core.sender.WebSocketMessageSender;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;

/**
 * WebSocket 发送器的 API 实现类
 *
 * @author 圣钰科技
 */
@Component
public class WebSocketSenderApiImpl implements WebSocketSenderApi {

    @Resource
    private WebSocketMessageSender webSocketMessageSender;

    @Override
    public void send(Integer userType, Long userId, String messageType, String messageContent) {
        webSocketMessageSender.send(userType, userId, messageType, messageContent);
    }

    @Override
    public void send(Integer userType, String messageType, String messageContent) {
        webSocketMessageSender.send(userType, messageType, messageContent);
    }

    @Override
    public void send(String sessionId, String messageType, String messageContent) {
        webSocketMessageSender.send(sessionId, messageType, messageContent);
    }

}
