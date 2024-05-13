package com.shengyu.framework.security.core;

import com.shengyu.framework.security.core.util.LoginBase;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;
import lombok.experimental.SuperBuilder;

/**
 * 登录用户信息
 *
 * @author 圣钰科技
 */
@Data
@AllArgsConstructor
@NoArgsConstructor
@SuperBuilder(toBuilder = true)
@EqualsAndHashCode(callSuper = true)
public class LoginUser extends LoginBase {

    /**
     * 租户编号
     */
    private Long tenantId;

}
