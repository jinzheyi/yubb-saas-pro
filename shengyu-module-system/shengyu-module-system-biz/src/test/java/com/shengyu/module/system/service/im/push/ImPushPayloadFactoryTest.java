package com.shengyu.module.system.service.im.push;

import org.junit.jupiter.api.Test;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;

class ImPushPayloadFactoryTest {

    private final ImPushPayloadFactory factory = new ImPushPayloadFactory();

    @Test
    void messagePayloadContainsOnlyRoutingFields() {
        Map<String, String> payload = factory.messageData(2L, 3L, "4", "5", 6L);

        assertEquals("1", payload.get("v"));
        assertEquals("im_message", payload.get("kind"));
        assertEquals("3", payload.get("recipientUserId"));
        assertFalse(payload.containsKey("content"));
        assertFalse(payload.containsKey("accessToken"));
    }

    @Test
    void callPayloadContainsNoCallerOrMediaCredential() {
        Map<String, String> payload = factory.callData(2L, "call-1", "7", 8L);

        assertEquals("call-1:7", payload.get("eventId"));
        assertFalse(payload.containsKey("callerName"));
        assertFalse(payload.containsKey("callSessionId"));
        assertFalse(payload.containsKey("token"));
    }
}
