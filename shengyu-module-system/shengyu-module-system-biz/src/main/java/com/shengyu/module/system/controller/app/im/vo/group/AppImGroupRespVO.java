package com.shengyu.module.system.controller.app.im.vo.group;

import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import com.fasterxml.jackson.databind.ser.std.ToStringSerializer;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.time.LocalDateTime;

@Schema(description = "移动端 - IM 群组 Response VO")
@Data
public class AppImGroupRespVO {

    @Schema(description = "群ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long id;

    @Schema(description = "群名称", requiredMode = Schema.RequiredMode.REQUIRED, example = "技术交流群")
    private String name;

    @Schema(description = "群头像", example = "https://...")
    private String avatar;

    @Schema(description = "群主ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long ownerId;

    @Schema(description = "群主名称", example = "张三")
    private String ownerName;

    @Schema(description = "群类型(1-普通群 2-工作群)", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    private Integer groupType;

    @Schema(description = "成员数量", requiredMode = Schema.RequiredMode.REQUIRED, example = "10")
    private Integer memberCount;

    @Schema(description = "最大成员数量", requiredMode = Schema.RequiredMode.REQUIRED, example = "500")
    private Integer maxMemberCount;

    @Schema(description = "群公告", example = "欢迎加入技术交流群")
    private String notice;

    @Schema(description = "群公告是否置顶", example = "false")
    private Boolean noticePinned;

    @Schema(description = "群简介", example = "这是一个技术交流群")
    private String introduction;

    @Schema(description = "群状态(1-正常 2-已解散)", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    private Integer status;

    @Schema(description = "是否允许成员邀请", requiredMode = Schema.RequiredMode.REQUIRED, example = "true")
    private Boolean allowMemberInvite;

    @Schema(description = "加群是否需要审批", requiredMode = Schema.RequiredMode.REQUIRED, example = "false")
    private Boolean needApproval;

    @Schema(description = "是否全员禁言", requiredMode = Schema.RequiredMode.REQUIRED, example = "false")
    private Boolean muteAll;

    @Schema(description = "当前用户在群里的角色(0-普通成员 1-管理员 2-群主)", example = "0")
    private Integer myRole;

    @Schema(description = "当前用户是否仍在群内（被踢/已退出时为 false，仍可只读查看群信息）", example = "true")
    private Boolean inGroup;

    @Schema(description = "当前群待审批入群申请数量", example = "0")
    private Long pendingJoinRequestCount;

    @Schema(description = "创建时间", requiredMode = Schema.RequiredMode.REQUIRED)
    private LocalDateTime createTime;

    @Schema(description = "群成员信息列表(用于组合头像,最多4个)", example = "[{\"userId\":1,\"name\":\"张三\",\"avatar\":\"url1\"}]")
    private java.util.List<GroupMemberItem> groupMemberItems;

    @Schema(description = "群组成员状态（群聊时有值）：0=正常(在群内), 1=已退出(主动退群), 2=已被踢(被群主/管理员踢出), 3=群已解散", example = "0")
    private Integer groupMemberStatus;

    @Schema(description = "离群时间（群聊且已离群时有值）", example = "2026-06-01 10:30:00")
    private LocalDateTime leftAt;

    @Schema(description = "会话ID（用于关联群设置）", example = "100")
    @JsonSerialize(using = ToStringSerializer.class)
    private Long chatId;

    @Schema(description = "是否来自快照数据（被踢/退出/解散后返回的是离群时的冻结数据）", example = "false")
    private Boolean fromSnapshot;

    @Data
    @Schema(description = "群成员信息项(用于组合头像)")
    public static class GroupMemberItem {
        @Schema(description = "用户ID")
        private Long userId;
        @Schema(description = "用户名称")
        private String name;
        @Schema(description = "用户头像")
        private String avatar;
    }
}
