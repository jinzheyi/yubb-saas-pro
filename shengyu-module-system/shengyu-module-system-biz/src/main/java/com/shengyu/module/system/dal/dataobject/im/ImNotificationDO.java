package com.shengyu.module.system.dal.dataobject.im;

import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.framework.tenant.core.db.TenantBaseDO;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * IM 通知 DO
 * 
 * 对应表: im_notification
 * 功能: 存储系统通知、流程通知、待办提醒等
 *
 * @author 圣钰科技
 */
@TableName(value = "im_notification", autoResultMap = true)
@KeySequence("im_notification_seq")
@Data
@EqualsAndHashCode(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ImNotificationDO extends TenantBaseDO {

    /**
     * 通知ID
     */
    @TableId
    private Long id;

    /**
     * 接收用户ID
     */
    private Long userId;

    /**
     * 通知类型
     * 
     * 枚举: {@link com.shengyu.module.system.enums.im.ImNotificationTypeEnum}
     * 1-系统公告, 2-流程审批, 3-待办提醒, 4-自定义通知
     */
    private Integer notifyType;

    /**
     * 通知标题
     */
    private String title;

    /**
     * 通知内容
     */
    private String content;

    /**
     * 通知图标URL
     */
    private String icon;

    /**
     * 扩展信息(JSON格式,存储操作按钮、跳转配置、业务数据等)
     */
    private String extra;

    /**
     * 是否已读
     */
    private Boolean isRead;

    /**
     * 已读时间
     */
    private LocalDateTime readTime;

    /**
     * 是否重要(重要通知需强制阅读)
     */
    private Boolean isImportant;

    /**
     * 过期时间
     */
    private LocalDateTime expireTime;

    /**
     * 通知状态
     * 
     * 枚举: {@link com.shengyu.module.system.enums.im.ImNotificationStatusEnum}
     * 1-正常, 2-已过期, 3-已撤回
     */
    private Integer status;

}
