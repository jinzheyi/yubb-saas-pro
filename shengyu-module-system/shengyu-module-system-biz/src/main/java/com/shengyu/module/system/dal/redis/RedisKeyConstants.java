package com.shengyu.module.system.dal.redis;

import com.shengyu.module.system.dal.dataobject.oauth2.OAuth2AccessTokenDO;

/**
 * System Redis Key 枚举类
 *
 * @author 圣钰科技
 */
public interface RedisKeyConstants {

    /**
     * 指定部门的所有子部门编号数组的缓存
     * <p>
     * KEY 格式：dept_children_ids:{id}
     * VALUE 数据类型：String 子部门编号集合
     */
    String DEPT_CHILDREN_ID_LIST = "dept_children_ids";

    /**
     * 角色的缓存
     * <p>
     * KEY 格式：role:{id}
     * VALUE 数据类型：String 角色信息
     */
    String ROLE = "role";

    /**
     * 用户拥有的角色编号的缓存
     * <p>
     * KEY 格式：user_role_ids:{userId}
     * VALUE 数据类型：String 角色编号集合
     */
    String USER_ROLE_ID_LIST = "user_role_ids";

    /**
     * 拥有指定菜单的角色编号的缓存
     * <p>
     * KEY 格式：user_role_ids:{menuId}
     * VALUE 数据类型：String 角色编号集合
     */
    String MENU_ROLE_ID_LIST = "menu_role_ids";

    /**
     * 拥有权限对应的菜单编号数组的缓存
     * <p>
     * KEY 格式：permission_menu_ids:{permission}
     * VALUE 数据类型：String 菜单编号数组
     */
    String PERMISSION_MENU_ID_LIST = "permission_menu_ids";

    /**
     * OAuth2 客户端的缓存
     * <p>
     * KEY 格式：user:{id}
     * VALUE 数据类型：String 客户端信息
     */
    String OAUTH_CLIENT = "oauth_client";

    /**
     * 访问令牌的缓存
     * <p>
     * KEY 格式：oauth2_access_token:{token}
     * VALUE 数据类型：String 访问令牌信息 {@link OAuth2AccessTokenDO}
     * <p>
     * 由于动态过期时间，使用 RedisTemplate 操作
     */
    String OAUTH2_ACCESS_TOKEN = "oauth2_access_token:%s";

    /**
     * 站内信模版的缓存
     * <p>
     * KEY 格式：notify_template:{code}
     * VALUE 数据格式：String 模版信息
     */
    String NOTIFY_TEMPLATE = "notify_template";

    /**
     * 用户在线状态缓存
     * <p>
     * KEY 格式：online_${userId}
     * VALUE 数据类型：String 用户在线状态
     */
    String ONLINE_STATUS = "online_%s";

    /**
     * IM 用户在线状态聚合缓存
     * <p>
     * KEY 格式：im_presence_user_${userId}
     * VALUE 数据类型：Hash，field=设备类型，value=presence json
     */
    String IM_PRESENCE_USER = "im_presence_user_%s";

    /**
     * 用户离线消息缓存
     * <p>
     * KEY 格式：getmessage_${userId}
     * VALUE 数据类型：List<Map> 离线消息列表
     */
    String OFFLINE_MESSAGE = "getmessage_%s";

    /**
     * 聊天记录缓存
     * <p>
     * KEY 格式：chatlog_${userId}_${chatType}_${targetId}
     * VALUE 数据类型：List<Map> 聊天记录列表
     */
    String CHAT_LOG = "chatlog_%s_%s_%s";

    /**
     * 大群未读状态缓存（Redis Hash）
     * <p>
     * KEY 格式：im:group:unread:{chatId}:{userId}
     * VALUE 数据类型：Hash，field=last_message_id，value=未读状态JSON
     */
    String LARGE_GROUP_UNREAD = "im:group:unread:%s:%s";

    /**
     * 大群未读状态 dirty key 集合（Redis Set）
     * <p>
     * KEY 格式：im:group:unread:dirty
     * VALUE 数据类型：Set，member={chatId}:{userId}
     */
    String LARGE_GROUP_UNREAD_DIRTY = "im:group:unread:dirty";

    /**
     * 会话快照缓存 key（Redis Hash）
     * <p>
     * KEY 格式：im:snapshot:{userId}:{chatId}
     * VALUE 数据类型：Hash，field=lastMessageId/lastMessageSequence/lastMessageType/lastMessageTime/incrementUnread
     */
    String IM_SNAPSHOT = "im:snapshot";

    /**
     * 会话快照 dirty key 集合（Redis Set）
     * <p>
     * KEY 格式：im:snapshot:dirty
     * VALUE 数据类型：Set，member={userId}:{chatId}
     */
    String IM_SNAPSHOT_DIRTY = "im:snapshot:dirty";

}
