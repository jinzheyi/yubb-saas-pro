package com.shengyu.module.system.controller.app.im.vo.call;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotEmpty;
import java.util.List;

@Schema(description = "移动端 - 群组通话邀请 Request VO")
@Data
public class AppCallGroupInviteReqVO {

    @Schema(description = "通话会话ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "abc123def456")
    @NotBlank(message = "通话会话ID不能为空")
    private String callSessionId;

    @Schema(description = "群组ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "20001")
    @NotBlank(message = "群组ID不能为空")
    private String groupId;

    @Schema(description = "被邀请者ID列表", requiredMode = Schema.RequiredMode.REQUIRED)
    @NotEmpty(message = "被邀请者ID列表不能为空")
    private List<Long> inviteeIds;
}
