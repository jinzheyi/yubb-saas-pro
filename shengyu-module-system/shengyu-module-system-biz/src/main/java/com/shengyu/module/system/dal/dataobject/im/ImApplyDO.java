package com.shengyu.module.system.dal.dataobject.im;

import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.framework.common.enums.im.ImApplyStatusEnum;
import com.shengyu.framework.tenant.core.db.TenantBaseDO;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 申请信息
 */
@TableName("im_apply")
@KeySequence("im_apply_seq") // 用于 Oracle、PostgreSQL、Kingbase、DB2、H2 数据库的主键自增。如果是 MySQL 等数据库，可不写。
@Data
@EqualsAndHashCode(callSuper = true)
public class ImApplyDO extends TenantBaseDO {

    /**
     * 主键
     */
    @TableId
    private Long id;
    /**
     * 用户id
     */
    private Long userId;
    /**
     * 好友id
     */
    private Long friendId;
    /**
     * 昵称备注
     */
    private String nickname;
    /**
     * 允许查看我：0、不允许 1、允许
     */
    private Integer lookme;
    /**
     * 允许查看他：0、不允许 1、允许
     */
    private Integer lookhim;
    /**
     * 申请状态
     * {@link ImApplyStatusEnum}
     */
    private String status;

}
