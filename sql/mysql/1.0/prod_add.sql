-- 钰信 App 正式用户更新中心增量脚本
-- 执行范围：生产库增量升级，可重复执行
-- 日期：2026-09-07

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
