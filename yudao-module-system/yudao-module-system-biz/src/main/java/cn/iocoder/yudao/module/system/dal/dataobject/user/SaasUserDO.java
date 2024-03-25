package cn.iocoder.yudao.module.system.dal.dataobject.user;

import cn.iocoder.yudao.framework.mybatis.core.dataobject.BaseDO;
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
     * 账号,这个账号大概率是邮箱之类的，为了模拟真实业务场景，建议邮箱
     */
    private String account;
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
     * 用户唯一标识值
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
