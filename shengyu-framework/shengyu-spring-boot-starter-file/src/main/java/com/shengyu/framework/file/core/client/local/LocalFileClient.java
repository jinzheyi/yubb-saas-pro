package com.shengyu.framework.file.core.client.local;

import cn.hutool.core.io.FileUtil;
import cn.hutool.core.io.IORuntimeException;
import cn.hutool.core.util.IdUtil;
import cn.hutool.crypto.digest.DigestUtil;
import com.shengyu.framework.file.core.client.AbstractFileClient;
import com.shengyu.framework.file.core.client.PartETag;
import lombok.extern.slf4j.Slf4j;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.List;

/**
 * 本地文件客户端
 *
 * @author 圣钰科技
 */
@Slf4j
public class LocalFileClient extends AbstractFileClient<LocalFileClientConfig> {

    public LocalFileClient(Long id, LocalFileClientConfig config) {
        super(id, config);
    }

    @Override
    protected void doInit() {
    }

    @Override
    public String upload(byte[] content, String path, String type) {
        // 执行写入
        String filePath = getFilePath(path);
        FileUtil.writeBytes(content, filePath);
        // 拼接返回路径
        return super.formatFileUrl(config.getDomain(), path);
    }

    @Override
    public void delete(String path) {
        String filePath = getFilePath(path);
        FileUtil.del(filePath);
    }

    @Override
    public byte[] getContent(String path) {
        String filePath = getFilePath(path);
        try {
            return FileUtil.readBytes(filePath);
        } catch (IORuntimeException ex) {
            if (ex.getMessage().startsWith("File not exist:")) {
                return null;
            }
            throw ex;
        }
    }

    // ========== 分片上传支持 ==========

    @Override
    public String createMultipartUpload(String path, String type, Long totalSize) {
        // 1. 生成 uploadId
        String uploadId = IdUtil.fastSimpleUUID();

        // 2. 创建临时目录存储分片
        String tempDir = getTempDir(uploadId);
        FileUtil.mkdir(tempDir);

        // 3. 保存元信息
        String metaFile = tempDir + File.separator + "_meta.json";
        String meta = String.format("{\"path\":\"%s\",\"type\":\"%s\",\"totalSize\":%d}", path, type, totalSize);
        FileUtil.writeString(meta, metaFile, "UTF-8");

        // 4. 返回复合 uploadId：path::uploadId
        return path + "::" + uploadId;
    }

    @Override
    public String uploadPart(String uploadId, int partNumber, byte[] content) {
        // 1. 解析临时目录
        String tempDir = getTempDir(extractUploadId(uploadId));

        // 2. 写入分片文件
        String chunkFile = tempDir + File.separator + "chunk_" + partNumber;
        FileUtil.writeBytes(content, chunkFile);

        // 3. 返回 ETag（使用 MD5）
        return DigestUtil.md5Hex(content);
    }

    @Override
    public String completeMultipartUpload(String uploadId, List<PartETag> partETags) {
        // 1. 解析路径和临时目录
        String path = extractPath(uploadId);
        String tempDir = getTempDir(extractUploadId(uploadId));

        // 2. 合并所有分片
        String targetFile = getFilePath(path);
        FileUtil.touch(targetFile);

        // 按分片号排序合并（使用流式写入避免内存溢出）
        try (FileOutputStream fos = new FileOutputStream(targetFile)) {
            for (PartETag part : partETags) {
                String chunkFile = tempDir + File.separator + "chunk_" + part.getPartNumber();
                byte[] chunkData = FileUtil.readBytes(chunkFile);
                fos.write(chunkData);
            }
        } catch (IOException e) {
            log.error("[completeMultipartUpload][合并分片失败] uploadId={}", uploadId, e);
            throw new RuntimeException("合并分片失败", e);
        }

        // 3. 清理临时文件
        FileUtil.del(tempDir);

        // 4. 返回文件 URL
        return formatFileUrl(config.getDomain(), path);
    }

    @Override
    public void abortMultipartUpload(String uploadId) {
        // 清理临时目录
        String tempDir = getTempDir(extractUploadId(uploadId));
        FileUtil.del(tempDir);
    }

    // ========== 私有方法 ==========

    private String getFilePath(String path) {
        return config.getBasePath() + File.separator + path;
    }

    private String getTempDir(String uploadId) {
        return config.getBasePath() + File.separator + ".tmp" + File.separator + uploadId;
    }

    private String extractPath(String compositeUploadId) {
        int idx = compositeUploadId.indexOf("::");
        return idx >= 0 ? compositeUploadId.substring(0, idx) : compositeUploadId;
    }

    private String extractUploadId(String compositeUploadId) {
        int idx = compositeUploadId.indexOf("::");
        return idx >= 0 ? compositeUploadId.substring(idx + 2) : compositeUploadId;
    }

}
