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

@TableName(value = "im_chat", autoResultMap = true)
@KeySequence("im_chat_seq")
@Data
@EqualsAndHashCode(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ImChatDO extends TenantBaseDO {

    @TableId
    private Long id;

    private Integer chatType;

    private Long singleUser1;

    private Long singleUser2;

    private Long groupId;

    private Long lastSequence;

    private Integer status;

}
