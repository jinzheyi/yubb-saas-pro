package com.shengyu.framework.websocket.core.service;

import java.util.Map;

public interface ConversationSnapshotService {

    Map<String, Object> buildSnapshot(Long userId, Long chatId);

}
