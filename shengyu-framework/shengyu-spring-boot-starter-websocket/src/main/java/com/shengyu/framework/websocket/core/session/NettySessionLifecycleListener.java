package com.shengyu.framework.websocket.core.session;

/**
 * Netty 会话生命周期监听器
 *
 * 用于将会话在线态、业务活跃等事件同步到外部存储，
 * 例如 Redis presence、审计、监控打点等。
 */
public interface NettySessionLifecycleListener {

    default void onSessionAdded(NettySession session) {
    }

    default void onSessionRemoved(NettySession session) {
    }

    default void onSessionBizActive(NettySession session) {
    }
}
