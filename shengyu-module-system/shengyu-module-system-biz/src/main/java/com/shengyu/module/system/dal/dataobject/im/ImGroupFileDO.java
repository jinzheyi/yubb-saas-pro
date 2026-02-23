package com.shengyu.module.system.dal.dataobject.im;

import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.framework.mybatis.core.dataobject.BaseDO;
import lombok.*;

/**
 * IM 群文件关联 DO
 *
 * @author 圣钰科技
 */
@TableName("im_group_file")
@KeySequence("im_group_file_seq")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ImGroupFileDO extends BaseDO {

    /**
     * 主键ID
     */
    @TableId
    private Long id;
    
    /**
     * 群组ID
     */
    private Long groupId;
    
    /**
     * 文件ID(关联 infra_file.id)
     */
    private Long fileId;
    
    /**
     * 上传者ID
     */
    private Long uploaderId;
    
    /**
     * 文件夹ID(0表示根目录)
     */
    private Long folderId;
    
    /**
     * 是否收藏
     */
    private Boolean isFavorite;
    
    /**
     * 下载次数
     */
    private Integer downloadCount;

}
