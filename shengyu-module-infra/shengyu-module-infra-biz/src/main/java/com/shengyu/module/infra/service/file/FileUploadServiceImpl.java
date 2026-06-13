package com.shengyu.module.infra.service.file;

import cn.hutool.core.date.LocalDateTimeUtil;
import cn.hutool.core.io.IoUtil;
import cn.hutool.core.lang.Assert;
import cn.hutool.core.util.StrUtil;
import com.shengyu.framework.file.core.client.FileClient;
import com.shengyu.framework.file.core.client.PartETag;
import com.shengyu.framework.common.exception.util.ServiceExceptionUtil;
import com.shengyu.module.infra.controller.platform.file.vo.file.*;
import com.shengyu.module.infra.dal.dataobject.file.FileDO;
import com.shengyu.module.infra.dal.dataobject.file.FileUploadChunkDO;
import com.shengyu.module.infra.dal.dataobject.file.FileUploadTaskDO;
import com.shengyu.module.infra.dal.mysql.file.FileMapper;
import com.shengyu.module.infra.dal.mysql.file.FileUploadChunkMapper;
import com.shengyu.module.infra.dal.mysql.file.FileUploadTaskMapper;
import lombok.SneakyThrows;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.annotation.Resource;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

import static com.shengyu.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.shengyu.module.infra.enums.ErrorCodeConstants.*;

/**
 * 文件分片上传 Service 实现类
 *
 * @author 圣钰科技
 */
@Service
@Slf4j
public class FileUploadServiceImpl implements FileUploadService {

    /**
     * 分片大小默认值：5MB
     */
    private static final int DEFAULT_CHUNK_SIZE = 5 * 1024 * 1024;

    /**
     * 任务过期时间：24小时
     */
    private static final long EXPIRE_HOURS = 24;

    @Resource
    private FileConfigService fileConfigService;

    @Resource
    private FileUploadTaskMapper uploadTaskMapper;

    @Resource
    private FileUploadChunkMapper uploadChunkMapper;

    @Resource
    private FileMapper fileMapper;

    @Override
    @SneakyThrows
    public FileUploadInitRespVO initMultipartUpload(FileUploadInitReqVO reqVO) {
        // 1. 生成 uploadId
        String uploadId = UUID.randomUUID().toString().replace("-", "");

        // 2. 计算分片大小和总分片数
        int chunkSize = reqVO.getChunkSize() != null && reqVO.getChunkSize() > 0 ? reqVO.getChunkSize() : DEFAULT_CHUNK_SIZE;
        int totalChunks = (int) ((reqVO.getSize() + chunkSize - 1) / chunkSize);

        // 3. 生成目标 path
        String name = reqVO.getName();
        String type = StrUtil.isNotEmpty(reqVO.getType()) ? reqVO.getType() : "application/octet-stream";
        String path = generateUploadPath(name, reqVO.getDirectory());

        // 4. 调用 FileClient 创建分片上传任务
        FileClient client = fileConfigService.getMasterFileClient();
        Assert.notNull(client, "客户端(master) 不能为空");
        String s3UploadId = client.createMultipartUpload(path, type, reqVO.getSize());

        // 5. 插入 FileUploadTaskDO 记录
        LocalDateTime expireTime = LocalDateTimeUtil.offset(LocalDateTimeUtil.now(), EXPIRE_HOURS, java.time.temporal.ChronoUnit.HOURS);
        FileUploadTaskDO task = FileUploadTaskDO.builder()
                .uploadId(uploadId)
                .configId(client.getId())
                .name(name)
                .path(path)
                .type(type)
                .totalSize(reqVO.getSize())
                .chunkSize(chunkSize)
                .totalChunks(totalChunks)
                .uploadedChunks(0)
                .status(0) // 0-初始化
                .expireTime(expireTime)
                .s3UploadId(s3UploadId)
                .build();
        uploadTaskMapper.insert(task);

        // 6. 返回响应
        FileUploadInitRespVO respVO = new FileUploadInitRespVO();
        respVO.setUploadId(uploadId);
        respVO.setChunkSize(chunkSize);
        respVO.setTotalChunks(totalChunks);
        return respVO;
    }

    @Override
    @SneakyThrows
    public FileChunkUploadRespVO uploadChunk(FileChunkUploadReqVO reqVO) {
        // 1. 查询上传任务，校验状态
        FileUploadTaskDO task = validateUploadTaskExists(reqVO.getUploadId());

        // 2. 校验 chunkNumber 范围
        if (reqVO.getChunkNumber() < 1 || reqVO.getChunkNumber() > task.getTotalChunks()) {
            throw exception(FILE_CHUNK_NUMBER_INVALID);
        }

        // 3. 读取分片内容
        byte[] chunkContent = IoUtil.readBytes(reqVO.getChunk().getInputStream());

        // 4. 调用 FileClient 上传分片
        FileClient client = fileConfigService.getFileClient(task.getConfigId());
        Assert.notNull(client, "客户端({}) 不能为空", task.getConfigId());
        String etag;
        try {
            etag = client.uploadPart(task.getS3UploadId(), reqVO.getChunkNumber(), chunkContent);
        } catch (Exception e) {
            log.error("[uploadChunk][分片上传失败] uploadId={}, chunkNumber={}", reqVO.getUploadId(), reqVO.getChunkNumber(), e);
            throw exception(FILE_CHUNK_UPLOAD_FAIL);
        }

        // 5. 插入/更新 FileUploadChunkDO 记录
        List<FileUploadChunkDO> existingChunks = uploadChunkMapper.selectList(
                new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<FileUploadChunkDO>()
                        .eq(FileUploadChunkDO::getUploadId, reqVO.getUploadId())
                        .eq(FileUploadChunkDO::getChunkNumber, reqVO.getChunkNumber()));
        if (existingChunks.isEmpty()) {
            // 新增分片记录
            FileUploadChunkDO chunk = FileUploadChunkDO.builder()
                    .uploadId(reqVO.getUploadId())
                    .chunkNumber(reqVO.getChunkNumber())
                    .chunkSize((long) chunkContent.length)
                    .etag(etag)
                    .status(1) // 1-已完成
                    .build();
            uploadChunkMapper.insert(chunk);
        } else {
            // 更新分片记录（重试场景）
            FileUploadChunkDO chunk = existingChunks.get(0);
            chunk.setChunkSize((long) chunkContent.length);
            chunk.setEtag(etag);
            chunk.setStatus(1);
            uploadChunkMapper.updateById(chunk);
        }

        // 6. 更新已上传分片数
        int uploadedChunks = uploadChunkMapper.selectCompletedChunks(reqVO.getUploadId()).size();
        FileUploadTaskDO updateTask = new FileUploadTaskDO();
        updateTask.setId(task.getId());
        updateTask.setUploadedChunks(uploadedChunks);
        // 如果还有分片未上传，更新状态为"上传中"
        if (task.getStatus() == 0) {
            updateTask.setStatus(1); // 1-上传中
        }
        // 如果全部分片已上传完成，标记为"已完成"
        if (uploadedChunks >= task.getTotalChunks()) {
            updateTask.setStatus(2); // 2-已完成
        }
        uploadTaskMapper.updateById(updateTask);

        // 7. 返回响应
        FileChunkUploadRespVO respVO = new FileChunkUploadRespVO();
        respVO.setUploadId(reqVO.getUploadId());
        respVO.setChunkNumber(reqVO.getChunkNumber());
        respVO.setEtag(etag);
        respVO.setUploadedChunks(uploadedChunks);
        respVO.setTotalChunks(task.getTotalChunks());
        respVO.setCompleted(uploadedChunks >= task.getTotalChunks());
        return respVO;
    }

    @Override
    @SneakyThrows
    @Transactional(rollbackFor = Exception.class)
    public FileMergeRespVO completeMultipartUpload(FileMergeReqVO reqVO) {
        // 1. 查询上传任务，校验所有分片已上传
        FileUploadTaskDO task = validateUploadTaskExists(reqVO.getUploadId());
        List<FileUploadChunkDO> completedChunks = uploadChunkMapper.selectCompletedChunks(reqVO.getUploadId());
        if (completedChunks.size() < task.getTotalChunks()) {
            throw exception(FILE_CHUNK_NOT_ALL_UPLOADED);
        }

        // 2. 构建 PartETag 列表
        List<PartETag> partETags = completedChunks.stream()
                .map(chunk -> new PartETag(chunk.getChunkNumber(), chunk.getEtag()))
                .collect(Collectors.toList());

        // 3. 调用 FileClient 完成分片合并
        FileClient client = fileConfigService.getFileClient(task.getConfigId());
        Assert.notNull(client, "客户端({}) 不能为空", task.getConfigId());
        String url;
        try {
            url = client.completeMultipartUpload(task.getS3UploadId(), partETags);
        } catch (Exception e) {
            log.error("[completeMultipartUpload][分片合并失败] uploadId={}", reqVO.getUploadId(), e);
            throw exception(FILE_MERGE_FAIL);
        }

        // 4. 插入 FileDO 记录
        FileDO fileDO = new FileDO();
        fileDO.setConfigId(task.getConfigId());
        fileDO.setName(task.getName());
        fileDO.setPath(task.getPath());
        fileDO.setUrl(url);
        fileDO.setType(task.getType());
        fileDO.setSize(task.getTotalSize().intValue());
        fileMapper.insert(fileDO);

        // 5. 更新任务状态为"已完成"
        FileUploadTaskDO updateTask = new FileUploadTaskDO();
        updateTask.setId(task.getId());
        updateTask.setStatus(2); // 2-已完成
        uploadTaskMapper.updateById(updateTask);

        // 6. 返回响应
        FileMergeRespVO respVO = new FileMergeRespVO();
        respVO.setUploadId(reqVO.getUploadId());
        respVO.setUrl(url);
        respVO.setFileId(fileDO.getId());
        return respVO;
    }

    @Override
    @SneakyThrows
    public void abortMultipartUpload(String uploadId) {
        // 1. 查询上传任务
        FileUploadTaskDO task = validateUploadTaskExists(uploadId);

        // 2. 调用 FileClient 取消分片上传
        FileClient client = fileConfigService.getFileClient(task.getConfigId());
        Assert.notNull(client, "客户端({}) 不能为空", task.getConfigId());
        try {
            client.abortMultipartUpload(task.getS3UploadId());
        } catch (Exception e) {
            log.error("[abortMultipartUpload][取消分片上传失败] uploadId={}", uploadId, e);
            throw exception(FILE_UPLOAD_FAIL);
        }

        // 3. 更新任务状态为"已取消"
        FileUploadTaskDO updateTask = new FileUploadTaskDO();
        updateTask.setId(task.getId());
        updateTask.setStatus(3); // 3-已取消
        uploadTaskMapper.updateById(updateTask);
    }

    @Override
    public FileUploadStatusRespVO getUploadStatus(String uploadId) {
        // 1. 查询上传任务
        FileUploadTaskDO task = validateUploadTaskExists(uploadId);

        // 2. 计算进度
        double progress = task.getTotalChunks() > 0
                ? (double) task.getUploadedChunks() / task.getTotalChunks()
                : 0.0;

        // 3. 返回响应
        FileUploadStatusRespVO respVO = new FileUploadStatusRespVO();
        respVO.setUploadId(uploadId);
        respVO.setStatus(task.getStatus());
        respVO.setUploadedChunks(task.getUploadedChunks());
        respVO.setTotalChunks(task.getTotalChunks());
        respVO.setProgress(Math.round(progress * 100.0) / 100.0);
        return respVO;
    }

    // ==================== 私有方法 ====================

    /**
     * 校验上传任务是否存在，并检查状态
     *
     * @param uploadId 分片上传唯一标识
     * @return 上传任务
     */
    private FileUploadTaskDO validateUploadTaskExists(String uploadId) {
        FileUploadTaskDO task = uploadTaskMapper.selectByUploadId(uploadId);
        if (task == null) {
            throw exception(FILE_UPLOAD_TASK_NOT_EXISTS);
        }
        // 校验任务是否已过期
        if (LocalDateTimeUtil.now().isAfter(task.getExpireTime())) {
            throw exception(FILE_UPLOAD_TASK_EXPIRED);
        }
        // 校验任务是否已取消
        if (task.getStatus() == 3) {
            throw exception(FILE_UPLOAD_TASK_CANCELLED);
        }
        // 校验任务是否已完成
        if (task.getStatus() == 2) {
            throw exception(FILE_UPLOAD_TASK_COMPLETED);
        }
        return task;
    }

    /**
     * 生成上传文件路径
     *
     * @param name      原始文件名
     * @param directory 存储目录
     * @return 生成的文件路径
     */
    private String generateUploadPath(String name, String directory) {
        // 1. 处理 name 为空的情况
        if (StrUtil.isEmpty(name)) {
            name = String.valueOf(System.currentTimeMillis());
        }

        // 2. 添加时间戳后缀，保证唯一性
        String timestamp = String.valueOf(System.currentTimeMillis());
        String ext = cn.hutool.core.io.FileUtil.extName(name);
        if (StrUtil.isNotEmpty(ext)) {
            name = cn.hutool.core.io.FileUtil.mainName(name) + "_" + timestamp + "." + ext;
        } else {
            name = name + "_" + timestamp;
        }

        // 3. 添加日期前缀
        String datePrefix = LocalDateTimeUtil.format(LocalDateTimeUtil.now(), "yyyyMMdd");
        name = datePrefix + "/" + name;

        // 4. 添加目录前缀
        if (StrUtil.isNotEmpty(directory)) {
            name = directory + "/" + name;
        }

        return name;
    }

}
