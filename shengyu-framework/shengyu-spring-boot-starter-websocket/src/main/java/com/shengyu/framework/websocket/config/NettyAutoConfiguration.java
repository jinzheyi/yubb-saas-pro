package com.shengyu.framework.websocket.config;

import com.shengyu.framework.websocket.core.netty.NettyChannelInitializer;
import com.shengyu.framework.websocket.core.netty.NettyServer;
import com.shengyu.framework.websocket.core.processor.MessageProcessorFactory;
import com.shengyu.framework.websocket.core.protocol.MessageType;
import com.shengyu.framework.websocket.core.netty.handler.AuthHandler;
import com.shengyu.framework.websocket.core.netty.handler.ExceptionHandler;
import com.shengyu.framework.websocket.core.netty.handler.HeartbeatHandler;
import com.shengyu.framework.websocket.core.netty.handler.JsonBusinessMessageHandler;
import com.shengyu.framework.websocket.core.netty.handler.ProtobufMessageHandler;
import com.shengyu.framework.websocket.core.netty.handler.WebSocketFrameHandler;
import com.shengyu.framework.websocket.core.processor.impl.FileMessageProcessor;
import com.shengyu.framework.websocket.core.processor.impl.ImageMessageProcessor;
import com.shengyu.framework.websocket.core.processor.impl.ReadReceiptMessageProcessor;
import com.shengyu.framework.websocket.core.processor.impl.TextMessageProcessor;
import com.shengyu.framework.websocket.core.processor.impl.VoiceMessageProcessor;
import com.shengyu.framework.websocket.core.sender.NettyMessageSender;
import com.shengyu.framework.websocket.core.service.AuthService;
import com.shengyu.framework.websocket.core.service.MessageCacheService;
import com.shengyu.framework.websocket.core.service.MessageStorageService;
import com.shengyu.framework.websocket.core.service.OfflinePushService;
import com.shengyu.framework.websocket.core.service.impl.AuthServiceImpl;
import com.shengyu.framework.websocket.core.service.impl.NoOpMessageCacheServiceImpl;
import com.shengyu.framework.websocket.core.service.impl.NoOpMessageStorageServiceImpl;
import com.shengyu.framework.websocket.core.service.impl.OfflinePushServiceImpl;
import com.shengyu.framework.websocket.core.session.NettySessionManager;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.AutoConfiguration;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;

/**
 * Netty 自动配置类
 *
 * @author 圣钰科技
 */
@Slf4j
@AutoConfiguration
@EnableConfigurationProperties({NettyProperties.class, WebSocketProperties.class})
@ConditionalOnProperty(prefix = "shengyu.netty", name = "enable", havingValue = "true", matchIfMissing = true)
public class NettyAutoConfiguration {

    // ========== 核心组件 ==========

    @Bean
    @ConditionalOnMissingBean
    public NettySessionManager nettySessionManager() {
        return new NettySessionManager();
    }

    @Bean
    @ConditionalOnMissingBean
    public MessageProcessorFactory messageProcessorFactory() {
        return new MessageProcessorFactory();
    }

    @Bean
    @ConditionalOnMissingBean
    public AuthService authService() {
        return new AuthServiceImpl();
    }

    @Bean
    @ConditionalOnMissingBean
    public NettyMessageSender nettyMessageSender(NettySessionManager sessionManager) {
        return new NettyMessageSender(sessionManager);
    }

    /**
     * 消息存储服务（默认空实现）
     *
     * 说明：
     * 1. 这是一个默认的空实现，不做实际存储
     * 2. 业务模块应该提供自己的实现
     * 3. 使用 @ConditionalOnMissingBean，业务模块的实现会自动覆盖此默认实现
     */
    @Bean
    @ConditionalOnMissingBean
    public MessageStorageService messageStorageService() {
        log.warn("[Netty] 使用默认的消息存储服务（NoOp），消息不会被持久化。建议业务模块提供自己的实现。");
        return new NoOpMessageStorageServiceImpl();
    }

    /**
     * 消息缓存服务（默认空实现）
     *
     * 说明：
     * 1. 这是一个默认的空实现，不做实际缓存
     * 2. 业务模块可以提供自己的实现来启用缓存功能
     * 3. 使用 @ConditionalOnMissingBean，业务模块的实现会自动覆盖此默认实现
     */
    @Bean
    @ConditionalOnMissingBean
    public MessageCacheService messageCacheService() {
        log.info("[Netty] 使用默认的消息缓存服务（NoOp），缓存功能未启用。");
        return new NoOpMessageCacheServiceImpl();
    }

    @Bean
    @ConditionalOnMissingBean
    public OfflinePushService offlinePushService() {
        return new OfflinePushServiceImpl();
    }

    // ========== Handler ==========

    @Bean
    public WebSocketFrameHandler webSocketFrameHandler(NettySessionManager sessionManager) {
        return new WebSocketFrameHandler(sessionManager);
    }

    @Bean
    public ProtobufMessageHandler protobufMessageHandler(MessageProcessorFactory processorFactory) {
        return new ProtobufMessageHandler(processorFactory);
    }

    @Bean
    public HeartbeatHandler heartbeatHandler(NettySessionManager sessionManager) {
        return new HeartbeatHandler(sessionManager);
    }

    @Bean
    public AuthHandler authHandler(NettySessionManager sessionManager, AuthService authService) {
        return new AuthHandler(sessionManager, authService);
    }

    @Bean
    public JsonBusinessMessageHandler jsonBusinessMessageHandler(MessageProcessorFactory processorFactory) {
        return new JsonBusinessMessageHandler(processorFactory);
    }

    @Bean
    public ExceptionHandler exceptionHandler() {
        return new ExceptionHandler();
    }

    // ========== Netty Server ==========

    @Bean
    public NettyChannelInitializer nettyChannelInitializer(
            NettyProperties nettyProperties,
            WebSocketFrameHandler webSocketFrameHandler,
            ProtobufMessageHandler protobufMessageHandler,
            HeartbeatHandler heartbeatHandler,
            AuthHandler authHandler,
            JsonBusinessMessageHandler jsonBusinessMessageHandler) {
        return new NettyChannelInitializer(
            nettyProperties,
            webSocketFrameHandler,
            protobufMessageHandler,
            heartbeatHandler,
            authHandler,
            jsonBusinessMessageHandler
        );
    }

    @Bean
    public NettyServer nettyServer(
            NettyProperties nettyProperties,
            NettyChannelInitializer channelInitializer) {
        return new NettyServer(nettyProperties, channelInitializer);
    }

    // ========== 消息处理器 ==========

    /**
     * 文本消息处理器
     */
    @Bean
    public TextMessageProcessor textMessageProcessor(
            NettySessionManager sessionManager,
            MessageStorageService messageStorageService,
            MessageProcessorFactory processorFactory) {
        TextMessageProcessor processor = new TextMessageProcessor(sessionManager, messageStorageService);
        processorFactory.registerProcessor(MessageType.TEXT, processor);
        log.info("[Netty] 注册文本消息处理器");
        return processor;
    }

    /**
     * 图片消息处理器
     */
    @Bean
    public ImageMessageProcessor imageMessageProcessor(
            NettySessionManager sessionManager,
            MessageStorageService messageStorageService,
            MessageProcessorFactory processorFactory) {
        ImageMessageProcessor processor = new ImageMessageProcessor(sessionManager, messageStorageService);
        processorFactory.registerProcessor(MessageType.IMAGE, processor);
        log.info("[Netty] 注册图片消息处理器");
        return processor;
    }

    /**
     * 语音消息处理器
     */
    @Bean
    public VoiceMessageProcessor voiceMessageProcessor(
            NettySessionManager sessionManager,
            MessageStorageService messageStorageService,
            MessageProcessorFactory processorFactory) {
        VoiceMessageProcessor processor = new VoiceMessageProcessor(sessionManager, messageStorageService);
        processorFactory.registerProcessor(MessageType.VOICE, processor);
        log.info("[Netty] 注册语音消息处理器");
        return processor;
    }

    /**
     * 文件消息处理器
     */
    @Bean
    public FileMessageProcessor fileMessageProcessor(
            NettySessionManager sessionManager,
            MessageStorageService messageStorageService,
            MessageProcessorFactory processorFactory) {
        FileMessageProcessor processor = new FileMessageProcessor(sessionManager, messageStorageService);
        processorFactory.registerProcessor(MessageType.FILE, processor);
        log.info("[Netty] 注册文件消息处理器");
        return processor;
    }

    /**
     * 已读回执消息处理器
     */
    @Bean
    public ReadReceiptMessageProcessor readReceiptMessageProcessor(
            NettySessionManager sessionManager,
            MessageStorageService messageStorageService,
            MessageProcessorFactory processorFactory) {
        ReadReceiptMessageProcessor processor = new ReadReceiptMessageProcessor(sessionManager, messageStorageService);
        processorFactory.registerProcessor(MessageType.READ_RECEIPT, processor);
        log.info("[Netty] 注册已读回执消息处理器");
        return processor;
    }

    // TODO: 可以继续添加其他消息类型的处理器
    // @Bean
    // public VideoMessageProcessor videoMessageProcessor(...) { ... }
    // @Bean
    // public LocationMessageProcessor locationMessageProcessor(...) { ... }
}
