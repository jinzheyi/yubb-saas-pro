package com.shengyu.module.system.api.user.dto;

import com.shengyu.framework.common.validation.Mobile;
import lombok.Data;
import org.hibernate.validator.constraints.Length;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotEmpty;
import javax.validation.constraints.Pattern;
import javax.validation.constraints.Size;

/**
 * 外部服务创建租户用户接口入参DTO
 *
 * @author 朱述勇
 * @copyright: 版权所有 开源组织 gitee(https://gitee.com/jinzheyi)作者：朱述勇<br/>
 * GitHub(https://github.com/jinzheyi)作者：朱述勇 。
 * @since 2022/7/21 21:27
 */
@Data
public class AdminUserCreateReqDTO {

    @NotBlank(message = "用户账号不能为空")
    @Size(max = 50, message = "长度不能超过 50 个字符")
    private String username;

    @NotEmpty(message = "密码不能为空")
    @Length(min = 4, max = 50, message = "密码长度为 4-50 位")
    private String password;

    @Size(max = 30, message = "用户昵称长度不能超过30个字符")
    private String nickname;

    /**
     * 手机号码
     */
    @Mobile
    private String mobile;

}
