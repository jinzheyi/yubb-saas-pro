package com.shengyu.framework.websocket.core.session;

/**
 * Netty 会话鉴权状态
 *
 * @author 圣钰科技
 */
public enum NettySessionAuthState {

    /**
     * 已认证且租约有效
     */
    ACTIVE,

    /**
     * 租约过期，需要重新登录
     */
    EXPIRED,

    /**
     * 被踢下线或撤销
     */
    REVOKED

}
