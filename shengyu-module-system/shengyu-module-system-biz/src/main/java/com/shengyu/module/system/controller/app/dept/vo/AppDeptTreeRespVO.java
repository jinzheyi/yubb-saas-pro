package com.shengyu.module.system.controller.app.dept.vo;

import com.shengyu.module.system.controller.app.user.vo.AppUserSimpleRespVO;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.util.List;

@Schema(description = "移动端 - 部门树 Response VO")
@Data
public class AppDeptTreeRespVO {

    @Schema(description = "部门编号", requiredMode = Schema.RequiredMode.REQUIRED, example = "1024")
    private Long id;

    @Schema(description = "部门名称", requiredMode = Schema.RequiredMode.REQUIRED, example = "圣钰")
    private String name;

    @Schema(description = "父部门 ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1024")
    private Long parentId;

    @Schema(description = "排序", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    private Integer sort;

    @Schema(description = "部门成员数量", example = "10")
    private Integer memberCount;

    @Schema(description = "部门成员列表（仅用户所属部门才有数据）")
    private List<AppUserSimpleRespVO> users;

}
