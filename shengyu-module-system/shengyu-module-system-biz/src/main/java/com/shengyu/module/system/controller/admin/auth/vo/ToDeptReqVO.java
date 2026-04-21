package com.shengyu.module.system.controller.admin.auth.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import javax.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * @author zhusy
 * @description: 跳转到目标部门的请求 VO
 * @date 2024/3/31 11:42
 */
@Schema(description = "管理后台 - 跳转到目标部门的请求 VO")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ToDeptReqVO {

    @Schema(description = "部门id", requiredMode = Schema.RequiredMode.REQUIRED, example = "10")
    @NotNull(message = "{validation.auth.target_dept_id.required}")
    private Long id;

}
