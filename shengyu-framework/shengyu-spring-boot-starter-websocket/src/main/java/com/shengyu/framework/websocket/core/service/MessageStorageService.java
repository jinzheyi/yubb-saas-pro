package com.shengyu.framework.websocket.core.service;

import com.shengyu.framework.websocket.core.protocol.ImMessage;
import com.shengyu.framework.websocket.core.service.dto.MessageSaveResult;

import java.util.List;

/**
 * 消息存储服务接口（SPI）
 * 
 * 【架构设计】
 * 这是一个 SPI（Service Provider Interface）接口，由业务模块实现。
 * 中间件只负责：
 * 1. 连接管理（Netty 服务器、会话管理）
 * 2. 协议处理（WebSocket、Protobuf）
 * 3. 消息路由（消息分发、消息发送）
 * 4. 认证鉴权（Token 验证）
 * 
 * 业务模块负责：
 * 1. 消息存储（数据库设计、表结构、存储逻辑）
 * 2. 业务逻辑（好友关系、群组管理、会话管理）
 * 3. 业务规则（权限控制、敏感词过滤）
 * 
 * 【实现方式】
 * 在业务模块（如 shengyu-module-system）中创建实现类：
 * 
 * <pre>
 * &#64;Service
 * public class SystemMessageStorageServiceImpl implements MessageStorageService {
 *     
 *     &#64;Autowired
 *     private SystemImMessageMapper messageMapper;
 *     
 *     &#64;Override
 *     public void saveMessage(ImMessage message) {
 *         // 1. 转换为业务 DO 对象
 *         SystemImMessageDO messageDO = convertToMessageDO(message);
 *         
 *         // 2. 保存到数据库
 *         messageMapper.insert(messageDO);
 *         
 *         // 3. 其他业务逻辑（如更新会话、推送通知等）
 *     }
 * }
 * </pre>
 * 
 * 【多租户支持】
 * - system 模块：实现租户端的消息存储，表名如 system_im_message
 * - platform 模块：实现平台端的消息存储，表名如 platform_im_message
 * - 两个模块可以有不同的表结构和业务逻辑
 *
 * @author 圣钰科技
 */
public interface MessageStorageService {

    /**
     * 保存消息
     * 
     * 说明：
     * 1. 中间件在接收到消息后会调用此方法
     * 2. 业务模块负责将消息持久化到数据库
     * 3. 业务模块可以在此方法中实现额外的业务逻辑
     * 
     * @param message IM 消息（Protobuf 对象）
     */
    void saveMessage(ImMessage message);

    /**
     * 保存消息（带返回值）
     * 
     * 说明：
     * 1. 某些场景需要获取保存后的消息ID
     * 2. 业务模块可以返回数据库生成的主键ID
     * 
     * @param message IM 消息
     * @return 消息ID（业务模块生成）
     */
    default Long saveMessageWithId(ImMessage message) {
        saveMessage(message);
        return null;
    }

    /**
     * 保存消息并返回落库结果（用于回填 messageId/sequence 等元数据）
     */
    default MessageSaveResult saveMessageWithResult(ImMessage message) {
        Long id = saveMessageWithId(message);
        return MessageSaveResult.builder()
                .messageId(id)
                .build();
    }

    /**
     * 标记消息为已读（用于 WS 已读回执）
     *
     * 说明：
     * - 中间件收到 READ_RECEIPT 后会调用此方法
     * - 默认实现为空，业务模块按需实现落库逻辑
     *
     * @param userId 当前读者用户ID
     * @param messageIds 消息ID列表
     */
    default void markMessagesRead(Long userId, List<Long> messageIds) {
        // no-op
    }

    /**
     * 批量保存消息
     *
     * 说明：
     * - 使用 MyBatis Batch Executor 模式实现批量写入，适用于大群消息等高性能场景
     * - 批量写入在单个事务中完成，保证数据一致性
     * - 默认实现为空，业务模块按需实现
     *
     * @param messages IM 消息列表（Protobuf 对象）
     * @return 保存成功的消息ID列表
     */
    default List<Long> batchSaveMessages(List<ImMessage> messages) {
        // no-op
        return java.util.Collections.emptyList();
    }
}
