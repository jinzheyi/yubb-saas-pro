package com.shengyu.framework.websocket.config;

import com.shengyu.framework.websocket.core.netty.NettyChannelInitializer;
import com.shengyu.framework.websocket.core.netty.NettyServer;
import com.shengyu.framework.websocket.core.netty.handler.*;
import com.shengyu.framework.websocket.core.processor.MessageProcessorFactory;
import com.shengyu.framework.websocket.core.protocol.MessageType;
import com.shengyu.framework.websocket.core.session.NettyAuthLeaseMonitor;
import com.shengyu.framework.websocket.core.processor.impl.AckMessageProcessor;
import com.shengyu.framework.websocket.core.processor.impl.BadgeUpdateMessageProcessor;
import com.shengyu.framework.websocket.core.processor.impl.FileMessageProcessor;
import com.shengyu.framework.websocket.core.processor.impl.ImageMessageProcessor;
import com.shengyu.framework.websocket.core.processor.impl.LocationMessageProcessor;
import com.shengyu.framework.websocket.core.processor.impl.ReadReceiptMessageProcessor;
import com.shengyu.framework.websocket.core.processor.impl.RecallMessageProcessor;
import com.shengyu.framework.websocket.core.processor.impl.QuoteReplyMessageProcessor;
import com.shengyu.framework.websocket.core.processor.impl.TextMessageProcessor;
import com.shengyu.framework.websocket.core.processor.impl.TypingMessageProcessor;
import com.shengyu.framework.websocket.core.processor.impl.VideoMessageProcessor;
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
    public WebSocketFrameHandler webSocketFrameHandler(NettySessionManager sessionManager, NettyProperties nettyProperties) {
        return new WebSocketFrameHandler(sessionManager, nettyProperties);
    }

    @Bean
    public ProtobufMessageHandler protobufMessageHandler(MessageProcessorFactory processorFactory,
                                                         NettySessionManager sessionManager) {
        return new ProtobufMessageHandler(processorFactory, sessionManager);
    }

    @Bean
    public HeartbeatHandler heartbeatHandler(NettySessionManager sessionManager) {
        return new HeartbeatHandler(sessionManager);
    }

    @Bean
    public AuthHandler authHandler(NettySessionManager sessionManager,
                                   AuthService authService,
                                   NettyProperties nettyProperties) {
        return new AuthHandler(sessionManager, authService, nettyProperties);
    }

    @Bean
    public NettyAuthLeaseMonitor nettyAuthLeaseMonitor(NettySessionManager sessionManager,
                                                       NettyProperties nettyProperties) {
        return new NettyAuthLeaseMonitor(sessionManager, nettyProperties);
    }

    @Bean
    public JsonBusinessMessageHandler jsonBusinessMessageHandler(MessageProcessorFactory processorFactory,
                                                                 NettySessionManager sessionManager) {
        return new JsonBusinessMessageHandler(processorFactory, sessionManager);
    }

    @Bean
    public WebSocketProtobufOutboundHandler webSocketProtobufOutboundHandler() {
        return new WebSocketProtobufOutboundHandler();
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
            WebSocketProtobufOutboundHandler webSocketProtobufOutboundHandler,
            ProtobufMessageHandler protobufMessageHandler,
            HeartbeatHandler heartbeatHandler,
            AuthHandler authHandler,
            JsonBusinessMessageHandler jsonBusinessMessageHandler) {
        return new NettyChannelInitializer(
            nettyProperties,
            webSocketFrameHandler,
            webSocketProtobufOutboundHandler,
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
            com.shengyu.framework.websocket.core.sender.NettyMessageSender messageSender,
            MessageProcessorFactory processorFactory) {
        TextMessageProcessor processor = new TextMessageProcessor(sessionManager, messageStorageService, messageSender);
        processorFactory.registerProcessor(MessageType.TEXT, processor);
        log.info("[Netty] 注册文本消息处理器");
        return processor;
    }

	/**
	 * 引用回复消息处理器
	 */
	@Bean
	public QuoteReplyMessageProcessor quoteReplyMessageProcessor(
			NettySessionManager sessionManager,
			MessageStorageService messageStorageService,
			com.shengyu.framework.websocket.core.sender.NettyMessageSender messageSender,
			MessageProcessorFactory processorFactory) {
		QuoteReplyMessageProcessor processor = new QuoteReplyMessageProcessor(sessionManager, messageStorageService, messageSender);
		processorFactory.registerProcessor(MessageType.QUOTE_REPLY, processor);
		log.info("[Netty] 注册引用回复消息处理器");
		return processor;
	}

    /**
     * 图片消息处理器
     */
    @Bean
    public ImageMessageProcessor imageMessageProcessor(
            NettySessionManager sessionManager,
            MessageStorageService messageStorageService,
            com.shengyu.framework.websocket.core.sender.NettyMessageSender messageSender,
            MessageProcessorFactory processorFactory) {
        ImageMessageProcessor processor = new ImageMessageProcessor(sessionManager, messageStorageService, messageSender);
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
            com.shengyu.framework.websocket.core.sender.NettyMessageSender messageSender,
            MessageProcessorFactory processorFactory) {
        VoiceMessageProcessor processor = new VoiceMessageProcessor(sessionManager, messageStorageService, messageSender);
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
            com.shengyu.framework.websocket.core.sender.NettyMessageSender messageSender,
            MessageProcessorFactory processorFactory) {
        FileMessageProcessor processor = new FileMessageProcessor(sessionManager, messageStorageService, messageSender);
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
            com.shengyu.framework.websocket.core.sender.NettyMessageSender messageSender,
            MessageProcessorFactory processorFactory) {
        ReadReceiptMessageProcessor processor = new ReadReceiptMessageProcessor(sessionManager, messageStorageService, messageSender);
        processorFactory.registerProcessor(MessageType.READ_RECEIPT, processor);
        log.info("[Netty] 注册已读回执消息处理器");
        return processor;
    }

    /**
     * 视频消息处理器
     */
    @Bean
    public VideoMessageProcessor videoMessageProcessor(
            NettySessionManager sessionManager,
            MessageStorageService messageStorageService,
            com.shengyu.framework.websocket.core.sender.NettyMessageSender messageSender,
            MessageProcessorFactory processorFactory) {
        VideoMessageProcessor processor = new VideoMessageProcessor(sessionManager, messageStorageService, messageSender);
        processorFactory.registerProcessor(MessageType.VIDEO, processor);
        log.info("[Netty] 注册视频消息处理器");
        return processor;
    }

    /**
     * 位置消息处理器
     */
    @Bean
    public LocationMessageProcessor locationMessageProcessor(
            NettySessionManager sessionManager,
            MessageStorageService messageStorageService,
            com.shengyu.framework.websocket.core.sender.NettyMessageSender messageSender,
            MessageProcessorFactory processorFactory) {
        LocationMessageProcessor processor = new LocationMessageProcessor(sessionManager, messageStorageService, messageSender);
        processorFactory.registerProcessor(MessageType.LOCATION, processor);
        log.info("[Netty] 注册位置消息处理器");
        return processor;
    }

    /**
     * 消息撤回处理器
     */
    @Bean
    public RecallMessageProcessor recallMessageProcessor(
            NettySessionManager sessionManager,
            com.shengyu.framework.websocket.core.sender.NettyMessageSender messageSender,
            MessageProcessorFactory processorFactory) {
        RecallMessageProcessor processor = new RecallMessageProcessor(sessionManager, messageSender);
        processorFactory.registerProcessor(MessageType.RECALL, processor);
        log.info("[Netty] 注册消息撤回处理器");
        return processor;
    }

    /**
     * 正在输入消息处理器
     */
    @Bean
    public TypingMessageProcessor typingMessageProcessor(
            NettySessionManager sessionManager,
            com.shengyu.framework.websocket.core.sender.NettyMessageSender messageSender,
            MessageProcessorFactory processorFactory) {
        TypingMessageProcessor processor = new TypingMessageProcessor(sessionManager, messageSender);
        processorFactory.registerProcessor(MessageType.TYPING, processor);
        log.info("[Netty] 注册正在输入消息处理器");
        return processor;
    }

    /**
     * 角标更新消息处理器
     */
    @Bean
    public BadgeUpdateMessageProcessor badgeUpdateMessageProcessor(
            NettySessionManager sessionManager,
            com.shengyu.framework.websocket.core.sender.NettyMessageSender messageSender,
            MessageProcessorFactory processorFactory) {
        BadgeUpdateMessageProcessor processor = new BadgeUpdateMessageProcessor(sessionManager, messageSender);
        processorFactory.registerProcessor(MessageType.BADGE_UPDATE, processor);
        log.info("[Netty] 注册角标更新消息处理器");
        return processor;
    }

    /**
     * ACK 消息处理器（轻量投递回执，phase1：仅日志/指标 + 去重）
     */
    @Bean
    public AckMessageProcessor ackMessageProcessor(
            NettySessionManager sessionManager,
            MessageProcessorFactory processorFactory) {
        AckMessageProcessor processor = new AckMessageProcessor(sessionManager);
        processorFactory.registerProcessor(MessageType.ACK, processor);
        log.info("[Netty] 注册 ACK 消息处理器");
        return processor;
    }
}
