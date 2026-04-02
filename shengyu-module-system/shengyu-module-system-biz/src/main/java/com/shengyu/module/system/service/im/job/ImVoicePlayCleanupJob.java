package com.shengyu.module.system.service.im.job;

import com.shengyu.framework.tenant.core.util.TenantUtils;
import com.shengyu.module.system.dal.mysql.im.ImMessageVoicePlayMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;
import java.time.LocalDateTime;

/**
 * 定时清理语音播放状态历史数据。
 */
@Component
@Slf4j
public class ImVoicePlayCleanupJob {

    @Resource
    private ImMessageVoicePlayMapper messageVoicePlayMapper;

    @Value("${im.voice-play.cleanup.enabled:true}")
    private boolean cleanupEnabled;

    @Value("${im.voice-play.cleanup.retention-days:90}")
    private int retentionDays;

    @Value("${im.voice-play.cleanup.batch-size:1000}")
    private int batchSize;

    @Value("${im.voice-play.cleanup.max-batches-per-run:20}")
    private int maxBatchesPerRun;

    @Scheduled(cron = "${im.voice-play.cleanup.cron:0 30 4 * * ?}")
    public void cleanupExpiredRecords() {
        if (!cleanupEnabled) {
            return;
        }
        final int safeRetentionDays = Math.max(1, retentionDays);
        final int safeBatchSize = Math.max(100, batchSize);
        final int safeMaxBatches = Math.max(1, maxBatchesPerRun);
        final LocalDateTime expireBefore = LocalDateTime.now().minusDays(safeRetentionDays);

        TenantUtils.executeIgnore(() -> {
            int totalDeleted = 0;
            for (int i = 0; i < safeMaxBatches; i++) {
                int deleted = messageVoicePlayMapper.deleteExpiredByPlayedTime(expireBefore, safeBatchSize);
                if (deleted <= 0) {
                    break;
                }
                totalDeleted += deleted;
                if (deleted < safeBatchSize) {
                    break;
                }
            }
            if (totalDeleted > 0) {
                log.info("[ImVoicePlayCleanupJob] cleanup finished, retentionDays: {}, deleted: {}",
                        safeRetentionDays, totalDeleted);
            }
        });
    }
}
