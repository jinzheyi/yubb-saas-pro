package com.shengyu.module.system.controller.admin.user.vo.user;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Schema(description = "管理后台 - 用户全部租户列表 Response VO")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class MyTenantRespVO {

    @Schema(description = "租户编号", requiredMode = Schema.RequiredMode.REQUIRED, example = "1024")
    private Long id;

    @Schema(description = "租户名称", requiredMode = Schema.RequiredMode.REQUIRED, example = "圣钰")
    private String tenantName;

    @Schema(description = "租户状态")
    private String status;

    @Schema(description = "当前账号在该租户下的成员状态")
    private Integer userStatus;

    @Schema(description = "是否等待用户主动确认加入")
    private Boolean waitingConfirm;

    @Schema(description = "最后登录时间", example = "时间戳格式")
    private LocalDateTime loginDate;

}
