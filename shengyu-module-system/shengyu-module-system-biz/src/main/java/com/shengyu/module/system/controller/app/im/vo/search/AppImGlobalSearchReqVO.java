package com.shengyu.module.system.controller.app.im.vo.search;

import com.shengyu.framework.common.pojo.PageParam;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.ToString;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Size;

@Schema(description = "移动端 - IM 全局搜索 Request VO")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
public class AppImGlobalSearchReqVO extends PageParam {

    @Schema(description = "搜索关键词", requiredMode = Schema.RequiredMode.REQUIRED, example = "会议")
    @NotBlank(message = "搜索关键词不能为空")
    @Size(min = 2, max = 64, message = "搜索关键词长度需在 2 到 64 个字符之间")
    private String keyword;

    @Schema(description = "标签页(all|message|contact|group|media)", example = "all")
    private String tab;

    @Schema(description = "排序方式(recent|relevance)", example = "relevance")
    private String sort;

    @Schema(description = "会话内搜索时可传 chatId", example = "10001")
    private Long chatId;
}

