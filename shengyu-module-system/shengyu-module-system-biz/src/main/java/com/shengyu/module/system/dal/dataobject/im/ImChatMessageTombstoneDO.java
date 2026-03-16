package com.shengyu.module.system.dal.dataobject.im;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.framework.tenant.core.db.TenantBaseDO;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@TableName("im_chat_message_tombstone")
@Data
@EqualsAndHashCode(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ImChatMessageTombstoneDO extends TenantBaseDO {

    @TableId
    private Long id;

    private Long chatId;

    private Long userId;

    private Long messageId;

    private LocalDateTime deletedAt;

}
