package cn.iocoder.yudao.module.system.controller.admin.auth.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import javax.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * @author zhusy
 * @description: 跳转到目标租户的请求 VO
 * @date 2024/3/31 11:42
 */
@Schema(description = "管理后台 - 跳转到目标租户的请求 VO")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ToTenantReqVO {

    @Schema(description = "租户id", requiredMode = Schema.RequiredMode.REQUIRED, example = "10")
    @NotNull(message = "目标租户id不能为空")
    private Long id;

}
