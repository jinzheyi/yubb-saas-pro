package com.shengyu.module.im.service;

import com.shengyu.module.im.dal.dataobject.ImGroupDO;
import com.shengyu.module.im.dal.dataobject.ImGroupMemberDO;

import java.util.List;

/**
 * IM群组服务
 *
 * @author 圣钰科技
 */
public interface ImGroupService {

    /**
     * 创建群组
     *
     * @param name        群组名称
     * @param avatar      群组头像
     * @param description 群组描述
     * @param ownerId     群主ID
     * @return 群组ID
     */
    Long createGroup(String name, String avatar, String description, Long ownerId);

    /**
     * 加入群组
     *
     * @param groupId 群组ID
     * @param userId  用户ID
     * @return 是否加入成功
     */
    boolean joinGroup(Long groupId, Long userId);

    /**
     * 退出群组
     *
     * @param groupId 群组ID
     * @param userId  用户ID
     * @return 是否退出成功
     */
    boolean exitGroup(Long groupId, Long userId);

    /**
     * 获取群组信息
     *
     * @param groupId 群组ID
     * @return 群组信息
     */
    ImGroupDO getGroupInfo(Long groupId);

    /**
     * 获取群组成员列表
     *
     * @param groupId 群组ID
     * @return 群组成员列表
     */
    List<ImGroupMemberDO> getGroupMembers(Long groupId);

    /**
     * 获取用户加入的群组列表
     *
     * @param userId 用户ID
     * @return 群组列表
     */
    List<ImGroupDO> getUserGroups(Long userId);

    /**
     * 获取群组成员ID列表
     *
     * @param groupId 群组ID
     * @return 群组成员ID列表
     */
    List<Long> getGroupMemberIds(Long groupId);

    /**
     * 更新群组信息
     *
     * @param groupId     群组ID
     * @param name        群组名称
     * @param avatar      群组头像
     * @param description 群组描述
     * @param ownerId     群主ID
     * @return 是否更新成功
     */
    boolean updateGroup(Long groupId, String name, String avatar, String description, Long ownerId);

    /**
     * 解散群组
     *
     * @param groupId 群组ID
     * @param ownerId 群主ID
     * @return 是否解散成功
     */
    boolean dissolveGroup(Long groupId, Long ownerId);

    /**
     * 移除群组成员
     *
     * @param groupId  群组ID
     * @param userId   被移除用户ID
     * @param operator 操作人ID
     * @return 是否移除成功
     */
    boolean removeMember(Long groupId, Long userId, Long operator);

    /**
     * 设置群成员角色
     *
     * @param groupId  群组ID
     * @param userId   用户ID
     * @param role     角色：0-普通成员，1-管理员，2-群主
     * @param operator 操作人ID
     * @return 是否设置成功
     */
    boolean setMemberRole(Long groupId, Long userId, Integer role, Long operator);
}
