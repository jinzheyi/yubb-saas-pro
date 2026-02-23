/*
 IM 即时通讯 - 群文件关联表
 
 功能说明: 存储群组与文件的关联关系，复用平台 infra_file 表存储实际文件
 创建日期: 2026-02-23
 版本: v1.0
 
 设计要点:
 1. 不存储文件本身，只存储关联关系
 2. 实际文件存储在 infra_file 表中
 3. 支持文件夹管理（通过 folder_id 字段）
 4. 支持文件收藏、下载统计
 5. 文件目录按群组分类：im/group/{groupId}/
*/

SET NAMES utf8mb4;

-- ----------------------------
-- Table structure for im_group_file
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
-- Table structure for im_group_folder (可选，用于文件夹管理)
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
