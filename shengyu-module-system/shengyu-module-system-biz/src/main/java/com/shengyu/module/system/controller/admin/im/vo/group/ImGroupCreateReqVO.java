package com.shengyu.module.system.controller.admin.im.vo.group;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotNull;
import java.util.List;

/**
 * 群聊创建请求VO
 *
 * @author 朱述勇
 * @since 2025/12/20
 */
@Data
@Schema(description = "群聊创建请求VO")
public class ImGroupCreateReqVO {

    @Schema(description = "好友ID列表")
    @NotNull(message = "好友ID列表不能为空")
    private List<Long> ids;
}
