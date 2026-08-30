package com.shengyu.module.system.service.im;

import cn.hutool.json.JSONObject;
import com.shengyu.framework.common.exception.ServiceException;
import com.shengyu.framework.tenant.core.context.TenantContextHolder;
import com.shengyu.module.system.dal.dataobject.im.ImCallEventOutboxDO;
import com.shengyu.module.system.dal.dataobject.im.ImCallParticipantDO;
import com.shengyu.module.system.dal.dataobject.im.ImCallRecordDO;
import com.shengyu.module.system.dal.dataobject.im.ImGroupUserDO;
import com.shengyu.module.system.dal.mysql.im.ImCallEventOutboxMapper;
import com.shengyu.module.system.dal.mysql.im.ImCallParticipantMapper;
import com.shengyu.module.system.dal.mysql.im.ImCallRecordMapper;
import com.shengyu.module.system.dal.mysql.im.ImGroupUserMapper;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Field;
import java.util.List;
import java.util.Collection;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class ImCallGroupInviteConsistencyTest {

    @Test
    void pendingMemberCanRejectAfterAnotherMemberConnectedTheGroupCall() throws Exception {
        ImCallRecordMapper recordMapper = mock(ImCallRecordMapper.class);
        ImCallParticipantMapper participantMapper = mock(ImCallParticipantMapper.class);
        ImCallServiceImpl service = new ImCallServiceImpl();
        inject(service, "callRecordMapper", recordMapper);
        inject(service, "callParticipantMapper", participantMapper);

        ImCallRecordDO call = new ImCallRecordDO();
        call.setCallId("call-1");
        call.setGroupId(9L);
        call.setState("CONNECTED");
        ImCallParticipantDO participant = new ImCallParticipantDO();
        participant.setCallId("call-1");
        participant.setUserId(2L);
        participant.setInviteState("PENDING");
        when(recordMapper.selectByCallId("call-1")).thenReturn(call);
        when(participantMapper.selectByCallIdAndUserId("call-1", 2L)).thenReturn(participant);

        service.rejectCall("call-1", 2L, "REJECT");

        verify(participantMapper).rejectInvitation("call-1", 2L);
    }

    @Test
    void pendingGroupInviteIsNotExpiredMerelyBecauseCallIsConnected() {
        ImCallEventOutboxMapper outboxMapper = mock(ImCallEventOutboxMapper.class);
        ImCallRecordMapper recordMapper = mock(ImCallRecordMapper.class);
        ImCallParticipantMapper participantMapper = mock(ImCallParticipantMapper.class);
        CapturingCallPushService pushService = new CapturingCallPushService();
        CallEventPublisher publisher = new CallEventPublisher(
                outboxMapper, recordMapper, participantMapper, pushService);

        ImCallEventOutboxDO outbox = new ImCallEventOutboxDO();
        outbox.setId(1L);
        outbox.setTenantId(1L);
        outbox.setCallId("call-1");
        outbox.setRecipientId(2L);
        outbox.setRetryCount(0);
        JSONObject payload = new JSONObject();
        payload.set("type", "call.group_invite");
        payload.set("callId", "call-1");
        payload.set("actorId", 1L);
        outbox.setPayload(payload.toString());

        ImCallRecordDO call = new ImCallRecordDO();
        call.setCallId("call-1");
        call.setState("CONNECTED");
        ImCallParticipantDO participant = new ImCallParticipantDO();
        participant.setInviteState("PENDING");
        when(outboxMapper.selectRetryable(eq(100), any())).thenReturn(List.of(outbox));
        when(recordMapper.selectByCallId("call-1")).thenReturn(call);
        when(participantMapper.selectByCallIdAndUserId("call-1", 2L)).thenReturn(participant);
        publisher.retryPendingEvents();

        org.junit.jupiter.api.Assertions.assertTrue(pushService.delivered);
        verify(outboxMapper, never()).markSkipped(anyLong());
        verify(outboxMapper).markPublished(eq(1L), any());
    }

    @Test
    void busyGroupMemberUsesStableBusinessCodeWithoutLeakingUserId() throws Exception {
        GroupCallService service = new GroupCallService();
        ImCallService callService = mock(ImCallService.class);
        ImGroupUserMapper groupUserMapper = mock(ImGroupUserMapper.class);
        inject(service, "callService", callService);
        inject(service, "groupUserMapper", groupUserMapper);
        when(groupUserMapper.selectByGroupIdAndUserId(9L, 1L)).thenReturn(new ImGroupUserDO());
        when(callService.isUserBusy(1L)).thenReturn(true);

        TenantContextHolder.setTenantId(1L);
        try {
            ServiceException error = assertThrows(ServiceException.class,
                    () -> service.initiateGroupCall(1L, 8L, 9L, List.of(2L), 1, "device"));
            assertEquals(1_002_050_003, error.getCode());
            assertEquals("用户正在通话中", error.getMessage());
        } finally {
            TenantContextHolder.clear();
        }
    }

    private static void inject(Object target, String fieldName, Object value) throws Exception {
        Field field = target.getClass().getDeclaredField(fieldName);
        field.setAccessible(true);
        field.set(target, value);
    }

    private static final class CapturingCallPushService extends CallPushService {
        private boolean delivered;

        @Override
        public CallEventDeliveryResult publishCallEvent(Collection<Long> recipientIds, Long senderId,
                                                         Long tenantId, JSONObject payload) {
            delivered = true;
            return CallEventDeliveryResult.DELIVERED;
        }
    }
}
