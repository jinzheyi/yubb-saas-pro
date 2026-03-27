package com.shengyu.module.system.dal.dataobject.im;

import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.framework.tenant.core.db.TenantBaseDO;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;
import lombok.ToString;

@TableName("im_user_sticker")
@KeySequence("im_user_sticker_seq")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ImUserStickerDO extends TenantBaseDO {

    @TableId
    private Long id;

    private Long userId;

    private Long fileId;

    private Long thumbFileId;

    private String name;

    private String md5;

    private Integer width;

    private Integer height;

    private String mimeType;

    private Integer sourceType;

    private Long sourceMessageId;

    private Integer sortNo;

    private Integer status;
}
