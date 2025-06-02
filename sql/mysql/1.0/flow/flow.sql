-- 1、脚本同步git节点：新增数据权限维护脚本20250205

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for flw_ext_instance
-- ----------------------------
DROP TABLE IF EXISTS `flw_ext_instance`;
CREATE TABLE `flw_ext_instance`  (
 `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
 `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
 `create_id`  varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建人ID',
 `create_by` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者名称',
 `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
 `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
 `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
 `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
 `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
 `process_id` bigint NOT NULL COMMENT '流程定义ID',
 `process_name`  varchar(100) COMMENT '流程名称',
 `process_type`  varchar(100) COMMENT '流程类型',
 `model_content` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL COMMENT '流程模型定义JSON内容',
 PRIMARY KEY (`id`) USING BTREE,
 CONSTRAINT `fk_ext_instance_id` FOREIGN KEY (`id`) REFERENCES `flw_his_instance` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '扩展流程实例表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for flw_his_instance
-- ----------------------------
DROP TABLE IF EXISTS `flw_his_instance`;
CREATE TABLE `flw_his_instance`  (
 `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
 `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
 `create_id`  varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建人ID',
 `create_by` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者名称',
 `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
 `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
 `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
 `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
 `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
 `process_id` bigint NOT NULL COMMENT '流程定义ID',
 `parent_instance_id` bigint NULL DEFAULT NULL COMMENT '父流程实例ID',
 `priority` smallint NULL DEFAULT NULL COMMENT '优先级',
 `instance_no` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '流程实例编号',
 `business_key` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '业务KEY',
 `variable` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL COMMENT '变量json',
 `current_node_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '当前所在节点名称',
 `current_node_key` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '当前所在节点key',
 `expire_time` datetime NULL DEFAULT NULL COMMENT '期望完成时间',
 `last_update_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '上次更新人',
 `last_update_time` datetime NULL DEFAULT NULL COMMENT '上次更新时间',
 `instance_state` smallint NOT NULL DEFAULT 0 COMMENT '状态 0，审批中 1，审批通过 2，审批拒绝 3，撤销审批 4，超时结束 5，强制终止',
 `end_time` datetime NULL DEFAULT NULL COMMENT '结束时间',
 `duration` bigint NULL DEFAULT NULL COMMENT '处理耗时',
 PRIMARY KEY (`id`) USING BTREE,
 INDEX `idx_his_instance_process_id`(`process_id` ASC) USING BTREE,
 CONSTRAINT `flw_his_instance_process_id_fkey` FOREIGN KEY (`process_id`) REFERENCES `flw_process` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '历史流程实例表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for flw_his_task
-- ----------------------------
DROP TABLE IF EXISTS `flw_his_task`;
CREATE TABLE `flw_his_task`  (
 `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
 `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
 `create_id`  varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建人ID',
 `create_by` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者名称',
 `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
 `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
 `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
 `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
 `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
 `instance_id` bigint NOT NULL COMMENT '流程实例ID',
 `parent_task_id` bigint NULL DEFAULT NULL COMMENT '父任务ID',
 `call_process_id` bigint NULL DEFAULT NULL COMMENT '调用外部流程定义ID',
 `call_instance_id` bigint NULL DEFAULT NULL COMMENT '调用外部流程实例ID',
 `task_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '任务名称',
 `task_key` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '任务 key 唯一标识',
 `task_type` smallint NOT NULL COMMENT '任务类型',
 `perform_type` smallint NULL DEFAULT NULL COMMENT '参与类型',
 `action_url` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '任务处理的url',
 `variable` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL COMMENT '变量json',
 `assignor_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '委托人ID',
 `assignor` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '委托人',
 `expire_time` datetime NULL DEFAULT NULL COMMENT '任务期望完成时间',
 `remind_time` datetime NULL DEFAULT NULL COMMENT '提醒时间',
 `remind_repeat` smallint NOT NULL DEFAULT 0 COMMENT '提醒次数',
 `viewed` smallint NOT NULL DEFAULT 0 COMMENT '已阅 0，否 1，是',
 `finish_time` datetime NULL DEFAULT NULL COMMENT '任务完成时间',
 `task_state` smallint NOT NULL DEFAULT 0 COMMENT '任务状态 0，活动 1，跳转 2，完成 3，拒绝 4，撤销审批  5，超时 6，终止 7，驳回终止',
 `duration` bigint NULL DEFAULT NULL COMMENT '处理耗时',
 PRIMARY KEY (`id`) USING BTREE,
 INDEX `idx_his_task_instance_id`(`instance_id` ASC) USING BTREE,
 INDEX `idx_his_task_parent_task_id`(`parent_task_id` ASC) USING BTREE,
 CONSTRAINT `flw_his_task_instance_id_fkey` FOREIGN KEY (`instance_id`) REFERENCES `flw_his_instance` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '历史任务表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for flw_his_task_actor
-- ----------------------------
DROP TABLE IF EXISTS `flw_his_task_actor`;
CREATE TABLE `flw_his_task_actor`  (
   `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
   `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
   `create_id`  varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建人ID',
   `create_by` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者名称',
   `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
   `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
   `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
   `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
   `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
   `instance_id` bigint NOT NULL COMMENT '流程实例ID',
   `task_id` bigint NOT NULL COMMENT '任务ID',
   `actor_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '参与者ID',
   `actor_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '参与者名称',
   `actor_type` int NOT NULL COMMENT '参与者类型 0，用户 1，角色 2，部门',
   `weight` int NULL DEFAULT NULL COMMENT '权重，票签任务时，该值为不同处理人员的分量比例，代理任务时，该值为 1 时为代理人，或签任务时，该值为 1 时为或签处理人',
   `agent_id`    varchar(100) COMMENT '代理人ID',
   `agent_type`  int          COMMENT '代理人类型 0，代理 1，被代理 2，认领角色 3，认领部门',
   `extend`      json COMMENT '扩展json',
   PRIMARY KEY (`id`) USING BTREE,
   INDEX `idx_his_task_actor_task_id`(`task_id` ASC) USING BTREE,
   CONSTRAINT `flw_his_task_actor_task_id_fkey` FOREIGN KEY (`task_id`) REFERENCES `flw_his_task` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '历史任务参与者表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for flw_instance
-- ----------------------------
DROP TABLE IF EXISTS `flw_instance`;
CREATE TABLE `flw_instance`  (
 `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
 `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
 `create_id`  varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建人ID',
 `create_by` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者名称',
 `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
 `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
 `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
 `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
 `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
 `process_id` bigint NOT NULL COMMENT '流程定义ID',
 `parent_instance_id` bigint NULL DEFAULT NULL COMMENT '父流程实例ID',
 `priority` smallint NULL DEFAULT NULL COMMENT '优先级',
 `instance_no` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '流程实例编号',
 `business_key` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '业务KEY',
 `variable` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL COMMENT '变量json',
 `current_node_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '当前所在节点名称',
 `current_node_key` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '当前所在节点key',
 `expire_time` datetime NULL DEFAULT NULL COMMENT '期望完成时间',
 `last_update_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '上次更新人',
 `last_update_time` datetime NULL DEFAULT NULL COMMENT '上次更新时间',
 PRIMARY KEY (`id`) USING BTREE,
 INDEX `idx_instance_process_id`(`process_id` ASC) USING BTREE,
 CONSTRAINT `flw_instance_process_id_fkey` FOREIGN KEY (`process_id`) REFERENCES `flw_process` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '流程实例表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of flw_instance
-- ----------------------------

-- ----------------------------
-- Table structure for flw_process
-- ----------------------------
DROP TABLE IF EXISTS `flw_process`;
CREATE TABLE `flw_process`  (
    `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
    `create_id`  varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建人ID',
    `create_by` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者名称',
    `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
    `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
    `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
    `process_key` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '流程定义 key 唯一标识',
    `process_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '流程定义名称',
    `process_icon` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '流程图标地址',
    `process_type` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '流程类型',
    `process_version` int NOT NULL DEFAULT 1 COMMENT '流程版本，默认 1',
    `instance_url` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '实例地址',
    `remark` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '备注说明',
    `use_scope` smallint NOT NULL DEFAULT 0 COMMENT '使用范围 0，全员 1，指定人员（业务关联） 2，均不可提交',
    `process_state` smallint NOT NULL DEFAULT 0 COMMENT '流程状态 0，不可用 1，可用',
    `model_content` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL COMMENT '流程模型定义JSON内容',
    `sort` smallint NULL DEFAULT NULL COMMENT '排序',
    PRIMARY KEY (`id`) USING BTREE,
    INDEX `idx_process_name`(`process_name` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '流程定义表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for flw_process_actor
-- ----------------------------
DROP TABLE IF EXISTS `flw_process_actor`;
CREATE TABLE `flw_process_actor`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_id`  varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建人ID',
  `create_by` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者名称',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  `process_id` bigint NOT NULL COMMENT '流程定义ID',
  `actor_id` bigint NOT NULL COMMENT '参与者ID',
  `actor_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '参与者',
  `actor_type` smallint NOT NULL COMMENT '参与者类型 0，角色 1，部门',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '流程定义参与者' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of flw_process_actor
-- ----------------------------

-- ----------------------------
-- Table structure for flw_process_approval
-- ----------------------------
DROP TABLE IF EXISTS `flw_process_approval`;
CREATE TABLE `flw_process_approval`  (
     `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
     `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
     `create_id`  varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建人ID',
     `create_by` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者名称',
     `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
     `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
     `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
     `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
     `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
     `instance_id` bigint NOT NULL COMMENT '流程实例ID',
     `task_id` bigint NULL DEFAULT NULL COMMENT '流程任务ID',
     `task_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '任务名称',
     `task_key` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '任务 key 唯一标识',
     `type` smallint NOT NULL COMMENT '审批类型 0，评论 1，提交 2，抄送 3，办理 4，驳回 5，认领 6，转办 7，委派 8，跳转 9，拿回 10，唤醒 11，前加签 12，并加签 13，后加签 14，减签 15，撤销 16，终止 17，超时',
     `content` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL COMMENT '操作 json 内容',
     `attachments` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL COMMENT '附件 json 内容',
     PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '流程审批记录' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for flw_process_category
-- ----------------------------
DROP TABLE IF EXISTS `flw_process_category`;
CREATE TABLE `flw_process_category`  (
 `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
 `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
 `create_id`  varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建人ID',
 `create_by` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者名称',
 `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
 `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
 `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
 `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
 `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
 `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '名称',
 `remark` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '备注',
 `sort` smallint NOT NULL DEFAULT 0 COMMENT '排序',
 PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '流程分类' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for flw_process_configure
-- ----------------------------
DROP TABLE IF EXISTS `flw_process_configure`;
CREATE TABLE `flw_process_configure`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_id`  varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建人ID',
  `create_by` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者名称',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  `process_id` bigint NOT NULL COMMENT '流程定义ID',
  `category_id` bigint NOT NULL COMMENT '流程分类ID',
  `process_setting` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '流程设置',
  `process_form` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '流程表单',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '流程定义配置' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for flw_process_form
-- ----------------------------
DROP TABLE IF EXISTS `flw_process_form`;
CREATE TABLE `flw_process_form`  (
 `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
 `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
 `create_id`  varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建人ID',
 `create_by` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者名称',
 `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
 `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
 `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
 `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
 `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
 `instance_id` bigint NOT NULL COMMENT '流程实例ID',
 `content` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '表单内容',
 PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '流程定义表单' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for flw_process_permission
-- ----------------------------
DROP TABLE IF EXISTS `flw_process_permission`;
CREATE TABLE `flw_process_permission`  (
       `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
       `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
       `create_id`  varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建人ID',
       `create_by` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者名称',
       `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
       `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
       `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
       `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
       `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
       `process_id` bigint NOT NULL COMMENT '流程定义ID',
       `user_id` bigint NOT NULL COMMENT '用户ID',
       `user_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '用户名',
       `operate_approval` smallint NOT NULL DEFAULT 0 COMMENT '允许编辑/停用/删除审批 0，否 1，是',
       `operate_owner` smallint NOT NULL DEFAULT 0 COMMENT '允许添加/移除审批负责人 0，否 1，是',
       `operate_data` smallint NOT NULL DEFAULT 0 COMMENT '允许审批数据查询与操作 0，否 1，是',
       PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '流程定义权限' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of flw_process_permission
-- ----------------------------

-- ----------------------------
-- Table structure for flw_task
-- ----------------------------
DROP TABLE IF EXISTS `flw_task`;
CREATE TABLE `flw_task`  (
`id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
`creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
`create_id`  varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建人ID',
`create_by` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者名称',
`create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
`updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
`update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
`deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
`tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
`instance_id` bigint NOT NULL COMMENT '流程实例ID',
`parent_task_id` bigint NULL DEFAULT NULL COMMENT '父任务ID',
`task_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '任务名称',
`task_key` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '任务 key 唯一标识',
`task_type` smallint NOT NULL COMMENT '任务类型',
`perform_type` smallint NULL DEFAULT NULL COMMENT '参与类型',
`action_url` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '任务处理的url',
`variable` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL COMMENT '变量json',
`assignor_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '委托人ID',
`assignor` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '委托人',
`expire_time` datetime NULL DEFAULT NULL COMMENT '任务期望完成时间',
`remind_time` datetime NULL DEFAULT NULL COMMENT '提醒时间',
`remind_repeat` smallint NOT NULL DEFAULT 0 COMMENT '提醒次数',
`viewed` smallint NOT NULL DEFAULT 0 COMMENT '已阅 0，否 1，是',
PRIMARY KEY (`id`) USING BTREE,
INDEX `idx_task_instance_id`(`instance_id` ASC) USING BTREE,
CONSTRAINT `flw_task_instance_id_fkey` FOREIGN KEY (`instance_id`) REFERENCES `flw_instance` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '任务表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of flw_task
-- ----------------------------

-- ----------------------------
-- Table structure for flw_task_actor
-- ----------------------------
DROP TABLE IF EXISTS `flw_task_actor`;
CREATE TABLE `flw_task_actor`  (
`id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
`creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
`create_id`  varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建人ID',
`create_by` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者名称',
`create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
`updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
`update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
`deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
`tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
`instance_id` bigint NOT NULL COMMENT '流程实例ID',
`task_id` bigint NOT NULL COMMENT '任务ID',
`actor_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '参与者ID',
`actor_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '参与者名称',
`actor_type` int NOT NULL COMMENT '参与者类型 0，用户 1，角色 2，部门',
`weight` int NULL DEFAULT NULL COMMENT '权重，票签任务时，该值为不同处理人员的分量比例，代理任务时，该值为 1 时为代理人，或签任务时，该值为 1 时为或签处理人',
`agent_id`    varchar(100) COMMENT '代理人ID',
`agent_type`  int          COMMENT '代理人类型 0，代理 1，被代理 2，认领角色 3，认领部门',
`extend`      json COMMENT '扩展json',
PRIMARY KEY (`id`) USING BTREE,
INDEX `idx_task_actor_task_id`(`task_id` ASC) USING BTREE,
CONSTRAINT `flw_task_actor_task_id_fkey` FOREIGN KEY (`task_id`) REFERENCES `flw_task` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '任务参与者表' ROW_FORMAT = Dynamic;


-- ----------------------------
-- Table structure for flw_form_template
-- ----------------------------
DROP TABLE IF EXISTS `flw_form_template`;
CREATE TABLE `flw_form_template`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_id`  varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建人ID',
  `create_by` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者名称',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  `form_category_id` bigint NOT NULL COMMENT '表单分类ID',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '名称',
  `code` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '唯一编号',
  `type` smallint NOT NULL DEFAULT 0 COMMENT '类型 0，设计表单 1，系统表单',
  `pc_url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT 'PC端地址',
  `app_url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT 'APP端地址',
  `content` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL COMMENT '内容',
  `remark` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '备注',
  `status` smallint NOT NULL DEFAULT 1 COMMENT '状态 0、禁用 1、正常',
  `sort` smallint NOT NULL DEFAULT 0 COMMENT '排序',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '流程表单模板' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for flw_form_category
-- ----------------------------
DROP TABLE IF EXISTS `flw_form_category`;
CREATE TABLE `flw_form_category`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_id`  varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建人ID',
  `create_by` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者名称',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  `pid` bigint NOT NULL DEFAULT 0 COMMENT '父ID',
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '名称',
  `remark` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '备注',
  `status` smallint NOT NULL DEFAULT 1 COMMENT '状态 0、禁用 1、正常',
  `sort` smallint NOT NULL DEFAULT 0 COMMENT '排序',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '流程表单分类' ROW_FORMAT = Dynamic;




-- business  表或数据
INSERT INTO `system_notify_template` (`id`, `name`, `code`, `nickname`, `content`, `type`, `params`, `status`, `remark`, `creator`, `create_time`, `updater`, `update_time`, `deleted`, `tenant_id`) VALUES (1929134406828666882, '流程到达消息', 'flow_send_msg', '系统', '流程：{processName}  待审批，当前所在节点：{taskName}  ，任务发起人：{createBy}', 2, '[\"processName\",\"taskName\",\"createBy\"]', 0, '', '507075497791557', '2025-06-01 19:14:19', '507075497791557', '2025-06-01 20:28:08', b'0', 507075493834821);
INSERT INTO `system_notify_template` (`id`, `name`, `code`, `nickname`, `content`, `type`, `params`, `status`, `remark`, `creator`, `create_time`, `updater`, `update_time`, `deleted`, `tenant_id`) VALUES (1929152917693116418, '流程催办消息', 'flow_urge_msg', '流程系统', '发起人对流程：“{processName}” 发起了催办，请您尽快审批', 2, '[\"processName\"]', 0, '', '507075497791557', '2025-06-01 20:27:52', '507075497791557', '2025-06-01 20:27:52', b'0', 507075493834821);
