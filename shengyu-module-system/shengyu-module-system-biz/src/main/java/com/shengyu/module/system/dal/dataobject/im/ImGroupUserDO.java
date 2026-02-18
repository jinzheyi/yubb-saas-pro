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

import java.time.LocalDateTime;

/**
 * IM 群成员 DO
 * 
 * 对应表: im_group_member
 * 功能: 存储群组成员关系
 *
 * @author 圣钰科技
 */
@TableName(value = "im_group_member", autoResultMap = true)
@KeySequence("im_group_member_seq")
@Data
@EqualsAndHashCode(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ImGroupUserDO extends TenantBaseDO {

    /**
     * 主键ID
     */
    @TableId
    private Long id;

    /**
     * 群ID
     */
    private Long groupId;

    /**
     * 用户ID
     */
    private Long userId;

    /**
     * 群成员角色
     * 
     * 枚举: {@link com.shengyu.module.system.enums.im.ImGroupMemberRoleEnum}
     * 1-群主, 2-管理员, 3-普通成员
     */
    private Integer role;

    /**
     * 在群里的昵称
     */
    private String nickname;

    /**
     * 加入时间
     */
    private LocalDateTime joinTime;

    /**
     * 禁言结束时间
     */
    private LocalDateTime muteEndTime;

}
