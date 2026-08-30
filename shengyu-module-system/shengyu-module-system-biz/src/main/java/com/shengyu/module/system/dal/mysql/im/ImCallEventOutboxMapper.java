package com.shengyu.module.system.dal.mysql.im;

import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.module.system.dal.dataobject.im.ImCallEventOutboxDO;
import org.apache.ibatis.annotations.Mapper;

import java.time.LocalDateTime;
import java.util.List;

@Mapper
public interface ImCallEventOutboxMapper extends BaseMapperX<ImCallEventOutboxDO> {
    default void markPublished(Long id, LocalDateTime publishedAt) {
        update(null, new LambdaUpdateWrapper<ImCallEventOutboxDO>()
                .eq(ImCallEventOutboxDO::getId, id)
                .eq(ImCallEventOutboxDO::getStatus, "PENDING")
                .set(ImCallEventOutboxDO::getStatus, "PUBLISHED")
                .set(ImCallEventOutboxDO::getPublishedAt, publishedAt));
    }

    default void markSkipped(Long id) {
        update(null, new LambdaUpdateWrapper<ImCallEventOutboxDO>()
                .eq(ImCallEventOutboxDO::getId, id)
                .eq(ImCallEventOutboxDO::getStatus, "PENDING")
                .set(ImCallEventOutboxDO::getStatus, "SKIPPED"));
    }

    default List<ImCallEventOutboxDO> selectRetryable(int limit, LocalDateTime now) {
        return selectList(new LambdaQueryWrapper<ImCallEventOutboxDO>()
                .eq(ImCallEventOutboxDO::getStatus, "PENDING")
                .and(w -> w.isNull(ImCallEventOutboxDO::getNextRetryAt)
                        .or().le(ImCallEventOutboxDO::getNextRetryAt, now))
                .orderByAsc(ImCallEventOutboxDO::getId)
                .last("LIMIT " + Math.max(1, Math.min(limit, 500))));
    }

    default void scheduleRetry(Long id, int retryCount, LocalDateTime nextRetryAt) {
        update(null, new LambdaUpdateWrapper<ImCallEventOutboxDO>()
                .eq(ImCallEventOutboxDO::getId, id)
                .eq(ImCallEventOutboxDO::getStatus, "PENDING")
                .set(ImCallEventOutboxDO::getRetryCount, retryCount)
                .set(ImCallEventOutboxDO::getNextRetryAt, nextRetryAt));
    }

    default void markFailed(Long id, int retryCount) {
        update(null, new LambdaUpdateWrapper<ImCallEventOutboxDO>()
                .eq(ImCallEventOutboxDO::getId, id)
                .eq(ImCallEventOutboxDO::getStatus, "PENDING")
                .set(ImCallEventOutboxDO::getStatus, "FAILED")
                .set(ImCallEventOutboxDO::getRetryCount, retryCount));
    }
}
