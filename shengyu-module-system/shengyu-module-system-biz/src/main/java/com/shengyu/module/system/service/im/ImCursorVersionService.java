package com.shengyu.module.system.service.im;

import com.shengyu.framework.tenant.core.context.TenantContextHolder;
import com.shengyu.module.system.dal.dataobject.im.ImUserCursorDO;
import com.shengyu.module.system.dal.mysql.im.ImUserCursorMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.annotation.Resource;

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
}
