package com.shengyu.module.system.controller.app.im.vo.readreceipt;

import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import com.fasterxml.jackson.databind.ser.std.ToStringSerializer;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.time.LocalDateTime;

@Schema(description = "移动端 - IM 群聊已读/未读详情分页 Response VO")
@Data
public class AppImReadReceiptDetailRespVO {

    @Schema(description = "用户ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "100")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long userId;

    @Schema(description = "用户昵称", example = "张三")
    private String userNickname;

    @Schema(description = "用户头像", example = "https://...")
    private String userAvatar;

    @Schema(description = "已读时间(未读为空)")
    private LocalDateTime readTime;

}
