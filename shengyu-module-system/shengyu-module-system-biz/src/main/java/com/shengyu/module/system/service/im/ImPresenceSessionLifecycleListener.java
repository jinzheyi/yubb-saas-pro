package com.shengyu.module.system.service.im;

import com.shengyu.framework.tenant.core.util.TenantUtils;
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
        runWithSessionTenant(session, () -> {
            ImPresenceSnapshot before = imPresenceService.getUserPresence(session.getUserId());
            imPresenceService.markSessionOnline(session);
            ImPresenceSnapshot after = imPresenceService.getUserPresence(session.getUserId());
            if (hasMeaningfulPresenceChange(before, after)) {
                imPresencePushService.pushPresenceUpdate(session.getUserId(), after);
            }
        });
    }

    @Override
    public void onSessionRemoved(NettySession session) {
        runWithSessionTenant(session, () -> {
            ImPresenceSnapshot before = imPresenceService.getUserPresence(session.getUserId());
            imPresenceService.markSessionOffline(session);
            ImPresenceSnapshot after = imPresenceService.getUserPresence(session.getUserId());
            if (hasMeaningfulPresenceChange(before, after)) {
                imPresencePushService.pushPresenceUpdate(session.getUserId(), after);
            }
        });
    }

    @Override
    public void onSessionBizActive(NettySession session) {
        runWithSessionTenant(session, () -> imPresenceService.refreshSessionBizActive(session));
    }

    private void runWithSessionTenant(NettySession session, Runnable runnable) {
        if (session == null || runnable == null) {
            return;
        }
        Long tenantId = session.getTenantId();
        if (tenantId != null) {
            TenantUtils.execute(tenantId, runnable);
            return;
        }
        runnable.run();
    }
}
