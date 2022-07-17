package cn.iocoder.yudao.module.base.api.common.dto;

import lombok.Data;

import javax.validation.constraints.NotNull;
import java.io.Serializable;
import java.time.Duration;

/**
 * 获取验证码入参
 * @author 朱述勇
 * @since 2022/7/16 17:43
 * @copyright: 版权所有 开源组织 gitee(https://gitee.com/jinzheyi)作者：朱述勇<br/>
 * GitHub(https://github.com/jinzheyi)作者：朱述勇 。
 */
@Data
public class CaptchaImageReqDTO implements Serializable {

    /**
     * 是否开启验证码
     */
    @NotNull(message = "是否开启验证码不为空")
    private Boolean enable;

    /**
     * 验证码的过期时间
     */
    @NotNull(message = "验证码的过期时间不为空")
    private Duration timeout;
    /**
     * 验证码的高度
     */
    @NotNull(message = "验证码的高度不能为空")
    private Integer height;
    /**
     * 验证码的宽度
     */
    @NotNull(message = "验证码的宽度不能为空")
    private Integer width;

}
