package com.shengyu.module.system.service.im;

import cn.hutool.json.JSONUtil;
import com.shengyu.module.system.dal.dataobject.im.ImNotificationDO;
import com.shengyu.module.system.dal.mysql.im.ImNotificationMapper;
import com.shengyu.module.system.enums.im.ImNotificationStatusEnum;
import com.shengyu.module.system.enums.im.ImNotificationTypeEnum;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.annotation.Resource;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import static com.shengyu.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.shengyu.module.system.enums.ErrorCodeConstants.*;

/**
 * IM 通知 Service 实现类
 *
 * @author 圣钰科技
 */
@Service
@Slf4j
public class ImNotifyServiceImpl implements ImNotifyService {

    @Resource
    private ImNotificationMapper notificationMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long sendSystemNotify(Long userId, String title, String content) {
        log.info("[ImNotifyService] 发送系统通知, userId: {}, title: {}", userId, title);

        ImNotificationDO notification = ImNotificationDO.builder()
                .userId(userId)
                .notifyType(ImNotificationTypeEnum.SYSTEM_ANNOUNCEMENT.getType())
                .title(title)
                .content(content)
                .isRead(false)
                .isImportant(false)
                .status(ImNotificationStatusEnum.NORMAL.getStatus())
                .build();

        notificationMapper.insert(notification);

        log.info("[ImNotifyService] 系统通知发送成功, notifyId: {}", notification.getId());
        return notification.getId();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void broadcastAnnouncement(List<Long> userIds, String title, String content, Boolean isImportant) {
        log.info("[ImNotifyService] 广播系统公告, userCount: {}, title: {}, isImportant: {}", 
                userIds.size(), title, isImportant);

        for (Long userId : userIds) {
            ImNotificationDO notification = ImNotificationDO.builder()
                    .userId(userId)
                    .notifyType(ImNotificationTypeEnum.SYSTEM_ANNOUNCEMENT.getType())
                    .title(title)
                    .content(content)
                    .isRead(false)
                    .isImportant(isImportant != null ? isImportant : false)
                    .status(ImNotificationStatusEnum.NORMAL.getStatus())
                    .build();

            notificationMapper.insert(notification);
        }

        log.info("[ImNotifyService] 系统公告广播完成, 发送数量: {}", userIds.size());
    }

    @Override
    public List<Long> getUserNotifications(Long userId) {
        log.info("[ImNotifyService] 查询用户通知列表, userId: {}", userId);

        List<ImNotificationDO> notifications = notificationMapper.selectListByUserId(userId);

        return notifications.stream()
                .map(ImNotificationDO::getId)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void markNotifyAsRead(Long userId, Long notifyId) {
        log.info("[ImNotifyService] 标记通知为已读, userId: {}, notifyId: {}", userId, notifyId);

        // 查询通知
        ImNotificationDO notification = notificationMapper.selectById(notifyId);
        if (notification == null) {
            throw exception(NOTIFICATION_NOT_EXISTS);
        }

        // 检查权限
        if (!notification.getUserId().equals(userId)) {
            throw exception(NOTIFICATION_PERMISSION_DENIED);
        }

        // 更新已读状态
        notification.setIsRead(true);
        notification.setReadTime(LocalDateTime.now());
        notificationMapper.updateById(notification);

        log.info("[ImNotifyService] 通知已标记为已读, notifyId: {}", notifyId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteNotify(Long userId, Long notifyId) {
        log.info("[ImNotifyService] 删除通知, userId: {}, notifyId: {}", userId, notifyId);

        // 查询通知
        ImNotificationDO notification = notificationMapper.selectById(notifyId);
        if (notification == null) {
            throw exception(NOTIFICATION_NOT_EXISTS);
        }

        // 检查权限
        if (!notification.getUserId().equals(userId)) {
            throw exception(NOTIFICATION_PERMISSION_DENIED);
        }

        // 删除通知
        notificationMapper.deleteById(notifyId);

        log.info("[ImNotifyService] 通知删除成功, notifyId: {}", notifyId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long sendWorkflowNotify(Long userId, String title, String content, Long workflowId, Long taskId) {
        log.info("[ImNotifyService] 发送流程审批通知, userId: {}, title: {}, workflowId: {}, taskId: {}", 
                userId, title, workflowId, taskId);

        // 构建扩展信息
        Map<String, Object> extraMap = new HashMap<>();
        extraMap.put("workflowId", workflowId);
        extraMap.put("taskId", taskId);
        extraMap.put("type", "workflow");
        String extra = JSONUtil.toJsonStr(extraMap);

        ImNotificationDO notification = ImNotificationDO.builder()
                .userId(userId)
                .notifyType(ImNotificationTypeEnum.WORKFLOW_APPROVAL.getType())
                .title(title)
                .content(content)
                .extra(extra)
                .isRead(false)
                .isImportant(true) // 流程审批通知默认为重要
                .status(ImNotificationStatusEnum.NORMAL.getStatus())
                .build();

        notificationMapper.insert(notification);

        log.info("[ImNotifyService] 流程审批通知发送成功, notifyId: {}", notification.getId());
        return notification.getId();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long sendTodoReminder(Long userId, String title, String content, Long todoId) {
        log.info("[ImNotifyService] 发送待办提醒, userId: {}, title: {}, todoId: {}", 
                userId, title, todoId);

        // 构建扩展信息
        Map<String, Object> extraMap = new HashMap<>();
        extraMap.put("todoId", todoId);
        extraMap.put("type", "todo");
        String extra = JSONUtil.toJsonStr(extraMap);

        ImNotificationDO notification = ImNotificationDO.builder()
                .userId(userId)
                .notifyType(ImNotificationTypeEnum.TODO_REMINDER.getType())
                .title(title)
                .content(content)
                .extra(extra)
                .isRead(false)
                .isImportant(false)
                .status(ImNotificationStatusEnum.NORMAL.getStatus())
                .build();

        notificationMapper.insert(notification);

        log.info("[ImNotifyService] 待办提醒发送成功, notifyId: {}", notification.getId());
        return notification.getId();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long sendCustomNotify(Long userId, String title, String content, String icon, String extra) {
        log.info("[ImNotifyService] 发送自定义通知, userId: {}, title: {}", userId, title);

        ImNotificationDO notification = ImNotificationDO.builder()
                .userId(userId)
                .notifyType(ImNotificationTypeEnum.CUSTOM.getType())
                .title(title)
                .content(content)
                .icon(icon)
                .extra(extra)
                .isRead(false)
                .isImportant(false)
                .status(ImNotificationStatusEnum.NORMAL.getStatus())
                .build();

        notificationMapper.insert(notification);

        log.info("[ImNotifyService] 自定义通知发送成功, notifyId: {}", notification.getId());
        return notification.getId();
    }

}
