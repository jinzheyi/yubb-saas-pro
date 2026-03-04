package com.shengyu.framework.websocket.core.mq.message;

import com.shengyu.framework.mq.redis.core.pubsub.AbstractRedisChannelMessage;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;

/**
 * IM 会话撤销消息（Redis Pub/Sub）
 *
 * 用途：HTTP 侧登出/互踢/管理员强退时广播，IM 网关收到后立即断开对应连接。
 *
 * TODO: 后续增加 accessToken / refreshToken 维度的精确撤销，以及按 deviceId/deviceType 精确踢下线。
 */
@Data
@EqualsAndHashCode(callSuper = true)
@Accessors(chain = true)
public class ImSessionRevokeMessage extends AbstractRedisChannelMessage {

    /**
     * 用户编号
     */
    private Long userId;

    /**
     * 用户类型
     */
    private Integer userType;

    /**
     * 租户编号（平台端可为空）
     */
    private Long tenantId;

    /**
     * OAuth2 clientId（用于消费者侧过滤）
     */
    private String clientId;

    /**
     * 操作类型：LOGOUT / KICKED / REVOKED
     */
    private String action;

    /**
     * 原因
     */
    private String reason;

    /**
     * 可选：设备类型
     */
    private Integer deviceType;

    /**
     * 可选：设备ID
     */
    private String deviceId;

    /**
     * 可选：访问令牌（最精确撤销维度）
     */
    private String accessToken;

}
