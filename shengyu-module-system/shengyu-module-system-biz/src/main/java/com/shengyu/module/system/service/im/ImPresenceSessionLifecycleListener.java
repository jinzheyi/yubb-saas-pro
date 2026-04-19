package com.shengyu.module.system.service.im;

import com.shengyu.framework.websocket.core.session.NettySession;
import com.shengyu.framework.websocket.core.session.NettySessionLifecycleListener;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;
import java.util.List;
import java.util.Objects;

/**
 * 将 Netty 会话生命周期同步到 IM presence 服务。
 */
@Component
public class ImPresenceSessionLifecycleListener implements NettySessionLifecycleListener {

    @Resource
    private ImPresenceService imPresenceService;

    @Resource
    private ImPresencePushService imPresencePushService;

    private boolean hasMeaningfulPresenceChange(ImPresenceSnapshot before, ImPresenceSnapshot after) {
        if (before == null && after == null) {
            return false;
        }
        if (before == null || after == null) {
            return true;
        }
        if (!Objects.equals(Boolean.TRUE.equals(before.getOnline()), Boolean.TRUE.equals(after.getOnline()))) {
            return true;
        }
        List<Integer> beforeDevices = before.getOnlineDeviceTypes();
        List<Integer> afterDevices = after.getOnlineDeviceTypes();
        if (!Objects.equals(beforeDevices, afterDevices)) {
            return true;
        }
        if (!Boolean.TRUE.equals(after.getOnline())
                && !Objects.equals(before.getLastActiveTime(), after.getLastActiveTime())) {
            return true;
        }
        return false;
    }

    @Override
    public void onSessionAdded(NettySession session) {
        ImPresenceSnapshot before = imPresenceService.getUserPresence(session != null ? session.getUserId() : null);
        imPresenceService.markSessionOnline(session);
        ImPresenceSnapshot after = imPresenceService.getUserPresence(session != null ? session.getUserId() : null);
        if (session != null && hasMeaningfulPresenceChange(before, after)) {
            imPresencePushService.pushPresenceUpdate(session.getUserId(), after);
        }
    }

    @Override
    public void onSessionRemoved(NettySession session) {
        ImPresenceSnapshot before = imPresenceService.getUserPresence(session != null ? session.getUserId() : null);
        imPresenceService.markSessionOffline(session);
        ImPresenceSnapshot after = imPresenceService.getUserPresence(session != null ? session.getUserId() : null);
        if (session != null && hasMeaningfulPresenceChange(before, after)) {
            imPresencePushService.pushPresenceUpdate(session.getUserId(), after);
        }
    }

    @Override
    public void onSessionBizActive(NettySession session) {
        imPresenceService.refreshSessionBizActive(session);
    }
}
