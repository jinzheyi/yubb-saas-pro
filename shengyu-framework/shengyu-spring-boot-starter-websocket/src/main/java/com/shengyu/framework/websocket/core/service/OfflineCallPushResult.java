package com.shengyu.framework.websocket.core.service;

/**
 * 离线来电推送的可判定结果。
 *
 * <p>只有 {@link #RETRYABLE_FAILURE} 可以进入 outbox 重试；配置缺失、用户关闭、
 * 无设备和永久失败都必须终止本次投递，避免把确定性失败放大成重试风暴。</p>
 */
public enum OfflineCallPushResult {
    DELIVERED,
    NOT_CONFIGURED,
    DISABLED,
    NO_DEVICE,
    PERMANENT_FAILURE,
    RETRYABLE_FAILURE
}
