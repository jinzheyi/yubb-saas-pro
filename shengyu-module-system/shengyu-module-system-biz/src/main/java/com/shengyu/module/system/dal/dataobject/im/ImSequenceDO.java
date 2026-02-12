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

/**
 * IM 序列号 DO
 * 
 * 对应表: im_sequence
 * 功能: 消息序列号生成,用于消息排序和去重
 *
 * @author 圣钰科技
 */
@TableName(value = "im_sequence", autoResultMap = true)
@KeySequence("im_sequence_seq")
@Data
@EqualsAndHashCode(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ImSequenceDO extends TenantBaseDO {

    /**
     * 主键ID
     */
    @TableId
    private Long id;

    /**
     * 序列号类型
     * 
     * 1-消息序列号
     */
    private Integer sequenceType;

    /**
     * 当前序列号值
     */
    private Long currentValue;

    /**
     * 步长
     */
    private Integer step;

}
