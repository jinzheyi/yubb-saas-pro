package com.shengyu.module.system.service.im;

import com.shengyu.framework.websocket.core.protocol.BadgeUpdateMessage;
import com.shengyu.framework.websocket.core.protocol.ConversationBadge;
import com.shengyu.framework.websocket.core.protocol.MenuBadge;
import com.shengyu.framework.websocket.core.protocol.MessageType;
import com.shengyu.framework.websocket.core.sender.NettyMessageSender;
import com.shengyu.module.system.dal.mysql.im.ImConversationMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.util.ArrayList;
import java.util.List;

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
    private ImConversationMapper conversationMapper;

    @Resource
    private ImConversationService conversationService;

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

        // TODO: 集成待办事项服务
        // 说明: 需要等待工作流服务提供待办事项数量查询接口
        // 预期接口: workflowService.getTodoCount(userId) 或 flowTaskService.getPendingTaskCount(userId)
        // 
        // 示例实现:
        // int todoCount = workflowService.getTodoCount(userId);
        // if (todoCount > 0) {
        //     badges.add(MenuBadge.newBuilder()
        //             .setMenuId("todo")
        //             .setBadgeCount(todoCount)
        //             .build());
        // }

        // 可以在这里添加其他菜单角标类型
        // 例如: 审批待办、通知待读等
        // 
        // 示例: 通知未读数
        // int notifyUnreadCount = imNotifyService.getUnreadCount(userId);
        // if (notifyUnreadCount > 0) {
        //     badges.add(MenuBadge.newBuilder()
        //             .setMenuId("notification")
        //             .setBadgeCount(notifyUnreadCount)
        //             .build());
        // }

        return badges;
    }

}
