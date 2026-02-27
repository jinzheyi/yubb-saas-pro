package com.shengyu.module.system.service.im;

import com.shengyu.framework.websocket.core.protocol.BadgeUpdateMessage;
import com.shengyu.framework.websocket.core.protocol.ConversationBadge;
import com.shengyu.framework.websocket.core.protocol.MenuBadge;

import java.util.List;

/**
 * IM 角标 Service 接口
 *
 * @author 圣钰科技
 */
public interface ImBadgeService {

    /**
     * 获取用户的角标数据
     *
     * @param userId 用户ID
     * @return 角标数据
     */
    BadgeUpdateMessage getBadgeData(Long userId);

    /**
     * 推送角标更新到用户的所有设备
     *
     * @param userId 用户ID
     */
    void pushBadgeUpdate(Long userId);

    /**
     * 获取菜单角标列表
     *
     * @param userId 用户ID
     * @return 菜单角标列表
     */
    List<MenuBadge> getMenuBadges(Long userId);

}
