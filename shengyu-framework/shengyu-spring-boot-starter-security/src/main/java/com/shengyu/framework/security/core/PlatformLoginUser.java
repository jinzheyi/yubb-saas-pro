package com.shengyu.framework.security.core;

import com.shengyu.framework.security.core.util.LoginBase;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.SuperBuilder;

/**
 * 平台系统用户信息
 * @author zhusy
 * @since 2022/7/26
 */
@Data
@AllArgsConstructor
@SuperBuilder(toBuilder = true)
@EqualsAndHashCode(callSuper = true)
public class PlatformLoginUser extends LoginBase {

}
