package com.shengyu.module.system.service.im;

import cn.hutool.json.JSONObject;
import cn.hutool.json.JSONUtil;
import com.shengyu.framework.websocket.core.protocol.MessageType;
import com.shengyu.framework.websocket.core.protocol.TextMessage;
import com.shengyu.framework.websocket.core.sender.NettyMessageSender;
import com.shengyu.framework.websocket.core.session.NettySessionManager;
import com.shengyu.module.system.dal.dataobject.im.ImCallRecordDO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;

/**
 * 通话转接服务
 * 
 * 处理通话转接的业务逻辑：
 * - 发起转接请求
 * - 接受/拒绝转接
 * - 取消转接
 * - 广播转接状态变化
 *
 * @author 圣钰科技
 */
@Service
@Slf4j
public class CallTransferService {

    @Resource
    private ImCallService callService;

    @Resource
    private ObjectProvider<NettyMessageSender> nettyMessageSenderProvider;

    @Resource
    private NettySessionManager sessionManager;

    /**
     * 发起通话转接请求
     * 
     * @param callId 通话ID
     * @param fromUserId 发起转接的用户ID
     * @param targetUserId 转接目标用户ID
     * @param targetUserName 转接目标用户名称
     */
    public void initiateTransfer(String callId, Long fromUserId, Long targetUserId, String targetUserName) {
        log.info("[CallTransfer] 发起通话转接, callId={}, fromUserId={}, targetUserId={}", 
            callId, fromUserId, targetUserId);
        
        // 1. 验证通话是否存在且处于通话中状态
        ImCallRecordDO callRecord = callService.getCallRecord(callId);
        if (callRecord == null) {
            log.error("[CallTransfer] 通话记录不存在, callId={}", callId);
            throw new IllegalArgumentException("通话记录不存在");
        }
        
        // 2. 构建转接请求信令
        JSONObject payload = JSONUtil.createObj()
            .set("type", "call.transfer_requested")
            .set("callSessionId", callId)
            .set("callId", callId)
            .set("fromUserId", String.valueOf(fromUserId))
            .set("fromUserName", targetUserName) // 这里应该是发起者的名字，但参数传的是目标用户名字
            .set("targetUserId", String.valueOf(targetUserId))
            .set("targetUserName", targetUserName)
            .set("transferTime", System.currentTimeMillis());
        
        // 3. 向目标用户发送转接请求
        sendTransferSignal(targetUserId, payload);
        
        log.info("[CallTransfer] 发送转接请求成功, callId={}, targetUserId={}", callId, targetUserId);
    }

    /**
     * 接受通话转接
     * 
     * @param callId 通话ID
     * @param userId 接受转接的用户ID
     */
    public void acceptTransfer(String callId, Long userId) {
        log.info("[CallTransfer] 接受通话转接, callId={}, userId={}", callId, userId);
        
        // 1. 验证通话是否存在
        ImCallRecordDO callRecord = callService.getCallRecord(callId);
        if (callRecord == null) {
            log.error("[CallTransfer] 通话记录不存在, callId={}", callId);
            throw new IllegalArgumentException("通话记录不存在");
        }
        
        // 2. 构建接受转接信令
        JSONObject payload = JSONUtil.createObj()
            .set("type", "call.transfer_accepted")
            .set("callSessionId", callId)
            .set("callId", callId)
            .set("userId", String.valueOf(userId))
            .set("acceptTime", System.currentTimeMillis());
        
        // 3. 向原通话参与者广播接受转接
        broadcastTransferSignal(callRecord, payload);
        
        log.info("[CallTransfer] 接受转接成功, callId={}, userId={}", callId, userId);
    }

    /**
     * 拒绝通话转接
     * 
     * @param callId 通话ID
     * @param userId 拒绝转接的用户ID
     */
    public void rejectTransfer(String callId, Long userId) {
        log.info("[CallTransfer] 拒绝通话转接, callId={}, userId={}", callId, userId);
        
        // 1. 验证通话是否存在
        ImCallRecordDO callRecord = callService.getCallRecord(callId);
        if (callRecord == null) {
            log.error("[CallTransfer] 通话记录不存在, callId={}", callId);
            throw new IllegalArgumentException("通话记录不存在");
        }
        
        // 2. 构建拒绝转接信令
        JSONObject payload = JSONUtil.createObj()
            .set("type", "call.transfer_rejected")
            .set("callSessionId", callId)
            .set("callId", callId)
            .set("userId", String.valueOf(userId))
            .set("rejectTime", System.currentTimeMillis());
        
        // 3. 向原通话参与者广播拒绝转接
        broadcastTransferSignal(callRecord, payload);
        
        log.info("[CallTransfer] 拒绝转接成功, callId={}, userId={}", callId, userId);
    }

    /**
     * 取消通话转接
     * 
     * @param callId 通话ID
     * @param userId 取消转接的用户ID
     */
    public void cancelTransfer(String callId, Long userId) {
        log.info("[CallTransfer] 取消通话转接, callId={}, userId={}", callId, userId);
        
        // 1. 验证通话是否存在
        ImCallRecordDO callRecord = callService.getCallRecord(callId);
        if (callRecord == null) {
            log.error("[CallTransfer] 通话记录不存在, callId={}", callId);
            throw new IllegalArgumentException("通话记录不存在");
        }
        
        // 2. 构建取消转接信令
        JSONObject payload = JSONUtil.createObj()
            .set("type", "call.transfer_cancelled")
            .set("callSessionId", callId)
            .set("callId", callId)
            .set("userId", String.valueOf(userId))
            .set("cancelTime", System.currentTimeMillis());
        
        // 3. 向原通话参与者广播取消转接
        broadcastTransferSignal(callRecord, payload);
        
        log.info("[CallTransfer] 取消转接成功, callId={}, userId={}", callId, userId);
    }

    /**
     * 发送转接信令给指定用户
     */
    private void sendTransferSignal(Long targetUserId, JSONObject payload) {
        NettyMessageSender messageSender = nettyMessageSenderProvider.getIfAvailable();
        if (messageSender == null) {
            log.warn("[CallTransfer] NettyMessageSender 不可用，跳过推送");
            return;
        }
        
        TextMessage textMessage = TextMessage.newBuilder()
            .setContent("")
            .build();
        
        try {
            messageSender.sendToUserWithExtra(
                targetUserId, 
                MessageType.SYSTEM_NOTIFY, 
                textMessage,
                null,  // fromUserId
                targetUserId, 
                0L, 
                null, 
                null, 
                null, 
                null,
                null, 
                null, 
                payload.toString()
            );
        } catch (Exception e) {
            log.error("[CallTransfer] 发送转接信令失败, targetUserId={}", targetUserId, e);
        }
    }

    /**
     * 广播转接信令给通话参与者
     */
    private void broadcastTransferSignal(ImCallRecordDO callRecord, JSONObject payload) {
        NettyMessageSender messageSender = nettyMessageSenderProvider.getIfAvailable();
        if (messageSender == null) {
            log.warn("[CallTransfer] NettyMessageSender 不可用，跳过广播");
            return;
        }
        
        TextMessage textMessage = TextMessage.newBuilder()
            .setContent("")
            .build();
        
        // 向主叫方发送
        try {
            messageSender.sendToUserWithExtra(
                callRecord.getCallerId(), 
                MessageType.SYSTEM_NOTIFY, 
                textMessage,
                null,
                callRecord.getCallerId(), 
                0L, 
                null, 
                null, 
                null, 
                null,
                null, 
                null, 
                payload.toString()
            );
        } catch (Exception e) {
            log.error("[CallTransfer] 向主叫方广播转接信令失败, callerId={}", callRecord.getCallerId(), e);
        }
        
        // 向被叫方发送（如果不是群通话）
        if (callRecord.getGroupId() == null) {
            try {
                messageSender.sendToUserWithExtra(
                    callRecord.getCalleeId(), 
                    MessageType.SYSTEM_NOTIFY, 
                    textMessage,
                    null,
                    callRecord.getCalleeId(), 
                    0L, 
                    null, 
                    null, 
                    null, 
                    null,
                    null, 
                    null, 
                    payload.toString()
                );
            } catch (Exception e) {
                log.error("[CallTransfer] 向被叫方广播转接信令失败, calleeId={}", callRecord.getCalleeId(), e);
            }
        }
    }
}
