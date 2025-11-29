package com.shengyu.module.im.dal.dataobject;

import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.framework.tenant.core.db.TenantBaseDO;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.util.Date;

/**
 * IM群组成员DO
 *
 * @author 圣钰科技
 */
@TableName("im_group_member")
@KeySequence("im_group_member_seq") // 用于 Oracle、PostgreSQL、Kingbase、DB2、H2 数据库的主键自增。如果是 MySQL 等数据库，可不写。
@Data
@EqualsAndHashCode(callSuper = true)
public class ImGroupMemberDO extends TenantBaseDO {

    /**
     * ID
     */
    @TableId
    private Long id;

    /**
     * 群组ID
     */
    private Long groupId;

    /**
     * 用户ID
     */
    private Long userId;

    /**
     * 角色：0-普通成员，1-管理员，2-群主
     */
    private Integer role;

    /**
     * 加入时间
     */
    private Date joinTime;

    /**
     * 状态：0-正常，1-已退出，2-已拉黑
     */
    private Integer status;

}
