package com.shengyu.module.system.dal.dataobject.im;

import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.framework.tenant.core.db.TenantBaseDO;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 好友标签
 */
@TableName("im_friend_tag")
@KeySequence("im_friend_tag_seq") // 用于 Oracle、PostgreSQL、Kingbase、DB2、H2 数据库的主键自增。如果是 MySQL 等数据库，可不写。
@Data
@EqualsAndHashCode(callSuper = true)
public class ImFriendTagDO extends TenantBaseDO {
    /**
     * 主键
     */
    @TableId
    private Long id;
    /**
     * 好友id
     */
    private Long friendId;
    /**
     * 标签
     */
    private Long tagId;
}
