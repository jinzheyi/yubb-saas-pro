package com.shengyu.module.system.controller.app.im.vo.contact;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotNull;

@Schema(description = "移动端 - IM 联系人设置更新 Request VO")
@Data
public class AppImContactSettingUpdateReqVO {

    @Schema(description = "联系人ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "100")
    @NotNull(message = "联系人ID不能为空")
    private Long contactId;

    @Schema(description = "备注名", example = "小张")
    private String nickname;

    @Schema(description = "是否星标联系人", example = "true")
    private Boolean star;

    @Schema(description = "是否免打扰", example = "false")
    private Boolean noDisturb;

}
