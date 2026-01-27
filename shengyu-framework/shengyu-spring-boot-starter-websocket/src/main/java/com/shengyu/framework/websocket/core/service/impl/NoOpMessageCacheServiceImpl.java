package com.shengyu.framework.websocket.core.service.impl;

import com.shengyu.framework.websocket.core.service.MessageCacheService;
import lombok.extern.slf4j.Slf4j;

/**
 * 消息缓存服务空实现（NoOp）
 * 
 * 说明：
 * 1. 这是一个默认的空实现，不做任何实际缓存操作
 * 2. 当业务模块没有提供实现时，使用此默认实现
 * 3. 不会影响中间件的核心功能
 * 4. 业务模块可以提供自己的实现来启用缓存功能
 *
 * @author 圣钰科技
 */
@Slf4j
public class NoOpMessageCacheServiceImpl implements MessageCacheService {

    @Override
    public void cacheUnreadCount(Long userId, long count) {
        log.debug("[NoOpMessageCache] 未读计数未缓存（使用空实现）: userId={}, count={}", userId, count);
    }

    @Override
    public Long getCachedUnreadCount(Long userId) {
        return null;
    }

    @Override
    public void removeCachedUnreadCount(Long userId) {
        // NoOp
    }

    @Override
    public long incrementUnreadCount(Long userId, long delta) {
        log.debug("[NoOpMessageCache] 未读计数增量未缓存（使用空实现）: userId={}, delta={}", userId, delta);
        return 0;
    }
}
