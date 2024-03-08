package cn.iocoder.yudao.module.system.controller.admin.plug.vo.orderitem;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotNull;

/**
* 订单项 Base VO，提供给添加、修改、详细的子 VO 使用
* 如果子 VO 存在差异的字段，请不要添加到这里，影响 Swagger 文档生成
*/
@Data
public class PlugOrderItemBaseVO {

    @Schema(description = "插件应用id")
    private Long plugAppId;

    @Schema(description = "订单编号", required = true)
    @NotNull(message = "订单编号不能为空")
    private String orderNo;

}
