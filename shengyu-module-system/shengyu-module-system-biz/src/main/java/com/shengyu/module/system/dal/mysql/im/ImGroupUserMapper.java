package com.shengyu.module.system.dal.mysql.im;

import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.module.system.dal.dataobject.im.ImGroupUserDO;
import org.apache.ibatis.annotations.Delete;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;

import java.util.ArrayList;
import java.util.Collections;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * IM 群成员 Mapper
 *
 * @author 圣钰科技
 */
@Mapper
public interface ImGroupUserMapper extends BaseMapperX<ImGroupUserDO> {

    @Select("SELECT id, group_id, user_id, role, nickname, join_time, mute_end_time, creator, create_time, updater, update_time, deleted, tenant_id " +
            "FROM im_group_member WHERE group_id = #{groupId} AND user_id = #{userId} AND deleted = 1 LIMIT 1")
    ImGroupUserDO selectDeletedByGroupIdAndUserId(@Param("groupId") Long groupId, @Param("userId") Long userId);

    @Update("UPDATE im_group_member SET deleted = 0, role = #{role}, nickname = #{nickname}, join_time = #{joinTime}, mute_end_time = #{muteEndTime}, update_time = NOW() " +
            "WHERE id = #{id} AND deleted = 1")
    int reviveSoftDeleted(@Param("id") Long id,
                          @Param("role") Integer role,
                          @Param("nickname") String nickname,
                          @Param("joinTime") LocalDateTime joinTime,
                          @Param("muteEndTime") LocalDateTime muteEndTime);

    @Delete("DELETE FROM im_group_member WHERE group_id = #{groupId} AND user_id = #{userId} AND deleted = 1")
    int hardDeleteSoftDeletedByGroupIdAndUserId(@Param("groupId") Long groupId, @Param("userId") Long userId);

    /**
     * 批量删除指定群的所有成员关系（硬删除已软删除的记录）
     * @param groupId 群ID
     * @return 删除行数
     */
    @Delete("DELETE FROM im_group_member WHERE group_id = #{groupId} AND deleted = 1")
    int hardDeleteAllSoftDeletedByGroupId(@Param("groupId") Long groupId);

    /**
     * 按群ID删除所有成员关系（包括未删除的和已删除的）
     * @param groupId 群ID
     * @return 删除行数
     */
    default int deleteByGroupId(Long groupId) {
        // 先硬删除所有已软删除的记录
        hardDeleteAllSoftDeletedByGroupId(groupId);
        // 再删除剩余的未删除记录
        return delete(new LambdaQueryWrapperX<ImGroupUserDO>()
                .eq(ImGroupUserDO::getGroupId, groupId));
    }

    /**
     * 根据群ID查询群成员列表
     *
     * @param groupId 群ID
     * @return 群成员列表
     */
    default List<ImGroupUserDO> selectListByGroupId(Long groupId) {
        return selectList(ImGroupUserDO::getGroupId, groupId);
    }

    /**
     * 分页查询群成员列表（SQL 层分页，替代内存 subList）
     *
     * @param groupId 群ID
     * @param offset 偏移量
     * @param pageSize 每页数量
     * @return 分页后的群成员列表
     */
    default List<ImGroupUserDO> selectPageByGroupId(Long groupId, int offset, int pageSize) {
        return selectList(new LambdaQueryWrapperX<ImGroupUserDO>()
                .eq(ImGroupUserDO::getGroupId, groupId)
                .orderByAsc(ImGroupUserDO::getJoinTime)
                .last("LIMIT " + offset + ", " + pageSize));
    }

    /**
     * 统计群成员数量（未删除的）
     *
     * @param groupId 群ID
     * @return 成员数量
     */
    default long countMembersByGroupId(Long groupId) {
        return selectCount(new LambdaQueryWrapperX<ImGroupUserDO>()
                .eq(ImGroupUserDO::getGroupId, groupId));
    }

    /**
     * 根据群ID和用户ID列表查询群成员
     *
     * @param groupId 群ID
     * @param userIds 用户ID列表
     * @return 群成员列表
     */
    default List<ImGroupUserDO> selectListByGroupIdAndUserIds(Long groupId, List<Long> userIds) {
        if (groupId == null || userIds == null || userIds.isEmpty()) {
            return Collections.emptyList();
        }
        return selectList(new LambdaQueryWrapperX<ImGroupUserDO>()
                .eq(ImGroupUserDO::getGroupId, groupId)
                .in(ImGroupUserDO::getUserId, userIds));
    }

    /**
     * 根据用户ID查询群成员列表
     *
     * @param userId 用户ID
     * @return 群成员列表
     */
    default List<ImGroupUserDO> selectListByUserId(Long userId) {
        return selectList(ImGroupUserDO::getUserId, userId);
    }

    /**
     * 根据群ID和用户ID查询群成员
     *
     * @param groupId 群ID
     * @param userId 用户ID
     * @return 群成员
     */
    default ImGroupUserDO selectByGroupIdAndUserId(Long groupId, Long userId) {
        return selectOne(new LambdaQueryWrapperX<ImGroupUserDO>()
                .eq(ImGroupUserDO::getGroupId, groupId)
                .eq(ImGroupUserDO::getUserId, userId));
    }

    /**
     * 根据群ID和角色查询群成员列表
     *
     * @param groupId 群ID
     * @param role 角色
     * @return 群成员列表
     */
    default List<ImGroupUserDO> selectListByGroupIdAndRole(Long groupId, Integer role) {
        return selectList(new LambdaQueryWrapperX<ImGroupUserDO>()
                .eq(ImGroupUserDO::getGroupId, groupId)
                .eq(ImGroupUserDO::getRole, role));
    }

    /**
     * 统计群成员数量
     *
     * @param groupId 群ID
     * @return 成员数量
     */
    default Long selectCountByGroupId(Long groupId) {
        return selectCount(ImGroupUserDO::getGroupId, groupId);
    }

    /**
     * 批量查询多个群的前N个成员（用于组合头像展示）
     * 使用一次SQL查询替代N+1循环查询
     *
     * @param groupIds 群ID列表
     * @param limitPerGroup 每个群最多查询的成员数
     * @return Map<groupId, 该群的前N个成员列表>
     */
    default Map<Long, List<ImGroupUserDO>> selectBatchGroupMembersWithLimit(List<Long> groupIds, int limitPerGroup) {
        if (groupIds == null || groupIds.isEmpty()) {
            return Collections.emptyMap();
        }
        // 一次查询所有群的成员。joinTime 相同（例如批量建群）时再按成员
        // 主键排序，保证组合头像在每次列表/增量同步中的成员顺序完全一致。
        List<ImGroupUserDO> members = selectList(new LambdaQueryWrapperX<ImGroupUserDO>()
                .in(ImGroupUserDO::getGroupId, groupIds)
                .orderByAsc(ImGroupUserDO::getGroupId, ImGroupUserDO::getJoinTime,
                        ImGroupUserDO::getId));

        // 内存分组并按 groupId 限制数量
        Map<Long, List<ImGroupUserDO>> result = new HashMap<>();
        Map<Long, Integer> groupCount = new HashMap<>();
        for (ImGroupUserDO member : members) {
            if (member == null || member.getGroupId() == null) {
                continue;
            }
            Long gid = member.getGroupId();
            int count = groupCount.getOrDefault(gid, 0);
            if (count >= limitPerGroup) {
                continue;
            }
            result.computeIfAbsent(gid, k -> new ArrayList<>()).add(member);
            groupCount.put(gid, count + 1);
        }
        return result;
    }

}
