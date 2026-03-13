/*
 IM 即时通讯模块 - 数据库表结构定义
 
 功能说明: IM 即时通讯模块所有表结构定义
 创建日期: 2026-02-11
 版本: v1.0
 
 注意事项: 
 1. 本文件处于设计阶段,尚未执行
 2. 后续表结构变更直接在本文件中修改
 3. 正式执行前需要经过代码审查
*/

SET NAMES utf8mb4;

-- ----------------------------
-- Table structure for im_chat
-- 全局会话表: 存储所有会话信息(单聊/群聊)
-- ----------------------------
DROP TABLE IF EXISTS `im_chat`;
CREATE TABLE `im_chat` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT 'ChatID',
  `chat_type` tinyint NOT NULL COMMENT '会话类型(1-单聊 2-群聊)',
  `single_user1` bigint NULL DEFAULT NULL COMMENT '单聊用户1(较小ID)',
  `single_user2` bigint NULL DEFAULT NULL COMMENT '单聊用户2(较大ID)',
  `group_id` bigint NULL DEFAULT NULL COMMENT '群ID',
  `last_sequence` bigint NOT NULL DEFAULT 0 COMMENT '会话内消息序列号水位（自增）',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '状态(1-正常 2-已解散)',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_single_chat`(`tenant_id` ASC, `chat_type` ASC, `single_user1` ASC, `single_user2` ASC, `deleted` ASC) USING BTREE,
  UNIQUE INDEX `uk_group_chat`(`tenant_id` ASC, `chat_type` ASC, `group_id` ASC, `deleted` ASC) USING BTREE,
  INDEX `idx_tenant`(`tenant_id` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'IM全局会话表' ROW_FORMAT = DYNAMIC;

DROP TABLE IF EXISTS `im_chat_user`;
CREATE TABLE `im_chat_user` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '用户会话ID',
  `chat_id` bigint NOT NULL COMMENT 'ChatID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `unread_count` int NOT NULL DEFAULT 0 COMMENT '未读消息数',
  `last_read_message_id` bigint NULL DEFAULT NULL COMMENT '最后已读消息ID',
  `last_read_sequence` bigint NOT NULL DEFAULT 0 COMMENT '最后已读序列号水位（单调递增）',
  `last_message_id` bigint NULL DEFAULT NULL COMMENT '最后一条消息ID',
  `last_message_sequence` bigint NOT NULL DEFAULT 0 COMMENT '最后一条消息序列号水位（单调递增）',
  `last_message_type` tinyint NULL DEFAULT NULL COMMENT '最后一条消息类型(同 im_chat_message.message_type)',
  `last_message_content` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '最后一条消息预览',
  `last_message_time` datetime NULL DEFAULT NULL COMMENT '最后一条消息时间',
  `is_pinned` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否置顶',
  `no_disturb` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否免打扰',
  `draft` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '草稿内容',
  `deleted_by_user` bit(1) NOT NULL DEFAULT b'0' COMMENT '用户是否删除会话',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_user_chat`(`tenant_id` ASC, `user_id` ASC, `chat_id` ASC, `deleted` ASC) USING BTREE,
  INDEX `idx_user_time`(`tenant_id` ASC, `user_id` ASC, `last_message_time` DESC) USING BTREE,
  INDEX `idx_chat`(`tenant_id` ASC, `chat_id` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'IM用户会话状态表' ROW_FORMAT = DYNAMIC;

DROP TABLE IF EXISTS `im_user_cursor`;
CREATE TABLE `im_user_cursor` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `next_cursor_version` bigint NOT NULL DEFAULT 0 COMMENT '下一个会话同步游标版本号',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_user_cursor`(`tenant_id` ASC, `user_id` ASC, `deleted` ASC) USING BTREE,
  INDEX `idx_tenant`(`tenant_id` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'IM用户会话游标分配器' ROW_FORMAT = DYNAMIC;

DROP TABLE IF EXISTS `im_conversation_user_state`;
CREATE TABLE `im_conversation_user_state` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `chat_id` bigint NOT NULL COMMENT 'ChatID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `cursor_version` bigint NOT NULL DEFAULT 0 COMMENT '会话同步游标版本号（用户维度）',
  `conversation_version` bigint NOT NULL DEFAULT 0 COMMENT '会话版本号（会话级，用于合并快照）',
  `unread_count` int NOT NULL DEFAULT 0 COMMENT '未读消息数',
  `last_read_sequence` bigint NOT NULL DEFAULT 0 COMMENT '最后已读序列号水位（单调递增）',
  `last_read_time` datetime NULL DEFAULT NULL COMMENT '最后已读时间',
  `last_message_id` bigint NULL DEFAULT NULL COMMENT '最后一条消息ID',
  `last_message_sequence` bigint NOT NULL DEFAULT 0 COMMENT '最后一条消息序列号水位（单调递增）',
  `last_message_type` tinyint NULL DEFAULT NULL COMMENT '最后一条消息类型(同 im_chat_message.message_type)',
  `last_message_content` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '最后一条消息预览',
  `last_message_time` datetime NULL DEFAULT NULL COMMENT '最后一条消息时间',
  `is_pinned` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否置顶',
  `no_disturb` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否免打扰',
  `draft` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '草稿内容',
  `deleted_by_user` bit(1) NOT NULL DEFAULT b'0' COMMENT '用户是否删除会话',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_user_chat_state`(`tenant_id` ASC, `user_id` ASC, `chat_id` ASC, `deleted` ASC) USING BTREE,
  INDEX `idx_user_cursor`(`tenant_id` ASC, `user_id` ASC, `cursor_version` ASC) USING BTREE,
  INDEX `idx_chat`(`tenant_id` ASC, `chat_id` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'IM会话-用户态表' ROW_FORMAT = DYNAMIC;

DROP TABLE IF EXISTS `im_chat_message`;
CREATE TABLE `im_chat_message` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '消息ID',
  `chat_id` bigint NOT NULL COMMENT 'ChatID',
  `sequence` bigint NOT NULL DEFAULT 0 COMMENT '会话内序列号（单调递增，用于排序与断线补偿）',
  `sender_id` bigint NOT NULL COMMENT '发送者ID',
  `message_type` tinyint NOT NULL COMMENT '消息类型(1-文本 2-图片 3-语音 4-视频 5-文件 6-位置 7-表情包 8-自定义贴纸 10-系统消息)',
  `content` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '消息内容',
  `extra` longtext NULL COMMENT '扩展信息(JSON格式,存储文件URL、时长、大小等)',
  `send_time` datetime NOT NULL COMMENT '发送时间',
  `rev` bigint NOT NULL DEFAULT 1 COMMENT '消息版本号（最终态：撤回/编辑/删除等变更时 rev+1，用于乱序合并）',
  `status` tinyint NOT NULL DEFAULT 2 COMMENT '消息状态(2-已发送 6-已撤回)',
  `recall_time` datetime NULL DEFAULT NULL COMMENT '撤回时间',
  `recall_by` bigint NULL DEFAULT NULL COMMENT '撤回人ID',
  `quote_message_id` bigint NULL DEFAULT NULL COMMENT '引用消息ID',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_chat_seq`(`tenant_id` ASC, `chat_id` ASC, `sequence` DESC) USING BTREE,
  INDEX `idx_sender_time`(`tenant_id` ASC, `sender_id` ASC, `send_time` DESC) USING BTREE,
  INDEX `idx_tenant`(`tenant_id` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'IM消息表(全局会话单份存储)' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for im_group
-- 群组表: 存储群组基本信息
-- ----------------------------
DROP TABLE IF EXISTS `im_group`;
CREATE TABLE `im_group`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '群ID',
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '群名称',
  `avatar` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '群头像',
  `owner_id` bigint NOT NULL COMMENT '群主ID',
  `group_type` tinyint NOT NULL DEFAULT 1 COMMENT '群类型(1-普通群 2-工作群)',
  `member_count` int NOT NULL DEFAULT 0 COMMENT '成员数量',
  `max_member_count` int NOT NULL DEFAULT 500 COMMENT '最大成员数量',
  `notice` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '群公告',
  `notice_pinned` bit(1) NOT NULL DEFAULT b'0' COMMENT '群公告是否置顶',
  `introduction` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '群简介',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '群状态(1-正常 2-已解散)',
  `allow_member_invite` bit(1) NOT NULL DEFAULT b'1' COMMENT '是否允许成员邀请',
  `need_approval` bit(1) NOT NULL DEFAULT b'0' COMMENT '加群是否需要审批',
  `mute_all` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否全员禁言',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_owner`(`owner_id` ASC) USING BTREE COMMENT '群主索引',
  INDEX `idx_tenant`(`tenant_id` ASC) USING BTREE COMMENT '租户索引'
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'IM群组表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for im_group_member
-- 群成员表: 存储群组成员关系
-- 注意: 唯一索引包含 deleted 字段,支持逻辑删除后重新加入
-- ----------------------------
DROP TABLE IF EXISTS `im_group_member`;
CREATE TABLE `im_group_member`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '成员ID',
  `group_id` bigint NOT NULL COMMENT '群ID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `role` tinyint NOT NULL DEFAULT 3 COMMENT '角色(1-群主 2-管理员 3-普通成员)',
  `nickname` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '群昵称',
  `join_time` datetime NOT NULL COMMENT '加入时间',
  `mute_end_time` datetime NULL DEFAULT NULL COMMENT '禁言结束时间',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `idx_group_user_deleted`(`group_id` ASC, `user_id` ASC, `tenant_id` ASC, `deleted` ASC) USING BTREE COMMENT '群+用户+删除状态唯一索引',
  INDEX `idx_user`(`user_id` ASC) USING BTREE COMMENT '用户索引',
  INDEX `idx_tenant`(`tenant_id` ASC) USING BTREE COMMENT '租户索引'
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'IM群成员表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for im_contact_setting
-- 联系人设置表: 存储用户对联系人的个性化设置(星标、免打扰)
-- 说明: 企业内部IM,联系人直接来源于 system_users 表,本表仅存储个性化设置
-- 注意: 
-- 1. remark_name 字段保留用于未来扩展,当前版本API不返回此字段
-- 2. 唯一索引包含 deleted 字段,支持逻辑删除后重新创建设置
-- ----------------------------
DROP TABLE IF EXISTS `im_contact_setting`;
CREATE TABLE `im_contact_setting`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '设置ID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `contact_id` bigint NOT NULL COMMENT '联系人ID',
  `remark_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '备注名(保留字段,当前版本未使用)',
  `star` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否星标',
  `no_disturb` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否免打扰',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `idx_user_contact_deleted`(`user_id` ASC, `contact_id` ASC, `tenant_id` ASC, `deleted` ASC) USING BTREE COMMENT '用户+联系人+删除状态唯一索引',
  INDEX `idx_tenant`(`tenant_id` ASC) USING BTREE COMMENT '租户索引'
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'IM联系人设置表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for im_message_read
-- 消息已读表: 存储群聊消息的已读状态(单聊通过 im_message.status 字段判断)
-- 说明: 
-- 1. 仅用于群聊消息已读回执
-- 2. 唯一索引包含 deleted 字段,支持逻辑删除
-- ----------------------------
DROP TABLE IF EXISTS `im_message_read`;
CREATE TABLE `im_message_read`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '已读ID',
  `message_id` bigint NOT NULL COMMENT '消息ID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `read_time` datetime NOT NULL COMMENT '已读时间',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `idx_message_user_deleted`(`message_id` ASC, `user_id` ASC, `tenant_id` ASC, `deleted` ASC) USING BTREE COMMENT '消息+用户+删除状态唯一索引',
  INDEX `idx_user`(`user_id` ASC) USING BTREE COMMENT '用户索引',
  INDEX `idx_tenant`(`tenant_id` ASC) USING BTREE COMMENT '租户索引'
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'IM消息已读表(群聊)' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for im_group_invite
-- 群邀请码表: 存储群二维码邀请信息
-- 说明: 
-- 1. 用于生成群二维码和验证扫码加入
-- 2. 支持设置有效期和使用次数限制
-- 3. 邀请码具有时效性，过期自动失效
-- ----------------------------
DROP TABLE IF EXISTS `im_group_invite`;
CREATE TABLE `im_group_invite`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '邀请ID',
  `group_id` bigint NOT NULL COMMENT '群ID',
  `invite_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '邀请码(唯一)',
  `creator_id` bigint NOT NULL COMMENT '创建者ID',
  `expire_time` datetime NOT NULL COMMENT '过期时间',
  `max_use_count` int NOT NULL DEFAULT 0 COMMENT '最大使用次数(0表示不限制)',
  `used_count` int NOT NULL DEFAULT 0 COMMENT '已使用次数',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '状态(1-有效 2-已过期 3-已禁用)',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `idx_tenant_invite_code`(`tenant_id` ASC, `invite_code` ASC) USING BTREE COMMENT '租户+邀请码唯一索引',
  INDEX `idx_group`(`group_id` ASC) USING BTREE COMMENT '群组索引',
  INDEX `idx_expire`(`expire_time` ASC, `status` ASC) USING BTREE COMMENT '过期时间+状态索引',
  INDEX `idx_tenant`(`tenant_id` ASC) USING BTREE COMMENT '租户索引'
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'IM群邀请码表' ROW_FORMAT = DYNAMIC;


-- ----------------------------
-- Table structure for im_group_file
-- 群文件关联表: 存储群组与文件的关联关系
-- 设计要点:
-- 1. 不存储文件本身，只存储关联关系
-- 2. 实际文件存储在 infra_file 表中
-- 3. 支持文件夹管理（通过 folder_id 字段）
-- 4. 支持文件收藏、下载统计
-- 5. 文件目录按群组分类：im/group/{groupId}/
-- ----------------------------
DROP TABLE IF EXISTS `im_group_file`;
CREATE TABLE `im_group_file` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `group_id` bigint NOT NULL COMMENT '群组ID',
  `file_id` bigint NOT NULL COMMENT '文件ID(关联 infra_file.id)',
  `uploader_id` bigint NOT NULL COMMENT '上传者ID',
  `folder_id` bigint DEFAULT 0 COMMENT '文件夹ID(0表示根目录)',
  `is_favorite` bit(1) DEFAULT b'0' COMMENT '是否收藏',
  `download_count` int DEFAULT 0 COMMENT '下载次数',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_group_file_deleted` (`group_id`, `file_id`, `tenant_id`, `deleted`) COMMENT '群组文件唯一索引(包含deleted)',
  KEY `idx_group` (`group_id`, `tenant_id`) COMMENT '群组索引',
  KEY `idx_uploader` (`uploader_id`) COMMENT '上传者索引',
  KEY `idx_folder` (`folder_id`) COMMENT '文件夹索引',
  KEY `idx_tenant` (`tenant_id`) COMMENT '租户索引'
) ENGINE=InnoDB CHARACTER SET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='IM群文件关联表' ROW_FORMAT=DYNAMIC;

-- ----------------------------
-- Table structure for im_group_folder
-- 群文件夹表: 用于文件夹管理（可选功能）
-- ----------------------------
DROP TABLE IF EXISTS `im_group_folder`;
CREATE TABLE `im_group_folder` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `group_id` bigint NOT NULL COMMENT '群组ID',
  `folder_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '文件夹名称',
  `parent_id` bigint DEFAULT 0 COMMENT '父文件夹ID(0表示根目录)',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_group` (`group_id`, `tenant_id`) COMMENT '群组索引',
  KEY `idx_parent` (`parent_id`) COMMENT '父文件夹索引',
  KEY `idx_tenant` (`tenant_id`) COMMENT '租户索引'
) ENGINE=InnoDB CHARACTER SET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='IM群文件夹表' ROW_FORMAT=DYNAMIC;

-- ----------------------------
-- Table structure for im_call_record
-- 通话记录表: 存储语音/视频通话记录
-- 说明:
-- 1. 记录所有通话信息，包括通话类型、时长、状态
-- 2. 支持未接听、已接听、已拒绝等状态
-- 3. 通话时长以秒为单位
-- ----------------------------
DROP TABLE IF EXISTS `im_call_record`;
CREATE TABLE `im_call_record` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '通话记录ID',
  `call_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '通话ID(唯一标识)',
  `call_type` tinyint NOT NULL COMMENT '通话类型(1-语音通话 2-视频通话)',
  `caller_id` bigint NOT NULL COMMENT '呼叫者ID',
  `callee_id` bigint NOT NULL COMMENT '被叫者ID',
  `start_time` datetime NOT NULL COMMENT '通话开始时间',
  `end_time` datetime NULL DEFAULT NULL COMMENT '通话结束时间',
  `duration` int NOT NULL DEFAULT 0 COMMENT '通话时长(秒)',
  `status` tinyint NOT NULL COMMENT '通话状态(1-未接听 2-已接听 3-已拒绝 4-忙线 5-已取消)',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `idx_tenant_call_id`(`tenant_id` ASC, `call_id` ASC) USING BTREE COMMENT '租户+通话ID唯一索引',
  INDEX `idx_caller`(`caller_id` ASC, `start_time` DESC) USING BTREE COMMENT '呼叫者+时间索引',
  INDEX `idx_callee`(`callee_id` ASC, `start_time` DESC) USING BTREE COMMENT '被叫者+时间索引',
  INDEX `idx_tenant`(`tenant_id` ASC) USING BTREE COMMENT '租户索引'
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'IM通话记录表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for im_notification
-- 通知表: 存储系统通知、流程通知、待办提醒等
-- 说明:
-- 1. 支持多种通知类型：系统公告、流程审批、待办提醒、自定义通知
-- 2. 支持通知内容、操作按钮、跳转配置
-- 3. 支持已读状态、过期时间
-- ----------------------------
DROP TABLE IF EXISTS `im_notification`;
CREATE TABLE `im_notification` (
   `id` bigint NOT NULL AUTO_INCREMENT COMMENT '通知ID',
   `user_id` bigint NOT NULL COMMENT '接收用户ID',
   `notify_type` tinyint NOT NULL COMMENT '通知类型(1-系统公告 2-流程审批 3-待办提醒 4-自定义通知)',
   `title` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '通知标题',
   `content` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '通知内容',
   `icon` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '通知图标URL',
   `extra` longtext NULL COMMENT '扩展信息(JSON格式,存储操作按钮、跳转配置、业务数据等)',
   `is_read` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否已读',
   `read_time` datetime NULL DEFAULT NULL COMMENT '已读时间',
   `is_important` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否重要(重要通知需强制阅读)',
   `expire_time` datetime NULL DEFAULT NULL COMMENT '过期时间',
   `status` tinyint NOT NULL DEFAULT 1 COMMENT '通知状态(1-正常 2-已过期 3-已撤回)',
   `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
   `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
   `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
   `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
   `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
   `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
   PRIMARY KEY (`id`) USING BTREE,
   INDEX `idx_user_time`(`user_id` ASC, `create_time` DESC) USING BTREE COMMENT '用户+时间索引',
   INDEX `idx_user_read`(`user_id` ASC, `is_read` ASC) USING BTREE COMMENT '用户+已读状态索引',
   INDEX `idx_type`(`notify_type` ASC) USING BTREE COMMENT '通知类型索引',
   INDEX `idx_tenant`(`tenant_id` ASC) USING BTREE COMMENT '租户索引'
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'IM通知表' ROW_FORMAT = DYNAMIC;
