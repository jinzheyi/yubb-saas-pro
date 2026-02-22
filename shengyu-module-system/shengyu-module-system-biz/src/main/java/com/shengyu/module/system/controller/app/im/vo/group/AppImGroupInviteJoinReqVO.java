package com.shengyu.module.system.controller.app.im.vo.group;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotBlank;

@Schema(description = "移动端 - IM 通过邀请码加入群 Request VO")
@Data
public class AppImGroupInviteJoinReqVO {

    @Schema(description = "邀请码", requiredMode = Schema.RequiredMode.REQUIRED, example = "GRP1A2B3C4D5E6F7G8H")
    @NotBlank(message = "邀请码不能为空")
    private String inviteCode;

}
