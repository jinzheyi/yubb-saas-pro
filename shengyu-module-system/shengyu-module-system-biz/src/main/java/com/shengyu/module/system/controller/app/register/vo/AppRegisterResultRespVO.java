package com.shengyu.module.system.controller.app.register.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Data;

@Schema(description = "移动端 - 注册/加入企业结果 Response VO")
@Data
@AllArgsConstructor
public class AppRegisterResultRespVO {
    @Schema(description = "是否新建了全局账号")
    private Boolean newUser;
    @Schema(description = "是否已自动通过加入申请")
    private Boolean approved;
    @Schema(description = "结果提示")
    private String message;
}
