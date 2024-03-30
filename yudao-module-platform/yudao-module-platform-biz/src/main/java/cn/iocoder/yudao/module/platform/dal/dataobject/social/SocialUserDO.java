package cn.iocoder.yudao.module.platform.dal.dataobject.social;

import cn.iocoder.yudao.framework.common.enums.social.SocialTypeEnum;
import cn.iocoder.yudao.framework.tenant.core.db.TenantBaseDO;
import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.*;

/**
 * 社交（三方）用户,
 * 1、三方登錄用戶当是平台用户三方用户登录时绑定的是平台用户id
 * 2、当如果是租户用户三方登录时绑定的是SaaS体系用户id，因为一个SaaS用户体系用户可以对应多个租户，不能直接使用租户用户id
 *
 * @author weir
 */
@TableName(value = "tenant_social_user", autoResultMap = true)
@KeySequence("tenant_social_user_seq") // 用于 Oracle、PostgreSQL、Kingbase、DB2、H2 数据库的主键自增。如果是 MySQL 等数据库，可不写。
@Data
@EqualsAndHashCode(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SocialUserDO extends TenantBaseDO {

    /**
     * 自增主键
     */
    @TableId
    private Long id;
    /**
     * 社交平台的类型
     *
     * 枚举 {@link SocialTypeEnum}
     */
    private Integer type;

    /**
     * 社交 openid
     */
    private String openid;
    /**
     * 社交 token
     */
    private String token;
    /**
     * 原始 Token 数据，一般是 JSON 格式
     */
    private String rawTokenInfo;

    /**
     * 用户昵称
     */
    private String nickname;
    /**
     * 用户头像
     */
    private String avatar;
    /**
     * 原始用户数据，一般是 JSON 格式
     */
    private String rawUserInfo;

    /**
     * 最后一次的认证 code
     */
    private String code;
    /**
     * 最后一次的认证 state
     */
    private String state;

}


