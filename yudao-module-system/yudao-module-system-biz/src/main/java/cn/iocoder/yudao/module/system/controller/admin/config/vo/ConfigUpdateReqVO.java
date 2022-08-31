package cn.iocoder.yudao.module.system.controller.admin.config.vo;

import io.swagger.annotations.ApiModel;
import io.swagger.annotations.ApiModelProperty;
import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;

@ApiModel("管理后台 - 参数配置创建 Request VO")
@Data
public class ConfigUpdateReqVO {

    @ApiModelProperty(value = "参数配置序号", required = true, example = "1024")
    @NotNull(message = "参数配置编号不能为空")
    private Long id;

    @ApiModelProperty(value = "参数名称", required = true, example = "数据库名")
    @NotBlank(message = "参数名称不能为空")
    @Size(max = 100, message = "参数名称不能超过100个字符")
    private String name;

    @ApiModelProperty(value = "参数键值", required = true, example = "1024")
    @NotBlank(message = "参数键值不能为空")
    @Size(max = 500, message = "参数键值长度不能超过500个字符")
    private String value;

    @ApiModelProperty(value = "备注", example = "备注一下很帅气！")
    private String remark;

}
