package com.shengyu.module.infra.dal.dataobject.file;

import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.framework.mybatis.core.dataobject.BaseDO;
import lombok.*;

/**
 * 分片上传记录表
 * 用于记录每个分片的上传信息
 *
 * @author 圣钰科技
 */
@TableName("infra_file_upload_chunk")
@KeySequence("infra_file_upload_chunk_seq") // 用于 Oracle、PostgreSQL、Kingbase、DB2、H2 数据库的主键自增。如果是 MySQL 等数据库，可不写。
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FileUploadChunkDO extends BaseDO {

    /**
     * 编号，数据库自增
     */
    private Long id;
    /**
     * 关联的分片上传唯一标识
     * <p>
     * 关联 {@link FileUploadTaskDO#getUploadId()}
     */
    private String uploadId;
    /**
     * 分片序号，从 1 开始
     */
    private Integer chunkNumber;
    /**
     * 分片大小（字节）
     */
    private Long chunkSize;
    /**
     * 分片 ETag 或 S3 分片 ID
     */
    private String etag;
    /**
     * 状态: 0-上传中, 1-已完成
     */
    private Integer status;

}
