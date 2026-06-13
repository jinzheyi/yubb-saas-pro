package com.shengyu.framework.file.core.client;

import java.util.List;

/**
 * 文件客户端
 *
 * @author 圣钰科技
 */
public interface FileClient {

    /**
     * 获得客户端编号
     *
     * @return 客户端编号
     */
    Long getId();

    /**
     * 上传文件
     *
     * @param content 文件流
     * @param path    相对路径
     * @return 完整路径，即 HTTP 访问地址
     * @throws Exception 上传文件时，抛出 Exception 异常
     */
    String upload(byte[] content, String path, String type) throws Exception;

    /**
     * 删除文件
     *
     * @param path 相对路径
     * @throws Exception 删除文件时，抛出 Exception 异常
     */
    void delete(String path) throws Exception;

    /**
     * 获得文件的内容
     *
     * @param path 相对路径
     * @return 文件的内容
     */
    byte[] getContent(String path) throws Exception;

    // ========== 文件签名，目前仅 S3 支持 ==========

    /**
     * 获得文件预签名地址，用于上传
     *
     * @param path 相对路径
     * @return 文件预签名地址
     */
    default String presignPutUrl(String path) {
        throw new UnsupportedOperationException("不支持的操作");
    }

    /**
     * 生成文件预签名地址，用于读取
     *
     * @param url 完整的文件访问地址
     * @param expirationSeconds 访问有效期，单位秒
     * @return 文件预签名地址
     */
    default String presignGetUrl(String url, Integer expirationSeconds) {
        throw new UnsupportedOperationException("不支持的操作");
    }

    // ========== 分片上传，目前仅 S3 支持 ==========

    /**
     * 创建分片上传任务
     *
     * @param path 相对路径
     * @param type 文件类型（MIME 类型）
     * @param totalSize 文件总大小（字节）
     * @return 分片上传任务 ID（uploadId）
     */
    default String createMultipartUpload(String path, String type, Long totalSize) {
        throw new UnsupportedOperationException("不支持的操作");
    }

    /**
     * 上传分片
     *
     * @param uploadId 分片上传任务 ID
     * @param partNumber 分片号，从 1 开始
     * @param content 分片内容
     * @return 分片 ETag
     */
    default String uploadPart(String uploadId, int partNumber, byte[] content) {
        throw new UnsupportedOperationException("不支持的操作");
    }

    /**
     * 完成分片上传，合并所有分片
     *
     * @param uploadId 分片上传任务 ID
     * @param partETags 分片 ETag 列表
     * @return 完整路径，即 HTTP 访问地址
     */
    default String completeMultipartUpload(String uploadId, List<PartETag> partETags) {
        throw new UnsupportedOperationException("不支持的操作");
    }

    /**
     * 取消分片上传，清理已上传的分片
     *
     * @param uploadId 分片上传任务 ID
     */
    default void abortMultipartUpload(String uploadId) {
        throw new UnsupportedOperationException("不支持的操作");
    }

}
