package com.shengyu.module.system.controller.admin.im.vo.apply;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotNull;
import javax.validation.constraints.Pattern;

/**
 * 处理好友申请请求VO
 *
 * @author 朱述勇
 * @since 2025/12/20
 */
@Data
@Schema(description = "处理好友申请请求VO")
public class ImApplyHandleReqVO {

    @Schema(description = "昵称备注")
    private String nickname;

    @Schema(description = "处理结果：refuse-拒绝, agree-同意, ignore-忽略")
    @NotNull(message = "处理结果不能为空")
    @Pattern(regexp = "^(refuse|agree|ignore)$", message = "处理结果只能是refuse、agree或ignore")
    private String status;

    @Schema(description = "允许查看我：0、不允许 1、允许")
    @NotNull(message = "允许查看我不能为空")
    @Pattern(regexp = "[01]", message = "允许查看我只能是0或1")
    private String lookme;

    @Schema(description = "允许查看他：0、不允许 1、允许")
    @NotNull(message = "允许查看他不能为空")
    @Pattern(regexp = "[01]", message = "允许查看他只能是0或1")
    private String lookhim;
}
