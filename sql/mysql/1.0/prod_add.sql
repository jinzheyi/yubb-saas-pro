-- 钰信 App 正式用户更新中心增量脚本
-- 执行范围：生产库增量升级，可重复执行
-- 日期：2026-09-07

-- 2026-09-09 App 自助注册/企业加入闭环
SET @column_needs_modify := (
  SELECT COUNT(1) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'system_saas_user'
    AND COLUMN_NAME = 'username'
    AND CHARACTER_MAXIMUM_LENGTH < 50
);
SET @ddl := IF(@column_needs_modify > 0,
  'ALTER TABLE `system_saas_user` MODIFY COLUMN `username` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT ''邮箱，第一登录方式账号没有用手机号是因为邮箱验证免费''',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @column_exists := (
  SELECT COUNT(1) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'tenant' AND COLUMN_NAME = 'owner_saas_user_id'
);
SET @ddl := IF(@column_exists = 0,
  'ALTER TABLE `tenant` ADD COLUMN `owner_saas_user_id` bigint NULL DEFAULT NULL COMMENT ''企业所有者SaaS用户编号'' AFTER `contact_user_id`',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @index_exists := (
  SELECT COUNT(1) FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'tenant' AND INDEX_NAME = 'idx_owner_saas_user_deleted'
);
SET @ddl := IF(@index_exists = 0,
  'ALTER TABLE `tenant` ADD INDEX `idx_owner_saas_user_deleted` (`owner_saas_user_id`, `deleted`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @index_exists := (
  SELECT COUNT(1) FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'system_users' AND INDEX_NAME = 'uk_tenant_saas_user_deleted'
);
SET @ddl := IF(@index_exists = 0,
  'ALTER TABLE `system_users` ADD UNIQUE INDEX `uk_tenant_saas_user_deleted` (`tenant_id`, `saas_user_id`, `deleted`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @index_exists := (
  SELECT COUNT(1) FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'system_saas_user' AND INDEX_NAME = 'uk_username_deleted'
);
SET @ddl := IF(@index_exists = 0,
  'ALTER TABLE `system_saas_user` ADD UNIQUE INDEX `uk_username_deleted` (`username`, `deleted`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

CREATE TABLE IF NOT EXISTS `platform_app_release` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `app_key` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '应用标识',
  `platform` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '平台 android/ios/harmony',
  `channel` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'prod' COMMENT '渠道',
  `version_name` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '版本名',
  `version_code` int NOT NULL COMMENT '构建号',
  `min_supported_version_code` int NOT NULL COMMENT '最低可用构建号',
  `update_type` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'FULL' COMMENT '更新类型 FULL/PATCH',
  `force_update` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否强制更新',
  `title` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '更新标题',
  `changelog` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '更新日志',
  `package_url` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '下载或跳转地址',
  `package_size` bigint NULL DEFAULT NULL COMMENT '包大小',
  `sha256` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT 'Android APK SHA-256',
  `status` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DRAFT' COMMENT '状态 DRAFT/PUBLISHED/PAUSED',
  `remark` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '内部备注',
  `patch_provider` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '补丁提供商',
  `patch_release_id` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '补丁基线版本',
  `patch_no` int NULL DEFAULT NULL COMMENT '补丁号',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_app_platform_channel_version` (`app_key`, `platform`, `channel`, `version_code`, `deleted`) USING BTREE,
  KEY `idx_app_platform_channel_status` (`app_key`, `platform`, `channel`, `status`) USING BTREE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '平台应用版本发布表' ROW_FORMAT = DYNAMIC;

INSERT IGNORE INTO `platform_menu`
(`id`, `name`, `permission`, `type`, `sort`, `parent_id`, `path`, `icon`, `component`, `component_name`, `status`, `visible`, `keep_alive`, `always_show`, `creator`, `create_time`, `updater`, `update_time`, `deleted`)
VALUES
(506900000000001, '应用版本', '', 2, 9, 1, 'app-release', 'ep:cellphone', 'system/appRelease/index', 'SystemAppRelease', 0, b'1', b'1', b'1', '1', NOW(), '1', NOW(), b'0'),
(506900000000002, '应用版本查询', 'system:app-release:query', 3, 1, 506900000000001, '', '', '', NULL, 0, b'1', b'1', b'1', '1', NOW(), '1', NOW(), b'0'),
(506900000000003, '应用版本创建', 'system:app-release:create', 3, 2, 506900000000001, '', '', '', NULL, 0, b'1', b'1', b'1', '1', NOW(), '1', NOW(), b'0'),
(506900000000004, '应用版本更新', 'system:app-release:update', 3, 3, 506900000000001, '', '', '', NULL, 0, b'1', b'1', b'1', '1', NOW(), '1', NOW(), b'0'),
(506900000000005, '应用版本删除', 'system:app-release:delete', 3, 4, 506900000000001, '', '', '', NULL, 0, b'1', b'1', b'1', '1', NOW(), '1', NOW(), b'0'),
(506900000000006, '应用版本发布', 'system:app-release:publish', 3, 5, 506900000000001, '', '', '', NULL, 0, b'1', b'1', b'1', '1', NOW(), '1', NOW(), b'0'),
(506900000000007, '应用版本暂停', 'system:app-release:pause', 3, 6, 506900000000001, '', '', '', NULL, 0, b'1', b'1', b'1', '1', NOW(), '1', NOW(), b'0');
-- ----------------------------
-- App 企业加入闭环（第二阶段）
-- ----------------------------
CREATE TABLE IF NOT EXISTS `system_tenant_invite` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `tenant_id` bigint NOT NULL COMMENT '租户编号',
  `invite_code` varchar(32) NOT NULL COMMENT '邀请码',
  `name` varchar(64) NOT NULL DEFAULT '' COMMENT '邀请名称',
  `status` tinyint NOT NULL DEFAULT 0 COMMENT '状态（0启用 1停用）',
  `expire_time` datetime DEFAULT NULL COMMENT '过期时间',
  `max_use_count` int NOT NULL DEFAULT 0 COMMENT '最多使用次数，0不限',
  `used_count` int NOT NULL DEFAULT 0 COMMENT '已使用次数',
  `default_dept_id` bigint DEFAULT NULL COMMENT '默认部门',
  `default_role_id` bigint DEFAULT NULL COMMENT '默认角色',
  `auto_approve` bit(1) NOT NULL DEFAULT b'1' COMMENT '是否自动通过',
  `creator` varchar(64) NOT NULL DEFAULT '', `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updater` varchar(64) NOT NULL DEFAULT '', `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted` bit(1) NOT NULL DEFAULT b'0',
  PRIMARY KEY (`id`), UNIQUE KEY `uk_invite_code_deleted` (`invite_code`,`deleted`), KEY `idx_tenant_deleted` (`tenant_id`,`deleted`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='企业邀请码';

CREATE TABLE IF NOT EXISTS `system_tenant_join_apply` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `tenant_id` bigint NOT NULL COMMENT '目标租户编号',
  `saas_user_id` bigint NOT NULL COMMENT '申请 SaaS 用户编号',
  `invite_id` bigint DEFAULT NULL COMMENT '邀请码编号',
  `source` varchar(16) NOT NULL DEFAULT 'invite' COMMENT '来源',
  `status` tinyint NOT NULL DEFAULT 0 COMMENT '状态（0待审批 1已通过 2已拒绝）',
  `remark` varchar(255) NOT NULL DEFAULT '' COMMENT '申请说明',
  `auditor_id` bigint DEFAULT NULL COMMENT '审批人', `audit_time` datetime DEFAULT NULL COMMENT '审批时间',
  `creator` varchar(64) NOT NULL DEFAULT '', `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updater` varchar(64) NOT NULL DEFAULT '', `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted` bit(1) NOT NULL DEFAULT b'0',
  PRIMARY KEY (`id`), UNIQUE KEY `uk_tenant_saas_deleted` (`tenant_id`,`saas_user_id`,`deleted`), KEY `idx_tenant_status_deleted` (`tenant_id`,`status`,`deleted`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='企业加入申请';

-- 企业邀请工作台菜单（系统管理目录 ID=1；按钮权限复用现有邀请成员权限）
INSERT INTO `tenant_menu` (`id`,`name`,`permission`,`type`,`sort`,`parent_id`,`path`,`icon`,`component`,`component_name`,`status`,`visible`,`keep_alive`,`always_show`,`dimension`,`plug_app_sn`,`creator`,`create_time`,`updater`,`update_time`,`deleted`)
SELECT 1900000000000000001, '企业邀请', 'system:user:create', 2, 99, 1, 'tenant-invite', 'connection', 'system/tenant-invite/index', 'TenantInvite', 0, b'1', b'1', b'1', 0, NULL, 'admin', NOW(), 'admin', NOW(), b'0'
WHERE NOT EXISTS (SELECT 1 FROM `tenant_menu` WHERE `id` = 1900000000000000001);

UPDATE `tenant_package`
SET `menu_ids` = JSON_ARRAY_APPEND(`menu_ids`, '$', CAST(1900000000000000001 AS UNSIGNED))
WHERE `deleted` = b'0'
  AND NOT JSON_CONTAINS(`menu_ids`, '1900000000000000001', '$');

-- App 注册/加入企业邮箱验证码模板。首次账号密码邮件继续复用 tenant-add-user 模板。
INSERT INTO `tenant_mail_template`
(`name`,`code`,`account_id`,`nickname`,`title`,`content`,`params`,`status`,`remark`,`creator`,`create_time`,`updater`,`update_time`,`deleted`,`tenant_id`)
SELECT 'App 注册邮箱验证码', 'app-register-code', 2, '钰信', '钰信邮箱验证码',
       '<p>您的钰信邮箱验证码：<strong>{code}</strong></p><p>验证码 {expireMinutes} 分钟内有效，请勿向任何人泄露。</p>',
       '["code","expireMinutes"]', 0, '用于创建企业或通过邀请码加入企业', 'admin', NOW(), 'admin', NOW(), b'0', 0
WHERE NOT EXISTS (SELECT 1 FROM `tenant_mail_template` WHERE `code` = 'app-register-code' AND `deleted` = b'0');
