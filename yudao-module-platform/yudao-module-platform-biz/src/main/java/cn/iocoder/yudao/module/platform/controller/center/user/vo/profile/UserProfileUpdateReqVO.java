package cn.iocoder.yudao.module.platform.controller.center.user.vo.profile;

import cn.iocoder.yudao.framework.common.enums.SexEnum;
import io.swagger.annotations.ApiModel;
import io.swagger.annotations.ApiModelProperty;
import lombok.Data;
import org.hibernate.validator.constraints.Length;

import javax.validation.constraints.Email;
import javax.validation.constraints.Size;

@ApiModel("平台管理后台 - 用户个人信息更新 Request VO")
@Data
public class UserProfileUpdateReqVO {

    @ApiModelProperty(value = "用户昵称", required = true, example = "SaaS")
    @Size(max = 30, message = "用户昵称长度不能超过 30 个字符")
    private String nickname;

    @ApiModelProperty(value = "用户邮箱", example = "jin_zheyicn@qq.com")
    @Email(message = "邮箱格式不正确")
    @Size(max = 50, message = "邮箱长度不能超过 50 个字符")
    private String email;

    @ApiModelProperty(value = "手机号码", example = "15188888888")
    @Length(min = 11, max = 11, message = "手机号长度必须 11 位")
    private String mobile;

    /**
     * 用户性别 {@link SexEnum}
     */
    @ApiModelProperty(value = "用户性别", example = "1", notes = "参见 SexEnum 枚举类")
    private Integer sex;

}
