package com.shengyu.module.infra.dal.mysql.file;

import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.module.infra.dal.dataobject.file.FileUploadChunkDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * 分片上传记录 Mapper
 *
 * @author 圣钰科技
 */
@Mapper
public interface FileUploadChunkMapper extends BaseMapperX<FileUploadChunkDO> {

    /**
     * 根据 uploadId 查询所有分片记录
     *
     * @param uploadId 分片上传唯一标识
     * @return 分片记录列表
     */
    default List<FileUploadChunkDO> selectByUploadId(String uploadId) {
        return selectList(new LambdaQueryWrapperX<FileUploadChunkDO>()
                .eq(FileUploadChunkDO::getUploadId, uploadId)
                .orderByAsc(FileUploadChunkDO::getChunkNumber));
    }

    /**
     * 查询已完成上传的分片记录
     *
     * @param uploadId 分片上传唯一标识
     * @return 已完成分片记录列表
     */
    default List<FileUploadChunkDO> selectCompletedChunks(String uploadId) {
        return selectList(new LambdaQueryWrapperX<FileUploadChunkDO>()
                .eq(FileUploadChunkDO::getUploadId, uploadId)
                .eq(FileUploadChunkDO::getStatus, 1)
                .orderByAsc(FileUploadChunkDO::getChunkNumber));
    }

}
