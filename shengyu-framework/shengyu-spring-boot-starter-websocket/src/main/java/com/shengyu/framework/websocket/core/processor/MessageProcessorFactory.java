package com.shengyu.framework.websocket.core.processor;

import com.shengyu.framework.websocket.core.protocol.ImMessage;
import com.shengyu.framework.websocket.core.protocol.MessageType;
import io.netty.channel.ChannelHandlerContext;
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
     * 空处理器：用于未注册消息类型的兜底（防止 null 导致 NPE）
     */
    private static final MessageProcessor NOOP_PROCESSOR = (ctx, message) ->
        log.warn("[NOOP_PROCESSOR] Dropped unknown message type: {}",
                message.getHeader() != null ? message.getHeader().getMessageType() : "null");

    /**
     * 注册消息处理器
     */
    public void registerProcessor(MessageType messageType, MessageProcessor processor) {
        processorMap.put(messageType, processor);
        log.info("[ProcessorFactory] 注册消息处理器: {}", messageType);
    }

    /**
     * 获取消息处理器（未知类型返回 NOOP_PROCESSOR 并告警）
     */
    public MessageProcessor getProcessor(MessageType messageType) {
        MessageProcessor processor = processorMap.get(messageType);
        if (processor == null) {
            log.error("[ProcessorFactory] UNKNOWN message type: {}, message will be DROPPED!", messageType);
            return NOOP_PROCESSOR;
        }
        return processor;
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
