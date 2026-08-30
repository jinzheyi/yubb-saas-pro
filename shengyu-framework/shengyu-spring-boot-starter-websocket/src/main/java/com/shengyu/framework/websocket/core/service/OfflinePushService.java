package com.shengyu.framework.websocket.core.service;

import com.shengyu.framework.websocket.core.protocol.ImMessage;

import java.util.Map;

/**
 * 离线推送服务接口
 * 
 * 功能说明：
 * 1. 当用户离线时，通过第三方推送服务发送通知
 * 2. 支持多种推送平台（极光推送、个推、Firebase等）
 * 3. 支持推送模板配置
 * 4. 支持推送统计和追踪
 * 
 * 使用场景：
 * 1. 用户离线时接收到新消息
 * 2. 系统通知推送
 * 3. 重要消息提醒
 *
 * @author 圣钰科技
 */
public interface OfflinePushService {

    /**
     * 推送离线消息
     *
     * @param userId  用户ID
     * @param message Protobuf 消息对象
     * @return 是否推送成功
     */
    boolean pushOfflineMessage(Long userId, ImMessage message);

    /**
     * 批量推送离线消息
     *
     * @param userId 用户ID
     * @param count  未读消息数
     * @return 是否推送成功
     */
    boolean pushUnreadCount(Long userId, long count);

    /**
     * 推送系统通知
     *
     * @param userId  用户ID
     * @param title   通知标题
     * @param content 通知内容
     * @return 是否推送成功
     */
    boolean pushSystemNotify(Long userId, String title, String content);

    /**
     * 高优先级来电 data push。实现方必须原样携带最小业务字段，严禁加入 RTC Token。
     * 默认明确返回 NOT_CONFIGURED，避免未集成推送平台时伪报成功或无限重试。
     */
    default OfflineCallPushResult pushCallInvite(Long userId, Map<String, String> data) {
        return OfflineCallPushResult.NOT_CONFIGURED;
    }

    /**
     * 检查用户是否启用离线推送
     *
     * @param userId 用户ID
     * @return 是否启用
     */
    boolean isPushEnabled(Long userId);

    /**
     * 设置用户推送开关
     *
     * @param userId  用户ID
     * @param enabled 是否启用
     */
    void setPushEnabled(Long userId, boolean enabled);

    /**
     * 绑定设备推送Token
     *
     * @param userId     用户ID
     * @param deviceType 设备类型（iOS/Android）
     * @param pushToken  推送Token
     */
    void bindPushToken(Long userId, String deviceType, String pushToken);

    /**
     * 解绑设备推送Token
     *
     * @param userId     用户ID
     * @param deviceType 设备类型
     */
    void unbindPushToken(Long userId, String deviceType);
}
