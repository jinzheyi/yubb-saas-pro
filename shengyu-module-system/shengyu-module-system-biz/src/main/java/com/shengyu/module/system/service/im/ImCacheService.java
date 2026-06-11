package com.shengyu.module.system.service.im;

import com.shengyu.module.system.dal.dataobject.im.ImGroupDO;
import com.shengyu.module.system.dal.dataobject.user.AdminUserDO;
import com.shengyu.module.system.dal.mysql.im.ImGroupMapper;
import com.shengyu.module.system.dal.mysql.user.AdminUserMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * IM 模块缓存服务
 * 
 * 基于项目已有的 Spring Cache + Redis 基础设施（TimeoutRedisCacheManager），
 * 支持自定义过期时间语法：cacheNames 格式为 "key#ttl"，
 * 例如 "im:user#15m" 表示缓存 15 分钟。
 * 
 * @author 圣钰科技
 */
@Service
@Slf4j
public class ImCacheService {

    @Resource
    private AdminUserMapper userMapper;
    
    @Resource
    private ImGroupMapper groupMapper;

    /**
     * 获取用户信息（带缓存，TTL: 15 分钟）
     * 
     * @param userId 用户ID
     * @return 用户信息，不存在返回 null
     */
    @Cacheable(value = "im:user#15m", key = "#userId", unless = "#result == null")
    public AdminUserDO getUserCache(Long userId) {
        log.debug("[ImCacheService] 缓存未命中，查询数据库, userId: {}", userId);
        return userMapper.selectById(userId);
    }

    /**
     * 批量获取用户信息（带缓存）
     * 
     * @param userIds 用户ID列表
     * @return 用户信息 Map
     */
    public Map<Long, AdminUserDO> batchGetUserCache(List<Long> userIds) {
        if (userIds == null || userIds.isEmpty()) {
            return Collections.emptyMap();
        }
        return userIds.stream()
                .collect(Collectors.toMap(
                        userId -> userId,
                        this::getUserCache,
                        (v1, v2) -> v1
                ));
    }

    /**
     * 清除用户信息缓存
     * 
     * @param userId 用户ID
     */
    @CacheEvict(value = "im:user#15m", key = "#userId")
    public void evictUserCache(Long userId) {
        log.info("[ImCacheService] 清除用户缓存, userId: {}", userId);
    }

    /**
     * 获取群信息（带缓存，TTL: 10 分钟）
     * 
     * @param groupId 群ID
     * @return 群信息，不存在返回 null
     */
    @Cacheable(value = "im:group#10m", key = "#groupId", unless = "#result == null")
    public ImGroupDO getGroupCache(Long groupId) {
        log.debug("[ImCacheService] 缓存未命中，查询数据库, groupId: {}", groupId);
        return groupMapper.selectById(groupId);
    }

    /**
     * 批量获取群信息（带缓存）
     * 
     * @param groupIds 群ID列表
     * @return 群信息 Map
     */
    public Map<Long, ImGroupDO> batchGetGroupCache(List<Long> groupIds) {
        if (groupIds == null || groupIds.isEmpty()) {
            return Collections.emptyMap();
        }
        return groupIds.stream()
                .collect(Collectors.toMap(
                        groupId -> groupId,
                        this::getGroupCache,
                        (v1, v2) -> v1
                ));
    }

    /**
     * 清除群信息缓存
     * 
     * @param groupId 群ID
     */
    @CacheEvict(value = "im:group#10m", key = "#groupId")
    public void evictGroupCache(Long groupId) {
        log.info("[ImCacheService] 清除群缓存, groupId: {}", groupId);
    }
}
