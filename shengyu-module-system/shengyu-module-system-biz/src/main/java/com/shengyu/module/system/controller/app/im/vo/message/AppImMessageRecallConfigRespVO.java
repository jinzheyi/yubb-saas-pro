package com.shengyu.module.system.controller.app.im.vo.message;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Schema(description = "移动端 - IM 撤回配置 Response VO")
@Data
public class AppImMessageRecallConfigRespVO {

    @Schema(description = "普通用户可撤回窗口（秒）", requiredMode = Schema.RequiredMode.REQUIRED, example = "120")
    private Integer windowSeconds;

    @Schema(description = "管理员可撤回窗口（秒）", requiredMode = Schema.RequiredMode.REQUIRED, example = "86400")
    private Integer adminWindowSeconds;
}
