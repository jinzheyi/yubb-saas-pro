package com.shengyu.module.system.controller.app.im.vo.conversation;

import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import com.fasterxml.jackson.databind.ser.std.ToStringSerializer;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.util.List;

@Schema(description = "移动端 - IM 会话增量同步 Response")
@Data
public class AppImConversationSyncRespVO {

    @Schema(description = "下一次同步游标", requiredMode = Schema.RequiredMode.REQUIRED, example = "1000")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long nextCursorVersion;

    @Schema(description = "是否还有更多", requiredMode = Schema.RequiredMode.REQUIRED, example = "false")
    private Boolean hasMore;

    @Schema(description = "会话变更列表", requiredMode = Schema.RequiredMode.REQUIRED)
    private List<AppImConversationSyncItemRespVO> items;
}
