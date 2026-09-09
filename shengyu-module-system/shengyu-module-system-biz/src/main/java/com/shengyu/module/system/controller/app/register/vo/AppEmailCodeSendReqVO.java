package com.shengyu.module.system.controller.app.register.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import javax.validation.constraints.Email;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Size;
import lombok.Data;

@Schema(description = "移动端 - 发送注册邮箱验证码 Request VO")
@Data
public class AppEmailCodeSendReqVO {

    @NotBlank(message = "邮箱账号不能为空")
    @Email(message = "邮箱账号格式不正确")
    @Size(max = 50, message = "邮箱账号长度不能超过 50 个字符")
    private String email;
}
