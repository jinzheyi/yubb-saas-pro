package com.shengyu.module.system.controller.app.im.vo.call;

import com.shengyu.framework.common.pojo.PageParam;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

@Schema(description = "移动端 - IM 通话记录分页 Request VO")
@Data
@EqualsAndHashCode(callSuper = true)
public class AppCallRecordPageReqVO extends PageParam {

    @Schema(description = "通话类型：1-语音 2-视频", example = "1")
    private Integer callType;

    @Schema(description = "开始时间", example = "2026-01-01 00:00:00")
    private LocalDateTime startTime;

    @Schema(description = "结束时间", example = "2026-12-31 23:59:59")
    private LocalDateTime endTime;

    @Schema(description = "会话ID（查询特定会话的通话记录）", example = "10001")
    private Long chatId;
}
