package com.shengyu.module.system.dal.mysql.im;

import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.module.system.dal.dataobject.im.ImGroupUserDO;
import org.apache.ibatis.annotations.Delete;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;

import java.util.Collections;
import java.time.LocalDateTime;
import java.util.List;

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
     * 根据群ID查询群成员列表
     *
     * @param groupId 群ID
     * @return 群成员列表
     */
    default List<ImGroupUserDO> selectListByGroupId(Long groupId) {
        return selectList(ImGroupUserDO::getGroupId, groupId);
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

}
