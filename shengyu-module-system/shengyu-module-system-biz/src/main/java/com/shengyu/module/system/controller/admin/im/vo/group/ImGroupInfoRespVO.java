package com.shengyu.module.system.controller.admin.im.vo.group;

import com.shengyu.module.system.controller.admin.user.vo.user.UserRespVO;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.util.List;

/**
 * 群聊信息响应VO
 *
 * @author 朱述勇
 * @since 2025/12/20
 */
@Data
@Schema(description = "群聊信息响应VO")
public class ImGroupInfoRespVO {

    @Schema(description = "群ID")
    private Long id;

    @Schema(description = "群主ID")
    private Long userId;

    @Schema(description = "群名")
    private String name;

    @Schema(description = "群头像地址")
    private String avatar;

    @Schema(description = "状态（0正常 1停用）")
    private Integer status;

    @Schema(description = "群公告")
    private String remark;

    @Schema(description = "邀请确认")
    private Integer inviteConfirm;

    @Schema(description = "创建时间")
    private Long createTime;

    @Schema(description = "群成员列表")
    private List<GroupMemberRespVO> members;

    /**
     * 群成员响应VO
     */
    @Data
    public static class GroupMemberRespVO {

        @Schema(description = "用户ID")
        private Long userId;

        @Schema(description = "在群里的昵称")
        private String nickname;

        @Schema(description = "用户信息")
        private UserRespVO user;
    }
}
