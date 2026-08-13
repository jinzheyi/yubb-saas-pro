package com.shengyu.module.system.service.im;

import com.shengyu.module.system.dal.dataobject.im.ImCallRecordDO;
import com.shengyu.module.system.dal.dataobject.im.ImGroupUserDO;
import com.shengyu.module.system.dal.mysql.im.ImGroupUserMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.time.Duration;
import java.util.concurrent.TimeUnit;

/**
 * 通话安全审计服务
 * 
 * 实现通话信令的安全校验和防护：
 * 1. 信令频率限制（防止恶意刷信令）
 * 2. 通话参与者权限验证
 * 3. 群组通话权限验证
 * 4. 信令数据合法性校验
 *
 * @author 圣钰科技
 */
@Service
@Slf4j
public class CallSecurityService {

    @Resource
    private RedisTemplate<String, Object> redisTemplate;

    @Resource
    private ImCallService callService;

    @Resource
    private ImGroupUserMapper groupUserMapper;

    // Redis Key 前缀
    private static final String CALL_SIGNAL_RATE_LIMIT_KEY = "im:call:signal:rate:";
    private static final String CALL_PARTICIPANT_KEY = "im:call:participant:";

    // 频率限制配置
    private static final int MAX_SIGNALS_PER_MINUTE = 60; // 每分钟最多 60 个信令
    private static final int MAX_SIGNALS_PER_HOUR = 1000; // 每小时最多 1000 个信令

    /**
     * 检查信令频率限制
     * 
     * @param userId 用户ID
     * @param callId 通话ID
     * @return 是否允许
     */
    public boolean checkSignalRateLimit(Long userId, String callId) {
        if (userId == null || callId == null) {
            return false;
        }

        try {
            // 检查每分钟限制
            String minuteKey = CALL_SIGNAL_RATE_LIMIT_KEY + userId + ":min:" + callId;
            Long minuteCount = redisTemplate.opsForValue().increment(minuteKey);
            if (minuteCount == 1) {
                redisTemplate.expire(minuteKey, 1, TimeUnit.MINUTES);
            }
            if (minuteCount > MAX_SIGNALS_PER_MINUTE) {
                log.warn("[CallSecurity] 信令频率超限（每分钟）, userId={}, callId={}, count={}", 
                    userId, callId, minuteCount);
                return false;
            }

            // 检查每小时限制
            String hourKey = CALL_SIGNAL_RATE_LIMIT_KEY + userId + ":hour:" + callId;
            Long hourCount = redisTemplate.opsForValue().increment(hourKey);
            if (hourCount == 1) {
                redisTemplate.expire(hourKey, 1, TimeUnit.HOURS);
            }
            if (hourCount > MAX_SIGNALS_PER_HOUR) {
                log.warn("[CallSecurity] 信令频率超限（每小时）, userId={}, callId={}, count={}", 
                    userId, callId, hourCount);
                return false;
            }

            return true;
        } catch (Exception e) {
            log.error("[CallSecurity] 检查信令频率限制失败, userId={}, callId={}", userId, callId, e);
            // 异常时默认允许（避免误杀）
            return true;
        }
    }

    /**
     * 验证通话参与者权限
     * 
     * @param callId 通话ID
     * @param userId 用户ID
     * @return 是否是通话参与者
     */
    public boolean isCallParticipant(String callId, Long userId) {
        if (callId == null || userId == null) {
            return false;
        }

        try {
            ImCallRecordDO callRecord = callService.getCallRecord(callId);
            if (callRecord == null) {
                log.warn("[CallSecurity] 通话记录不存在, callId={}", callId);
                return false;
            }

            // 检查是否是主叫或被叫
            boolean isParticipant = callRecord.getCallerId().equals(userId) || 
                                   callRecord.getCalleeId().equals(userId);
            
            if (!isParticipant) {
                log.warn("[CallSecurity] 用户不是通话参与者, callId={}, userId={}, callerId={}, calleeId={}", 
                    callId, userId, callRecord.getCallerId(), callRecord.getCalleeId());
            }

            return isParticipant;
        } catch (Exception e) {
            log.error("[CallSecurity] 验证通话参与者权限失败, callId={}, userId={}", callId, userId, e);
            return false;
        }
    }

    /**
     * 验证群组通话权限
     * 
     * @param groupId 群组ID
     * @param userId 用户ID
     * @return 是否有权限参与群组通话
     */
    public boolean hasGroupCallPermission(Long groupId, Long userId) {
        if (groupId == null || userId == null) {
            return false;
        }

        try {
            // 查询用户是否在群组中
            ImGroupUserDO groupUser = groupUserMapper.selectByGroupIdAndUserId(groupId, userId);
            boolean isInGroup = groupUser != null;
            
            if (!isInGroup) {
                log.warn("[CallSecurity] 用户不在群组中, groupId={}, userId={}", groupId, userId);
            }
            
            return isInGroup;
        } catch (Exception e) {
            log.error("[CallSecurity] 验证群组通话权限失败, groupId={}, userId={}", groupId, userId, e);
            return false;
        }
    }

    /**
     * 校验信令数据合法性
     * 
     * @param callId 通话ID
     * @param signalType 信令类型
     * @return 是否合法
     */
    public boolean validateSignalData(String callId, Integer signalType) {
        if (callId == null || callId.isEmpty()) {
            log.warn("[CallSecurity] 通话ID为空");
            return false;
        }

        // CALL_SIGNAL(206) is reserved for in-call media control.  All
        // lifecycle actions (invite/accept/reject/cancel/hangup) are REST
        // endpoints backed by the call state-machine CAS updates.
        if (signalType == null || signalType != 6) {
            log.warn("[CallSecurity] 非媒体控制信令被拒绝, callId={}, signalType={}", callId, signalType);
            return false;
        }

        return true;
    }

    /**
     * 记录安全审计日志
     * 
     * @param userId 用户ID
     * @param callId 通话ID
     * @param action 操作
     * @param result 结果
     */
    public void logSecurityAudit(Long userId, String callId, String action, String result) {
        log.info("[CallSecurity] 安全审计, userId={}, callId={}, action={}, result={}", 
            userId, callId, action, result);
    }

    /**
     * 清理通话参与者缓存
     * 
     * @param callId 通话ID
     */
    public void clearParticipantCache(String callId) {
        if (callId == null) {
            return;
        }

        try {
            String key = CALL_PARTICIPANT_KEY + callId;
            redisTemplate.delete(key);
            log.debug("[CallSecurity] 清理通话参与者缓存, callId={}", callId);
        } catch (Exception e) {
            log.error("[CallSecurity] 清理通话参与者缓存失败, callId={}", callId, e);
        }
    }
}
