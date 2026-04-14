package com.shengyu.module.system.controller.app.im.vo.group;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;

@Schema(description = "移动端 - IM 群成员昵称更新 Request VO")
@Data
public class AppImGroupMemberNicknameUpdateReqVO {

    @Schema(description = "群组ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "123456")
    @NotNull(message = "群组ID不能为空")
    private Long groupId;

    @Schema(description = "成员用户ID，为空时表示设置自己的群昵称", example = "10001")
    private Long memberUserId;

    @Schema(description = "群昵称", requiredMode = Schema.RequiredMode.REQUIRED, example = "张三-产品")
    @NotNull(message = "群昵称不能为空")
    @Size(min = 1, max = 15, message = "群昵称长度必须在 1 到 15 个字符之间")
    private String nickname;
}
