package com.shengyu.module.system.controller.app.register.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import javax.validation.constraints.Email;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Size;
import lombok.Data;

@Schema(description = "移动端 - 邮箱验证码加入企业 Request VO")
@Data
public class AppTenantJoinByInviteReqVO {

    @NotBlank(message = "邮箱账号不能为空")
    @Email(message = "邮箱账号格式不正确")
    @Size(max = 50, message = "邮箱账号长度不能超过 50 个字符")
    private String email;

    @NotBlank(message = "邮箱验证码不能为空")
    @Size(min = 6, max = 6, message = "邮箱验证码为 6 位")
    private String emailCode;

    @NotBlank(message = "邀请码不能为空")
    @Size(max = 32, message = "邀请码长度不能超过 32 个字符")
    private String inviteCode;

    @Size(max = 30, message = "姓名或昵称长度不能超过 30 个字符")
    private String nickname;
}
