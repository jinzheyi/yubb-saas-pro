package com.shengyu.module.system.dal.mysql.im;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.module.system.dal.dataobject.im.ImGroupInviteDO;
import org.apache.ibatis.annotations.Mapper;

import java.time.LocalDateTime;

/**
 * IM 群邀请码 Mapper
 *
 * @author 圣钰科技
 */
@Mapper
public interface ImGroupInviteMapper extends BaseMapperX<ImGroupInviteDO> {

    /**
     * 根据邀请码查询
     *
     * @param inviteCode 邀请码
     * @return 邀请码信息
     */
    default ImGroupInviteDO selectByInviteCode(String inviteCode) {
        return selectOne(ImGroupInviteDO::getInviteCode, inviteCode);
    }

    /**
     * 查询群的有效邀请码
     *
     * @param groupId 群ID
     * @return 有效的邀请码
     */
    default ImGroupInviteDO selectValidByGroupId(Long groupId) {
        return selectOne(new LambdaQueryWrapper<ImGroupInviteDO>()
                .eq(ImGroupInviteDO::getGroupId, groupId)
                .eq(ImGroupInviteDO::getStatus, 1) // 状态为有效
                .gt(ImGroupInviteDO::getExpireTime, LocalDateTime.now()) // 未过期
                .orderByDesc(ImGroupInviteDO::getCreateTime)
                .last("LIMIT 1"));
    }

    /**
     * 更新过期的邀请码状态
     *
     * @return 更新数量
     */
    default int updateExpiredInvites() {
        return update(new LambdaUpdateWrapper<ImGroupInviteDO>()
                .eq(ImGroupInviteDO::getStatus, 1)
                .lt(ImGroupInviteDO::getExpireTime, LocalDateTime.now())
                .set(ImGroupInviteDO::getStatus, 2)); // 设置为已过期
    }

}
