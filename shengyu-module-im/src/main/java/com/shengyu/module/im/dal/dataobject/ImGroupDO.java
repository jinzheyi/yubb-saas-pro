package com.shengyu.module.im.dal.dataobject;

import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.framework.tenant.core.db.TenantBaseDO;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * IM群组DO
 *
 * @author 圣钰科技
 */
@TableName("im_group")
@KeySequence("im_group_seq") // 用于 Oracle、PostgreSQL、Kingbase、DB2、H2 数据库的主键自增。如果是 MySQL 等数据库，可不写。
@Data
@EqualsAndHashCode(callSuper = true)
public class ImGroupDO extends TenantBaseDO {

    /**
     * 群组ID
     */
    @TableId
    private Long id;

    /**
     * 群组名称
     */
    private String name;

    /**
     * 群组头像
     */
    private String avatar;

    /**
     * 群组描述
     */
    private String description;

    /**
     * 群主ID
     */
    private Long ownerId;

    /**
     * 成员数量
     */
    private Integer memberCount;

    /**
     * 群组状态：0-正常，1-解散
     */
    private Integer status;

}
