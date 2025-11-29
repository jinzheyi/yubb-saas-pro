package com.shengyu.module.im.netty;

import com.alibaba.fastjson.JSON;
import com.shengyu.framework.common.enums.im.ImMessageTypeEnum;
import com.shengyu.framework.common.exception.enums.GlobalErrorCodeConstants;
import com.shengyu.module.im.constants.ImConstants;
import com.shengyu.module.im.dto.ImMessage;
import com.shengyu.module.im.service.ImAuthService;
import com.shengyu.module.im.service.ImGroupService;
import com.shengyu.module.im.service.ImMessageService;
import com.shengyu.module.system.api.oauth2.OAuth2TokenApi;
import io.netty.channel.Channel;
import io.netty.channel.ChannelFuture;
import io.netty.channel.ChannelFutureListener;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.SimpleChannelInboundHandler;
import io.netty.handler.timeout.IdleStateEvent;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.concurrent.*;

import java.time.LocalDateTime;
import java.util.Date;
import java.util.List;

/**
 * IM消息处理器
 *
 * @author 圣钰科技
 */
@Slf4j
@Component
public class ImMessageHandler extends SimpleChannelInboundHandler<String> {

    @Autowired
    private ConnectionManager connectionManager;

    @Autowired
    private ImAuthService imAuthService;

    @Autowired
    private ImMessageService imMessageService;

    @Autowired
    private ImGroupService imGroupService;

    @Autowired
    private OAuth2TokenApi oauth2TokenApi;

    /**
     * 消息加密密钥（Base64编码）
     */
    @Value("${im.encryption.key:}")
    private String encryptionKey;

    /**
     * 是否启用消息加密
     */
    @Value("${im.encryption.enabled:false}")
    private boolean encryptionEnabled;
    
    /**
     * 消息最大重试次数
     */
    @Value("${im.message.maxRetryCount:3}")
    private int maxRetryCount;
    
    /**
     * 消息重试间隔（毫秒）
     */
    @Value("${im.message.retryInterval:1000}")
    private long retryInterval;
    
    /**
     * 待重试消息存储
     * key: messageId
     * value: 重试信息（包含消息、重试次数、下次重试时间）
     */
    private final Map<String, RetryMessageInfo> retryMessageMap = new ConcurrentHashMap<>();
    
    /**
     * 重试定时器
     */
    private final ScheduledExecutorService retryExecutor = Executors.newSingleThreadScheduledExecutor(r -> {
        Thread thread = new Thread(r, "im-message-retry-thread");
        thread.setDaemon(true);
        return thread;
    });
    
    /**
     * 重试消息信息
     */
    private class RetryMessageInfo {
        private final ImMessage message;
        private final Channel channel;
        private int retryCount;
        private long nextRetryTime;
        
        public RetryMessageInfo(ImMessage message, Channel channel) {
            this.message = message;
            this.channel = channel;
            this.retryCount = 0;
            this.nextRetryTime = System.currentTimeMillis();
        }
        
        public ImMessage getMessage() {
            return message;
        }
        
        public Channel getChannel() {
            return channel;
        }
        
        public int getRetryCount() {
            return retryCount;
        }
        
        public void incrementRetryCount() {
            this.retryCount++;
            this.nextRetryTime = System.currentTimeMillis() + retryInterval;
        }
        
        public long getNextRetryTime() {
            return nextRetryTime;
        }
    }
    
    @Override
    public void handlerAdded(ChannelHandlerContext ctx) throws Exception {
        // 启动重试定时器，每秒检查一次待重试消息
        retryExecutor.scheduleAtFixedRate(this::processRetryMessages, 0, 1, TimeUnit.SECONDS);
        super.handlerAdded(ctx);
    }
    
    @Override
    protected void channelRead0(ChannelHandlerContext ctx, String msg) throws Exception {
        try {
            log.debug("收到原始IM消息: {}", msg);
            
            // 解密消息（如果启用了加密）
            String decryptedMsg = msg;
            if (encryptionEnabled && !msg.isEmpty()) {
                log.debug("开始解密消息");
                decryptedMsg = com.shengyu.module.im.util.ImEncryptionUtil.decrypt(msg, encryptionKey);
                log.debug("消息解密成功");
            }
            
            // 解析消息
            ImMessage message = JSON.parseObject(decryptedMsg, ImMessage.class);
            log.info("收到IM消息: type={}, senderId={}, receiverId={}, messageId={}", 
                     message.getType(), message.getSenderId(), message.getReceiverId(), message.getMessageId());

            // 根据消息类型处理
            int type = message.getType();
            if (type == ImMessageTypeEnum.HEARTBEAT.getCode()) {
                handleHeartbeat(ctx, message);
            } else if (type == ImMessageTypeEnum.LOGIN_REQUEST.getCode()) {
                handleLogin(ctx, message);
            } else if (type == ImMessageTypeEnum.SINGLE_CHAT.getCode() ||
                    type == ImMessageTypeEnum.FILE_MESSAGE.getCode() ||
                    type == ImMessageTypeEnum.IMAGE_MESSAGE.getCode() ||
                    type == ImMessageTypeEnum.VOICE_MESSAGE.getCode() ||
                    type == ImMessageTypeEnum.VIDEO_MESSAGE.getCode()) {
                handleSingleChat(ctx, message);
            } else if (type == ImMessageTypeEnum.GROUP_CHAT.getCode()) {
                handleGroupChat(ctx, message);
            } else if (type == ImMessageTypeEnum.MESSAGE_ACK.getCode()) {
                handleMessageAck(ctx, message);
            } else if (type == ImMessageTypeEnum.TOKEN_REFRESH_REQUEST.getCode()) {
                handleTokenRefresh(ctx, message);
            } else {
                log.warn("未知消息类型: {}", message.getType());
            }
        } catch (Exception e) {
            log.error("处理IM消息失败: {}", msg, e);
            // 发送错误消息
            sendErrorMessage(ctx, "消息格式错误");
        }
    }

    /**
     * 处理心跳消息
     */
    private void handleHeartbeat(ChannelHandlerContext ctx, ImMessage message) {
        // 回复心跳
        ImMessage response = new ImMessage();
        response.setType(ImMessageTypeEnum.HEARTBEAT.getCode());
        // 将Date转换为LocalDateTime
        response.setTimestamp(LocalDateTime.now());
        sendMessage(ctx, response);
    }

    /**
     * 处理登录请求
     */
    private void handleLogin(ChannelHandlerContext ctx, ImMessage message) {
        imAuthService.authenticate(ctx, message);
    }

    /**
     * 处理单聊消息
     */
    private void handleSingleChat(ChannelHandlerContext ctx, ImMessage message) {
        try {
            // 1. 验证发送者权限
            Long senderId = connectionManager.getUserIdByChannel(ctx);
            if (senderId == null) {
                sendErrorMessage(ctx, GlobalErrorCodeConstants.UNAUTHORIZED.getMsg());
                return;
            }

            // 2. 验证消息有效性
            if (message.getReceiverId() == null) {
                sendErrorMessage(ctx, GlobalErrorCodeConstants.BAD_REQUEST.getMsg());
                return;
            }

            // 3. 设置消息发送者ID
            message.setSenderId(senderId);

            // 4. 存储消息
            imMessageService.saveMessage(message);

            // 5. 转发消息给接收者
            Channel receiverChannel = connectionManager.getChannelByUserId(message.getReceiverId());
            if (receiverChannel != null && receiverChannel.isActive()) {
                sendMessage(receiverChannel, message);
            } else {
                // 接收者离线，消息已存储在数据库中，上线后会自动获取
                log.info("接收者离线，消息已存储: senderId={}, receiverId={}", senderId, message.getReceiverId());
            }

            // 6. 发送消息确认
            sendMessageAck(ctx, message.getMessageId(), true);
        } catch (Exception e) {
            log.error("处理单聊消息失败: {}", message, e);
            sendErrorMessage(ctx, GlobalErrorCodeConstants.INTERNAL_SERVER_ERROR.getMsg());
        }
    }

    /**
     * 处理群聊消息
     */
    private void handleGroupChat(ChannelHandlerContext ctx, ImMessage message) {
        try {
            // 1. 验证发送者权限
            Long senderId = connectionManager.getUserIdByChannel(ctx);
            if (senderId == null) {
                sendErrorMessage(ctx, GlobalErrorCodeConstants.UNAUTHORIZED.getMsg());
                return;
            }

            // 2. 验证消息有效性
            if (message.getReceiverId() == null) {
                sendErrorMessage(ctx, GlobalErrorCodeConstants.BAD_REQUEST.getMsg());
                return;
            }

            // 3. 设置消息发送者ID
            message.setSenderId(senderId);

            // 4. 存储消息
            imMessageService.saveMessage(message);

            // 5. 获取群成员列表
            List<Long> memberIds = imGroupService.getGroupMemberIds(message.getReceiverId());

            // 6. 转发消息给所有群成员
            for (Long memberId : memberIds) {
                if (memberId.equals(senderId)) {
                    continue; // 跳过发送者自己
                }
                Channel memberChannel = connectionManager.getChannelByUserId(memberId);
                if (memberChannel != null && memberChannel.isActive()) {
                    sendMessage(memberChannel, message);
                } else {
                    // 群成员离线，消息已存储在数据库中，上线后会自动获取
                    log.info("群成员离线，消息已存储: groupId={}, memberId={}", message.getReceiverId(), memberId);
                }
            }

            // 7. 发送消息确认
            sendMessageAck(ctx, message.getMessageId(), true);
        } catch (Exception e) {
            log.error("处理群聊消息失败: {}", message, e);
            sendErrorMessage(ctx, GlobalErrorCodeConstants.INTERNAL_SERVER_ERROR.getMsg());
        }
    }

    /**
     * 处理消息确认
     */
    private void handleMessageAck(ChannelHandlerContext ctx, ImMessage message) {
        try {
            // 1. 验证发送者权限
            Long senderId = connectionManager.getUserIdByChannel(ctx);
            if (senderId == null) {
                sendErrorMessage(ctx, GlobalErrorCodeConstants.UNAUTHORIZED.getMsg());
                return;
            }

            // 2. 更新消息状态为已读
            imMessageService.updateMessageStatus(message.getMessageId(), 1);
            log.info("消息已确认: messageId={}, senderId={}", message.getMessageId(), senderId);
        } catch (Exception e) {
            log.error("处理消息确认失败: {}", message, e);
            sendErrorMessage(ctx, GlobalErrorCodeConstants.INTERNAL_SERVER_ERROR.getMsg());
        }
    }

    /**
     * 处理Token刷新请求
     */
    private void handleTokenRefresh(ChannelHandlerContext ctx, ImMessage message) {
        try {
            // 1. 验证发送者权限
            Long senderId = connectionManager.getUserIdByChannel(ctx);
            if (senderId == null) {
                sendErrorMessage(ctx, GlobalErrorCodeConstants.UNAUTHORIZED.getMsg());
                return;
            }

            // 2. 从消息中获取refreshToken
            String refreshToken = message.getExt();
            if (refreshToken == null || refreshToken.isEmpty()) {
                sendErrorMessage(ctx, GlobalErrorCodeConstants.BAD_REQUEST.getMsg());
                return;
            }

            // 3. 调用系统服务刷新token
            // 注意：这里使用默认的clientId，实际应用中应该根据具体情况获取
            String clientId = ImConstants.DEFAULT_CLIENT_ID;
            com.shengyu.module.system.api.oauth2.dto.OAuth2AccessTokenRespDTO accessTokenRespDTO = oauth2TokenApi.refreshAccessToken(refreshToken, clientId);

            // 4. 构建刷新响应
            ImMessage response = new ImMessage();
            response.setType(ImMessageTypeEnum.TOKEN_REFRESH_RESPONSE.getCode());
            response.setTimestamp(LocalDateTime.now());
            response.setStatus(0); // 成功
            
            // 5. 将新的token信息放入响应的ext字段
            com.alibaba.fastjson.JSONObject tokenInfo = new com.alibaba.fastjson.JSONObject();
            tokenInfo.put("accessToken", accessTokenRespDTO.getAccessToken());
            tokenInfo.put("refreshToken", accessTokenRespDTO.getRefreshToken());
            tokenInfo.put("expiresTime", accessTokenRespDTO.getExpiresTime());
            response.setExt(tokenInfo.toJSONString());

            // 6. 发送刷新响应
            sendMessage(ctx, response);
            log.info("Token刷新成功: senderId={}", senderId);
        } catch (Exception e) {
            log.error("处理Token刷新失败: {}", message, e);
            sendErrorMessage(ctx, GlobalErrorCodeConstants.INTERNAL_SERVER_ERROR.getMsg());
        }
    }

    /**
     * 发送消息（自动处理加密和重试）
     */
    private void sendMessage(ChannelHandlerContext ctx, ImMessage message) {
        sendMessage(ctx.channel(), message);
    }

    /**
     * 发送消息（自动处理加密和重试）
     */
    private void sendMessage(Channel channel, ImMessage message) {
        try {
            String messageJson = JSON.toJSONString(message);
            
            // 加密消息（如果启用了加密）
            String finalMessage = messageJson;
            if (encryptionEnabled) {
                finalMessage = com.shengyu.module.im.util.ImEncryptionUtil.encrypt(messageJson, encryptionKey);
            }
            
            // 发送消息并添加监听器
            channel.writeAndFlush(finalMessage).addListener((ChannelFutureListener) future -> {
                if (!future.isSuccess()) {
                    // 发送失败，添加到重试队列
                    handleSendFailure(message, channel, future.cause());
                }
            });
        } catch (Exception e) {
            log.error("发送消息失败: {}", message, e);
            // 异常，添加到重试队列
            handleSendFailure(message, channel, e);
        }
    }
    
    /**
     * 处理消息发送失败
     */
    private void handleSendFailure(ImMessage message, Channel channel, Throwable cause) {
        String messageId = message.getMessageId();
        if (messageId == null || messageId.isEmpty()) {
            log.error("消息ID为空，无法重试: {}", message, cause);
            return;
        }
        
        RetryMessageInfo retryInfo = retryMessageMap.computeIfAbsent(messageId, k -> new RetryMessageInfo(message, channel));
        
        if (retryInfo.getRetryCount() >= maxRetryCount) {
            // 超过最大重试次数，移除并记录日志
            retryMessageMap.remove(messageId);
            log.error("消息重试超过最大次数，放弃重试: messageId={}, retryCount={}", messageId, retryInfo.getRetryCount());
            return;
        }
        
        // 增加重试次数
        retryInfo.incrementRetryCount();
        log.warn("消息发送失败，将进行重试: messageId={}, retryCount={}, error={}", 
                 messageId, retryInfo.getRetryCount(), cause.getMessage());
    }
    
    /**
     * 处理待重试消息
     */
    private void processRetryMessages() {
        long currentTime = System.currentTimeMillis();
        
        // 遍历所有待重试消息
        for (Map.Entry<String, RetryMessageInfo> entry : retryMessageMap.entrySet()) {
            String messageId = entry.getKey();
            RetryMessageInfo retryInfo = entry.getValue();
            
            // 检查是否到了重试时间
            if (currentTime >= retryInfo.getNextRetryTime()) {
                ImMessage message = retryInfo.getMessage();
                Channel channel = retryInfo.getChannel();
                
                try {
                    if (!channel.isActive()) {
                        // 通道已关闭，移除重试消息
                        retryMessageMap.remove(messageId);
                        log.error("通道已关闭，放弃重试: messageId={}, channel={}", messageId, channel.id());
                        continue;
                    }
                    
                    // 重新发送消息
                    String messageJson = JSON.toJSONString(message);
                    String finalMessage = messageJson;
                    if (encryptionEnabled) {
                        finalMessage = com.shengyu.module.im.util.ImEncryptionUtil.encrypt(messageJson, encryptionKey);
                    }
                    
                    channel.writeAndFlush(finalMessage).addListener((ChannelFutureListener) future -> {
                        if (!future.isSuccess()) {
                            // 再次发送失败，检查是否超过最大重试次数
                            if (retryInfo.getRetryCount() >= maxRetryCount) {
                                retryMessageMap.remove(messageId);
                                log.error("消息重试超过最大次数，放弃重试: messageId={}, retryCount={}", 
                                         messageId, retryInfo.getRetryCount());
                            } else {
                                // 增加重试次数
                                retryInfo.incrementRetryCount();
                                log.warn("消息重试失败，将继续重试: messageId={}, retryCount={}, error={}", 
                                         messageId, retryInfo.getRetryCount(), future.cause().getMessage());
                            }
                        } else {
                            // 发送成功，移除重试消息
                            retryMessageMap.remove(messageId);
                            log.info("消息重试成功: messageId={}, retryCount={}", messageId, retryInfo.getRetryCount());
                        }
                    });
                } catch (Exception e) {
                    log.error("处理重试消息失败: messageId={}, retryCount={}", messageId, retryInfo.getRetryCount(), e);
                    
                    // 异常，检查是否超过最大重试次数
                    if (retryInfo.getRetryCount() >= maxRetryCount) {
                        retryMessageMap.remove(messageId);
                        log.error("消息重试超过最大次数，放弃重试: messageId={}, retryCount={}", 
                                 messageId, retryInfo.getRetryCount());
                    } else {
                        // 增加重试次数
                        retryInfo.incrementRetryCount();
                    }
                }
            }
        }
    }

    /**
     * 发送消息确认
     */
    private void sendMessageAck(ChannelHandlerContext ctx, String messageId, boolean success) {
        ImMessage ackMessage = new ImMessage();
        ackMessage.setType(ImMessageTypeEnum.MESSAGE_ACK.getCode());
        ackMessage.setMessageId(messageId);
        ackMessage.setStatus(success ? 0 : 1);
        ackMessage.setTimestamp(LocalDateTime.now());
        sendMessage(ctx, ackMessage);
    }

    /**
     * 发送错误消息
     */
    private void sendErrorMessage(ChannelHandlerContext ctx, String errorMsg) {
        ImMessage errorMessage = new ImMessage();
        errorMessage.setType(ImMessageTypeEnum.ERROR.getCode());
        errorMessage.setContent(errorMsg);
        errorMessage.setTimestamp(LocalDateTime.now());
        sendMessage(ctx, errorMessage);
    }

    @Override
    public void userEventTriggered(ChannelHandlerContext ctx, Object evt) throws Exception {
        if (evt instanceof IdleStateEvent) {
            IdleStateEvent event = (IdleStateEvent) evt;
            switch (event.state()) {
                case READER_IDLE:
                    // 读空闲，关闭连接
                    log.info("客户端读空闲，关闭连接: {}", ctx.channel().remoteAddress());
                    ctx.close();
                    break;
                case WRITER_IDLE:
                    // 写空闲，发送心跳
                    ImMessage heartbeat = new ImMessage();
                    heartbeat.setType(ImMessageTypeEnum.HEARTBEAT.getCode());
                    heartbeat.setTimestamp(LocalDateTime.now());
                    ctx.writeAndFlush(JSON.toJSONString(heartbeat));
                    break;
                case ALL_IDLE:
                    // 读写都空闲
                    break;
                default:
                    break;
            }
        }
        super.userEventTriggered(ctx, evt);
    }

    @Override
    public void channelActive(ChannelHandlerContext ctx) throws Exception {
        log.info("客户端连接成功: {}", ctx.channel().remoteAddress());
        super.channelActive(ctx);
    }

    @Override
    public void channelInactive(ChannelHandlerContext ctx) throws Exception {
        log.info("客户端断开连接: {}", ctx.channel().remoteAddress());
        // 获取断开连接的用户ID
        Long userId = connectionManager.getUserIdByChannel(ctx);
        // 移除用户连接
        connectionManager.removeConnection(ctx);
        // 如果用户ID不为空，调用logout方法更新用户状态
        if (userId != null) {
            imAuthService.logout(userId);
        }
        // TODO: 通知其他用户该用户下线
        super.channelInactive(ctx);
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) throws Exception {
        log.error("客户端连接异常: {}", ctx.channel().remoteAddress(), cause);
        ctx.close();
    }
}
