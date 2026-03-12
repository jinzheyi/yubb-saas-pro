package com.shengyu.module.system.controller.app.im.vo.readreceipt;

import com.shengyu.framework.common.pojo.PageParam;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;

@Schema(description = "移动端 - IM 群聊已读/未读详情分页 Request VO")
@Data
@EqualsAndHashCode(callSuper = true)
public class AppImReadReceiptDetailReqVO extends PageParam {

    @Schema(description = "消息ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @NotNull(message = "消息ID不能为空")
    private Long messageId;

    @Schema(description = "状态(read/unread)", requiredMode = Schema.RequiredMode.REQUIRED, example = "read")
    @NotBlank(message = "状态不能为空")
    private String status;

}
