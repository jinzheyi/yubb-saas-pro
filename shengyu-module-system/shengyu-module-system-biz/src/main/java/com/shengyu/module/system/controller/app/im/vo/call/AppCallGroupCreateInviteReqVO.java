package com.shengyu.module.system.controller.app.im.vo.call;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotEmpty;
import java.util.List;

/** One atomic request for creating a group-call session and its invited roster. */
@Schema(description = "移动端 - 创建群组通话邀请 Request VO")
@Data
public class AppCallGroupCreateInviteReqVO {
    @NotBlank(message = "会话ID不能为空")
    @Schema(description = "群聊会话ID", requiredMode = Schema.RequiredMode.REQUIRED)
    private String chatId;
    @NotBlank(message = "群组ID不能为空")
    @Schema(description = "群组ID", requiredMode = Schema.RequiredMode.REQUIRED)
    private String groupId;
    @NotBlank(message = "通话类型不能为空")
    @Schema(description = "audio 或 video", requiredMode = Schema.RequiredMode.REQUIRED)
    private String callType;
    @NotEmpty(message = "被邀请者列表不能为空")
    @Schema(description = "被邀请成员ID", requiredMode = Schema.RequiredMode.REQUIRED)
    private List<Long> inviteeIds;
    @Schema(description = "发起设备ID")
    @NotBlank(message = "发起设备ID不能为空")
    private String deviceId;
}
