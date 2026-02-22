package com.shengyu.module.system.dal.dataobject.im;

import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.framework.tenant.core.db.TenantBaseDO;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

/**
 * IM 群组 DO
 * 
 * 对应表: im_group
 * 功能: 存储群组基本信息
 *
 * @author 圣钰科技
 */
@TableName(value = "im_group", autoResultMap = true)
@KeySequence("im_group_seq")
@Data
@EqualsAndHashCode(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ImGroupDO extends TenantBaseDO {

    /**
     * 群ID
     */
    @TableId
    private Long id;

    /**
     * 群名称
     */
    private String name;

    /**
     * 群头像
     */
    private String avatar;

    /**
     * 群主ID
     */
    private Long ownerId;

    /**
     * 群类型
     * 
     * 枚举: {@link com.shengyu.module.system.enums.im.ImGroupTypeEnum}
     * 1-普通群, 2-工作群
     */
    private Integer groupType;

    /**
     * 成员数量
     */
    private Integer memberCount;

    /**
     * 最大成员数量
     */
    private Integer maxMemberCount;

    /**
     * 群公告
     */
    private String notice;

    /**
     * 群公告是否置顶
     */
    private Boolean noticePinned;

    /**
     * 群简介
     */
    private String introduction;

    /**
     * 群状态
     * 
     * 枚举: {@link com.shengyu.module.system.enums.im.ImGroupStatusEnum}
     * 1-正常, 2-已解散
     */
    private Integer status;

    /**
     * 是否允许成员邀请
     */
    private Boolean allowMemberInvite;

    /**
     * 加群是否需要审批
     */
    private Boolean needApproval;

    /**
     * 是否全员禁言
     */
    private Boolean muteAll;

}
