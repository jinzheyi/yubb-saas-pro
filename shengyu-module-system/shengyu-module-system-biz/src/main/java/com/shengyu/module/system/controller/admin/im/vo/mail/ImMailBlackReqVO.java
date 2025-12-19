package com.shengyu.module.system.controller.admin.im.vo.mail;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;

/**
 * @author zhusy
 * @since 2025/12/19
 */
@Schema(description = "更新好友黑名单状态 Request VO")
@Data
public class ImMailBlackReqVO {

    @Schema(description = "是否移入黑名单：0-移除，1-移入", required = true, example = "1")
    @NotNull(message = "移入/移除黑名单状态不能为空")
    @Size(min = 0, max = 1, message = "移入/移除黑名单状态只能是0或1")
    private Integer isblack;

}
