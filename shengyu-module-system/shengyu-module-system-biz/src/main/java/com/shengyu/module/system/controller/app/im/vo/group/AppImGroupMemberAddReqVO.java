package com.shengyu.module.system.controller.app.im.vo.group;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotEmpty;
import javax.validation.constraints.NotNull;
import java.util.List;

@Schema(description = "移动端 - IM 群组添加成员 Request VO")
@Data
public class AppImGroupMemberAddReqVO {

    @Schema(description = "群ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @NotNull(message = "{validation.im.group_id.required}")
    private Long groupId;

    @Schema(description = "成员ID列表", requiredMode = Schema.RequiredMode.REQUIRED)
    @NotEmpty(message = "{validation.im.member_ids.required}")
    private List<Long> memberIds;

}
