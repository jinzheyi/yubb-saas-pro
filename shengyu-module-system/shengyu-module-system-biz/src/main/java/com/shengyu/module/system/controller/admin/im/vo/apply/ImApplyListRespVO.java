package com.shengyu.module.system.controller.admin.im.vo.apply;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

/**
 * 好友申请列表响应VO
 *
 * @author 朱述勇
 * @since 2025/12/20
 */
@Data
@Schema(description = "好友申请列表响应VO")
public class ImApplyListRespVO {

    @Schema(description = "申请ID")
    private Long id;

    @Schema(description = "申请人ID")
    private Long userId;

    @Schema(description = "申请人用户名")
    private String username;

    @Schema(description = "申请人昵称")
    private String nickname;

    @Schema(description = "申请人头像")
    private String avatar;

    @Schema(description = "昵称备注")
    private String applyNickname;

    @Schema(description = "允许查看我：0、不允许 1、允许")
    private Integer lookme;

    @Schema(description = "允许查看他：0、不允许 1、允许")
    private Integer lookhim;

    @Schema(description = "申请状态：pending-待处理, agree-已同意, refuse-已拒绝, ignore-已忽略")
    private String status;

    @Schema(description = "创建时间")
    private Long createTime;
}
