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
 * 通话录制服务
 * 
 * 处理通话录制的业务逻辑：
 * - 开始录制
 * - 停止录制
 * - 广播录制状态变化
 *
 * @author 圣钰科技
 */
@Service
@Slf4j
public class CallRecordingService {

    @Resource
    private ImCallService callService;

    @Resource
    private ObjectProvider<NettyMessageSender> nettyMessageSenderProvider;

    @Resource
    private NettySessionManager sessionManager;

    /**
     * 开始通话录制
     * 
     * @param callId 通话ID
     * @param userId 发起录制的用户ID
     */
    public void startRecording(String callId, Long userId) {
        log.info("[CallRecording] 开始通话录制, callId={}, userId={}", callId, userId);
        
        // 1. 验证通话是否存在
        ImCallRecordDO callRecord = callService.getCallRecord(callId);
        if (callRecord == null) {
            log.error("[CallRecording] 通话记录不存在, callId={}", callId);
            throw new IllegalArgumentException("通话记录不存在");
        }
        
        // 2. 构建开始录制信令
        JSONObject payload = JSONUtil.createObj()
            .set("type", "call.recording_started")
            .set("callSessionId", callId)
            .set("callId", callId)
            .set("userId", String.valueOf(userId))
            .set("startTime", System.currentTimeMillis());
        
        // 3. 向通话参与者广播开始录制
        broadcastRecordingSignal(callRecord, payload);
        
        log.info("[CallRecording] 开始录制成功, callId={}, userId={}", callId, userId);
    }

    /**
     * 停止通话录制
     * 
     * @param callId 通话ID
     * @param userId 停止录制的用户ID
     * @param recordingFilePath 录制文件路径（客户端上传后提供）
     */
    public void stopRecording(String callId, Long userId, String recordingFilePath) {
        log.info("[CallRecording] 停止通话录制, callId={}, userId={}, filePath={}", 
            callId, userId, recordingFilePath);
        
        // 1. 验证通话是否存在
        ImCallRecordDO callRecord = callService.getCallRecord(callId);
        if (callRecord == null) {
            log.error("[CallRecording] 通话记录不存在, callId={}", callId);
            throw new IllegalArgumentException("通话记录不存在");
        }
        
        // 2. 构建停止录制信令
        JSONObject payload = JSONUtil.createObj()
            .set("type", "call.recording_stopped")
            .set("callSessionId", callId)
            .set("callId", callId)
            .set("userId", String.valueOf(userId))
            .set("stopTime", System.currentTimeMillis())
            .set("recordingFilePath", recordingFilePath);
        
        // 3. 向通话参与者广播停止录制
        broadcastRecordingSignal(callRecord, payload);
        
        log.info("[CallRecording] 停止录制成功, callId={}, userId={}", callId, userId);
    }

    /**
     * 广播录制信令给通话参与者
     */
    private void broadcastRecordingSignal(ImCallRecordDO callRecord, JSONObject payload) {
        NettyMessageSender messageSender = nettyMessageSenderProvider.getIfAvailable();
        if (messageSender == null) {
            log.warn("[CallRecording] NettyMessageSender 不可用，跳过广播");
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
            log.error("[CallRecording] 向主叫方广播录制信令失败, callerId={}", callRecord.getCallerId(), e);
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
                log.error("[CallRecording] 向被叫方广播录制信令失败, calleeId={}", callRecord.getCalleeId(), e);
            }
        }
    }
}
