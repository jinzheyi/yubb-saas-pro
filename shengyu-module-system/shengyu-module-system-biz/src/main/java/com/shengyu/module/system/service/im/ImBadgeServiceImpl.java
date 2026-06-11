package com.shengyu.module.system.service.im;

import com.shengyu.framework.websocket.core.protocol.BadgeUpdateMessage;
import com.shengyu.framework.websocket.core.protocol.ConversationBadge;
import com.shengyu.framework.websocket.core.protocol.MenuBadge;
import com.shengyu.framework.websocket.core.protocol.MessageType;
import com.shengyu.framework.websocket.core.sender.NettyMessageSender;
import com.shengyu.module.system.controller.app.im.vo.badge.AppImBadgeRespVO;
import com.shengyu.module.system.controller.app.im.vo.badge.AppImConversationBadgeRespVO;
import com.shengyu.module.system.controller.app.im.vo.badge.AppImMenuBadgeRespVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

/**
 * IM 角标 Service 实现类
 *
 * @author 圣钰科技
 */
@Service
@Slf4j
public class ImBadgeServiceImpl implements ImBadgeService {

    @Resource
    private NettyMessageSender messageSender;

    @Resource
    private ImConversationService conversationService;

    @Resource
    private ImGroupService imGroupService;

    @Override
    public BadgeUpdateMessage getBadgeData(Long userId) {
        log.debug("[ImBadgeService] 获取用户角标数据, userId: {}", userId);

        // 1. 获取总未读数
        Integer totalUnread = conversationService.getTotalUnreadCount(userId);
        if (totalUnread == null) {
            totalUnread = 0;
        }

        // 2. 获取会话角标列表
        List<ConversationBadge> conversationBadges = conversationService.getConversationBadges(userId);

        // 3. 获取菜单角标列表
        List<MenuBadge> menuBadges = getMenuBadges(userId);

        // 4. 构建角标更新消息
        BadgeUpdateMessage badgeUpdate = BadgeUpdateMessage.newBuilder()
                .setUnreadCount(totalUnread)
                .addAllConversationBadges(conversationBadges)
                .addAllMenuBadges(menuBadges)
                .build();

        log.debug("[ImBadgeService] 角标数据: totalUnread={}, conversationCount={}, menuCount={}", 
                totalUnread, conversationBadges.size(), menuBadges.size());

        return badgeUpdate;
    }

    @Override
    public void pushBadgeUpdate(Long userId) {
        log.info("[ImBadgeService] 推送角标更新, userId: {}", userId);

        try {
            // 1. 获取最新的角标数据
            BadgeUpdateMessage badgeUpdate = getBadgeData(userId);

            // 2. 推送到用户的所有在线设备
            messageSender.sendToUser(userId, MessageType.BADGE_UPDATE, badgeUpdate);

            log.info("[ImBadgeService] 角标更新推送成功, userId: {}, totalUnread: {}", 
                    userId, badgeUpdate.getUnreadCount());
        } catch (Exception e) {
            log.error("[ImBadgeService] 推送角标更新失败, userId: {}", userId, e);
        }
    }

    @Override
    public List<MenuBadge> getMenuBadges(Long userId) {
        List<MenuBadge> badges = new ArrayList<>();

        Long contactsPendingCount = imGroupService.getManagedPendingJoinRequestCount(userId);
        if (contactsPendingCount != null && contactsPendingCount > 0) {
            badges.add(MenuBadge.newBuilder()
                    .setMenuId("contactsGroupJoinRequest")
                    .setBadgeCount(Math.toIntExact(contactsPendingCount))
                    .build());
        }

        // 工作台等业务角标继续预留扩展位，当前不返回伪数据。
        return badges;
    }

    @Override
    public AppImBadgeRespVO getBadgeDataVO(Long userId) {
        BadgeUpdateMessage badgeUpdateMessage = getBadgeData(userId);

        AppImBadgeRespVO respVO = new AppImBadgeRespVO();
        respVO.setUnreadCount(badgeUpdateMessage.getUnreadCount());

        // 会话角标转换
        List<AppImConversationBadgeRespVO> conversationBadges = badgeUpdateMessage.getConversationBadgesList().stream()
                .map(item -> {
                    AppImConversationBadgeRespVO badge = new AppImConversationBadgeRespVO();
                    badge.setChatId(item.getConversationId());
                    badge.setUnreadCount(item.getUnreadCount());
                    return badge;
                })
                .collect(Collectors.toList());
        respVO.setConversationBadges(conversationBadges);

        // 菜单角标转换
        List<AppImMenuBadgeRespVO> menuBadges = badgeUpdateMessage.getMenuBadgesList().stream()
                .map(item -> {
                    AppImMenuBadgeRespVO badge = new AppImMenuBadgeRespVO();
                    badge.setMenuId(item.getMenuId());
                    badge.setBadgeCount(item.getBadgeCount());
                    return badge;
                })
                .collect(Collectors.toList());
        respVO.setMenuBadges(menuBadges);

        return respVO;
    }

}
