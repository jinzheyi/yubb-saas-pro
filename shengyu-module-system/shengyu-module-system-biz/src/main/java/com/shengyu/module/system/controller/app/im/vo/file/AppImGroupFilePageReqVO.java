package com.shengyu.module.system.controller.app.im.vo.file;

import com.shengyu.framework.common.pojo.PageParam;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.ToString;

import javax.validation.constraints.NotNull;

@Schema(description = "移动端 - IM 群文件分页 Request VO")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
public class AppImGroupFilePageReqVO extends PageParam {

    @Schema(description = "群组ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @NotNull(message = "群组ID不能为空")
    private Long groupId;

    @Schema(description = "文件名搜索", example = "会议纪要")
    private String fileName;

    @Schema(description = "文件类型过滤", example = "image")
    private String fileType;

}
