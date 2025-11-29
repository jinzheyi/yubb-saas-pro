package com.shengyu.module.im.service;

import com.shengyu.module.im.dal.dataobject.ImUserDO;

/**
 * IM用户服务
 *
 * @author 圣钰科技
 */
public interface ImUserService {

    /**
     * 获取IM用户信息
     *
     * @param userId 系统用户ID
     * @return IM用户信息
     */
    ImUserDO getImUserByUserId(Long userId);

    /**
     * 创建或更新IM用户
     *
     * @param userId   系统用户ID
     * @param nickname 用户昵称
     * @param avatar   用户头像
     * @return IM用户ID
     */
    Long createOrUpdateImUser(Long userId, String nickname, String avatar);

    /**
     * 更新用户在线状态
     *
     * @param userId       系统用户ID
     * @param onlineStatus 在线状态：0-离线，1-在线，2-忙碌，3-离开
     * @return 是否更新成功
     */
    boolean updateOnlineStatus(Long userId, Integer onlineStatus);

    /**
     * 获取用户在线状态
     *
     * @param userId 系统用户ID
     * @return 在线状态：0-离线，1-在线，2-忙碌，3-离开
     */
    Integer getOnlineStatus(Long userId);

    /**
     * 禁用用户
     *
     * @param userId 系统用户ID
     * @return 是否禁用成功
     */
    boolean disableUser(Long userId);

    /**
     * 启用用户
     *
     * @param userId 系统用户ID
     * @return 是否启用成功
     */
    boolean enableUser(Long userId);
}
