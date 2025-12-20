package com.shengyu.module.system.controller.admin.im.vo.group;

import io.swagger.v3.oas.annotations.media.Schema;

/**
 * 群聊关系响应VO
 *
 * @author 朱述勇
 * @since 2025/12/20
 */
@Schema(description = "群聊关系响应VO")
public interface GroupRelationRespVO {

    @Schema(description = "是否是群成员")
    boolean isStatus();

    @Schema(description = "群聊信息")
    GroupInfoResp getGroup();

    /**
     * 群聊信息响应接口
     */
    interface GroupInfoResp {

        @Schema(description = "群ID")
        Long getId();

        @Schema(description = "群名")
        String getName();

        @Schema(description = "群头像")
        String getAvatar();

        @Schema(description = "群成员数量")
        int getUsersCount();
    }
}
