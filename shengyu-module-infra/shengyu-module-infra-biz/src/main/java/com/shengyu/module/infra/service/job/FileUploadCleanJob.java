package com.shengyu.module.infra.service.job;

import cn.hutool.core.date.LocalDateTimeUtil;
import cn.hutool.core.lang.Assert;
import com.shengyu.framework.file.core.client.FileClient;
import com.shengyu.framework.quartz.core.handler.JobHandler;
import com.shengyu.framework.tenant.core.aop.TenantIgnore;
import com.shengyu.module.infra.dal.dataobject.file.FileUploadTaskDO;
import com.shengyu.module.infra.dal.mysql.file.FileUploadTaskMapper;
import com.shengyu.module.infra.service.file.FileConfigService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;
import java.time.LocalDateTime;
import java.util.List;

/**
 * 文件分片上传定时清理任务的 Job
 * <p>
 * 清理已过期的分片上传任务，以及超时未完成的上传任务
 * 建议 cron 表达式: 0 0 2 * * ?（每天凌晨2点执行）
 *
 * @author 圣钰科技
 */
@Slf4j
@Component
public class FileUploadCleanJob implements JobHandler {

    @Resource
    private FileUploadTaskMapper uploadTaskMapper;

    @Resource
    private FileConfigService fileConfigService;

    /**
     * 超时未完成任务的阈值（小时），默认 12 小时
     */
    private static final int TIMEOUT_HOURS = 12;

    /**
     * 状态：初始化
     */
    private static final int STATUS_INIT = 0;

    /**
     * 状态：上传中
     */
    private static final int STATUS_UPLOADING = 1;

    /**
     * 状态：已过期
     */
    private static final int STATUS_EXPIRED = 4;

    @Override
    @TenantIgnore
    public String execute(String param) {
        LocalDateTime now = LocalDateTimeUtil.now();

        // 1. 清理已过期的分片上传任务
        int expiredCount = cleanExpiredTasks(now);

        // 2. 清理超时未完成的任务
        int timeoutCount = cleanTimeoutTasks(now);

        String result = String.format("清理分片上传任务完成：过期任务 %d 个，超时任务 %d 个", expiredCount, timeoutCount);
        log.info("[execute]{}", result);
        return result;
    }

    /**
     * 清理已过期的分片上传任务
     *
     * @param now 当前时间
     * @return 清理的任务数量
     */
    private int cleanExpiredTasks(LocalDateTime now) {
        List<FileUploadTaskDO> expiredTasks = uploadTaskMapper.selectExpiredTasks(now);
        if (expiredTasks.isEmpty()) {
            return 0;
        }

        int count = 0;
        for (FileUploadTaskDO task : expiredTasks) {
            try {
                abortTask(task);
                count++;
            } catch (Exception e) {
                log.error("[cleanExpiredTasks][取消过期任务失败] uploadId={}", task.getUploadId(), e);
            }
        }
        return count;
    }

    /**
     * 清理超时未完成的任务
     * <p>
     * 查询 updateTime < 12小时前 且状态为"初始化"或"上传中"的任务
     *
     * @param now 当前时间
     * @return 清理的任务数量
     */
    private int cleanTimeoutTasks(LocalDateTime now) {
        LocalDateTime timeoutTime = LocalDateTimeUtil.offset(now, -TIMEOUT_HOURS, java.time.temporal.ChronoUnit.HOURS);
        List<FileUploadTaskDO> timeoutTasks = uploadTaskMapper.selectTimeoutTasks(timeoutTime);
        if (timeoutTasks.isEmpty()) {
            return 0;
        }

        int count = 0;
        for (FileUploadTaskDO task : timeoutTasks) {
            try {
                abortTask(task);
                count++;
            } catch (Exception e) {
                log.error("[cleanTimeoutTasks][取消超时任务失败] uploadId={}", task.getUploadId(), e);
            }
        }
        return count;
    }

    /**
     * 取消分片上传任务
     * <p>
     * 调用 FileClient 取消 S3 分片上传，并更新任务状态为"已过期"
     *
     * @param task 上传任务
     */
    private void abortTask(FileUploadTaskDO task) {
        // 只对"初始化"或"上传中"状态的任务调用取消分片上传
        if (task.getStatus() == STATUS_INIT || task.getStatus() == STATUS_UPLOADING) {
            FileClient client = fileConfigService.getFileClient(task.getConfigId());
            Assert.notNull(client, "客户端({}) 不能为空", task.getConfigId());
            client.abortMultipartUpload(task.getS3UploadId());
            log.info("[abortTask][取消分片上传] uploadId={}, status={}", task.getUploadId(), task.getStatus());
        }

        // 更新任务状态为"已过期"
        FileUploadTaskDO updateTask = new FileUploadTaskDO();
        updateTask.setId(task.getId());
        updateTask.setStatus(STATUS_EXPIRED);
        uploadTaskMapper.updateById(updateTask);
    }

}
