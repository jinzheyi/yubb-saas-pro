package com.shengyu.module.system.controller.admin.im.vo.apply;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotNull;
import javax.validation.constraints.Pattern;

/**
 * 好友申请请求VO
 *
 * @author 朱述勇
 * @since 2025/12/20
 */
@Data
@Schema(description = "好友申请请求VO")
public class ImApplyAddReqVO {

    @Schema(description = "好友ID")
    @NotNull(message = "好友ID不能为空")
    private Long friendId;

    @Schema(description = "昵称备注")
    private String nickname;

    @Schema(description = "允许查看我：0、不允许 1、允许")
    @NotNull(message = "允许查看我不能为空")
    @Pattern(regexp = "[01]", message = "允许查看我只能是0或1")
    private String lookme;

    @Schema(description = "允许查看他：0、不允许 1、允许")
    @NotNull(message = "允许查看他不能为空")
    @Pattern(regexp = "[01]", message = "允许查看他只能是0或1")
    private String lookhim;
}
