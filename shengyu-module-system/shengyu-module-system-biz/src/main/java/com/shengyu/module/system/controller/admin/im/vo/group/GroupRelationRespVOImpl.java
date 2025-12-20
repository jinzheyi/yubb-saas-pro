package com.shengyu.module.system.controller.admin.im.vo.group;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

/**
 * 群聊关系响应VO实现类
 *
 * @author 朱述勇
 * @since 2025/12/20
 */
@Data
@Schema(description = "群聊关系响应VO实现类")
public class GroupRelationRespVOImpl implements GroupRelationRespVO {

    @Schema(description = "是否是群成员")
    private boolean status;

    @Schema(description = "群聊信息")
    private GroupInfoRespImpl group;

    /**
     * 群聊信息响应实现类
     */
    @Data
    @Schema(description = "群聊信息响应实现类")
    public static class GroupInfoRespImpl implements GroupInfoResp {

        @Schema(description = "群ID")
        private Long id;

        @Schema(description = "群名")
        private String name;

        @Schema(description = "群头像")
        private String avatar;

        @Schema(description = "群成员数量")
        private int usersCount;
    }
}