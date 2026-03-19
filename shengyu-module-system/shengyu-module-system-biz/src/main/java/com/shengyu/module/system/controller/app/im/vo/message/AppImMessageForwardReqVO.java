package com.shengyu.module.system.controller.app.im.vo.message;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotEmpty;
import javax.validation.constraints.NotNull;
import java.util.List;

/**
 * 移动端 - IM 消息转发 Request VO
 * 
 * 企业级设计考量：
 * 1. 支持逐条转发和合并转发
 * 2. 权限校验：仅可转发自己可见的消息
 * 3. 隐私保护：转发显示原发送者，不暴露原会话成员
 */
@Schema(description = "移动端 - IM 消息转发 Request VO")
@Data
public class AppImMessageForwardReqVO {

    @Schema(description = "目标ChatID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @NotNull(message = "目标会话ID不能为空")
    private Long targetChatId;

    @Schema(description = "待转发的消息ID列表", requiredMode = Schema.RequiredMode.REQUIRED, example = "[100, 101]")
    @NotEmpty(message = "待转发的消息ID列表不能为空")
    private List<Long> messageIds;

    @Schema(description = "转发类型(1-逐条转发 2-合并转发)", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @NotNull(message = "转发类型不能为空")
    private Integer forwardType;

    @Schema(description = "合并转发时的附加留言", example = "请看这些消息")
    private String comment;

}
