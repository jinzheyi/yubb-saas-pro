package com.shengyu.module.system.controller.app.im.vo.group;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import java.util.List;

@Schema(description = "移动端 - IM 群组添加成员 Request VO")
@Data
public class AppImGroupMemberAddReqVO {

    @Schema(description = "群ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @NotNull(message = "群ID不能为空")
    private Long groupId;

    @Schema(description = "成员ID列表", requiredMode = Schema.RequiredMode.REQUIRED)
    @NotEmpty(message = "成员列表不能为空")
    private List<Long> memberIds;

}
