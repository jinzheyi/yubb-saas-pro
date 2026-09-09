package com.shengyu.module.system.controller.app.register.vo;

import com.shengyu.framework.common.validation.Mobile;
import io.swagger.v3.oas.annotations.media.Schema;
import javax.validation.constraints.Email;
import javax.validation.constraints.NotEmpty;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;
import lombok.Data;

@Schema(description = "移动端 - 创建企业 Request VO")
@Data
public class AppTrialTenantRegisterReqVO {

    @Schema(description = "邮箱账号", requiredMode = Schema.RequiredMode.REQUIRED, example = "jin_zheyicn@qq.com")
    @NotEmpty(message = "邮箱账号不能为空")
    @Email(message = "邮箱账号格式不正确")
    @Size(max = 50, message = "邮箱账号长度不能超过 50 个字符")
    private String username;

    @Schema(description = "邮箱验证码", requiredMode = Schema.RequiredMode.REQUIRED, example = "123456")
    @NotEmpty(message = "邮箱验证码不能为空")
    @Size(min = 6, max = 6, message = "邮箱验证码为 6 位")
    private String emailCode;

    @Schema(description = "用户昵称", requiredMode = Schema.RequiredMode.REQUIRED, example = "张三")
    @NotEmpty(message = "用户昵称不能为空")
    @Size(max = 30, message = "用户昵称长度不能超过 30 个字符")
    private String nickname;

    @Schema(description = "企业名称", requiredMode = Schema.RequiredMode.REQUIRED, example = "钰信体验企业")
    @NotEmpty(message = "企业名称不能为空")
    @Size(max = 30, message = "企业名称长度不能超过 30 个字符")
    private String tenantName;

    @Schema(description = "预留手机号", example = "15601691300")
    @Mobile(message = "手机号码格式不正确")
    private String mobile;

    @Schema(description = "设备类型", requiredMode = Schema.RequiredMode.REQUIRED, example = "3")
    @NotNull(message = "设备类型不能为空")
    private Integer deviceType;

    @Schema(description = "设备ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1234567890-abcdef")
    @NotEmpty(message = "设备ID不能为空")
    private String deviceId;

    @Schema(description = "客户端版本", requiredMode = Schema.RequiredMode.REQUIRED, example = "1.0.0")
    @NotEmpty(message = "客户端版本不能为空")
    private String clientVersion;

}
