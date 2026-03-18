package com.shengyu.module.system.service.im;

import com.shengyu.framework.tenant.core.context.TenantContextHolder;
import com.shengyu.module.system.dal.dataobject.im.ImUserCursorDO;
import com.shengyu.module.system.dal.mysql.im.ImUserCursorMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.annotation.Resource;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@Slf4j
public class ImCursorVersionService {

    @Resource
    private ImUserCursorMapper userCursorMapper;

    @Transactional(rollbackFor = Exception.class)
    public Long allocateNextCursorVersion(Long userId) {
        if (userId == null || userId <= 0) {
            return 0L;
        }
        Long tenantId = TenantContextHolder.getTenantId();
        if (tenantId == null) {
            tenantId = 0L;
        }
        return allocateNextCursorVersion(tenantId, userId);
    }

    @Transactional(rollbackFor = Exception.class)
    public Long allocateNextCursorVersion(Long tenantId, Long userId) {
        if (userId == null || userId <= 0) {
            return 0L;
        }
        Long tId = tenantId != null ? tenantId : 0L;
        userCursorMapper.insertIgnore(tId, userId);
        ImUserCursorDO cursor = userCursorMapper.selectForUpdate(tId, userId);
        long next = 1L;
        if (cursor != null && cursor.getNextCursorVersion() != null) {
            next = cursor.getNextCursorVersion() + 1L;
        }
        userCursorMapper.updateNext(tId, userId, next);
        return next;
    }

    @Transactional(rollbackFor = Exception.class)
    public Map<Long, Long> allocateNextCursorVersions(Long tenantId, List<Long> userIds) {
        if (userIds == null || userIds.isEmpty()) {
            return Collections.emptyMap();
        }
        Long tId = tenantId != null ? tenantId : 0L;
        List<Long> validUserIds = userIds.stream()
                .filter(uid -> uid != null && uid > 0)
                .distinct()
                .collect(Collectors.toList());
        if (validUserIds.isEmpty()) {
            return Collections.emptyMap();
        }

        userCursorMapper.insertIgnoreBatch(tId, validUserIds);
        userCursorMapper.incrementNextBatch(tId, validUserIds);

        List<ImUserCursorDO> list = userCursorMapper.selectListByUserIds(tId, validUserIds);
        if (list == null || list.isEmpty()) {
            return Collections.emptyMap();
        }
        Map<Long, Long> result = new HashMap<>((int) (list.size() / 0.75f) + 1);
        for (ImUserCursorDO item : list) {
            if (item == null || item.getUserId() == null) {
                continue;
            }
            result.put(item.getUserId(), item.getNextCursorVersion() != null ? item.getNextCursorVersion() : 0L);
        }
        return result;
    }

    @Transactional(rollbackFor = Exception.class)
    public Map<Long, Long> allocateNextCursorVersions(List<Long> userIds) {
        Long tenantId = TenantContextHolder.getTenantId();
        if (tenantId == null) {
            tenantId = 0L;
        }
        return allocateNextCursorVersions(tenantId, userIds);
    }
}
