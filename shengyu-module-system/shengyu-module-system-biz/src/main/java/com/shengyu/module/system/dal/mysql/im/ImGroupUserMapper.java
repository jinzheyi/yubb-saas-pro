package com.shengyu.module.system.dal.mysql.im;

import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.module.system.dal.dataobject.im.ImGroupUserDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * IM 群成员 Mapper
 *
 * @author 圣钰科技
 */
@Mapper
public interface ImGroupUserMapper extends BaseMapperX<ImGroupUserDO> {

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
