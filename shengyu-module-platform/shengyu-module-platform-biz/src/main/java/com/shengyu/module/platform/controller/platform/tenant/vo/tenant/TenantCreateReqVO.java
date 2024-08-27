package com.shengyu.module.platform.controller.platform.tenant.vo.tenant;

import io.swagger.v3.oas.annotations.media.Schema;
import javax.validation.constraints.Email;
import javax.validation.constraints.Size;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.ToString;

@Schema(description = "管理后台 - 租户创建 Request VO")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
public class TenantCreateReqVO extends TenantBaseVO {

    @Schema(description = "邮箱账号,saas用户表的邮箱账号，用于通知SaaS用户邀请", example = "jin_zheyicn@qq.com")
    @Email(message = "邮箱账号格式不正确")
    @Size(max = 50, message = "邮箱账号长度不能超过 50 个字符")
    private String username;

}
