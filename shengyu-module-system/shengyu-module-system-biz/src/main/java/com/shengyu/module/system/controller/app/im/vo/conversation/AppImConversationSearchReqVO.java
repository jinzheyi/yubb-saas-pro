package com.shengyu.module.system.controller.app.im.vo.conversation;

import com.shengyu.framework.common.pojo.PageParam;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.ToString;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Size;

@Schema(description = "移动端 - IM 会话搜索 Request VO")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
public class AppImConversationSearchReqVO extends PageParam {

    @Schema(description = "搜索关键词", requiredMode = Schema.RequiredMode.REQUIRED, example = "项目")
    @NotBlank(message = "搜索关键词不能为空")
    @Size(min = 2, max = 64, message = "搜索关键词长度需在2到64个字符之间")
    private String keyword;

    @Schema(description = "会话类型(1-单聊 2-群聊)，不传则全量", example = "2")
    private Integer conversationType;

}
