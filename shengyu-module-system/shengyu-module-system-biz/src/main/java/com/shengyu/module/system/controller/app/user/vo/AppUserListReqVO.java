package com.shengyu.module.system.controller.app.user.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Schema(description = "移动端 - 用户列表 Request VO")
@Data
public class AppUserListReqVO {

    @Schema(description = "部门ID", example = "1")
    private Long deptId;

    @Schema(description = "搜索关键词（姓名/手机号）", example = "张三")
    private String keyword;

    @Schema(description = "状态（0正常 1停用）", example = "0")
    private Integer status;

}
