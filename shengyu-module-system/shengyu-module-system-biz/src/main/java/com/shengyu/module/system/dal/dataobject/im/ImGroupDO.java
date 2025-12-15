package com.shengyu.module.system.dal.dataobject.im;

import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.framework.common.enums.CommonStatusEnum;
import com.shengyu.framework.tenant.core.db.TenantBaseDO;
import lombok.*;

/**
 * 聊天群组 DO
 *
 * @author 朱述勇
 * @since 2022/12/3 21:40
 * @copyright: 版权所有 开源组织 gitee(https://gitee.com/jinzheyi)作者：朱述勇<br/>
 * GitHub(https://github.com/jinzheyi)作者：朱述勇 。
 */
@TableName("im_group")
@KeySequence("im_group_seq") // 用于 Oracle、PostgreSQL、Kingbase、DB2、H2 数据库的主键自增。如果是 MySQL 等数据库，可不写。
@Data
@EqualsAndHashCode(callSuper = true)
public class ImGroupDO extends TenantBaseDO {

    /**
     * 群id
     */
    @TableId
    private Long id;
    /**
     * 群主id
     */
    private Long userId;
    /**
     * 群名
     */
    private String name;
    /**
     * 群头像地址
     */
    private String avatar;
    /**
     * 状态（0正常 1停用）
     * {@link CommonStatusEnum}
     */
    private Integer status;
    /**
     * 群公告
     */
    private String remark;
    /**
     * 邀请确认
     */
    private Integer inviteConfirm;

}
