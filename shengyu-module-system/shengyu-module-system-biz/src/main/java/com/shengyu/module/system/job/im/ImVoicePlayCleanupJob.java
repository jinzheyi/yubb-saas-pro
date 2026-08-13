package com.shengyu.module.system.job.im;

import com.shengyu.framework.quartz.core.handler.JobHandler;
import com.shengyu.framework.tenant.core.aop.TenantIgnore;
import com.shengyu.module.system.dal.mysql.im.ImMessageVoicePlayMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;
import java.time.LocalDateTime;

/**
 * 语音播放状态历史数据清理任务。
 *
 * <p>播放状态按租户存储，但清理条件与租户无关；任务以全局模式分批清理全部租户的过期记录。</p>
 */
@Component
@Slf4j
public class ImVoicePlayCleanupJob implements JobHandler {

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

    @Override
    @TenantIgnore
    public String execute(String param) {
        if (!cleanupEnabled) {
            return "语音播放状态清理已禁用";
        }
        int safeRetentionDays = Math.max(1, retentionDays);
        int safeBatchSize = Math.max(100, batchSize);
        int safeMaxBatches = Math.max(1, maxBatchesPerRun);
        LocalDateTime expireBefore = LocalDateTime.now().minusDays(safeRetentionDays);

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
        log.info("[ImVoicePlayCleanupJob] 清理完成，retentionDays={}, deleted={}", safeRetentionDays, totalDeleted);
        return String.format("语音播放状态清理完成：删除 %d 条", totalDeleted);
    }
}
