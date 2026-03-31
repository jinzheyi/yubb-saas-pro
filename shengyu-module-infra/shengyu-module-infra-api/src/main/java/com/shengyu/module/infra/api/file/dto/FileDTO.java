package com.shengyu.module.infra.api.file.dto;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 文件信息 DTO
 *
 * @author 圣钰科技
 */
@Data
public class FileDTO {

    /**
     * 文件ID
     */
    private Long id;

    /**
     * 文件名称
     */
    private String name;

    /**
     * 文件路径
     */
    private String path;

    /**
     * 文件URL
     */
    private String url;

    /**
     * 文件类型（MIME类型）
     */
    private String type;

    /**
     * 文件大小（字节）
     */
    private Integer size;

    /**
     * 创建时间
     */
    private LocalDateTime createTime;

    /**
     * 创建者
     */
    private String creator;

}
