package cn.iocoder.yudao.module.system.controller.admin.config.vo;

import io.swagger.annotations.ApiModel;
import io.swagger.annotations.ApiModelProperty;
import lombok.Data;
import lombok.EqualsAndHashCode;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;

@ApiModel("管理后台 - 参数配置创建 Request VO")
@Data
@EqualsAndHashCode(callSuper = true)
public class ConfigCreateReqVO extends ConfigBaseVO {

    @ApiModelProperty(value = "参数键名", required = true, example = "yunai.db.username")
    @NotBlank(message = "参数键名长度不能为空")
    @Size(max = 100, message = "参数键名长度不能超过100个字符")
    private String configKey;

    @NotNull(message = "平台参数id不能为空")
    private Long configId;

    @NotNull(message = "参数类型不能为空")
    private Integer type;

    @NotNull(message = "删除状态不能为空")
    private Boolean deleted;

}
