package com.shengyu.module.infra.dal.mysql.file;

import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.module.infra.dal.dataobject.file.FileUploadTaskDO;
import org.apache.ibatis.annotations.Mapper;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 分片上传任务 Mapper
 *
 * @author 圣钰科技
 */
@Mapper
public interface FileUploadTaskMapper extends BaseMapperX<FileUploadTaskDO> {

    /**
     * 根据 uploadId 查询任务
     *
     * @param uploadId 分片上传唯一标识
     * @return 任务信息
     */
    default FileUploadTaskDO selectByUploadId(String uploadId) {
        return selectOne(new LambdaQueryWrapperX<FileUploadTaskDO>()
                .eq(FileUploadTaskDO::getUploadId, uploadId));
    }

    /**
     * 查询已过期的任务
     *
     * @param now 当前时间
     * @return 过期任务列表
     */
    default List<FileUploadTaskDO> selectExpiredTasks(LocalDateTime now) {
        return selectList(new LambdaQueryWrapperX<FileUploadTaskDO>()
                .lt(FileUploadTaskDO::getExpireTime, now));
    }

    /**
     * 查询超时的上传任务（初始化或上传中状态，且超过指定时间未更新）
     *
     * @param timeoutTime 超时时间节点
     * @return 超时任务列表
     */
    default List<FileUploadTaskDO> selectTimeoutTasks(LocalDateTime timeoutTime) {
        return selectList(new LambdaQueryWrapperX<FileUploadTaskDO>()
                .in(FileUploadTaskDO::getStatus, 0, 1)
                .lt(FileUploadTaskDO::getUpdateTime, timeoutTime));
    }

}
