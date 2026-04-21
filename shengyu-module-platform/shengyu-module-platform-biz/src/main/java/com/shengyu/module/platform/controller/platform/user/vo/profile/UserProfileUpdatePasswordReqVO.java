package com.shengyu.module.platform.controller.platform.user.vo.profile;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import org.hibernate.validator.constraints.Length;

import javax.validation.constraints.NotEmpty;

@Schema(description = "管理后台 - 用户个人中心更新密码 Request VO")
@Data
public class UserProfileUpdatePasswordReqVO {

    @Schema(description = "旧密码", requiredMode = Schema.RequiredMode.REQUIRED, example = "123456")
    @NotEmpty(message = "{validation.user.old_password.required}")
    @Length(min = 4, max = 50, message = "{validation.user.password.length}")
    private String oldPassword;

    @Schema(description = "新密码", requiredMode = Schema.RequiredMode.REQUIRED, example = "654321")
    @NotEmpty(message = "{validation.user.new_password.required}")
    @Length(min = 4, max = 50, message = "{validation.user.password.length}")
    private String newPassword;

}
