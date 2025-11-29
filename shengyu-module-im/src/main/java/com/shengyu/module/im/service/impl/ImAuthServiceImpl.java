package com.shengyu.module.im.service.impl;

import com.alibaba.fastjson.JSON;
import com.shengyu.framework.common.enums.UserTypeEnum;
import com.shengyu.framework.security.core.LoginUser;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.framework.common.enums.im.ImMessageTypeEnum;
import com.shengyu.module.im.config.ImSecurityConfig;
import com.shengyu.module.im.dto.ImMessage;
import com.shengyu.module.im.netty.ConnectionManager;
import com.shengyu.module.im.service.ImAuthService;
import com.shengyu.module.im.service.ImMessageService;
import com.shengyu.module.im.service.ImUserService;
import io.netty.channel.ChannelHandlerContext;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

import java.time.LocalDateTime;
import java.util.Date;
import java.util.concurrent.TimeUnit;

/**
 * IM认证服务实现
 *
 * @author 圣钰科技
 */
@Slf4j
@Service
@Validated
public class ImAuthServiceImpl implements ImAuthService {

    @Autowired
    private ConnectionManager connectionManager;

    @Autowired
    private RedisTemplate<String, Object> redisTemplate;

    @Autowired
    private ImSecurityConfig imSecurityConfig;

    @Autowired
    private ImMessageService imMessageService;

    @Autowired
    private ImUserService imUserService;

    @Value("${im.auth.tokenPrefix:im:token:}")
    private String tokenPrefix;

    @Value("${im.auth.tokenExpire:3600}")
    private long tokenExpire;

    @Override
    public boolean authenticate(ChannelHandlerContext ctx, ImMessage message) {
        try {
            // 从消息中获取token
            String token = message.getExt();
            if (token == null || token.isEmpty()) {
                sendLoginResponse(ctx, false, "token不能为空");
                return false;
            }

            // 验证token格式
            if (!imSecurityConfig.validateTokenFormat(token)) {
                sendLoginResponse(ctx, false, "无效的token格式");
                return false;
            }

            // 提取纯净的token
            String pureToken = token;
            // 如果token带有Bearer前缀，去除前缀
            if (token.startsWith("Bearer ")) {
                pureToken = token.substring(7);
            }

            // 验证token并获取用户信息
            LoginUser loginUser = validateToken(pureToken);
            if (loginUser == null) {
                sendLoginResponse(ctx, false, "无效的token");
                return false;
            }

            // 检查用户类型
            if (!UserTypeEnum.ADMIN.getValue().equals(loginUser.getUserType())) {
                sendLoginResponse(ctx, false, "不支持的用户类型");
                return false;
            }

            // 添加用户连接
            connectionManager.addConnection(loginUser.getId(), ctx);

            // 发送登录成功响应
            sendLoginResponse(ctx, true, "登录成功", loginUser);

            // 更新用户在线状态为在线
            imUserService.updateOnlineStatus(loginUser.getId(), 1);

            // 推送离线消息
            pushOfflineMessages(ctx, loginUser.getId());

            // TODO: 通知其他用户该用户上线

            log.info("用户IM登录成功: userId={}, tenantId={}", loginUser.getId(), loginUser.getTenantId());
            return true;
        } catch (Exception e) {
            log.error("IM认证失败: {}", message, e);
            sendLoginResponse(ctx, false, "认证失败");
            return false;
        }
    }

    @Override
    public void logout(Long userId) {
        // 移除用户连接
        connectionManager.removeConnectionByUserId(userId);
        // 更新用户在线状态为离线
        imUserService.updateOnlineStatus(userId, 0);
        // TODO: 通知其他用户该用户下线
        log.info("用户IM登出成功: userId={}", userId);
    }

    /**
     * 验证token
     *
     * @param token token
     * @return 登录用户信息
     */
    private LoginUser validateToken(String token) {
        try {
            // 从Redis中获取登录用户信息
            String key = "login_user:" + token;
            Object loginUserObj = redisTemplate.opsForValue().get(key);
            if (loginUserObj == null) {
                return null;
            }

            // 刷新token过期时间
            redisTemplate.expire(key, tokenExpire, TimeUnit.SECONDS);

            // 转换为LoginUser对象
            if (loginUserObj instanceof LoginUser) {
                return (LoginUser) loginUserObj;
            }
            // 如果是JSON字符串，转换为LoginUser对象
            if (loginUserObj instanceof String) {
                return JSON.parseObject((String) loginUserObj, LoginUser.class);
            }

            return null;
        } catch (Exception e) {
            log.error("验证token失败: {}", token, e);
            return null;
        }
    }

    /**
     * 推送离线消息
     *
     * @param ctx     通道上下文
     * @param userId  用户ID
     */
    private void pushOfflineMessages(ChannelHandlerContext ctx, Long userId) {
        try {
            // 获取用户未读消息
            java.util.List<com.shengyu.module.im.dal.dataobject.ImMessageDO> offlineMessages = imMessageService.getUnreadMessages(userId);
            if (offlineMessages != null && !offlineMessages.isEmpty()) {
                log.info("推送离线消息: userId={}, count={}", userId, offlineMessages.size());
                
                // 转换为ImMessage并发送
                for (com.shengyu.module.im.dal.dataobject.ImMessageDO messageDO : offlineMessages) {
                    ImMessage offlineMessage = new ImMessage();
                    offlineMessage.setMessageId(messageDO.getMessageId());
                    offlineMessage.setType(messageDO.getType());
                    offlineMessage.setSenderId(messageDO.getSenderId());
                    offlineMessage.setReceiverId(messageDO.getReceiverId());
                    offlineMessage.setContent(messageDO.getContent());
                    offlineMessage.setStatus(messageDO.getStatus());
                    offlineMessage.setExt(messageDO.getExt());
                    // 将Date转换为LocalDateTime
                    LocalDateTime createTime = messageDO.getCreateTime();
                    if (createTime != null) {
                        offlineMessage.setTimestamp(createTime);
                    }
                    
                    // 发送离线消息
                    ctx.writeAndFlush(JSON.toJSONString(offlineMessage));
                }
            }
        } catch (Exception e) {
            log.error("推送离线消息失败: userId={}", userId, e);
        }
    }

    /**
     * 发送登录响应
     *
     * @param ctx        通道上下文
     * @param success    是否成功
     * @param message    消息
     * @param loginUser 登录用户信息
     */
    private void sendLoginResponse(ChannelHandlerContext ctx, boolean success, String message, LoginUser loginUser) {
        ImMessage response = new ImMessage();
        response.setType(ImMessageTypeEnum.LOGIN_RESPONSE.getCode());
        response.setContent(message);
        response.setStatus(success ? 0 : 1);
        response.setTimestamp(LocalDateTime.now());
        // 如果登录成功，添加用户信息到扩展字段
        if (success && loginUser != null) {
            response.setSenderId(loginUser.getId());
            // 将用户信息转换为JSON字符串，作为扩展字段
            response.setExt(JSON.toJSONString(loginUser));
        }
        
        try {
            // 从上下文中获取ImMessageHandler的encryptionEnabled和encryptionKey
            // 注意：这里简化处理，实际项目中应该通过配置或注入获取
            boolean encryptionEnabled = false;
            String encryptionKey = "";
            
            String messageJson = JSON.toJSONString(response);
            String finalMessage = messageJson;
            
            // 加密消息（如果启用了加密）
            if (encryptionEnabled && !encryptionKey.isEmpty()) {
                finalMessage = com.shengyu.module.im.util.ImEncryptionUtil.encrypt(messageJson, encryptionKey);
            }
            
            ctx.writeAndFlush(finalMessage);
        } catch (Exception e) {
            log.error("发送登录响应失败: {}", response, e);
            ctx.writeAndFlush(JSON.toJSONString(response)); // 发送原始消息作为 fallback
        }
    }

    /**
     * 发送登录响应
     *
     * @param ctx     通道上下文
     * @param success 是否成功
     * @param message 消息
     */
    private void sendLoginResponse(ChannelHandlerContext ctx, boolean success, String message) {
        sendLoginResponse(ctx, success, message, null);
    }

}
