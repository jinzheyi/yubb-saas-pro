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
-- Table structure for im_conversation
-- 会话表: 存储用户的会话列表(单聊/群聊)
-- ----------------------------
DROP TABLE IF EXISTS `im_conversation`;
CREATE TABLE `im_conversation`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '会话ID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `target_id` bigint NOT NULL COMMENT '目标ID(单聊为对方用户ID,群聊为群ID)',
  `conversation_type` tinyint NOT NULL COMMENT '会话类型(1-单聊 2-群聊)',
  `unread_count` int NOT NULL DEFAULT 0 COMMENT '未读消息数',
  `last_message_id` bigint NULL DEFAULT NULL COMMENT '最后一条消息ID',
  `last_message_content` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '最后一条消息内容',
  `last_message_time` datetime NULL DEFAULT NULL COMMENT '最后一条消息时间',
  `is_pinned` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否置顶',
  `no_disturb` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否免打扰',
  `deleted_by_user` bit(1) NOT NULL DEFAULT b'0' COMMENT '用户是否删除会话',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `idx_user_target`(`user_id` ASC, `target_id` ASC, `conversation_type` ASC, `tenant_id` ASC) USING BTREE COMMENT '用户+目标+类型唯一索引',
  INDEX `idx_user_time`(`user_id` ASC, `last_message_time` DESC) USING BTREE COMMENT '用户+时间索引',
  INDEX `idx_tenant`(`tenant_id` ASC) USING BTREE COMMENT '租户索引'
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'IM会话表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for im_message
-- 消息表: 存储所有聊天消息(单聊/群聊)
-- 注意: 消息表数据量大,建议按月分表
-- ----------------------------
DROP TABLE IF EXISTS `im_message`;
CREATE TABLE `im_message`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '消息ID',
  `conversation_id` bigint NOT NULL COMMENT '会话ID',
  `sender_id` bigint NOT NULL COMMENT '发送者ID',
  `receiver_id` bigint NULL DEFAULT NULL COMMENT '接收者ID(单聊有值,群聊为NULL)',
  `group_id` bigint NULL DEFAULT NULL COMMENT '群ID(群聊有值,单聊为NULL)',
  `message_type` tinyint NOT NULL COMMENT '消息类型(1-文本 2-图片 3-语音 4-视频 5-文件 6-位置 7-表情包 8-自定义贴纸 10-系统消息)',
  `content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '消息内容',
  `extra` json NULL COMMENT '扩展信息(JSON格式,存储文件URL、时长、大小等)',
  `send_time` datetime NOT NULL COMMENT '发送时间',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '消息状态(1-发送中 2-已发送 3-已送达 4-已读 5-发送失败 6-已撤回)',
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
  INDEX `idx_conversation`(`conversation_id` ASC, `send_time` DESC) USING BTREE COMMENT '会话+时间索引',
  INDEX `idx_sender`(`sender_id` ASC, `send_time` DESC) USING BTREE COMMENT '发送者+时间索引',
  INDEX `idx_receiver`(`receiver_id` ASC, `send_time` DESC) USING BTREE COMMENT '接收者+时间索引',
  INDEX `idx_group`(`group_id` ASC, `send_time` DESC) USING BTREE COMMENT '群组+时间索引',
  INDEX `idx_tenant`(`tenant_id` ASC) USING BTREE COMMENT '租户索引'
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'IM消息表' ROW_FORMAT = DYNAMIC;

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
  UNIQUE INDEX `idx_group_user`(`group_id` ASC, `user_id` ASC, `tenant_id` ASC) USING BTREE COMMENT '群+用户唯一索引',
  INDEX `idx_user`(`user_id` ASC) USING BTREE COMMENT '用户索引',
  INDEX `idx_tenant`(`tenant_id` ASC) USING BTREE COMMENT '租户索引'
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'IM群成员表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for im_contact_setting
-- 联系人设置表: 存储用户对联系人的个性化设置(星标、免打扰)
-- 说明: 企业内部IM,联系人直接来源于 system_users 表,本表仅存储个性化设置
-- 注意: remark_name 字段保留用于未来扩展,当前版本API不返回此字段
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
  UNIQUE INDEX `idx_user_contact`(`user_id` ASC, `contact_id` ASC, `tenant_id` ASC) USING BTREE COMMENT '用户+联系人唯一索引',
  INDEX `idx_tenant`(`tenant_id` ASC) USING BTREE COMMENT '租户索引'
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'IM联系人设置表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for im_message_read
-- 消息已读表: 存储群聊消息的已读状态(单聊通过 im_message.status 字段判断)
-- 说明: 仅用于群聊消息已读回执
-- ----------------------------
DROP TABLE IF EXISTS `im_message_read`;
CREATE TABLE `im_message_read`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '已读ID',
  `message_id` bigint NOT NULL COMMENT '消息ID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `read_time` datetime NOT NULL COMMENT '已读时间',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `idx_message_user`(`message_id` ASC, `user_id` ASC, `tenant_id` ASC) USING BTREE COMMENT '消息+用户唯一索引',
  INDEX `idx_user`(`user_id` ASC) USING BTREE COMMENT '用户索引',
  INDEX `idx_tenant`(`tenant_id` ASC) USING BTREE COMMENT '租户索引'
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'IM消息已读表(群聊)' ROW_FORMAT = DYNAMIC;
