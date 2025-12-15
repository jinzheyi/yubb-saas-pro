package com.shengyu.module.system.dal.dataobject.im;

import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.framework.tenant.core.db.TenantBaseDO;
import lombok.*;

/**
 * 好友设置 DO
 *
 * @author 朱述勇
 * @since 2022/12/3 21:40
 * @copyright: 版权所有 开源组织 gitee(https://gitee.com/jinzheyi)作者：朱述勇<br/>
 * GitHub(https://github.com/jinzheyi)作者：朱述勇 。
 */
@TableName("im_friend")
@KeySequence("im_friend_seq") // 用于 Oracle、PostgreSQL、Kingbase、DB2、H2 数据库的主键自增。如果是 MySQL 等数据库，可不写。
@Data
@EqualsAndHashCode(callSuper = true)
public class ImFriendDO extends TenantBaseDO {

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
     * 设为星标联系人：0、不是星标 1、是星标
     */
    private Integer star;
    /**
     * 是否加入黑名单：0否1是
     */
    private Integer isblack;

}
