package com.shengyu.module.system.service.im;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;

/**
 * 通话时长限制器
 * 
 * 负责监控通话时长，防止通话无限延长
 * 
 * @author 圣钰科技
 */
@Service
@Slf4j
public class CallDurationLimiter {

    @Value("${im.call.max-duration-minutes:240}")
    private int maxDurationMinutes;

    @Value("${im.call.warning-before-minutes:5}")
    private int warningBeforeMinutes;

    /**
     * 通话开始时间缓存
     * key: callId, value: startTime
     */
    private final ConcurrentMap<String, LocalDateTime> callStartTimes = new ConcurrentHashMap<>();

    /**
     * 通话时长回调接口
     */
    public interface CallDurationCallback {
        /**
         * 通话即将超时警告
         * 
         * @param callId 通话 ID
         * @param remainingMinutes 剩余分钟数
         */
        void onCallWarning(String callId, int remainingMinutes);

        /**
         * 通话超时
         * 
         * @param callId 通话 ID
         * @param durationMinutes 实际通话时长（分钟）
         */
        void onCallTimeout(String callId, int durationMinutes);
    }

    private CallDurationCallback callback;

    /**
     * 设置回调
     * 
     * @param callback 回调实现
     */
    public void setCallback(CallDurationCallback callback) {
        this.callback = callback;
    }

    /**
     * 注册通话开始
     * 
     * @param callId 通话 ID
     */
    public void registerCallStart(String callId) {
        callStartTimes.put(callId, LocalDateTime.now());
        log.info("[registerCallStart] 注册通话开始: callId={}, startTime={}", callId, callStartTimes.get(callId));
    }

    /**
     * 移除通话记录
     * 
     * @param callId 通话 ID
     */
    public void unregisterCall(String callId) {
        LocalDateTime removed = callStartTimes.remove(callId);
        if (removed != null) {
            log.info("[unregisterCall] 移除通话记录: callId={}, startTime={}", callId, removed);
        }
    }

    /**
     * 获取通话时长（分钟）
     * 
     * @param callId 通话 ID
     * @return 通话时长（分钟），如果通话不存在返回 -1
     */
    public int getCallDurationMinutes(String callId) {
        LocalDateTime startTime = callStartTimes.get(callId);
        if (startTime == null) {
            return -1;
        }

        LocalDateTime now = LocalDateTime.now();
        long minutes = java.time.Duration.between(startTime, now).toMinutes();
        return (int) minutes;
    }

    /**
     * 检查通话是否即将超时
     * 
     * @param callId 通话 ID
     * @return 是否即将超时
     */
    public boolean isCallAboutToTimeout(String callId) {
        int durationMinutes = getCallDurationMinutes(callId);
        if (durationMinutes < 0) {
            return false;
        }

        int remainingMinutes = maxDurationMinutes - durationMinutes;
        return remainingMinutes <= warningBeforeMinutes && remainingMinutes > 0;
    }

    /**
     * 检查通话是否已超时
     * 
     * @param callId 通话 ID
     * @return 是否已超时
     */
    public boolean isCallTimeout(String callId) {
        int durationMinutes = getCallDurationMinutes(callId);
        if (durationMinutes < 0) {
            return false;
        }

        return durationMinutes >= maxDurationMinutes;
    }

    /**
     * 获取剩余通话时间（分钟）
     * 
     * @param callId 通话 ID
     * @return 剩余分钟数，如果通话不存在返回 -1
     */
    public int getRemainingMinutes(String callId) {
        int durationMinutes = getCallDurationMinutes(callId);
        if (durationMinutes < 0) {
            return -1;
        }

        int remainingMinutes = maxDurationMinutes - durationMinutes;
        return Math.max(0, remainingMinutes);
    }

    /**
     * 定时检查通话时长（每分钟执行一次）
     */
    @Scheduled(fixedRate = 60000) // 每分钟执行一次
    public void checkCallDurations() {
        if (callStartTimes.isEmpty()) {
            return;
        }

        log.debug("[checkCallDurations] 开始检查通话时长，当前监控通话数: {}", callStartTimes.size());

        for (String callId : callStartTimes.keySet()) {
            try {
                int durationMinutes = getCallDurationMinutes(callId);
                int remainingMinutes = maxDurationMinutes - durationMinutes;

                // 即将超时警告
                if (remainingMinutes <= warningBeforeMinutes && remainingMinutes > 0) {
                    log.warn("[checkCallDurations] 通话即将超时: callId={}, durationMinutes={}, remainingMinutes={}", 
                        callId, durationMinutes, remainingMinutes);
                    
                    if (callback != null) {
                        callback.onCallWarning(callId, remainingMinutes);
                    }
                }

                // 已超时
                if (durationMinutes >= maxDurationMinutes) {
                    log.error("[checkCallDurations] 通话已超时: callId={}, durationMinutes={}, maxDurationMinutes={}", 
                        callId, durationMinutes, maxDurationMinutes);
                    
                    if (callback != null) {
                        callback.onCallTimeout(callId, durationMinutes);
                    }
                    
                    // 移除超时通话
                    unregisterCall(callId);
                }
            } catch (Exception e) {
                log.error("[checkCallDurations] 检查通话时长异常: callId={}", callId, e);
            }
        }
    }

    /**
     * 获取当前监控的通话数量
     * 
     * @return 通话数量
     */
    public int getMonitoredCallCount() {
        return callStartTimes.size();
    }

    /**
     * 获取最大通话时长（分钟）
     * 
     * @return 最大通话时长
     */
    public int getMaxDurationMinutes() {
        return maxDurationMinutes;
    }

    /**
     * 获取警告提前时间（分钟）
     * 
     * @return 警告提前时间
     */
    public int getWarningBeforeMinutes() {
        return warningBeforeMinutes;
    }
}
