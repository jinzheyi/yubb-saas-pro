-- IM 消息表
CREATE TABLE `im_message` (
  `id` bigint NOT NULL COMMENT '消息ID（雪花算法生成）',
  `message_type` int NOT NULL COMMENT '消息类型（100-文本 101-图片 102-语音 103-视频 104-文件 105-位置）',
  `sender_id` bigint NOT NULL COMMENT '发送者ID',
  `sender_nickname` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '发送者昵称',
  `receiver_id` bigint NULL DEFAULT NULL COMMENT '接收者ID（单聊时使用）',
  `receiver_nickname` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '接收者昵称',
  `group_id` bigint NULL DEFAULT NULL COMMENT '群组ID（群聊时使用）',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户ID',
  `content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL COMMENT '消息内容（JSON格式）',
  `body` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL COMMENT '消息体（Protobuf二进制，Base64编码）',
  `sequence` bigint NOT NULL DEFAULT 0 COMMENT '序列号（用于消息去重和排序）',
  `status` tinyint NOT NULL DEFAULT 0 COMMENT '消息状态（0-未读 1-已读 2-已撤回）',
  `extra` varchar(1024) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '扩展字段（JSON格式）',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_sender_receiver`(`sender_id`, `receiver_id`) USING BTREE COMMENT '发送者接收者索引',
  INDEX `idx_receiver_status`(`receiver_id`, `status`) USING BTREE COMMENT '接收者状态索引（查询未读消息）',
  INDEX `idx_group_id`(`group_id`) USING BTREE COMMENT '群组索引',
  INDEX `idx_tenant_id`(`tenant_id`) USING BTREE COMMENT '租户索引',
  INDEX `idx_create_time`(`create_time`) USING BTREE COMMENT '创建时间索引'
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'IM消息表' ROW_FORMAT = DYNAMIC;

-- IM 会话表
CREATE TABLE `im_conversation` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `target_id` bigint NOT NULL COMMENT '目标ID（单聊为对方用户ID，群聊为群组ID）',
  `conversation_type` tinyint NOT NULL COMMENT '会话类型（1-单聊 2-群聊）',
  `last_message_id` bigint NULL DEFAULT NULL COMMENT '最后一条消息ID',
  `last_message_content` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '最后一条消息内容',
  `last_message_time` datetime NULL DEFAULT NULL COMMENT '最后一条消息时间',
  `unread_count` int NOT NULL DEFAULT 0 COMMENT '未读消息数',
  `is_top` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否置顶',
  `is_mute` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否免打扰',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户ID',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_user_target`(`user_id`, `target_id`, `conversation_type`) USING BTREE COMMENT '用户目标唯一索引',
  INDEX `idx_user_id`(`user_id`) USING BTREE COMMENT '用户索引',
  INDEX `idx_tenant_id`(`tenant_id`) USING BTREE COMMENT '租户索引'
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'IM会话表' ROW_FORMAT = DYNAMIC;

-- IM 群组表
CREATE TABLE `im_group` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `group_name` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '群组名称',
  `group_avatar` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '群组头像',
  `group_notice` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '群公告',
  `owner_id` bigint NOT NULL COMMENT '群主ID',
  `member_count` int NOT NULL DEFAULT 0 COMMENT '成员数量',
  `max_member_count` int NOT NULL DEFAULT 500 COMMENT '最大成员数量',
  `is_mute_all` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否全员禁言',
  `join_type` tinyint NOT NULL DEFAULT 1 COMMENT '加群方式（1-自由加入 2-需要验证 3-禁止加入）',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户ID',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_owner_id`(`owner_id`) USING BTREE COMMENT '群主索引',
  INDEX `idx_tenant_id`(`tenant_id`) USING BTREE COMMENT '租户索引'
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'IM群组表' ROW_FORMAT = DYNAMIC;

-- IM 群成员表
CREATE TABLE `im_group_member` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `group_id` bigint NOT NULL COMMENT '群组ID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `nickname` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '群昵称',
  `role_type` tinyint NOT NULL DEFAULT 1 COMMENT '角色类型（1-普通成员 2-管理员 3-群主）',
  `is_mute` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否禁言',
  `join_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '加入时间',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户ID',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_group_user`(`group_id`, `user_id`) USING BTREE COMMENT '群组用户唯一索引',
  INDEX `idx_user_id`(`user_id`) USING BTREE COMMENT '用户索引',
  INDEX `idx_tenant_id`(`tenant_id`) USING BTREE COMMENT '租户索引'
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'IM群成员表' ROW_FORMAT = DYNAMIC;

-- IM 好友表
CREATE TABLE `im_friend` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `friend_id` bigint NOT NULL COMMENT '好友ID',
  `remark` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '好友备注',
  `group_name` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '我的好友' COMMENT '分组名称',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户ID',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_user_friend`(`user_id`, `friend_id`) USING BTREE COMMENT '用户好友唯一索引',
  INDEX `idx_user_id`(`user_id`) USING BTREE COMMENT '用户索引',
  INDEX `idx_tenant_id`(`tenant_id`) USING BTREE COMMENT '租户索引'
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'IM好友表' ROW_FORMAT = DYNAMIC;

-- IM 好友申请表
CREATE TABLE `im_friend_apply` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `user_id` bigint NOT NULL COMMENT '申请人ID',
  `friend_id` bigint NOT NULL COMMENT '被申请人ID',
  `apply_message` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '申请消息',
  `status` tinyint NOT NULL DEFAULT 0 COMMENT '状态（0-待处理 1-已同意 2-已拒绝）',
  `handle_message` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '处理消息',
  `handle_time` datetime NULL DEFAULT NULL COMMENT '处理时间',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户ID',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_user_id`(`user_id`) USING BTREE COMMENT '申请人索引',
  INDEX `idx_friend_id`(`friend_id`) USING BTREE COMMENT '被申请人索引',
  INDEX `idx_tenant_id`(`tenant_id`) USING BTREE COMMENT '租户索引'
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'IM好友申请表' ROW_FORMAT = DYNAMIC;
