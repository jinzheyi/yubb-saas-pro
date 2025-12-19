package com.shengyu.module.system.controller.admin.im.vo.mail;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotNull;
import javax.validation.constraints.Range;

/**
 * @author zhusy
 * @since 2025/12/19
 */
@Schema(description = "设置/取消星标好友 Request VO")
@Data
public class ImMailStarReqVO {

    @Schema(description = "是否设置为星标好友：0-取消，1-设置", required = true, example = "1")
    @NotNull(message = "设置/取消星标好友状态不能为空")
    @Range(min = 0, max = 1, message = "设置/取消星标好友状态只能是0或1")
    private Integer star;

}
