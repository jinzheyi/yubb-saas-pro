package com.shengyu.module.im.dal.mapper;

import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.module.im.dal.dataobject.ImGroupMemberDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * IM群组成员Mapper
 *
 * @author 圣钰科技
 */
@Mapper
public interface ImGroupMemberMapper extends BaseMapperX<ImGroupMemberDO> {

    /**
     * 获取群组成员列表
     *
     * @param groupId 群组ID
     * @return 群组成员列表
     */
    default List<ImGroupMemberDO> getGroupMembers(Long groupId) {
        return selectList(new LambdaQueryWrapperX<ImGroupMemberDO>()
                .eq(ImGroupMemberDO::getGroupId, groupId)
                .eq(ImGroupMemberDO::getStatus, 0) // 0表示正常
                .orderByAsc(ImGroupMemberDO::getJoinTime));
    }

    /**
     * 获取用户加入的群组列表
     *
     * @param userId 用户ID
     * @return 群组列表
     */
    default List<ImGroupMemberDO> getUserGroups(Long userId) {
        return selectList(new LambdaQueryWrapperX<ImGroupMemberDO>()
                .eq(ImGroupMemberDO::getUserId, userId)
                .eq(ImGroupMemberDO::getStatus, 0) // 0表示正常
                .orderByAsc(ImGroupMemberDO::getJoinTime));
    }

    /**
     * 获取群组成员信息
     *
     * @param groupId 群组ID
     * @param userId  用户ID
     * @return 群组成员信息
     */
    default ImGroupMemberDO getGroupMember(Long groupId, Long userId) {
        return selectOne(new LambdaQueryWrapperX<ImGroupMemberDO>()
                .eq(ImGroupMemberDO::getGroupId, groupId)
                .eq(ImGroupMemberDO::getUserId, userId));
    }

    /**
     * 批量获取群组成员
     *
     * @param groupId  群组ID
     * @param userIds  用户ID列表
     * @return 群组成员列表
     */
    default List<ImGroupMemberDO> getGroupMembersBatch(Long groupId, List<Long> userIds) {
        return selectList(new LambdaQueryWrapperX<ImGroupMemberDO>()
                .eq(ImGroupMemberDO::getGroupId, groupId)
                .in(ImGroupMemberDO::getUserId, userIds)
                .eq(ImGroupMemberDO::getStatus, 0)); // 0表示正常
    }
}
