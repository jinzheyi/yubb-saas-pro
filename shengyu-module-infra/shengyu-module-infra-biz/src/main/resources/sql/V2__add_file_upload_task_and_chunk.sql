-- 分片上传任务表
DROP TABLE IF EXISTS `infra_file_upload_task`;
CREATE TABLE `infra_file_upload_task`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '任务编号',
  `upload_id` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '分片上传唯一标识',
  `config_id` bigint NULL DEFAULT NULL COMMENT '文件配置编号',
  `name` varchar(256) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '原始文件名',
  `path` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '目标文件路径',
  `type` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT 'MIME 类型',
  `total_size` bigint NOT NULL COMMENT '文件总大小（字节）',
  `chunk_size` int NOT NULL COMMENT '分片大小（字节）',
  `total_chunks` int NOT NULL COMMENT '总分片数',
  `uploaded_chunks` int NOT NULL DEFAULT 0 COMMENT '已上传分片数',
  `status` tinyint NOT NULL DEFAULT 0 COMMENT '状态: 0-初始化, 1-上传中, 2-已完成, 3-已取消, 4-已过期',
  `expire_time` datetime NOT NULL COMMENT '过期时间',
  `s3_upload_id` varchar(256) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT 'S3 分片上传 ID',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_upload_id`(`upload_id` ASC) USING BTREE,
  INDEX `idx_expire_time`(`expire_time` ASC) USING BTREE,
  INDEX `idx_status_update_time`(`status` ASC, `update_time` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '分片上传任务表' ROW_FORMAT = DYNAMIC;

-- 分片上传记录表
DROP TABLE IF EXISTS `infra_file_upload_chunk`;
CREATE TABLE `infra_file_upload_chunk`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '分片编号',
  `upload_id` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '关联的分片上传唯一标识',
  `chunk_number` int NOT NULL COMMENT '分片序号，从 1 开始',
  `chunk_size` bigint NOT NULL COMMENT '分片大小（字节）',
  `etag` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '分片 ETag 或 S3 分片 ID',
  `status` tinyint NOT NULL DEFAULT 0 COMMENT '状态: 0-上传中, 1-已完成',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_upload_id_chunk_number`(`upload_id` ASC, `chunk_number` ASC) USING BTREE,
  INDEX `idx_upload_id_status`(`upload_id` ASC, `status` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '分片上传记录表' ROW_FORMAT = DYNAMIC;
