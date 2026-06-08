package com.shengyu.module.system.dal.dataobject.user;

import com.shengyu.framework.common.enums.CommonStatusEnum;
import com.shengyu.framework.tenant.core.db.TenantBaseDO;
import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

/**
 * 管理后台的用户 DO
 *
 * @author 圣钰科技
 */
@TableName(value = "system_users", autoResultMap = true) // 由于 SQL Server 的 system_user 是关键字，所以使用 system_users
@KeySequence("system_user_seq") // 用于 Oracle、PostgreSQL、Kingbase、DB2、H2 数据库的主键自增。如果是 MySQL 等数据库，可不写。
@Data
@EqualsAndHashCode(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AdminUserDO extends TenantBaseDO {

    /**
     * 用户ID
     */
    @TableId
    private Long id;
    /**
     * 所属SaaS用户表id
     */
    private Long saasUserId;
    /**
     * 在当前租户下用户唯一标识值
     * 创建时间+sy+用户id+雪花
     */
    private String openAccount;
    /**
     * 用户昵称
     */
    private String nickname;
    /**
     * 备注
     */
    private String remark;
    /**
     * 当前登录选择的部门 ID
     */
    private Long deptId;
    /**
     * 帐号状态
     *
     * 枚举 {@link CommonStatusEnum}
     */
    private Integer status;
    /**
     * 用户头像
     */
    private String avatar;
    /**
     * 聊天气泡颜色
     */
    private String chatBubbleColor;
    /**
     * 聊天气泡模式
     */
    private String chatBubbleMode;
    /**
     * 最后登录IP
     */
    private String loginIp;
    /**
     * 最后登录时间
     */
    private LocalDateTime loginDate;

}
