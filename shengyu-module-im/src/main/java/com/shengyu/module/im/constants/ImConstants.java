package com.shengyu.module.im.constants;

/**
 * IM模块常量类
 *
 * @author 圣钰科技
 */
public interface ImConstants {

    /**
     * 默认客户端ID
     */
    String DEFAULT_CLIENT_ID = "im-client";

    /**
     * Redis键前缀
     */
    String REDIS_KEY_PREFIX = "im:";

    /**
     * 连接映射键前缀
     */
    String CONNECTION_KEY_PREFIX = REDIS_KEY_PREFIX + "connection:";

    /**
     * 通道映射键前缀
     */
    String CHANNEL_KEY_PREFIX = REDIS_KEY_PREFIX + "channel:";

    /**
     * 用户租户映射键前缀
     */
    String USER_TENANT_KEY_PREFIX = REDIS_KEY_PREFIX + "user_tenant:";

    /**
     * 租户用户映射键前缀
     */
    String TENANT_USER_KEY_PREFIX = REDIS_KEY_PREFIX + "tenant_user:";

    /**
     * Token前缀
     */
    String TOKEN_PREFIX = REDIS_KEY_PREFIX + "token:";

    /**
     * 默认最大帧长度（100MB）
     */
    int DEFAULT_MAX_FRAME_LENGTH = 100 * 1024 * 1024;

    /**
     * 默认Token过期时间（3600秒）
     */
    long DEFAULT_TOKEN_EXPIRE = 3600;

    /**
     * 默认消息最大重试次数
     */
    int DEFAULT_MAX_RETRY_COUNT = 3;

    /**
     * 默认消息重试间隔（毫秒）
     */
    long DEFAULT_RETRY_INTERVAL = 1000;

    /**
     * 默认心跳间隔（秒）
     */
    int DEFAULT_HEARTBEAT_INTERVAL = 60;

    /**
     * 默认加密启用状态
     */
    boolean DEFAULT_ENCRYPTION_ENABLED = false;

    /**
     * Bearer前缀
     */
    String BEARER_PREFIX = "Bearer ";

    /**
     * 消息状态：未读
     */
    int MESSAGE_STATUS_UNREAD = 0;

    /**
     * 消息状态：已读
     */
    int MESSAGE_STATUS_READ = 1;

    /**
     * 消息状态：已删除
     */
    int MESSAGE_STATUS_DELETED = 2;

    /**
     * 消息状态：已撤回
     */
    int MESSAGE_STATUS_RECALLED = 3;

    /**
     * 群成员角色：普通成员
     */
    int GROUP_MEMBER_ROLE_NORMAL = 0;

    /**
     * 群成员角色：管理员
     */
    int GROUP_MEMBER_ROLE_ADMIN = 1;

    /**
     * 群成员角色：群主
     */
    int GROUP_MEMBER_ROLE_OWNER = 2;

    /**
     * 群成员状态：正常
     */
    int GROUP_MEMBER_STATUS_NORMAL = 0;

    /**
     * 群成员状态：已退出
     */
    int GROUP_MEMBER_STATUS_EXITED = 1;

    /**
     * 群组状态：正常
     */
    int GROUP_STATUS_NORMAL = 0;

    /**
     * 群组状态：已解散
     */
    int GROUP_STATUS_DISSOLVED = 1;

    /**
     * 用户在线状态：在线
     */
    int USER_ONLINE_STATUS_ONLINE = 1;

    /**
     * 用户在线状态：离线
     */
    int USER_ONLINE_STATUS_OFFLINE = 0;

    /**
     * 消息撤回超时时间（2分钟）
     */
    long MESSAGE_RECALL_TIMEOUT = 2 * 60 * 1000;

}