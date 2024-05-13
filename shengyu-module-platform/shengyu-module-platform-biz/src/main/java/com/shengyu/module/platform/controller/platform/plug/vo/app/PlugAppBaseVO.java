package com.shengyu.module.platform.controller.platform.plug.vo.app;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;

/**
* 插件应用 Base VO，提供给添加、修改、详细的子 VO 使用
* 如果子 VO 存在差异的字段，请不要添加到这里，影响 Swagger 文档生成
*/
@Data
public class PlugAppBaseVO {

    @Schema(description = "应用名称", requiredMode = Schema.RequiredMode.REQUIRED, example = "名称")
    @NotBlank(message = "应用名称不能为空")
    private String name;

    @Schema(description = "应用主图地址")
    @NotNull(message = "应用主图地址不能为空")
    private String mainPic;

}
