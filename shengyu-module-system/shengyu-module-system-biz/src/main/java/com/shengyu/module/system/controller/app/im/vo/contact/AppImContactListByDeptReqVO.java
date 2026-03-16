package com.shengyu.module.system.controller.app.im.vo.contact;

import com.shengyu.framework.common.pojo.PageParam;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;

import javax.validation.constraints.NotNull;

@Schema(description = "移动端 - IM 按部门获取联系人分页 Request VO")
@Data
@EqualsAndHashCode(callSuper = true)
public class AppImContactListByDeptReqVO extends PageParam {

    @Schema(description = "部门ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @NotNull(message = "deptId 不能为空")
    private Long deptId;

    @Schema(description = "关键字（昵称/用户名/手机号等）", requiredMode = Schema.RequiredMode.NOT_REQUIRED, example = "张三")
    private String keyword;

}
