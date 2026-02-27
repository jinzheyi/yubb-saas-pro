package com.shengyu.module.system.service.im;

import java.util.List;

/**
 * IM 通知 Service 接口
 *
 * @author 圣钰科技
 */
public interface ImNotifyService {

    /**
     * 发送系统通知
     *
     * @param userId 接收用户ID
     * @param title 通知标题
     * @param content 通知内容
     * @return 通知ID
     */
    Long sendSystemNotify(Long userId, String title, String content);

    /**
     * 广播系统公告
     *
     * @param userIds 接收用户ID列表
     * @param title 公告标题
     * @param content 公告内容
     * @param isImportant 是否重要
     */
    void broadcastAnnouncement(List<Long> userIds, String title, String content, Boolean isImportant);

    /**
     * 获取用户通知列表
     *
     * @param userId 用户ID
     * @return 通知列表
     */
    List<Long> getUserNotifications(Long userId);

    /**
     * 标记通知为已读
     *
     * @param userId 用户ID
     * @param notifyId 通知ID
     */
    void markNotifyAsRead(Long userId, Long notifyId);

    /**
     * 删除通知
     *
     * @param userId 用户ID
     * @param notifyId 通知ID
     */
    void deleteNotify(Long userId, Long notifyId);

    /**
     * 发送流程审批通知
     *
     * @param userId 接收用户ID
     * @param title 通知标题
     * @param content 通知内容
     * @param workflowId 流程ID
     * @param taskId 任务ID
     * @return 通知ID
     */
    Long sendWorkflowNotify(Long userId, String title, String content, Long workflowId, Long taskId);

    /**
     * 发送待办提醒
     *
     * @param userId 接收用户ID
     * @param title 提醒标题
     * @param content 提醒内容
     * @param todoId 待办ID
     * @return 通知ID
     */
    Long sendTodoReminder(Long userId, String title, String content, Long todoId);

    /**
     * 发送自定义通知
     *
     * @param userId 接收用户ID
     * @param title 通知标题
     * @param content 通知内容
     * @param icon 通知图标
     * @param extra 扩展信息(JSON格式)
     * @return 通知ID
     */
    Long sendCustomNotify(Long userId, String title, String content, String icon, String extra);

}
