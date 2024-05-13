package com.shengyu.module.system.dal.dataobject.user;

import com.shengyu.framework.common.enums.common.SexEnum;
import com.shengyu.framework.mybatis.core.dataobject.BaseDO;
import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;
import lombok.ToString;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

/**
 * 所属SaaS用户表 DO
 *
 * @author 圣钰科技
 */
@TableName("system_saas_user")
@KeySequence("system_saas_user_seq") // 用于 Oracle、PostgreSQL、Kingbase、DB2、H2 数据库的主键自增。如果是 MySQL 等数据库，可不写。
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SaasUserDO extends BaseDO {

    /**
     * 编号
     */
    @TableId
    private Long id;
    /**
     * 邮箱，第一登录方式账号没有用手机号是因为邮箱验证免费。
     * 而且这里不能用传统意义上的所谓的用户名，因为这个账号是可以对应多个租户的，这里需要确定唯一性
     */
    private String username;
    /**
     * 加密后的密码
     *
     * 因为目前使用 {@link BCryptPasswordEncoder} 加密器，所以无需自己处理 salt 盐
     */
    private String password;
    /**
     * 手机号码
     */
    private String mobile;
    /**
     * 用户性别
     *
     * 枚举类 {@link SexEnum}
     */
    private Integer sex;
    /**
     * 用户唯一标识值
     * 创建时间+sy+用户id+雪花
     */
    private String openId;
    /**
     * 默认所属租户，这个租户是指每次选定的租户，即上次登录的
     */
    private Long defaultTenant;

    /**
     * 我的租户（每个注册的用户都会拥有一个自己的租户，是这个租户的超管）
     */
    private Long myTenant;

}
