package com.shengyu.module.system.controller.app.im.vo.message;

import com.shengyu.framework.common.pojo.PageParam;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.ToString;

import javax.validation.constraints.NotNull;

@Schema(description = "移动端 - 聊天媒体文件分页 Request VO")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
public class AppImChatMediaPageReqVO extends PageParam {

    @Schema(description = "ChatID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @NotNull(message = "{validation.im.chat_id.required}")
    private Long chatId;

    @Schema(description = "文件类型过滤(all|image|video|file)", example = "all")
    private String fileType;
}
