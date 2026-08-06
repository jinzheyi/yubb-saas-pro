-- ========================================
-- IM 通话记录表增强
-- 添加冗余字段避免联表查询，支持群组通话参与者
-- 执行时间：2026-07-21
-- ========================================

-- 1. im_call_record 表新增冗余字段（主叫方昵称、头像）
ALTER TABLE `im_call_record` 
ADD COLUMN `caller_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '主叫方昵称（冗余字段，避免联表查询）' AFTER `record_message_id`;

ALTER TABLE `im_call_record` 
ADD COLUMN `caller_avatar` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '主叫方头像（冗余字段，避免联表查询）' AFTER `caller_name`;

-- 2. im_call_record 表新增冗余字段（被叫方昵称、头像）
ALTER TABLE `im_call_record` 
ADD COLUMN `callee_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '被叫方昵称（冗余字段，避免联表查询）' AFTER `caller_avatar`;

ALTER TABLE `im_call_record` 
ADD COLUMN `callee_avatar` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '被叫方头像（冗余字段，避免联表查询）' AFTER `callee_name`;

-- 3. im_call_record 表新增 Janus 房间 ID 字段
ALTER TABLE `im_call_record` 
ADD COLUMN `room_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT 'Janus 房间ID（用于 RTC 通话）' AFTER `callee_avatar`;

-- 4. im_call_record 表添加性能索引
ALTER TABLE `im_call_record`
ADD INDEX `idx_start_time` (`start_time`),
ADD INDEX `idx_tenant_id` (`tenant_id`);

-- 5. 创建群组通话参与者表
DROP TABLE IF EXISTS `im_call_participant`;
CREATE TABLE `im_call_participant` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `call_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '通话ID',
  `user_id` bigint NOT NULL COMMENT '参与者用户ID',
  `device_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '设备ID',
  `role` tinyint NOT NULL DEFAULT 1 COMMENT '角色：1-主叫 2-被叫',
  `join_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '加入时间',
  `leave_time` datetime NULL DEFAULT NULL COMMENT '离开时间',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '状态：1-在线 2-离线 3-已离开',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_call_user_device`(`call_id` ASC, `user_id` ASC, `device_id` ASC, `deleted` ASC) USING BTREE,
  INDEX `idx_call_id`(`call_id` ASC) USING BTREE,
  INDEX `idx_user_id`(`user_id` ASC) USING BTREE,
  INDEX `idx_tenant`(`tenant_id` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'IM 通话参与者表（群组通话）' ROW_FORMAT = DYNAMIC;

-- ========================================
-- 回滚脚本（如需回滚请执行以下SQL）
-- ========================================
-- ALTER TABLE `im_call_record` DROP COLUMN `caller_name`;
-- ALTER TABLE `im_call_record` DROP COLUMN `caller_avatar`;
-- ALTER TABLE `im_call_record` DROP COLUMN `callee_name`;
-- ALTER TABLE `im_call_record` DROP COLUMN `callee_avatar`;
-- ALTER TABLE `im_call_record` DROP COLUMN `room_id`;
-- DROP TABLE IF EXISTS `im_call_participant`;
