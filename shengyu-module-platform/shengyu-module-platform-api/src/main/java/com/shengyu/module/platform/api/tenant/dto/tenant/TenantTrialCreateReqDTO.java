package com.shengyu.module.platform.api.tenant.dto.tenant;

import java.time.LocalDateTime;
import javax.validation.constraints.Email;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;
import lombok.Data;

/**
 * App 自助试用租户创建 Request DTO
 *
 * @author 圣钰科技
 */
@Data
public class TenantTrialCreateReqDTO {

    @NotBlank(message = "租户名不能为空")
    @Size(max = 30, message = "租户名长度不能超过 30 个字符")
    private String name;

    @NotBlank(message = "联系人不能为空")
    @Size(max = 30, message = "联系人长度不能超过 30 个字符")
    private String contactName;

    private String contactMobile;

    @NotBlank(message = "邮箱账号不能为空")
    @Email(message = "邮箱账号格式不正确")
    @Size(max = 50, message = "邮箱账号长度不能超过 50 个字符")
    private String username;

    @NotNull(message = "企业所有者不能为空")
    private Long ownerSaasUserId;

    @NotNull(message = "租户套餐编号不能为空")
    private Long packageId;

    @NotNull(message = "过期时间不能为空")
    private LocalDateTime expireTime;

    @NotNull(message = "账号数量不能为空")
    private Integer accountCount;

}
