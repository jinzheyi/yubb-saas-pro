package com.shengyu.framework.websocket.core.processor;

import com.shengyu.framework.websocket.core.protocol.MessageType;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 消息处理器工厂
 * 根据消息类型获取对应的处理器
 *
 * @author 圣钰科技
 */
@Slf4j
@Component
public class MessageProcessorFactory {

    private final Map<MessageType, MessageProcessor> processorMap = new ConcurrentHashMap<>();

    /**
     * 注册消息处理器
     */
    public void registerProcessor(MessageType messageType, MessageProcessor processor) {
        processorMap.put(messageType, processor);
        log.info("[ProcessorFactory] 注册消息处理器: {}", messageType);
    }

    /**
     * 获取消息处理器
     */
    public MessageProcessor getProcessor(MessageType messageType) {
        return processorMap.get(messageType);
    }

    /**
     * 移除消息处理器
     */
    public void removeProcessor(MessageType messageType) {
        processorMap.remove(messageType);
        log.info("[ProcessorFactory] 移除消息处理器: {}", messageType);
    }

    /**
     * 获取所有已注册的消息类型
     */
    public Map<MessageType, MessageProcessor> getAllProcessors() {
        return new ConcurrentHashMap<>(processorMap);
    }
}
