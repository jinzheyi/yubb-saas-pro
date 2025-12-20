package com.shengyu.module.system.controller.admin.im.vo.tag;

import com.shengyu.module.system.controller.admin.user.vo.user.UserRespVO;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

/**
 * 标签用户列表响应VO
 *
 * @author 朱述勇
 * @since 2025/12/20
 */
@Data
@Schema(description = "标签用户列表响应VO")
public class ImTagUserListRespVO {

    @Schema(description = "用户ID", example = "1")
    private Long id;

    @Schema(description = "昵称", example = "张三")
    private String nickname;

    @Schema(description = "用户信息")
    private UserRespVO user;
}