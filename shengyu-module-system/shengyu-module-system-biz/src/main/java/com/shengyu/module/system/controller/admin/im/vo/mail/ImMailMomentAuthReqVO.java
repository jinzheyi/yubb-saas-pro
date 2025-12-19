package com.shengyu.module.system.controller.admin.im.vo.mail;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;

/**
 * @author zhusy
 * @since 2025/12/19
 */
@Schema(description = "设置朋友圈权限 Request VO")
@Data
public class ImMailMomentAuthReqVO {

    @Schema(description = "是否允许对方查看我的朋友圈：0-不允许，1-允许", required = true, example = "1")
    @NotNull(message = "是否允许对方查看我的朋友圈不能为空")
    @Size(min = 0, max = 1, message = "是否允许对方查看我的朋友圈只能是0或1")
    private Integer lookme;

    @Schema(description = "是否允许查看对方的朋友圈：0-不允许，1-允许", required = true, example = "1")
    @NotNull(message = "是否允许查看对方的朋友圈不能为空")
    @Size(min = 0, max = 1, message = "是否允许查看对方的朋友圈只能是0或1")
    private Integer lookhim;

}
