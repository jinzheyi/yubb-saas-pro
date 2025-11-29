package com.shengyu.module.im.controller.admin.vo.user;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotEmpty;
import javax.validation.constraints.NotNull;

@Schema(description = "管理后台 - IM用户创建或更新 Request VO")
@Data
public class ImUserCreateOrUpdateReqVO {

    @Schema(description = "用户ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1024")
    @NotNull(message = "用户ID不能为空")
    private Long userId;

    @Schema(description = "用户昵称", requiredMode = Schema.RequiredMode.REQUIRED, example = "张三")
    @NotEmpty(message = "用户昵称不能为空")
    private String nickname;

    @Schema(description = "用户头像", example = "https://example.com/avatar.jpg")
    private String avatar;

}
