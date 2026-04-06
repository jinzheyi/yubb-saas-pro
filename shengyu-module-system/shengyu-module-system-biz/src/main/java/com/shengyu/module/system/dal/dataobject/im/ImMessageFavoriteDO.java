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

import java.time.LocalDateTime;

@TableName("im_message_favorite")
@KeySequence("im_message_favorite_seq")
@Data
@EqualsAndHashCode(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ImMessageFavoriteDO extends TenantBaseDO {

    @TableId
    private Long id;

    private Long userId;

    private Long messageId;

    private Long chatId;

    private Long anchorSequence;

    private Integer messageType;

    private String messagePreview;

    private String messageContent;

    private String messageExtra;

    private String messageSnapshot;

    private LocalDateTime sourceSendTime;
}
