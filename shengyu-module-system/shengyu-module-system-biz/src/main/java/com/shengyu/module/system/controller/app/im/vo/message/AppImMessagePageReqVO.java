package com.shengyu.module.system.controller.app.im.vo.message;

import com.shengyu.framework.common.pojo.PageParam;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;

import javax.validation.constraints.NotNull;

@Schema(description = "移动端 - IM 消息分页 Request VO")
@Data
@EqualsAndHashCode(callSuper = true)
public class AppImMessagePageReqVO extends PageParam {

    @Schema(description = "ChatID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @NotNull(message = "{validation.im.chat_id.required}")
    private Long chatId;

    @Schema(description = "消息类型(1-文本 2-图片 3-语音 4-视频 5-文件 6-位置 7-表情包 8-自定义贴纸 10-系统消息)", example = "1")
    private Integer messageType;

}
