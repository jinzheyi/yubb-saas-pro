package com.shengyu.module.system.service.im;

import com.shengyu.framework.websocket.core.session.NettySession;

public interface ImPresenceService {

    ImPresenceSnapshot getUserPresence(Long userId);

    void markSessionOnline(NettySession session);

    void markSessionOffline(NettySession session);

    void refreshSessionBizActive(NettySession session);
}
