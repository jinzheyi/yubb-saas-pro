package com.shengyu.module.platform.dal.dataobject.social;

import com.shengyu.framework.common.enums.UserTypeEnum;
import com.shengyu.framework.mybatis.core.dataobject.BaseDO;
import com.shengyu.framework.tenant.core.db.TenantBaseDO;
import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.*;

/**
 * 社交用户的绑定
 * 即 {@link SocialUserDO} 与 UserDO 的关联表
 *
 * @author 圣钰科技
 */
@TableName(value = "tenant_social_user_bind", autoResultMap = true)
@KeySequence("tenant_social_user_bind_seq") // 用于 Oracle、PostgreSQL、Kingbase、DB2、H2 数据库的主键自增。如果是 MySQL 等数据库，可不写。
@Data
@EqualsAndHashCode(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SocialUserBindDO extends BaseDO {

    /**
     * 编号
     */
    @TableId
    private Long id;
    /**
     * 关联的saas用户表编号
     *
     * 关联 system_saas_user 的编号
     * 1、三方登錄用戶当是平台用户三方用户登录时绑定的是平台用户id
     * 2、当如果是租户用户三方登录时绑定的是SaaS体系用户id，因为一个SaaS用户体系用户可以对应多个租户，不能直接使用租户用户id
     */
    private Long saasUserId;
    /**
     * 用户类型
     *
     * 枚举 {@link UserTypeEnum}
     */
    private Integer userType;

    /**
     * 社交平台的用户编号
     *
     * 关联 {@link SocialUserDO#getId()}
     */
    private Long socialUserId;
    /**
     * 社交平台的类型
     *
     * 冗余 {@link SocialUserDO#getType()}
     */
    private Integer socialType;

}
