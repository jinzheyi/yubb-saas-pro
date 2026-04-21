package com.shengyu.module.system.controller.app.im.vo.message;

import com.shengyu.framework.common.pojo.PageParam;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.ToString;
import org.springframework.format.annotation.DateTimeFormat;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Size;
import java.time.LocalDateTime;

import static com.shengyu.framework.common.util.date.DateUtils.FORMAT_YEAR_MONTH_DAY_HOUR_MINUTE_SECOND;

@Schema(description = "移动端 - IM 消息搜索 Request VO")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
public class AppImMessageSearchReqVO extends PageParam {

    @Schema(description = "ChatID(会话内搜索时传，会话全局搜索可不传)", example = "1")
    private Long chatId;

    @Schema(description = "搜索关键词", requiredMode = Schema.RequiredMode.REQUIRED, example = "会议")
    @NotBlank(message = "{validation.im.search_keyword.required}")
    @Size(min = 2, max = 64, message = "{validation.im.search_keyword.length}")
    private String keyword;

    @Schema(description = "消息类型(可选)", example = "8")
    private Integer messageType;

    @Schema(description = "消息分类过滤(all|media)，media 代表图片/视频/文件", example = "media")
    private String category;

    @Schema(description = "开始时间", example = "2024-01-01 00:00:00")
    @DateTimeFormat(pattern = FORMAT_YEAR_MONTH_DAY_HOUR_MINUTE_SECOND)
    private LocalDateTime startTime;

    @Schema(description = "结束时间", example = "2024-12-31 23:59:59")
    @DateTimeFormat(pattern = FORMAT_YEAR_MONTH_DAY_HOUR_MINUTE_SECOND)
    private LocalDateTime endTime;

}
