package cn.iocoder.yudao.framework.security.core;

import cn.iocoder.yudao.framework.security.core.util.LoginBase;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;
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
