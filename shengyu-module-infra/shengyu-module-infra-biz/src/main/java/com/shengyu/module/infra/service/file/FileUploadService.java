package com.shengyu.module.infra.service.file;

import com.shengyu.module.infra.controller.platform.file.vo.file.*;

/**
 * 文件分片上传 Service 接口
 *
 * @author 圣钰科技
 */
public interface FileUploadService {

    /**
     * 初始化分片上传
     *
     * @param reqVO 初始化请求参数
     * @return 初始化响应结果
     */
    FileUploadInitRespVO initMultipartUpload(FileUploadInitReqVO reqVO);

    /**
     * 上传分片
     *
     * @param reqVO 分片上传请求参数
     * @return 分片上传响应结果
     */
    FileChunkUploadRespVO uploadChunk(FileChunkUploadReqVO reqVO);

    /**
     * 完成分片合并
     *
     * @param reqVO 合并请求参数
     * @return 合并响应结果
     */
    FileMergeRespVO completeMultipartUpload(FileMergeReqVO reqVO);

    /**
     * 取消分片上传
     *
     * @param uploadId 分片上传唯一标识
     */
    void abortMultipartUpload(String uploadId);

    /**
     * 查询上传进度
     *
     * @param uploadId 分片上传唯一标识
     * @return 上传状态信息
     */
    FileUploadStatusRespVO getUploadStatus(String uploadId);

}
