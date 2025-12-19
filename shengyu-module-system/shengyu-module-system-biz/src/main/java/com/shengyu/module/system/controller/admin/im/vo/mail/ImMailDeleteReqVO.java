package com.shengyu.module.system.controller.admin.im.vo.mail;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotNull;

/**
 * @author zhusy
 * @since 2025/12/19
 */
@Schema(description = "删除好友 Request VO")
@Data
public class ImMailDeleteReqVO {

    @Schema(description = "好友ID", required = true, example = "1")
    @NotNull(message = "好友ID不能为空")
    private Long friend_id;

}
