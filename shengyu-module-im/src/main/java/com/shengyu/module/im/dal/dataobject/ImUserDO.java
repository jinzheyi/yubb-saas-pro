package com.shengyu.module.im.dal.dataobject;

import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.framework.tenant.core.db.TenantBaseDO;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * IM用户DO
 *
 * @author 圣钰科技
 */
@TableName("im_user")
@KeySequence("im_user_seq") // 用于 Oracle、PostgreSQL、Kingbase、DB2、H2 数据库的主键自增。如果是 MySQL 等数据库，可不写。
@Data
@EqualsAndHashCode(callSuper = true)
public class ImUserDO extends TenantBaseDO {

    /**
     * 用户ID
     */
    @TableId
    private Long id;

    /**
     * 系统用户ID
     */
    private Long userId;

    /**
     * 用户昵称
     */
    private String nickname;

    /**
     * 用户头像
     */
    private String avatar;

    /**
     * 状态：0-正常，1-禁用
     */
    private Integer status;

    /**
     * 在线状态：0-离线，1-在线，2-忙碌，3-离开
     */
    private Integer onlineStatus;

    /**
     * 扩展字段
     */
    private String ext;

}
