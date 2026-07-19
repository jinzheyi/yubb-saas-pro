package com.shengyu.framework.websocket.core.session;

/**
 * 跨节点互踢消息发布器接口
 *
 * 用途：当新设备在节点 B 登录时，通过此接口广播互踢消息，
 * 让节点 A 上的同类型旧设备被踢掉。
 *
 * 实现类应在业务模块中提供（如 shengyu-module-system），
 * 通过 Redis Pub/Sub 广播互踢消息。
 *
 * @author 圣钰科技
 */
public interface CrossNodeKickPublisher {

    /**
     * 广播跨节点互踢消息
     *
     * @param userId     用户ID
     * @param deviceType 设备类型
     * @param byDevice   踢人设备显示名（新登录设备）
     */
    void publishKickMessage(Long userId, Integer deviceType, String byDevice);
}
