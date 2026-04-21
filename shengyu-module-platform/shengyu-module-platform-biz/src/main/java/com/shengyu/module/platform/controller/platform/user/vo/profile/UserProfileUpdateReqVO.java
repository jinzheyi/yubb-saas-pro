package com.shengyu.module.platform.controller.platform.user.vo.profile;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.Email;
import javax.validation.constraints.Size;
import org.hibernate.validator.constraints.Length;


@Schema(description = "管理后台 - 用户个人信息更新 Request VO")
@Data
public class UserProfileUpdateReqVO {

    @Schema(description = "用户昵称", requiredMode = Schema.RequiredMode.REQUIRED, example = "芋艿")
    @Size(max = 30, message = "{validation.user.nickname.max}")
    private String nickname;

    @Schema(description = "用户邮箱", example = "shengyu@iocoder.cn")
    @Email(message = "{validation.user.email.invalid}")
    @Size(max = 50, message = "{validation.user.email.max}")
    private String email;

    @Schema(description = "手机号码", example = "15601691300")
    @Length(min = 11, max = 11, message = "{validation.user.mobile.length}")
    private String mobile;

    @Schema(description = "用户性别-参见 SexEnum 枚举类", example = "1")
    private Integer sex;

}
