package com.shengyu.module.im.controller.admin.vo.group;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotNull;

@Schema(description = "管理后台 - 群组设置成员角色 Request VO")
@Data
public class ImGroupSetMemberRoleReqVO {

    @Schema(description = "群组ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1001")
    @NotNull(message = "群组ID不能为空")
    private Long groupId;

    @Schema(description = "用户ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1024")
    @NotNull(message = "用户ID不能为空")
    private Long userId;

    @Schema(description = "角色：0-普通成员，1-管理员，2-群主", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @NotNull(message = "角色不能为空")
    private Integer role;

}
