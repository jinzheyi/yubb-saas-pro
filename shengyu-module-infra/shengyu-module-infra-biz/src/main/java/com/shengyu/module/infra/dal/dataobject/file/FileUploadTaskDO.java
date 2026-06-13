package com.shengyu.module.infra.dal.dataobject.file;

import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.framework.mybatis.core.dataobject.BaseDO;
import lombok.*;

import java.time.LocalDateTime;

/**
 * 分片上传任务表
 * 用于记录大文件分片上传的任务信息
 *
 * @author 圣钰科技
 */
@TableName("infra_file_upload_task")
@KeySequence("infra_file_upload_task_seq") // 用于 Oracle、PostgreSQL、Kingbase、DB2、H2 数据库的主键自增。如果是 MySQL 等数据库，可不写。
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FileUploadTaskDO extends BaseDO {

    /**
     * 编号，数据库自增
     */
    private Long id;
    /**
     * 分片上传唯一标识
     */
    private String uploadId;
    /**
     * 文件配置编号
     * <p>
     * 关联 {@link FileConfigDO#getId()}
     */
    private Long configId;
    /**
     * 原始文件名
     */
    private String name;
    /**
     * 目标文件路径
     */
    private String path;
    /**
     * MIME 类型，例如 "application/octet-stream"
     */
    private String type;
    /**
     * 文件总大小（字节）
     */
    private Long totalSize;
    /**
     * 分片大小（字节），默认 5MB
     */
    private Integer chunkSize;
    /**
     * 总分片数
     */
    private Integer totalChunks;
    /**
     * 已上传分片数
     */
    private Integer uploadedChunks;
    /**
     * 状态: 0-初始化, 1-上传中, 2-已完成, 3-已取消, 4-已过期
     */
    private Integer status;
    /**
     * 过期时间，默认 24 小时后
     */
    private LocalDateTime expireTime;
    /**
     * S3 分片上传 ID（仅 S3 存储时使用）
     */
    private String s3UploadId;

}
