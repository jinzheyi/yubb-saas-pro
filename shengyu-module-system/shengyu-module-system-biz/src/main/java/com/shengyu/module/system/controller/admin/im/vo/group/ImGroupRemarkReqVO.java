package com.shengyu.module.system.controller.admin.im.vo.group;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;

/**
 * 更新群公告请求VO
 *
 * @author 朱述勇
 * @since 2025/12/20
 */
@Data
@Schema(description = "更新群公告请求VO")
public class ImGroupRemarkReqVO {

    @Schema(description = "群组ID")
    @NotNull(message = "群组ID不能为空")
    private Long id;

    @Schema(description = "群公告")
    @NotNull(message = "群公告不能为空")
    @Size(max = 200, message = "群公告不能超过200个字符")
    private String remark;
}
