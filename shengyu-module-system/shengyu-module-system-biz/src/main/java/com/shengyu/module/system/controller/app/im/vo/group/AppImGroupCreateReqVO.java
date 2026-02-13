package com.shengyu.module.system.controller.app.im.vo.group;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotEmpty;
import javax.validation.constraints.NotNull;
import java.util.List;

@Schema(description = "移动端 - IM 群组创建 Request VO")
@Data
public class AppImGroupCreateReqVO {

    @Schema(description = "群名称", requiredMode = Schema.RequiredMode.REQUIRED, example = "技术交流群")
    @NotBlank(message = "群名称不能为空")
    private String name;

    @Schema(description = "群头像", example = "https://...")
    private String avatar;

    @Schema(description = "群类型(1-普通群 2-工作群)", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @NotNull(message = "群类型不能为空")
    private Integer groupType;

    @Schema(description = "群成员ID列表", requiredMode = Schema.RequiredMode.REQUIRED)
    @NotEmpty(message = "群成员列表不能为空")
    private List<Long> memberIds;

    @Schema(description = "群简介", example = "这是一个技术交流群")
    private String introduction;

}
