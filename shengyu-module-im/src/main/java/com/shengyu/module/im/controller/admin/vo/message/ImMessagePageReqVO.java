package com.shengyu.module.im.controller.admin.vo.message;

import com.shengyu.framework.common.pojo.PageParam;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.ToString;

@Schema(description = "管理后台 - IM消息分页 Request VO")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
public class ImMessagePageReqVO extends PageParam {

    @Schema(description = "发送者ID", example = "1024")
    private Long senderId;

    @Schema(description = "接收者ID", example = "2048")
    private Long receiverId;

    @Schema(description = "消息类型", example = "1")
    private Integer type;

    @Schema(description = "消息状态", example = "0")
    private Integer status;

    @Schema(description = "是否已读", example = "1")
    private Integer readStatus;

}
