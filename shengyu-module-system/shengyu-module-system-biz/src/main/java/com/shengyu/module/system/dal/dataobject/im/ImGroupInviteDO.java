package com.shengyu.module.system.dal.dataobject.im;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.framework.mybatis.core.dataobject.BaseDO;
import lombok.*;

import java.time.LocalDateTime;

/**
 * IM 群邀请码 DO
 *
 * @author 圣钰科技
 */
@TableName("im_group_invite")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ImGroupInviteDO extends BaseDO {

    /**
     * 邀请ID
     */
    @TableId
    private Long id;

    /**
     * 群ID
     */
    private Long groupId;

    /**
     * 邀请码(唯一)
     */
    private String inviteCode;

    /**
     * 创建者ID
     */
    private Long creatorId;

    /**
     * 过期时间
     */
    private LocalDateTime expireTime;

    /**
     * 最大使用次数(0表示不限制)
     */
    private Integer maxUseCount;

    /**
     * 已使用次数
     */
    private Integer usedCount;

    /**
     * 状态(1-有效 2-已过期 3-已禁用)
     */
    private Integer status;

}
