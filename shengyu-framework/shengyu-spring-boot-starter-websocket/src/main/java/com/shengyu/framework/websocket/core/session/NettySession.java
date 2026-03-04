package com.shengyu.framework.websocket.core.session;

import io.netty.channel.Channel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Netty 会话信息
 *
 * @author 圣钰科技
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NettySession {

    /**
     * Netty Channel
     */
    private Channel channel;

    /**
     * 用户ID
     */
    private Long userId;

    /**
     * 租户ID（平台端用户为 null）
     */
    private Long tenantId;

    /**
     * 用户类型（1-租户端 2-平台端）
     * 关联 {@link com.shengyu.framework.common.enums.UserTypeEnum}
     */
    private Integer userType;

    /**
     * 用户昵称
     */
    private String nickname;

    /**
     * 设备类型（1-Web 2-iOS 3-Android 4-小程序）
     */
    private Integer deviceType;

    /**
     * 设备ID
     */
    private String deviceId;

    /**
     * 客户端版本
     */
    private String clientVersion;

    /**
     * 认证使用的访问令牌（用于精确撤销/踢下线）
     */
    private String accessToken;

    /**
     * 连接时间
     */
    private Long connectTime;

    /**
     * 最后活跃时间
     */
    private Long lastActiveTime;

    /**
     * 最后一次业务活跃时间（用于 IM 鉴权租约续期）
     */
    private Long lastBizActiveTime;

    /**
     * 鉴权租约到期时间（毫秒时间戳）
     */
    private Long leaseExpireTime;

    /**
     * 最近一次提示续期时间（毫秒时间戳），用于防止频繁提示
     */
    private Long lastRenewSuggestTime;

    /**
     * 会话鉴权状态
     */
    private NettySessionAuthState authState;

    /**
     * 获取 Channel ID
     */
    public String getChannelId() {
        return channel != null ? channel.id().asShortText() : null;
    }

    /**
     * 判断 Channel 是否活跃
     */
    public boolean isActive() {
        return channel != null && channel.isActive();
    }

    /**
     * 更新最后活跃时间
     */
    public void updateLastActiveTime() {
        this.lastActiveTime = System.currentTimeMillis();
    }

    public void updateLastBizActiveTime() {
        this.lastBizActiveTime = System.currentTimeMillis();
    }

    public boolean isLeaseExpired() {
        return leaseExpireTime != null && leaseExpireTime > 0 && System.currentTimeMillis() > leaseExpireTime;
    }

    public void markRenewSuggested() {
        this.lastRenewSuggestTime = System.currentTimeMillis();
    }

    /**
     * 判断是否为租户端用户
     */
    public boolean isTenantUser() {
        return userType != null && userType == 2; // UserTypeEnum.ADMIN
    }

    /**
     * 判断是否为平台端用户
     */
    public boolean isPlatformUser() {
        return userType != null && userType == 0; // UserTypeEnum.PLATFORM
    }
}
