package com.shengyu.module.system.service.im;

import com.shengyu.module.system.controller.app.im.vo.group.*;

import java.util.List;

/**
 * IM 群组 Service 接口
 *
 * @author 圣钰科技
 */
public interface ImGroupService {

    /**
     * 创建群组
     *
     * @param userId 创建者ID
     * @param createReqVO 创建请求
     * @return 群组ID
     */
    Long createGroup(Long userId, AppImGroupCreateReqVO createReqVO);

    /**
     * 更新群组信息
     *
     * @param userId 操作者ID
     * @param updateReqVO 更新请求
     */
    void updateGroup(Long userId, AppImGroupUpdateReqVO updateReqVO);

    /**
     * 解散群组
     *
     * @param userId 操作者ID(必须是群主)
     * @param groupId 群组ID
     */
    void dissolveGroup(Long userId, Long groupId);

    /**
     * 退出群组
     *
     * @param userId 用户ID
     * @param groupId 群组ID
     */
    void quitGroup(Long userId, Long groupId);

    /**
     * 获取群组信息
     *
     * @param userId 用户ID
     * @param groupId 群组ID
     * @return 群组信息
     */
    AppImGroupRespVO getGroup(Long userId, Long groupId);

    /**
     * 获取用户的群组列表
     *
     * @param userId 用户ID
     * @return 群组列表
     */
    List<AppImGroupRespVO> getGroupList(Long userId);

    /**
     * 添加群成员
     *
     * @param userId 操作者ID
     * @param addReqVO 添加请求
     */
    void addGroupMembers(Long userId, AppImGroupMemberAddReqVO addReqVO);

    /**
     * 移除群成员
     *
     * @param userId 操作者ID
     * @param groupId 群组ID
     * @param memberUserId 成员用户ID
     */
    void removeGroupMember(Long userId, Long groupId, Long memberUserId);

    /**
     * 获取群成员列表
     *
     * @param userId 用户ID
     * @param groupId 群组ID
     * @return 群成员列表
     */
    List<AppImGroupMemberRespVO> getGroupMembers(Long userId, Long groupId);

    /**
     * 设置群成员角色
     *
     * @param userId 操作者ID
     * @param groupId 群组ID
     * @param memberUserId 成员用户ID
     * @param role 角色(0-普通成员 1-管理员 2-群主)
     */
    void setGroupMemberRole(Long userId, Long groupId, Long memberUserId, Integer role);

    /**
     * 设置群成员禁言
     *
     * @param userId 操作者ID
     * @param groupId 群组ID
     * @param memberUserId 成员用户ID
     * @param muted 是否禁言
     */
    void setGroupMemberMuted(Long userId, Long groupId, Long memberUserId, Boolean muted);

    /**
     * 转让群主
     *
     * @param userId 当前群主ID
     * @param groupId 群组ID
     * @param newOwnerId 新群主ID
     */
    void transferGroupOwner(Long userId, Long groupId, Long newOwnerId);

    /**
     * 获取群成员ID列表
     *
     * @param groupId 群组ID
     * @return 成员ID列表
     */
    List<Long> getGroupMemberIds(Long groupId);

}
