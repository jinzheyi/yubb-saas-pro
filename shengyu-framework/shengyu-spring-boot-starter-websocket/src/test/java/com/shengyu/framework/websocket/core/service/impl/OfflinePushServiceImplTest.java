package com.shengyu.framework.websocket.core.service.impl;

import com.shengyu.framework.websocket.core.service.OfflineCallPushResult;
import org.junit.jupiter.api.Test;

import java.util.Collections;

import static org.junit.jupiter.api.Assertions.assertEquals;

class OfflinePushServiceImplTest {

    @Test
    void missingProviderIsTerminalSkippedResultInsteadOfRetryableFailure() {
        OfflinePushServiceImpl service = new OfflinePushServiceImpl();

        assertEquals(OfflineCallPushResult.NOT_CONFIGURED,
                service.pushCallInvite(1L, Collections.singletonMap("callId", "call-a")));
    }
}
