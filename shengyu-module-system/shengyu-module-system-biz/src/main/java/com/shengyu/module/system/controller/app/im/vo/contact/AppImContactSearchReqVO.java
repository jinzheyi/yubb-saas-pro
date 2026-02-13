package com.shengyu.module.system.controller.app.im.vo.contact;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotBlank;

/**
 * 移动端 - IM 联系人搜索 Request VO
 *
 * @author 圣钰科技
 */
@Schema(description = "移动端 - IM 联系人搜索 Request VO")
@Data
public class AppImContactSearchReqVO {

    @Schema(description = "搜索关键词(用户名/昵称/手机号)", requiredMode = Schema.RequiredMode.REQUIRED, example = "张三")
    @NotBlank(message = "搜索关键词不能为空")
    private String keyword;

    @Schema(description = "搜索类型(1-用户 2-群组 3-全部)", example = "3")
    private Integer searchType;

}
