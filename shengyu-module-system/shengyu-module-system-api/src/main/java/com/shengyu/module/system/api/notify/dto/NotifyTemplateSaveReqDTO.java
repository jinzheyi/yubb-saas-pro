package com.shengyu.module.system.api.notify.dto;

import com.shengyu.framework.common.enums.CommonStatusEnum;
import com.shengyu.framework.common.validation.InEnum;
import lombok.Builder;
import lombok.Data;

import javax.validation.constraints.NotEmpty;
import javax.validation.constraints.NotNull;

/**
 * 站内信模版创建
 */
@Data
@Builder
public class NotifyTemplateSaveReqDTO {

    /**
     * ID
     */
    private Long id;

    @NotEmpty(message = "模版名称不能为空")
    private String name;

    @NotNull(message = "模版编码不能为空")
    private String code;

    @NotNull(message = "模版类型不能为空")
    private Integer type;

    @NotEmpty(message = "发送人名称不能为空")
    private String nickname;

    @NotEmpty(message = "模版内容不能为空")
    private String content;

    @NotNull(message = "状态不能为空")
    @InEnum(value = CommonStatusEnum.class, message = "状态必须是 {value}")
    private Integer status;

    /**
     * 备注
     */
    private String remark;

    public static String tenant_new_admin_user = "tenant-new-admin-user";

    public static String tenant_admin_user = "tenant-admin-user";

    public static String tenant_super_admin_user = "tenant-super-admin-user";

    /**
     *  获取邀请新用户消息模版
     * @return 模版
     */
    public static NotifyTemplateSaveReqDTO getTenantNewAdminUser() {
        return NotifyTemplateSaveReqDTO.builder()
                .name("邀请新用户消息")
                .code(tenant_new_admin_user)
                .type(2)
                .nickname("系统")
                .content("您已被邀请加入租户【{tenantName}】。账号【{mail}】，密码【{password}】，注册时间【{registerTime}】请登录系统进行确认")
                .status(CommonStatusEnum.ENABLE.getStatus()).build();
    }

    /**
     *  获取邀请用户消息模版
     * @return 模版
     */
    public static NotifyTemplateSaveReqDTO getTenantAdminUser() {
        return NotifyTemplateSaveReqDTO.builder()
                .name("邀请用户消息")
                .code(tenant_admin_user)
                .type(2)
                .nickname("系统")
                .content("您已被邀请加入租户【{tenantName}】，请登录系统进行确认")
                .status(CommonStatusEnum.ENABLE.getStatus()).build();
    }

    /**
     *  获取邀请用户消息模版
     * @return 模版
     */
    public static NotifyTemplateSaveReqDTO getTenantSuperAdminUser() {
        return NotifyTemplateSaveReqDTO.builder()
                .name("创建租户超管消息")
                .code(tenant_super_admin_user)
                .type(2)
                .nickname("系统")
                .content("您已成为租户【{tenantName}】超管,拥有当前租户所有权限。账号【{mail}】，密码【{password}】，注册时间【{registerTime}】请登录系统进行确认")
                .status(CommonStatusEnum.ENABLE.getStatus()).build();
    }

}
