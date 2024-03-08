package cn.iocoder.yudao.module.system.api.plug.dto.tenant;

import lombok.Data;

import javax.validation.constraints.NotNull;

@Data
public class PlugAppEnableReqDTO {

    @NotNull(message = "插件应用id不能为空")
    private Long plugAppId;

    @NotNull(message = "是否停用状态不能为空")
    private Integer enable;

}
