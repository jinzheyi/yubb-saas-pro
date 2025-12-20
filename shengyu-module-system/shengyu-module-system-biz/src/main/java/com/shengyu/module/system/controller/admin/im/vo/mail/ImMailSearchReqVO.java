package com.shengyu.module.system.controller.admin.im.vo.mail;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotBlank;

/**
 * 搜索用户 Request VO
 *
 * @author zhusy
 * @since 2025/12/20
 */
@Schema(description = "搜索用户 Request VO")
@Data
public class ImMailSearchReqVO {

    @Schema(description = "关键词", required = true, example = "zhangsan")
    @NotBlank(message = "关键词不能为空")
    private String keyword;

}