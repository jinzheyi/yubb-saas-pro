package com.shengyu.module.system.service.im.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * 群组通话邀请结果 VO
 *
 * @author 圣钰科技
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "群组通话邀请结果")
public class GroupInviteResultVO {

    @Schema(description = "通话会话ID")
    private String callSessionId;

    @Schema(description = "邀请ID列表")
    private List<String> inviteIds;

    @Schema(description = "已邀请人数")
    private Integer invitedCount;
}
