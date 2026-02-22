package com.shengyu.module.system.controller.app.im.vo.group;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;

/**
 * IM 群公告更新 Request VO
 *
 * @author 圣钰科技
 */
@Schema(description = "移动端 - IM 群公告更新 Request VO")
@Data
public class AppImGroupNoticeUpdateReqVO {

    @Schema(description = "群组ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "123456")
    @NotNull(message = "群组ID不能为空")
    private Long groupId;

    @Schema(description = "群公告内容", example = "欢迎加入技术交流群！")
    @Size(max = 500, message = "群公告不能超过500字")
    private String notice;

    @Schema(description = "是否推送通知给所有成员", example = "true")
    private Boolean notifyMembers = true;

    @Schema(description = "是否置顶公告", example = "false")
    private Boolean pinNotice = false;

}
