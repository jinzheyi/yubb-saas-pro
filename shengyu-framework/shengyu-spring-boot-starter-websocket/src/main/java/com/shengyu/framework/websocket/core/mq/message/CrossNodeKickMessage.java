package com.shengyu.framework.websocket.core.mq.message;

import com.shengyu.framework.mq.redis.core.pubsub.AbstractRedisChannelMessage;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;

/**
 * 跨节点互踢消息（Redis Pub/Sub）
 *
 * 用途：当新设备在节点 B 登录时，广播互踢消息，
 * 让节点 A 上的同类型旧设备被踢掉。
 *
 * @author 圣钰科技
 */
@Data
@EqualsAndHashCode(callSuper = true)
@Accessors(chain = true)
public class CrossNodeKickMessage extends AbstractRedisChannelMessage {

    /**
     * 用户编号
     */
    private Long userId;

    /**
     * 设备类型
     */
    private Integer deviceType;

    /**
     * 踢人设备显示名（新登录设备）
     */
    private String byDevice;

}
