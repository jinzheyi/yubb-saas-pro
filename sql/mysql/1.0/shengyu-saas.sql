/*
 Navicat Premium Data Transfer

 Source Server         : 阿里云
 Source Server Type    : MySQL
 Source Server Version : 80400 (8.4.0)
 Source Host           : 127.0.0.1:3306
 Source Schema         : shengyu-saas

 Target Server Type    : MySQL
 Target Server Version : 80400 (8.4.0)
 File Encoding         : 65001

 Date: 21/08/2024 00:09:05
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for infra_api_access_log
-- ----------------------------
DROP TABLE IF EXISTS `infra_api_access_log`;
CREATE TABLE `infra_api_access_log`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '日志主键',
  `trace_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '链路追踪编号',
  `user_id` bigint NOT NULL DEFAULT 0 COMMENT '用户编号',
  `user_type` tinyint NOT NULL DEFAULT 0 COMMENT '用户类型',
  `application_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '应用名',
  `request_method` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '请求方法名',
  `request_url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '请求地址',
  `request_params` varchar(8000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '请求参数',
  `user_ip` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '用户 IP',
  `user_agent` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '浏览器 UA',
  `begin_time` datetime NOT NULL COMMENT '开始请求时间',
  `end_time` datetime NOT NULL COMMENT '结束请求时间',
  `duration` int NOT NULL COMMENT '执行时长',
  `result_code` int NOT NULL DEFAULT 0 COMMENT '结果码',
  `result_msg` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '结果提示',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_create_time`(`create_time` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1825927748800221186 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'API 访问日志表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of infra_api_access_log
-- ----------------------------
INSERT INTO `infra_api_access_log` VALUES (1825922441202110466, '', 1760311914397024258, 2, 'shengyu-server', 'GET', '/admin-api/system/notify-message/get-unread-count', '{\"query\":{},\"body\":null}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-20 23:46:49', '2024-08-20 23:46:49', 37, 0, '', NULL, '2024-08-20 23:46:49', NULL, '2024-08-20 23:46:49', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825922944539561985, '', 1760311914397024258, 2, 'shengyu-server', 'GET', '/admin-api/system/notify-message/get-unread-count', '{\"query\":{},\"body\":null}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-20 23:48:49', '2024-08-20 23:48:49', 39, 0, '', NULL, '2024-08-20 23:48:49', NULL, '2024-08-20 23:48:49', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825923447969288193, '', 1760311914397024258, 2, 'shengyu-server', 'GET', '/admin-api/system/notify-message/get-unread-count', '{\"query\":{},\"body\":null}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-20 23:50:49', '2024-08-20 23:50:49', 52, 0, '', NULL, '2024-08-20 23:50:49', NULL, '2024-08-20 23:50:49', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825923860953042946, '', 1, 0, 'shengyu-server', 'GET', '/platform-api/system/sms-channel/page', '{\"query\":{\"pageNo\":\"1\",\"pageSize\":\"10\"},\"body\":null}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-20 23:52:27', '2024-08-20 23:52:27', 489, 0, '', NULL, '2024-08-20 23:52:27', NULL, '2024-08-20 23:52:27', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825923874093797378, '', 1, 0, 'shengyu-server', 'GET', '/platform-api/system/sms-template/page', '{\"query\":{\"code\":\"\",\"pageNo\":\"1\",\"pageSize\":\"10\",\"apiTemplateId\":\"\",\"content\":\"\"},\"body\":null}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-20 23:52:30', '2024-08-20 23:52:30', 288, 0, '', NULL, '2024-08-20 23:52:30', NULL, '2024-08-20 23:52:30', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825923874584530946, '', 1, 0, 'shengyu-server', 'GET', '/platform-api/system/sms-channel/list-all-simple', '{\"query\":{},\"body\":null}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-20 23:52:30', '2024-08-20 23:52:30', 64, 0, '', NULL, '2024-08-20 23:52:30', NULL, '2024-08-20 23:52:30', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825923951138967553, '', 1760311914397024258, 2, 'shengyu-server', 'GET', '/admin-api/system/notify-message/get-unread-count', '{\"query\":{},\"body\":null}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-20 23:52:49', '2024-08-20 23:52:49', 32, 0, '', NULL, '2024-08-20 23:52:49', NULL, '2024-08-20 23:52:49', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825924454572888065, '', 1760311914397024258, 2, 'shengyu-server', 'GET', '/admin-api/system/notify-message/get-unread-count', '{\"query\":{},\"body\":null}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-20 23:54:49', '2024-08-20 23:54:49', 57, 0, '', NULL, '2024-08-20 23:54:49', NULL, '2024-08-20 23:54:49', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825924957851619329, '', 1760311914397024258, 2, 'shengyu-server', 'GET', '/admin-api/system/notify-message/get-unread-count', '{\"query\":{},\"body\":null}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-20 23:56:49', '2024-08-20 23:56:49', 51, 0, '', NULL, '2024-08-20 23:56:49', NULL, '2024-08-20 23:56:49', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825925461130350594, '', 1760311914397024258, 2, 'shengyu-server', 'GET', '/admin-api/system/notify-message/get-unread-count', '{\"query\":{},\"body\":null}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-20 23:58:49', '2024-08-20 23:58:49', 46, 0, '', NULL, '2024-08-20 23:58:49', NULL, '2024-08-20 23:58:49', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825925964467802113, '', 1760311914397024258, 2, 'shengyu-server', 'GET', '/admin-api/system/notify-message/get-unread-count', '{\"query\":{},\"body\":null}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-21 00:00:49', '2024-08-21 00:00:49', 22, 0, '', NULL, '2024-08-21 00:00:49', NULL, '2024-08-21 00:00:49', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825926467650064386, '', 1760311914397024258, 2, 'shengyu-server', 'GET', '/admin-api/system/notify-message/get-unread-count', '{\"query\":{},\"body\":null}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-21 00:02:49', '2024-08-21 00:02:49', 17, 0, '', NULL, '2024-08-21 00:02:49', NULL, '2024-08-21 00:02:49', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825926771611275265, '', 0, 0, 'shengyu-server', 'GET', '/platform-api/system/dict-data/list-all-simple', '{\"query\":{},\"body\":null}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-21 00:04:01', '2024-08-21 00:04:01', 50, 0, '', NULL, '2024-08-21 00:04:01', NULL, '2024-08-21 00:04:01', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825926771879710721, '', 0, 0, 'shengyu-server', 'POST', '/platform-api/system/auth/refresh-token', '{\"query\":{\"refreshToken\":\"78a39b94c2f24834aa3e1ec48ad30027\"},\"body\":null}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-21 00:04:01', '2024-08-21 00:04:01', 53, 400, '无效的刷新令牌', NULL, '2024-08-21 00:04:01', NULL, '2024-08-21 00:04:01', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825926800736522242, '', 0, 0, 'shengyu-server', 'POST', '/platform-api/system/captcha/get', '{\"query\":{},\"body\":\"{\\\"captchaType\\\":\\\"blockPuzzle\\\"}\"}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-21 00:04:08', '2024-08-21 00:04:08', 126, 0, '', NULL, '2024-08-21 00:04:08', NULL, '2024-08-21 00:04:08', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825926920450347010, '', 0, 0, 'shengyu-server', 'POST', '/platform-api/system/captcha/check', '{\"query\":{},\"body\":\"{\\\"captchaType\\\":\\\"blockPuzzle\\\",\\\"pointJson\\\":\\\"ON5KJF+ydZOUpp4D51fzwXDsi5Qj0GR495diRt4McCI=\\\",\\\"token\\\":\\\"86554833b8594f9a98c37a386fd112ba\\\"}\"}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-21 00:04:37', '2024-08-21 00:04:37', 62, 0, '', NULL, '2024-08-21 00:04:37', NULL, '2024-08-21 00:04:37', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825926926121046017, '', 0, 0, 'shengyu-server', 'POST', '/platform-api/system/auth/login', '{\"query\":{},\"body\":\"{\\\"username\\\":\\\"admin\\\",\\\"password\\\":\\\"36zhu186\\\",\\\"captchaVerification\\\":\\\"J8mePxlURn0NVqFbHmJ2MJnZFJw/PnWsM9H8ywEKJR+akV8Cvojq+rxJUqCJtlIegq6PyIiazHRDIJhtkX4//A==\\\",\\\"rememberMe\\\":false}\"}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-21 00:04:38', '2024-08-21 00:04:38', 282, 0, '', NULL, '2024-08-21 00:04:38', NULL, '2024-08-21 00:04:38', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825926926620168193, '', 1, 0, 'shengyu-server', 'GET', '/platform-api/system/dict-data/list-all-simple', '{\"query\":{},\"body\":null}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-21 00:04:38', '2024-08-21 00:04:38', 86, 0, '', NULL, '2024-08-21 00:04:38', NULL, '2024-08-21 00:04:38', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825926927173816321, '', 1, 0, 'shengyu-server', 'POST', '/platform-api/system/captcha/get', '{\"query\":{},\"body\":\"{\\\"captchaType\\\":\\\"blockPuzzle\\\"}\"}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-21 00:04:38', '2024-08-21 00:04:38', 83, 0, '', NULL, '2024-08-21 00:04:38', NULL, '2024-08-21 00:04:38', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825926927601635329, '', 1, 0, 'shengyu-server', 'GET', '/platform-api/system/auth/get-permission-info', '{\"query\":{},\"body\":null}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-21 00:04:38', '2024-08-21 00:04:38', 219, 0, '', NULL, '2024-08-21 00:04:38', NULL, '2024-08-21 00:04:38', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825926932345393154, '', 0, 0, 'shengyu-server', 'GET', '/platform-api/infra/file/4/get/37e56010ecbee472cdd821ac4b608e151e62a74d9633f15d085aee026eedeb60.png', '{\"query\":{},\"body\":null}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-21 00:04:39', '2024-08-21 00:04:39', 14, 0, '', NULL, '2024-08-21 00:04:39', NULL, '2024-08-21 00:04:39', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825926932626411521, '', 1, 0, 'shengyu-server', 'GET', '/platform-api/system/sms-template/page', '{\"query\":{\"code\":\"\",\"pageNo\":\"1\",\"pageSize\":\"10\",\"apiTemplateId\":\"\",\"content\":\"\"},\"body\":null}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-21 00:04:39', '2024-08-21 00:04:39', 161, 0, '', NULL, '2024-08-21 00:04:39', NULL, '2024-08-21 00:04:39', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825926932974538753, '', 1, 0, 'shengyu-server', 'GET', '/platform-api/system/sms-channel/list-all-simple', '{\"query\":{},\"body\":null}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-21 00:04:40', '2024-08-21 00:04:40', 42, 0, '', NULL, '2024-08-21 00:04:40', NULL, '2024-08-21 00:04:40', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825926974280044545, '', 1, 0, 'shengyu-server', 'GET', '/platform-api/system/tenant/page', '{\"query\":{\"pageNo\":\"1\",\"pageSize\":\"10\"},\"body\":null}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-21 00:04:49', '2024-08-21 00:04:49', 165, 0, '', NULL, '2024-08-21 00:04:49', NULL, '2024-08-21 00:04:49', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825926974540091393, '', 1, 0, 'shengyu-server', 'GET', '/platform-api/system/tenant-package/get-simple-list', '{\"query\":{},\"body\":null}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-21 00:04:49', '2024-08-21 00:04:49', 47, 0, '', NULL, '2024-08-21 00:04:49', NULL, '2024-08-21 00:04:49', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825926981112565762, '', 1, 0, 'shengyu-server', 'GET', '/platform-api/system/tenant-package/page', '{\"query\":{},\"body\":null}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-21 00:04:51', '2024-08-21 00:04:51', 152, 0, '', NULL, '2024-08-21 00:04:51', NULL, '2024-08-21 00:04:51', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825926985164263426, '', 1, 0, 'shengyu-server', 'GET', '/platform-api/system/tenant-menu/list', '{\"query\":{\"dimension\":\"0\"},\"body\":null}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-21 00:04:52', '2024-08-21 00:04:52', 152, 0, '', NULL, '2024-08-21 00:04:52', NULL, '2024-08-21 00:04:52', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825927014205624321, '', 1, 0, 'shengyu-server', 'GET', '/platform-api/system/user/profile/get', '{\"query\":{},\"body\":null}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-21 00:04:59', '2024-08-21 00:04:59', 162, 0, '', NULL, '2024-08-21 00:04:59', NULL, '2024-08-21 00:04:59', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825927014738300930, '', 1, 0, 'shengyu-server', 'GET', '/platform-api/system/user/profile/get', '{\"query\":{},\"body\":null}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-21 00:04:59', '2024-08-21 00:04:59', 127, 0, '', NULL, '2024-08-21 00:04:59', NULL, '2024-08-21 00:04:59', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825927014889295873, '', 0, 0, 'shengyu-server', 'GET', '/platform-api/infra/file/4/get/37e56010ecbee472cdd821ac4b608e151e62a74d9633f15d085aee026eedeb60.png', '{\"query\":{},\"body\":null}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-21 00:04:59', '2024-08-21 00:04:59', 27, 0, '', NULL, '2024-08-21 00:04:59', NULL, '2024-08-21 00:04:59', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825927015354863617, '', 1, 0, 'shengyu-server', 'GET', '/platform-api/system/user/profile/get', '{\"query\":{},\"body\":null}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-21 00:04:59', '2024-08-21 00:04:59', 147, 0, '', NULL, '2024-08-21 00:04:59', NULL, '2024-08-21 00:04:59', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825927339343876097, '', 1, 0, 'shengyu-server', 'POST', '/platform-api/system/user/profile/update-avatar', '{\"query\":{},\"body\":null}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-21 00:06:16', '2024-08-21 00:06:16', 692, 0, '', NULL, '2024-08-21 00:06:16', NULL, '2024-08-21 00:06:16', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825927466334818307, '', 1, 0, 'shengyu-server', 'PUT', '/platform-api/system/user/profile/update-password', '{\"query\":{},\"body\":\"{\\\"oldPassword\\\":\\\"36zhu186\\\",\\\"newPassword\\\":\\\"123456\\\"}\"}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-21 00:06:47', '2024-08-21 00:06:47', 103, 0, '', NULL, '2024-08-21 00:06:47', NULL, '2024-08-21 00:06:47', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825927521678659586, '', 1, 0, 'shengyu-server', 'GET', '/platform-api/system/dept/list-all-simple', '{\"query\":{},\"body\":null}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-21 00:07:00', '2024-08-21 00:07:00', 40, 0, '', NULL, '2024-08-21 00:07:00', NULL, '2024-08-21 00:07:00', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825927522307805185, '', 1, 0, 'shengyu-server', 'GET', '/platform-api/system/user/page', '{\"query\":{\"pageNo\":\"1\",\"pageSize\":\"10\"},\"body\":null}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-21 00:07:00', '2024-08-21 00:07:00', 190, 0, '', NULL, '2024-08-21 00:07:00', NULL, '2024-08-21 00:07:00', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825927535029129218, '', 1, 0, 'shengyu-server', 'GET', '/platform-api/system/user/get', '{\"query\":{\"id\":\"1\"},\"body\":null}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-21 00:07:03', '2024-08-21 00:07:03', 282, 0, '', NULL, '2024-08-21 00:07:03', NULL, '2024-08-21 00:07:03', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825927535310147585, '', 1, 0, 'shengyu-server', 'GET', '/platform-api/system/dept/list-all-simple', '{\"query\":{},\"body\":null}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-21 00:07:03', '2024-08-21 00:07:03', 51, 0, '', NULL, '2024-08-21 00:07:03', NULL, '2024-08-21 00:07:03', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825927535595360257, '', 1, 0, 'shengyu-server', 'GET', '/platform-api/system/post/list-all-simple', '{\"query\":{},\"body\":null}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-21 00:07:03', '2024-08-21 00:07:03', 66, 0, '', NULL, '2024-08-21 00:07:03', NULL, '2024-08-21 00:07:03', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825927613928181761, '', 1, 0, 'shengyu-server', 'GET', '/platform-api/system/user/get', '{\"query\":{\"id\":\"1\"},\"body\":null}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-21 00:07:22', '2024-08-21 00:07:22', 171, 0, '', NULL, '2024-08-21 00:07:22', NULL, '2024-08-21 00:07:22', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825927614272114689, '', 1, 0, 'shengyu-server', 'GET', '/platform-api/system/dept/list-all-simple', '{\"query\":{},\"body\":null}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-21 00:07:22', '2024-08-21 00:07:22', 43, 0, '', NULL, '2024-08-21 00:07:22', NULL, '2024-08-21 00:07:22', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825927614486024193, '', 1, 0, 'shengyu-server', 'GET', '/platform-api/system/post/list-all-simple', '{\"query\":{},\"body\":null}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-21 00:07:22', '2024-08-21 00:07:22', 55, 0, '', NULL, '2024-08-21 00:07:22', NULL, '2024-08-21 00:07:22', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825927685000663042, '', 1, 0, 'shengyu-server', 'POST', '/platform-api/system/auth/logout', '{\"query\":{},\"body\":null}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-21 00:07:39', '2024-08-21 00:07:39', 214, 0, '', NULL, '2024-08-21 00:07:39', NULL, '2024-08-21 00:07:39', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825927686250565633, '', 0, 0, 'shengyu-server', 'POST', '/platform-api/system/captcha/get', '{\"query\":{},\"body\":\"{\\\"captchaType\\\":\\\"blockPuzzle\\\"}\"}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-21 00:07:39', '2024-08-21 00:07:39', 100, 0, '', NULL, '2024-08-21 00:07:39', NULL, '2024-08-21 00:07:39', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825927738327044098, '', 0, 0, 'shengyu-server', 'POST', '/platform-api/system/captcha/check', '{\"query\":{},\"body\":\"{\\\"captchaType\\\":\\\"blockPuzzle\\\",\\\"pointJson\\\":\\\"qGwqhuEaQp72/RVlF4qPlBLbSVJdEAFlL49yQcSOJCo=\\\",\\\"token\\\":\\\"7a82e160ffb749ae9b9b6c08df905ab1\\\"}\"}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-21 00:07:51', '2024-08-21 00:07:52', 181, 0, '', NULL, '2024-08-21 00:07:52', NULL, '2024-08-21 00:07:52', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825927744199069698, '', 0, 0, 'shengyu-server', 'POST', '/platform-api/system/auth/login', '{\"query\":{},\"body\":\"{\\\"username\\\":\\\"admin\\\",\\\"password\\\":\\\"123456\\\",\\\"captchaVerification\\\":\\\"Ft6g1HNgeIcoaycrk6ExMJEGDxhvDCNG8Ai+kdWAZfgMDLHBkY8IdcVIsUwGZNMBMykswF8nrJw1Lk4K184Cdg==\\\",\\\"rememberMe\\\":false}\"}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-21 00:07:53', '2024-08-21 00:07:53', 324, 0, '', NULL, '2024-08-21 00:07:53', NULL, '2024-08-21 00:07:53', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825927744970821634, '', 1, 0, 'shengyu-server', 'POST', '/platform-api/system/captcha/get', '{\"query\":{},\"body\":\"{\\\"captchaType\\\":\\\"blockPuzzle\\\"}\"}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-21 00:07:53', '2024-08-21 00:07:53', 66, 0, '', NULL, '2024-08-21 00:07:53', NULL, '2024-08-21 00:07:53', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825927745604161538, '', 1, 0, 'shengyu-server', 'GET', '/platform-api/system/auth/get-permission-info', '{\"query\":{},\"body\":null}', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-21 00:07:53', '2024-08-21 00:07:53', 301, 0, '', NULL, '2024-08-21 00:07:53', NULL, '2024-08-21 00:07:53', b'0', 0);
INSERT INTO `infra_api_access_log` VALUES (1825927748800221185, '', 0, 0, 'shengyu-server', 'GET', '/platform-api/infra/file/4/get/098aab3cb5a9e33ec18ab3bf1ae28f338627f28d92b023d4fd441c098f760f77.png', '{\"query\":{},\"body\":null}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '2024-08-21 00:07:54', '2024-08-21 00:07:54', 28, 0, '', NULL, '2024-08-21 00:07:54', NULL, '2024-08-21 00:07:54', b'0', 0);

-- ----------------------------
-- Table structure for infra_api_error_log
-- ----------------------------
DROP TABLE IF EXISTS `infra_api_error_log`;
CREATE TABLE `infra_api_error_log`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `trace_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '链路追踪编号\n     *\n     * 一般来说，通过链路追踪编号，可以将访问日志，错误日志，链路追踪日志，logger 打印日志等，结合在一起，从而进行排错。',
  `user_id` bigint NOT NULL DEFAULT 0 COMMENT '用户编号',
  `user_type` tinyint NOT NULL DEFAULT 0 COMMENT '用户类型',
  `application_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '应用名\n     *\n     * 目前读取 spring.application.name',
  `request_method` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '请求方法名',
  `request_url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '请求地址',
  `request_params` varchar(8000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '请求参数',
  `user_ip` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '用户 IP',
  `user_agent` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '浏览器 UA',
  `exception_time` datetime NOT NULL COMMENT '异常发生时间',
  `exception_name` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '异常名\n     *\n     * {@link Throwable#getClass()} 的类全名',
  `exception_message` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '异常导致的消息\n     *\n     * {@link cn.iocoder.common.framework.util.ExceptionUtil#getMessage(Throwable)}',
  `exception_root_cause_message` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '异常导致的根消息\n     *\n     * {@link cn.iocoder.common.framework.util.ExceptionUtil#getRootCauseMessage(Throwable)}',
  `exception_stack_trace` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '异常的栈轨迹\n     *\n     * {@link cn.iocoder.common.framework.util.ExceptionUtil#getServiceException(Exception)}',
  `exception_class_name` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '异常发生的类全名\n     *\n     * {@link StackTraceElement#getClassName()}',
  `exception_file_name` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '异常发生的类文件\n     *\n     * {@link StackTraceElement#getFileName()}',
  `exception_method_name` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '异常发生的方法名\n     *\n     * {@link StackTraceElement#getMethodName()}',
  `exception_line_number` int NOT NULL COMMENT '异常发生的方法所在行\n     *\n     * {@link StackTraceElement#getLineNumber()}',
  `process_status` tinyint NOT NULL COMMENT '处理状态',
  `process_time` datetime NULL DEFAULT NULL COMMENT '处理时间',
  `process_user_id` bigint NULL DEFAULT 0 COMMENT '处理用户编号',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1809942452816433155 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '系统异常日志' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of infra_api_error_log
-- ----------------------------

-- ----------------------------
-- Table structure for infra_codegen_column
-- ----------------------------
DROP TABLE IF EXISTS `infra_codegen_column`;
CREATE TABLE `infra_codegen_column`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `table_id` bigint NOT NULL COMMENT '表编号',
  `column_name` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '字段名',
  `data_type` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '字段类型',
  `column_comment` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '字段描述',
  `nullable` bit(1) NOT NULL COMMENT '是否允许为空',
  `primary_key` bit(1) NOT NULL COMMENT '是否主键',
  `auto_increment` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '是否自增',
  `ordinal_position` int NOT NULL COMMENT '排序',
  `java_type` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Java 属性类型',
  `java_field` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Java 属性名',
  `dict_type` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '字典类型',
  `example` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '数据示例',
  `create_operation` bit(1) NOT NULL COMMENT '是否为 Create 创建操作的字段',
  `update_operation` bit(1) NOT NULL COMMENT '是否为 Update 更新操作的字段',
  `list_operation` bit(1) NOT NULL COMMENT '是否为 List 查询操作的字段',
  `list_operation_condition` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '=' COMMENT 'List 查询操作的条件类型',
  `list_operation_result` bit(1) NOT NULL COMMENT '是否为 List 查询操作的返回字段',
  `html_type` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '显示类型',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 2000 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '代码生成表字段定义' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of infra_codegen_column
-- ----------------------------

-- ----------------------------
-- Table structure for infra_codegen_table
-- ----------------------------
DROP TABLE IF EXISTS `infra_codegen_table`;
CREATE TABLE `infra_codegen_table`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `data_source_config_id` bigint NOT NULL COMMENT '数据源配置的编号',
  `scene` tinyint NOT NULL DEFAULT 1 COMMENT '生成场景',
  `table_name` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '表名称',
  `table_comment` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '表描述',
  `remark` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '备注',
  `module_name` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '模块名',
  `business_name` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '业务名',
  `class_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '类名称',
  `class_comment` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '类描述',
  `author` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '作者',
  `template_type` tinyint NOT NULL DEFAULT 1 COMMENT '模板类型',
  `front_type` tinyint NOT NULL COMMENT '前端类型',
  `parent_menu_id` bigint NULL DEFAULT NULL COMMENT '父菜单编号',
  `master_table_id` bigint NULL DEFAULT NULL COMMENT '主表的编号',
  `sub_join_column_id` bigint NULL DEFAULT NULL COMMENT '子表关联主表的字段编号',
  `sub_join_many` bit(1) NULL DEFAULT NULL COMMENT '主表与子表是否一对多',
  `tree_parent_column_id` bigint NULL DEFAULT NULL COMMENT '树表的父字段编号',
  `tree_name_column_id` bigint NULL DEFAULT NULL COMMENT '树表的名字字段编号',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 155 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '代码生成表定义' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of infra_codegen_table
-- ----------------------------

-- ----------------------------
-- Table structure for infra_config
-- ----------------------------
DROP TABLE IF EXISTS `infra_config`;
CREATE TABLE `infra_config`  (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '参数主键',
  `category` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '参数分组',
  `type` tinyint NOT NULL COMMENT '参数类型',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '参数名称',
  `config_key` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '参数键名',
  `value` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '参数键值',
  `visible` bit(1) NOT NULL COMMENT '是否可见',
  `remark` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '备注',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 12 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '参数配置表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of infra_config
-- ----------------------------
INSERT INTO `infra_config` VALUES (2, 'biz', 1, '用户管理-账号初始密码', 'sys.user.init-password', '123456', b'0', '初始化密码 123456', 'admin', '2021-01-05 17:03:48', '1', '2022-03-20 02:25:51', b'0');
INSERT INTO `infra_config` VALUES (7, 'url', 2, 'MySQL 监控的地址', 'url.druid', '', b'1', '', '1', '2023-04-07 13:41:16', '1', '2023-04-07 14:33:38', b'0');
INSERT INTO `infra_config` VALUES (8, 'url', 2, 'SkyWalking 监控的地址', 'url.skywalking', '', b'1', '', '1', '2023-04-07 13:41:16', '1', '2023-04-07 14:57:03', b'0');
INSERT INTO `infra_config` VALUES (9, 'url', 2, 'Spring Boot Admin 监控的地址', 'url.spring-boot-admin', '', b'1', '', '1', '2023-04-07 13:41:16', '1', '2023-04-07 14:52:07', b'0');
INSERT INTO `infra_config` VALUES (10, 'url', 2, 'Swagger 接口文档的地址', 'url.swagger', '', b'1', '', '1', '2023-04-07 13:41:16', '1', '2023-04-07 14:59:00', b'0');
INSERT INTO `infra_config` VALUES (11, 'ui', 2, '腾讯地图 key', 'tencent.lbs.key', 'TVDBZ-TDILD-4ON4B-PFDZA-RNLKH-VVF6E', b'1', '腾讯地图 key', '1', '2023-06-03 19:16:27', '1', '2023-06-03 19:16:27', b'0');

-- ----------------------------
-- Table structure for infra_data_source_config
-- ----------------------------
DROP TABLE IF EXISTS `infra_data_source_config`;
CREATE TABLE `infra_data_source_config`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键编号',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '参数名称',
  `url` varchar(1024) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '数据源连接',
  `username` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '用户名',
  `password` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '密码',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 13 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '数据源配置表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of infra_data_source_config
-- ----------------------------

-- ----------------------------
-- Table structure for infra_file
-- ----------------------------
DROP TABLE IF EXISTS `infra_file`;
CREATE TABLE `infra_file`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '文件编号',
  `config_id` bigint NULL DEFAULT NULL COMMENT '配置编号',
  `name` varchar(256) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '文件名',
  `path` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '文件路径',
  `url` varchar(1024) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '文件 URL',
  `type` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '文件类型',
  `size` int NOT NULL COMMENT '文件大小',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1825927338895085571 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '文件表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of infra_file
-- ----------------------------
INSERT INTO `infra_file` VALUES (1825927338895085570, 4, '098aab3cb5a9e33ec18ab3bf1ae28f338627f28d92b023d4fd441c098f760f77.png', '098aab3cb5a9e33ec18ab3bf1ae28f338627f28d92b023d4fd441c098f760f77.png', 'http://127.0.0.1:48080/platform-api/infra/file/4/get/098aab3cb5a9e33ec18ab3bf1ae28f338627f28d92b023d4fd441c098f760f77.png', 'image/png', 39285, '1', '2024-08-21 00:06:16', '1', '2024-08-21 00:06:16', b'0');

-- ----------------------------
-- Table structure for infra_file_config
-- ----------------------------
DROP TABLE IF EXISTS `infra_file_config`;
CREATE TABLE `infra_file_config`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `name` varchar(63) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '配置名',
  `storage` tinyint NOT NULL COMMENT '存储器',
  `remark` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '备注',
  `master` bit(1) NOT NULL COMMENT '是否为主配置',
  `config` varchar(4096) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '存储配置',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 18 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '文件配置表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of infra_file_config
-- ----------------------------
INSERT INTO `infra_file_config` (`id`, `name`, `storage`, `remark`, `master`, `config`, `creator`, `create_time`, `updater`, `update_time`, `deleted`) VALUES (4, '数据库（示例）', 1, '我是数据库', b'0', '{\"@class\":\"com.shengyu.framework.file.core.client.db.DBFileClientConfig\",\"domain\":\"http://127.0.0.1:48080\"}', '1', '2022-03-15 23:56:24', '1', '2025-11-24 20:57:14', b'0');
INSERT INTO `infra_file_config` (`id`, `name`, `storage`, `remark`, `master`, `config`, `creator`, `create_time`, `updater`, `update_time`, `deleted`) VALUES (22, '七牛存储器（示例）', 20, '请换成你自己的密钥！！！', b'1', '{\"@class\":\"com.shengyu.framework.file.core.client.s3.S3FileClientConfig\",\"endpoint\":\"s3.cn-south-1.qiniucs.com\",\"domain\":\"http://test.yudao.iocoder.cn\",\"bucket\":\"ruoyi-vue-pro\",\"accessKey\":\"3TvrJ70gl2Gt6IBe7_IZT1F6i_k0iMuRtyEv4EyS\",\"accessSecret\":\"wd0tbVBYlp0S-ihA8Qg2hPLncoP83wyrIq24OZuY\",\"enablePathStyleAccess\":false,\"enablePublicAccess\":true}', '1', '2024-01-13 22:11:12', '1', '2025-11-24 20:57:14', b'0');
INSERT INTO `infra_file_config` (`id`, `name`, `storage`, `remark`, `master`, `config`, `creator`, `create_time`, `updater`, `update_time`, `deleted`) VALUES (24, '腾讯云存储（示例）', 20, '请换成你的密钥！！！', b'0', '{\"@class\":\"com.shengyu.framework.file.core.client.s3.S3FileClientConfig\",\"endpoint\":\"https://cos.ap-shanghai.myqcloud.com\",\"domain\":\"http://tengxun-oss.iocoder.cn\",\"bucket\":\"aoteman-1255880240\",\"accessKey\":\"AKIDAF6WSh1uiIjwqtrOsGSN3WryqTM6cTMt\",\"accessSecret\":\"X\",\"enablePathStyleAccess\":false,\"enablePublicAccess\":true}', '1', '2024-11-09 16:03:22', '1', '2025-11-24 20:57:14', b'0');
INSERT INTO `infra_file_config` (`id`, `name`, `storage`, `remark`, `master`, `config`, `creator`, `create_time`, `updater`, `update_time`, `deleted`) VALUES (25, '阿里云存储（示例）', 20, '', b'0', '{\"@class\":\"com.shengyu.framework.file.core.client.s3.S3FileClientConfig\",\"endpoint\":\"oss-cn-beijing.aliyuncs.com\",\"domain\":\"http://ali-oss.iocoder.cn\",\"bucket\":\"yunai-aoteman\",\"accessKey\":\"LTAI5tEQLgnDyjh3WpNcdMKA\",\"accessSecret\":\"X\",\"enablePathStyleAccess\":false,\"enablePublicAccess\":true}', '1', '2024-11-09 16:47:08', '1', '2025-11-24 20:57:14', b'0');
INSERT INTO `infra_file_config` (`id`, `name`, `storage`, `remark`, `master`, `config`, `creator`, `create_time`, `updater`, `update_time`, `deleted`) VALUES (26, '火山云存储（示例）', 20, '', b'0', '{\"@class\":\"com.shengyu.framework.file.core.client.s3.S3FileClientConfig\",\"endpoint\":\"tos-s3-cn-beijing.volces.com\",\"domain\":null,\"bucket\":\"yunai\",\"accessKey\":\"AKLTZjc3Zjc4MzZmMjU3NDk0ZTgxYmIyMmFkNTIwMDI1ZGE\",\"accessSecret\":\"X==\",\"enablePathStyleAccess\":false,\"enablePublicAccess\":true}', '1', '2024-11-09 16:56:42', '1', '2025-11-24 20:57:14', b'0');
INSERT INTO `infra_file_config` (`id`, `name`, `storage`, `remark`, `master`, `config`, `creator`, `create_time`, `updater`, `update_time`, `deleted`) VALUES (27, '华为云存储（示例）', 20, '', b'0', '{\"@class\":\"com.shengyu.framework.file.core.client.s3.S3FileClientConfig\",\"endpoint\":\"obs.cn-east-3.myhuaweicloud.com\",\"domain\":\"\",\"bucket\":\"yudao\",\"accessKey\":\"PVDONDEIOTW88LF8DC4U\",\"accessSecret\":\"X\",\"enablePathStyleAccess\":false,\"enablePublicAccess\":true}', '1', '2024-11-09 17:18:41', '1', '2025-11-24 20:57:14', b'0');
INSERT INTO `infra_file_config` (`id`, `name`, `storage`, `remark`, `master`, `config`, `creator`, `create_time`, `updater`, `update_time`, `deleted`) VALUES (28, 'MinIO 存储（示例）', 20, '', b'0', '{\"@class\":\"com.shengyu.framework.file.core.client.s3.S3FileClientConfig\",\"endpoint\":\"http://127.0.0.1:9000\",\"domain\":\"http://127.0.0.1:9000/yudao\",\"bucket\":\"yudao\",\"accessKey\":\"admin\",\"accessSecret\":\"password\",\"enablePathStyleAccess\":false,\"enablePublicAccess\":true}', '1', '2024-11-09 17:43:10', '1', '2025-11-24 20:57:14', b'0');
INSERT INTO `infra_file_config` (`id`, `name`, `storage`, `remark`, `master`, `config`, `creator`, `create_time`, `updater`, `update_time`, `deleted`) VALUES (29, '本地存储（示例）', 10, 'mac/linux 使用 /，windows 使用 \\', b'0', '{\"@class\":\"com.shengyu.framework.file.core.client.local.LocalFileClientConfig\",\"basePath\":\"/Users/yunai/tmp/file\",\"domain\":\"http://127.0.0.1:48080\"}', '1', '2025-05-02 11:25:45', '1', '2025-11-24 20:57:14', b'0');
INSERT INTO `infra_file_config` (`id`, `name`, `storage`, `remark`, `master`, `config`, `creator`, `create_time`, `updater`, `update_time`, `deleted`) VALUES (30, 'SFTP 存储（示例）', 12, '', b'0', '{\"@class\":\"com.shengyu.framework.file.core.client.sftp.SftpFileClientConfig\",\"basePath\":\"/upload\",\"domain\":\"http://127.0.0.1:48080\",\"host\":\"127.0.0.1\",\"port\":2222,\"username\":\"foo\",\"password\":\"pass\"}', '1', '2025-05-02 16:34:10', '1', '2025-11-24 20:57:14', b'0');
INSERT INTO `infra_file_config` (`id`, `name`, `storage`, `remark`, `master`, `config`, `creator`, `create_time`, `updater`, `update_time`, `deleted`) VALUES (34, '七牛云存储【私有】（示例）', 20, '请换成你自己的密钥！！！', b'0', '{\"@class\":\"com.shengyu.framework.file.core.client.s3.S3FileClientConfig\",\"endpoint\":\"s3.cn-south-1.qiniucs.com\",\"domain\":\"http://t151glocd.hn-bkt.clouddn.com\",\"bucket\":\"ruoyi-vue-pro-private\",\"accessKey\":\"3TvrJ70gl2Gt6IBe7_IZT1F6i_k0iMuRtyEv4EyS\",\"accessSecret\":\"wd0tbVBYlp0S-ihA8Qg2hPLncoP83wyrIq24OZuY\",\"enablePathStyleAccess\":false,\"enablePublicAccess\":false}', '1', '2025-08-17 21:22:00', '1', '2025-11-24 20:57:14', b'0');
INSERT INTO `infra_file_config` (`id`, `name`, `storage`, `remark`, `master`, `config`, `creator`, `create_time`, `updater`, `update_time`, `deleted`) VALUES (35, '1', 20, '1', b'0', '{\"@class\":\"com.shengyu.framework.file.core.client.s3.S3FileClientConfig\",\"endpoint\":\"http://www.baidu.com\",\"domain\":\"http://www.xxx.com\",\"bucket\":\"1\",\"accessKey\":\"2\",\"accessSecret\":\"3\",\"enablePathStyleAccess\":false,\"enablePublicAccess\":false}', '1', '2025-10-02 14:32:12', '1', '2025-11-24 20:57:14', b'0');

-- ----------------------------
-- Table structure for infra_file_content
-- ----------------------------
DROP TABLE IF EXISTS `infra_file_content`;
CREATE TABLE `infra_file_content`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `config_id` bigint NOT NULL COMMENT '配置编号',
  `path` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '文件路径',
  `content` mediumblob NOT NULL COMMENT '文件内容',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 232 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '文件表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of infra_file_content
-- ----------------------------
INSERT INTO `infra_file_content` VALUES (231, 4, '098aab3cb5a9e33ec18ab3bf1ae28f338627f28d92b023d4fd441c098f760f77.png', 0x89504E470D0A1A0A0000000D49484452000000D8000000D8080600000089202DED000000017352474200AECE1CE90000200049444154785EECBD779C1CD77DE0F9ADAECED33D3903839C010204C04C30805112152D8A3225D996B56BEFAEEDB577F7EE739FDB8B7BF7B9BDBB3F6E6FCFBBEBF5DAD63AC9A202458914B3488260260012890091893839CF740E55C7DFABAA4ED33DDD330048D09EE2A78999E9AA57EFFDDE2FA7A7B1702D40600102570D02DA551B7961E005082C408005025B408205085C45082C10D85504EEC2D00B105820B0051C5880C05584C002815D45E02E0CBD008105025BC08105085C45082C10D85504EEC2D00B105820B0051C5880C05584C002815D45E02E0CBD008105025BC08105085C45082C10D85504EEC2D00B105820B0051C5880C05584C002815D45E02E0CBD008105025BC08105085C45082C10D85504EEC2D00B105820B0051C5880C05584C002815D45E02E0CBD0081CF348199A6F9DF03FFD7C236FEBD86C0BFD634EDFFFEACAEF0334960A669AE03FE0370FF6715F00BF39E13045E02FE50D3B4E3737AEA1AB8F9334760A6697E0FF813C07F0DC06F610A9F1C0412C0EF6B9AF6979FDC2B2FFF4D9F2902334DF3CF80DFBDFC652F8CF01986C09F6B9AF64F3E2BF3FF4C1098699A5B80BF006EFCAC0076619E571502FB80DFD134EDD0557DCB1518FC9A2730D3341F05442D585009AFC086FF3D1A4254C6EF699AF6A36B794DD7348199A6F9BF7E0CBC7F732D0370616E9F3A04FE8DA669FFDBA73E8B0A13B86609CC34CDBF067EEB5A05DCC2BCAE2908FC8DA669DFBDA666644FE69A2330D334DB0011FBF75E8B005B98D3350B81578047354D1BBE9666784D1198699A1B809F021BAF25202DCCE5330381A3C0239AA67D78ADCCF89A2130D3346F039E003AAF15E02CCCE333098101E0EB9AA6BD7D2DCCFE9A2030D3341F007E0104AF05A02CCCE1330F8118F0354DD37EF569AFE4532730D334BF04FCF2D306C4C2FBFF5E42E0CB9AA63DFD69AEEC532530D334BF6A4BAE4F13060BEFFEFB0D0191644F7E5A4BFCD4086C41727D5A5BFE0FF2BD9F9A24FB5408CCB6B95EBC16B7DA849ACE74AAF5BE6B718DFF40E7F4E0A761937DE204667B0BA5FCE0937568D44011728B73CD06985AEFFB078AC8D7EAB2C5F171FF27ED5DFC4409CC8E734940F09A75C5D740870A816ABDEF5AC5B67FA0F31217FEBD9F649CEC1323303B43E3D5CB0E227F5A98FD69BDF71F28255CC5654B307AE72795F1F14912D8CBE5D29FAE5DBCBD7667761591EF1FCAD0AF689A76DF27B1D84F84C02A25EE5EBBB68CCCCC21B04F04449FC45E2FBCA318029F4882F055C79E4A252785C425EBAE34912B2747AEDC480B98FAF7060257BDD4E5AA12985D2CF958E9769412575902B3E9C1B977DE1355E35C03126981BEAF55AAFCD6D52CDA9C37DE5683965DE6FF6EA54AE4CAEA61312656C44BB3944C4B49B1DCF7B2DC324BD6AE1A18AA8169E1FB4F1F0252197DCBD56A3F70D530CB34CDBD73EAA1A1E8C1B4A54D7942300D836C26637FD26433598C6C16D334304CF9D9C4A23B476259F4A459FF43C385CBA5E3D27534970B5DB77F77BBD13D1E74F9FB02B17DFA28FFC9CF609FA669375D8DD75E1502ABADFB5325D9644B1E4523068A62E4934E119B9C647C7484C9B131A626C6999E9C2416899288C7482462A41249324280D90C428C72B98490DCBA221EB7C78BDF1FC45F17241008120C85A80B8769686AA6B1A595FAA626BCC13A70BB41084D7D5C16DC2B10DE82E67735D0F25319F3AA74ABBAE20466F72DFCAFB383A89A4D649288C5181F1E626C608089E121A6C64698181E666A7494C8C4B8FA44A7A6D47DC9788C6432463A91229B4E6318594C239B23309158F21102F3FA83F88241FC8120BEBA20C17098706333F54D2D849B9B09373553DFD242434B2B4DAD6DEAE3ABAB134A9DB1A43979411728F153A19A39BEF41F5DE9BE8B5794C0EC8EBB076AEB0055807122A18C2CC9C8349323C34C8E8E30DCD7CBC5B31F71E1A38FB874FE3CE32343A4E271CC6C160CC32220C3405312CE9274F29FA51DE65544510F4D7B959A92461AB86CC924524908C7A5AB8FCBED26100CD2D2DE41F792252CEA91CF525A3B3B09B70801B650D7D884CBE7B3259AB690D131470CBEC66F177B6CEB95EC207CA5094C0ADCE6D4CE5A244E221A656A7C94DE53273975F820678F1D65B4F702D1E96992B1985201D3A91418A6A5A9D9EA9AD84B96B5E6A873167D3997B3B89CFBC3263E8BFC1C55D4B2DB0C4C35964B73E1F1F9F00702F8FC4102C1100DED1D2C5EB99225EB37D0B36E8322387F38ACA4A0EEF65CE338B330BD3942E0A58FF315A500F88A5C578CC0E6741083481C41F06482A10B17397EE800278F7CC08533A718BC7491F1916152D1884278DDA5E11242B289C95975458D4B1E2A7120AA5FEDBFE7BE169A149F4AC9EDA66962D8D250CC38C3048FDF4FBDD869EDEDB47575B368F94A566FD8C8CAF51B68ED5A841608D82AE41503E715D9DC8541E60D812B76E0C415C108D334B702FB6B5D4E36956078B09F731F1CE6C4FEF73979E07DFACF9C261299561E41714CCCE7B2049BA5265AB2CDBA14395B8EC41CF1A9DF4D903715F81CED276C6FA6D22DAD7184F0C471A26B2EC22D6DF4AC5CAD24DA92751B58BA6E3D5D2B56100C856B2C7699CFEA169EF98421B04DD33431772EEBBA52045636CF70C6CC4C83542442EFE913EC7FEB75DE7BEB4D2E9D3EAD6C2F2D935648AC267459B392318A07289460B9391548B402BA2B9872898C2C88BB9962B3E96EDCFE202D5DDDACDF723D5B6EBA89A5ABD7D2BAA8077F7D8388DE9A16329B2FB53C18FE7E784BE6BF8AB93E39D7FB73287045F2152F0B956DCEFE87C01F572373C330484E4F72E6E811DE79E1593E786337230303649262572AE3879C13A28C4C51F768056522A571E46A13B882DF2B35521C2D26783D5E02E17ADABBBB59BE792B5B6EBF93959B36116E6BC3EF0FE4DDFC65DE5FC90B59D93B59CDFB7A251759137F98D70BE7E47D2D7AC35CD73FD7FB672CE78F344D9363B2E67D5D168199A6B9F8E3668F272A154FE69D0B06B1F1718EBFBF97375F7C8E83EFBCCDE4409FF200BA451DB409C75A856315E5394FA1B3A254D59BF7CAAFD083426499AC81E6D6A96F6E63F18A95ACDF7603DB6EDFC1CA0D1BF1D437E6636A1588ACDC2694F25D798F26CA6E616C3027556DEF69E1F89637C802A7F29E8AB7543CAAE5E4FB65A1C13C21395FC932B7E7C49955BAE2394C588A34D76A9A76690ECF14DD7A5990ADD6DEDAE11F8989318EECDBCB1B4FFF82A36FBFCED4F884E5292F0DDEE62494FDA46D03399650395B6ABE0BBF2ACF19062E53A3A16B31EBB6DDC0A6DB6E67FDCDB7D0B578092EAFF7B25E99CD9A4A959E9E185541F6C8E404F148546900994C9AB4C4FFB219854CBAA8AF12F30B0408D4D5110C37A8585F435B2BFE7008DDA53B96E595AF1AA809FF2F5BB2D404CBF94BCAA2E12F2BEB7EDE0456535F0D510BA3118EEFDBC3AE5FFE8283EFBE457464C8F20A2A965CE6F53971555E82CD70FBD504EAAB7D9335695993521F7537BA3F40C79265DCB2732737EFBC8F456BD6A980B5A9A489B5F579CE9A93F5F644ADEC153391606A7CCC8E0D8E323A34C8705F1FC383038C48F07D62C20AB4271324530932E98C82ADDBE3C1EBF3110A8569686CA2A1B985B6CE2EBA7A16D3DAD9417DB304D1DB09B734E3F2CBA135B5D98B57168AD6FED6448F052F9E21D9AB68B2731DBFC21AE7DDCFE37208EC6D306F9DAD6E2A1B8B71FAE807ECFAF9E31CD8F512E3A3C30AA4A592AB5005BCB29B78F547B349CB8EA2599CD9B1D1748F5721F6E6BB7672EB17BEC8CAF59BF0D537D821076BEB2D22CB7374C33049C6A34A428D5DBAC4D9631F72E6C821FACF9E617A7C4205DBD3A924A954926C5AD2C2B22A734565AFD82AA31099CA5C1149E6F6E0F67AF1F8FCF88201EA1AEAE958B682D5D76D65C5A64DB4F42C215CDFA0325CE6EBBD9D2F94E72A614AEF9FEBF3F39D27F0CEC70D73A4F3F49CAF791198699ABF03FC792162946ABA6626C3E8B98FF8D5CF1F67D733BF64B2EFA24224BD446A55E230E538D59C5737CF072AD944E5869B8D396415C26B843B3AD97ADB0EEEFCFC1759BBED06020D8DB62D54F0B49D6F19191DE5D491C31CD9FF1E17CF9C66B8B797D1C1012293E32AC95959534E5CD04E64AE949FAC420B4A185AB13D998FCBAD53D7D0484B47371D3D3DAC58BB968DDB6E64C5868DD4353583DB5B31EF729EE09CF5B1B94A98B94AB02B38E7DFD5344D0E819CD3355F023B072C7508CC72AE3BBCDC4AD21D1DECE7BD179F67D7E33FE6F48963E8A691935CCEDD0EDF76665CFAF74AF7CD6985F3B839BF1AEBE1D279CE1C7266DCACF09E8C61D0D8D4CCC6DBEE64C7435FE1BA1B6FC2DFD49C97E4A6C9E4D828E73EFC8053070F7062FF7B9C3FF6011323A390CDA289CBDF262A2B25ECF2AE9C8475BB696D6B67E9C6EB58B3FD46D66EDDCE92B51BA89330C34255412990CF6B9AB66CAE909F3381CDCCD898A94B1BB188B2B77EF9B77FC3C97DEF92492571D96851EAD5990D590A27577A5F79C951FC8463E358CF56E17D1275B65F32132896AD302345A408DA9579B17C231224D0D4C2E61B6FE19E2F7F8D8DB7DC8A3FDC8091C930D67B91C37BDE61CF6BAF72EA83434C8F8FA2A5D38A51A9B938A96105D65BFED5B5935BE1BA643EAA80C7E5C2F078543AD8C6AD3770E38EBB58B7751B4DDD8B2DC74CD52A826A8A5AC9FCAA89A0A2EF6741CFB98ABEB95246F9FBE79CE1312702334DB30E105DAFA992752ADC71E0E4315EFEC5E3BCF6ECD34CF55E54A52239F4D49C9AADF20E8E1CDCCAE08D63AD289C2B45771B612CC3D992394EA6A245D422655C2581B4BC8C34353BC85D165F2F5F963AEA5A7D43039BEED8C9DD5F7B98556BD632323EC97B2FBFC07BBB7E45FFF9732A5628769826714197AB824F677EF329F7544E9AB95C041B9A58B46C255B77DECBF67BEEA77BE9323CC1E00C9B390F221BAE39642C96FDB93ABD8C61D5ED49EE99A8ABCA4EB593B21D679792D0E26EB1D6ED925A3DDDAD3E656BF49C49CC09832F9BCAC6811E4DD3A2B58E34A7E9553DD2556242C938EF3EFF0C4FFECDF7B970F204AE6452214B6E534A2863063EABEFF3D32A941D7989E46CA4A1F29D3432A0A56D9F9438F3ED5C472B7DD726478901B8314D0FA669FFCD8E093904995708AD9FCACE42B51F280ADC558075318B95B1446AC8A7AEB543D964EB376CE4FCC54B1C7CE74D862F9EC348A771DBE18BD9E5D26CB2BDF2D6CF469642681913E5DE6F5BB28C1BEFB89BDBEE7F80651B37E1951430A72ECE1E5EADCE89C9A9F4B4C28F01998C4AD48E47A344231162D108C94442951365B259654F8AD753AA2234978EEE71E3D65DB8DD6E7CFE007E092FD459F57A75752150150C56CC144D2FA8D79B130AD74A17B3DD37A73E1E35CFCE965EBD4043A5B79BE9147D172FF0ABC7FE96DD4FFC98E8E4141E5D5712A5549170E8AC3C22E551A190C09C2A14D3D4A452055C061E8F8EDF6FE0F767F17834DC6EC96514F8CBC82EA9821133864CC62499D049265CA4522699ACC53173F158E7E78299CE404891BE2A87B11A8195B7C99C358BB3A1A9A585D69636464646191F1B41AF7927E68F231509AC3043C630C9A2D1DADEC1E63BEEE696071F62FDB66D041A9B67BC58D4DB7834C2D4B8C4E5C6894A01ECE40491E92962B10889E928C9688C442C4A221621954CD8D5E85955146B088149905EA495C7ADE273521CEBF5FBF1AA9ABD3A95DF293661A8A191BAFA7AEA1A1B68686DA7B9BD43119FA6BBE70F90F93D39092CAA558AD5BCADA669FE0FC0BF75E6544E954E4D8E2B3BE2851FFD907307F7914AA614572AB55EAAF35FEB0E8590AA1D400AC8E0F525A9AB3308852C82F20721108250D04DB04EC7EF73E3F5886A216A863542366B90491BA45219E23183682CABFE4DC455323FC984463CEE261E7791486864B21E34DC687854E98AB419B0E8C94EBD2F04C0AC1B5408A1627D467D236A90E652EAA0690A4A57BB9CF19C3B6BB7BD9C912BC25D7D2112C8D211940E60425D4B1B5B6EBE8D9D5FFA326BB6DD80DFEB2516B54208B1A9492213138C8D0C3334D0CFA814C70E0DA97FC7C7C6145119423C32901ABBA03ADD2E1752D50CD66B8B6D3D4DC31415591446CD85CBED5184D6DCD6A26AF53A172F66F1D2A5B475765B05B2ADADD4B7B6E1094837767B9557D749F33F6A9AF67F56DBB1622DA8CADDA669F63B2DAF6D90E57C87CEEFD37D17F9E5DFFD0D2F3DF138A9D1612B2E23291BF3BDC4ADAC6978BC5902752E5ADB122C5E0C8B1619B477A6686872E10FA65485BF7C447229492004A124989D052F124F2499210427DD07DCC4230613E33AE3A32E86873C0C0DEA8C8C994C4D7B482745D57529A927D2D259E8FC51BB4276BE24373BDEC16AC4AA30D14E79AAC1AF3937905BF313C9AC0A5485C024D71297F27E5E77C75D5C7FD74E1AC261868706E93D739AC1F36719191C20313DAD627252AF27CEAC7422A1B24A4C45583693B409A850822AAF68018F504466277BE7F04B7E17BA94B89E4BC7EDF3E2954FC0AFA45CB0B199CE9EA52CDDB09115D76DA1AB6709C170A3CA5E91D8DF55BC06344DEBAA65FC9AB0DF34CDDF03FEA49479173E9C16F5F0E8611EFF8BFFC25B2FFF0A6F265D6C7BD5321BFB1EC9B91353D8E31EA7BE31C3B2E51E56ADAEA37B919F961693703D8443263E29C3D23368B20B2A4FCFDA9A229B4A6DA4BDB59AF832C5D1E1269386445C231E836854231281E969181B4BD3D79BE0E285188303108B8A3A5A87618472B69CB56E9B80E7B02E2777A32647BBA34FE6C6AF20C1ECFBE64FFCF95D759C42D6EA2C7B51C5F15ADB695BDC83CFE725168930393ACAF4C438F158545595ABC0B6D4ED299963A74056897716AEA6906117E2588E206D07AF55A7271A8D495608587713AA6FA0A9BD83D6AE6EE59459B36113EBAFDF4A7B4F0F9ACFAFEEB9CCF28C4A3BFCFB9AA6FDE76ADB5F2B811DFEF8FCE4EB2A0E669A2AA5E7C86BBB78EE877FCDD18307F094C9D8A836991C70CD3401BF87A5CBA3AC5D6FB26EBDC1F21531EA1B3CB8DDA99C3D6D49A8D9433656926C81D7B164C59604B16E32B23AD1689681012FBD17752E5D7273E9A287DE4B3032EC53AAA6A6E9561E65311957599A338342F42956F18A08A4D6AA01E7BE8A756DB5423C1FC5B47CA90ECADBCFDBB57096E7D8EED0953360AD7B7205B1769CAE54812DC7000AF7A55889AE141029AF0958080181FA06956CBD62F316EBB37E131D4B97ABCAF35CE273ED20A976E7079AA66DAE76535502ABE9A03CD3542EE6D79FFC196F3EF58472748837ACDA95BFC59109169803816156ACF070F36D0D5CB745A7B9591C18E3682EB1553205F2A3DA1B6C02746E2B985381573F4F80A6D844628785C866EA8846FDF45E8A73F2F8141F9D89D1D7AB313E1A209D161B2D585C3EE3E062D9299503461E050BBF9DB36575A524989A84E3BC2996298A991479A966AEA7F42FB9DB67995F5E1328F03257DDD252EBDFE6B2F28F24314B8323C903ED59C2E61B6F66CB4DB7A82C95868E4E5C1EA7974AF997941279D5A940D583FDAA9281699A72FCE6572A4B2F2B73E3CCD1A3FCF2AFFF9C83BB5E5459DEB5804C713065E45ABCCC50D91EB072E5083BEEF4B2F5063FED5DA3CA199077031779F16B8041E55B4A6DC9DC9D321D79A5A1934A184C4FF919E8CB72F448800F0EF9E8EF4F118F07ADB84EAE2F482D191FE5E752CAC9F370993DB45D3ADA0CADB24C257725FACFA1ADC2B25249317BA64A45085795C4F31CB7D20B95A4B57241DD5E0FE1E6565579BEE5CEBBD9B4E34EBA972CC51B0C15E75C16D06B110FA90DB39ED2344D8E419E0D04B320A069AE064E567D9791E5D87BFB78EC3FFE7B4EBCF3861D18ACCE8B95CE6F2FD0524DE2F8FD26B7DF91E2735FF0D2D5ADA37B47310D2157976D84CB236277551FBFDABC6703A863A2BB34D1E1EB948B7F68D0C7D933290E1E98E6F8B13493531EB299C682ACF85AD8CACC59954AB0E2DF4B38764ED72AC3C9CB2DB81CD555BA4FD15625A894DA80CE2055F6A1EA7C6B5C47A5CD2C585F21DCB2D2A4160DAF3F406BCF5236DF7C33B7ECBC8FB55BB6E26B6CAA58083B8FD9ACD134EDD46CD3AB2C9C4CF3FF00FEC76A882A1E83836FBEC10FFEBFFF870BFBF72A6F8FD5F6B3DAE5F06ECBDBE7F144E8ECF2F3C0E793DC79F714FE801BD34863986E3497D7EAE09435C966E3685A7AF6C19DA61BD5A63087EFC5751F8F653873AA81BD7B0D3E389C6270B001A9D5B26C1057317ECE61ECC25BF3F64A898CAD502F37CFD79479AC9A4429D82F150F2CB1D52A6352A13FFEB2A79B834F550969E195C41D9B5B5A5977D3ADDCB0F37EB6DC7A3B8DDD8B2E7B1EF600FF56D3B4FF69BE046627F556C1E55894775E7D851FFFC97FA0EFC8413C732230195BDCE826A1F0085BB63470CFFD3AEB370EE2F6E898668694D9891E588E27E881D814C998D878639F583E6ADE91227AA38B54B28D4B170DF6BC1B65FFFB49060620936EB6249999EFC35804B55A2549D14365AC824289604A898AFD215BE0F1B10841D3C4569476E092F950588766BD448D3E635E853C7C36D9EA8C5089E797FE7D1EB2A102DA296666B7DACB05106DA33ACF9CF20F3B6CC01B6A60F9BA0DDCF5D097B871E77D34767448EACAE512DAAC49C0156D30D3341F029EA9F676E11012607EEB572FF2C47FFD33068E1FC1E3F5CE31E35B2793162ED3CBCE9DF5DCB5334C5777AF8AF0ABF1DDD7E36DDC812BAC618C5E243E7100BFEBFC155113ABADAFDCF782B0E251BC78A18577DF4AB0776F8281FE56A5FFBB7281E982276BE0B473998753F7E5719B783D12033471E9F96E5C86A99135209B719149413AA3BCE996232D1FD62BDB6DAB781EA5D6A1F56DFEAF92D9928B14173C5A4D12CE65B533EF9D39ABFCFB8A13BC0B884CF5513155DAD5924D5BB8EBCB5FE3E69DF752D7DE7125EAE0BEA869DAB36571A5D2524DD3FC5BE037AA8142363B3E32C41B2F3ECF537FF3970C9D3CA60CCCD935738BAEF35E249D74DAA0ADA38F2F7EA9813BEE6C22DC70CEC206C96F0C7E1E6FEBD7C13F0883EF111D7FDF26B06AB32B93445FC323B5DC2244964EB670F14296D776C7D8F3AEC9D4A48E996DB033134AFA645C0109665978424C630482695ADB83742E6AA6B9BD9350430B75812C9A19219318231E1D667438C5407F8C810193A92917D96C10D30CE56CC6F212AC70F5E525587EDFEC0C97B27928574E62E5E56D21DE1448617BCAA5B32DDD4727E1DA5D1766FDD6EDDCFBD5AFB379C75D845B5B2FB73CE7079AA6FD66CD04669AA60F909C2BF977D64B261D19ECE7F5E79EE1991FFE2DC3674EA892F5EA0466E50C582E609D74C6A0B3BB8F5F7BB88E1D77B4E3F19DB5625C92EED4F83DDC6DFF044D3B88D9FF1CB189FDF8F50BD555C4C2C6A2156575B51556FE5E882C9B31F8F0481BAFBC94E683C351A6A65AD1755113ED5293CBF2C514D8600A5F0D7C5E9D458BA3AC5E63B278653B3D2B3B685BB486BA9625047C1398890BC4C64F909838C5D8989BA101B874C9CFD98F5C9C3B9766625C82E66233CEA7F7647989367F08D6FA64358968ABC40E3E55292C526960A110EB6EB983FBBFF1289B6FBA098F642F94BB6AE31349C9D1D5344DFE2DBACAA25DA583F3CABEDF34991EE8E3F5679FE699C77EC0C847278B084CBD4049A2C2FC85F212ACABBB8F871F0973FB1DEDE89E332A4D49390E5A7E0FBDE38FC07807A3EF496213EF11502A620D1B94F3525AF7965F702D50A9C09F4CC90059CCFEF763BCF4C22867CF344BDD3626EE028F5C2D132D60C3454429BF48AF8D2CE1862996ADF0B079FB3AD66F5949EBE24D845A57A2D7B7814F72B04FC0C41EB2437B3113C730B27E32593FB168800BE7A31C787F9AA347520C0F49C2B395BC5B49A52A0FD9E27DABC43BCAADB6563E3353D0CFE6EB2D9CE5CCEABFE2DD2E9E817819C3EDDDDC72CF7D3CF0F03759B6F97AABB0B532965443B6B207F95522B09F008F541B51BE1709161D1AE08DE79E517988A512AC3C81958E6CD9349D5D7D7CFDE1A022308FFF9C2A2B1123DD6CFD97B83AFE5B34F3758CBE9F121BDB47C075B636022BC84B70F86FD1DBAD24B822C2CBA94EB50040C1A0910B1723EC7ED9CDDEB7EB191B174626D903255EC06AE355B0D55C5A82FA7A0FEBAF8B71DB1D5E966FDA41F3E2EBD09B6E07DF3670F9C07041F275CCD1E7494EBE85CF389C4F50367592C92CBD179A797F6F9A7DFB92F45E6A518E254973AAD517E84CBF9C23A118D50B33674A99EBEC402826B06A92AB068096CB4C51A15B4305A6BB16F770DFA3BFC18EAF3EAC2A1C2C222B8B29D55EF6534DD3BE59558299A629819F482DEAA1436089B11165833DF957DF67F0E4313C556DB0D269B81481B577F4F3D0971AB9F3AE46420DE7ED88B20BA3F58FD03B85C00E901D788ED8E86B04B5233308A31204AAF2C052F63A078163BD33402C6670687F0B2F3C9BE4E4C90930DB6D065AC61338DB56156198A566861B46D9B031C04D776D65E30D6B685C743384D783B7090881D10BD13318136F919DDE8B91BE84471B2A2ABC916459B1197B2F65797D7742D98C13E31AD94CBD6DEA569731D56C1C6B5985CCCA3202F257799B2E2F350AE7E0907D5E47ABEDFDA5A4EEFC3E737DD2CAC1EBF3B3F6A65BF9FCAF7F5BD5E879A55D420DB50D65B650B86AE86397BD956A645F3350C9344D894CFFA21AB9167E9F894CF1F62BBFE2A7FFE53FD3FFE1E19ABD88795C72295BA6A9A59FBB77D673F73D613ABA7A5506B5727234FF017AE7BF42D7CF620EBF4D7CE4397CD977AC92FA2B10709ECB5AED82B09247AC2CF4736797F0F49313ECDB37412AD15D4260737A8B8DAB19BC5E9D0DD74D73EF8361D6DEF8551A96DC06A1EDA06F0063083371112DBA1B33F22A99C831DCD9B396672F2766EC26FC4A53D7C93836E3CB193E3838CDF4749BB219AD2295D9AFEA16987342A93D8E295EE00214537E1F4BA2E5EB54E4DEE29173670CE46AF4F2CB719C96A56CAB3A7B28B336BB9AC1D3D4CCCE2F7E892F7DFBBB342F5B95ABC0AF068F32DF7F4DD334C97C9A95C0FE0CF8DD390D9E4EF2FEEBAFF1833FFE775C38F8BE2A29A865C17955430A234DEA42236CDC54CF7D0FBAD978DD301EB76C50966CF81B783A7E13826188C4490CFF0C2DF20C9A114127A68C7FB57573963C735A65C59B65AD721CED50FF125E7E7182B7DE9C6074B43B974A65534B0D9CD15980A6546FAF6782CE2E9DDBEF5BC35D9FDF44F3F2FBA05E54C200645D107B8FCCE4DBA4A60EA3A54FA19B13B835F14D557A95A5834E4D2D66EF9E08BF7A619C4BE7DB545E98AA32A881C09C5B8A25935432483C2E0366C64A79735985AF1E8F7C4CDC9E2C6E5D3CA0A66ADBAFB9ACFD72AC3A7584946115D2CABFE9B4492AE52299D45571ACD8B42EA9D1C333A353B2C5A82D8C2BA7BE16FDAD4043503F4A184873B169FB76BEF89DDF66E3ED77136AB4BB315703C8CCEF679C92594E82D5145C2E1ADBC87074CFBBFCDD8C8F3FDA00002000494441541FFF3B4EEF795B55A5D6426085742E0076BB63B4B5F9B8FF7371EEBE779ABAA017CD4C93F0DC86B7E5415CCD7780761D4C3C8631FE43CC641F2EE1E2661A34EB44CBCBBE0A396E8DD251D6EA72C3F84817EFBE31C5EEDD312E5EE854C59E96B7AE565BC2E1E41278974E5483DC74533DB77DE173ACBDE566DCCD7782BE05B804D3C7498FFD1C3DFA2CD9F4042EA44D446D4CC6345A38757A92979E3739B8BF9D48440A5AE7523F6511AA727BAB3672868AC579A52E4FE271F2AF57434E75AA0BE984425902C1145E9F81CF67A8A25869D3E27299EA234170892166D22E39299864CA452C6E3039AE3339A1138D9924D23A99947C5CAA55B993D96FD9F8F2BFD909CC91D185ADD7ADC724D3039ADA5AB9E9735FE2C1477F939E356B663D5360161C9B11742E2230D33465F70ECE1949CD2CA70F1FE6E7DFFF538EEC7E59F55E98514732AB02ED7C99C2E735B9F19604F73FE863E9329D807F94B8B9044FDD06DC6D0F40F84EC80E40E423B291136462A720790A8F297CC1EAD171B52F275DCF9198CA4AD0616AAC83FDFBA2BCBA2BC1E9536D0504662140618FF4F2B374F8B9A11A892E5E3ACC435F5EC44D0FFE53C22BEE015F0F98AD90788DAC383326DEC59D398A4B4BE552C7AA0B71B9A38EB1B124EFBE55CFAE97DCF45E9A062DDF09A29C14C88B45C91049DB9F282E3D4520E4A5A9A59196D6461A9BEB69680E136E08110C05F105FCF8BC69742D8E471BC0EF1EC2ADA7D035E9D5920F7C3B124CD2CEB2594B82A97ABDB8C6F4B4C9F0489CC1812483FD494646201ED3318CA05DA737FB8ECF9060769279E153F2FE9537DEC2A3FFEC0FB9EED6DBC0E3309CAA167CE9CBAFD734ED90F3C75202FB97C0FF3B6704350D2E9D39C3AEC71F63CFB34F313438A0F2D472DD804A5A5814309CDCAB2C712D2B77D1D53DC8CDB706D8714780453D431866004D0F41F05EF4860721B41E435F862B7D1C33F201C6C4F3E8B15D1822C95C574892CD02844A04363DDEC6A1FD1176BD92E6C48936655716C69B947CB2131F66670319FC3E9D0DD74FF0E5AFB7B07EC7BF81966F5AFD7BA45274E2BF921DF93ED9E420BA842B0BBC8F55094CA57249D039CB87877B78F28938C73E1C05ADB3682FF232A1001052196E6A78DC711A1A5C747469742FF6D0DADD414B671B2D1DAD34B634D2D05C4FB02188EE0D63EA013452908941E22044F691490DA36B53C5B95A0513CFFDA83898109A97F1F12C23436E060775FA7BBD5CBAA0D3DB6B323AEA2393C95AF67A8D57290311212A15D9EDABD7F3D5DFFA6DEEF8FC1709B4B5DBA315DAA68E8631EB8BFE95A669FFBE12813DF5F1417A5FAE719EF9DB4C531D587EE0E51779F1C77FC7C9A347F0207A78815E3F8B042BFE4A43770FB16489871D7706D97603B4B679D0F52829AD07977F15BEF04A082C013D02E96198DC07D3EF61880D300F0956CAA3E6CAB3949A24126CA283C3EF47D9B52BC9F1E3AD39022B3EDDC31A3D6FC3947B5B84F6F620B7DE91E5DE077D746CF9EFA0F95160146217490FFF18267F0E664C498279CDD7AD73F6E44A1E7F6C9C03078631CC0E653F891D257D502CA7878818C965B48A527DBE184DCD062D9DF5F4AC6867F9DAAD2C5B733DAD9D8BF087EAF14883146F003C1AE8A2FA09D20B0E880A9A84F8EB30F82CA9A933B8652D552E4743300C0FEA930D92C904989EF270E9529493C7A39C3C29EA3844A6C46E92DC4B7741AD7939A49B092DB94BBA5C853ABAB9FDFE0779E0916FD1B3698B6DD3CF15BAFCF2E383FB72E55DA5126C4CF53C9CF365924A24B870703F4F7CFFCF78F7B557F198525252CC4F2BA91E0E5FC8C563CC2C5E8FCED215A3DC7CAB872D5BFDB4B78FE1F1FA14A732F5264CBD1117E265D430B383901D5488311F4787F3DED279581227EF85AB04961C818D7770605F8457772539292AA22DC1948F51490EEB4DF94EC8B915DB433BA27E84E52BEA79E00B01A52E8797FD1E66F377D08C531813EF931A7F116FEAADB9319382751882FF1EB8706A153FFFD138FBDE1FC5A40B9F57CE3BB3AAECA50D43D690BE24D2912B8DDBADD3B5689A8D9BDCACDCB48A9EB53D34763FA0724475BF1C38282D3303D647340943BCD696E343331398D9045AFC798C912748454FE175498B97B95D0E3E19868B64CA606234C4D93369F6BCAB73F4483DD1A8B481132788237F4B77B4D4CB999748D283C4531766C3966D7CF97BFF984D77DD3BDF1CC5F18FCF14CBB5E0CA51C05C8F819D011AD364E2C2399EF8CBEFF3F2533FC788DADEAC826C01EB19DBDF63497F7595F2192B7D2A8BCF3F4E67376CDE1C60CBD6203D4BFCD4D5C530B42C8654374BA687296738277069F11953AA95D8CAF1A8523770E1E0852AA25319AD9C1CC3DDBCFB6684D75E8B72E17C8752C344452CB6BD941E5CA877E57E76EAE30CFAD9B0B185AF7EBD910DD70DE20ADD08C16DB84D39BBFA3C46E20C5E4DFABFCEE12A2030F951E67BE96C27CF3E39C8C14326C120F4F4F858BC38486353008FC7201687D19118E3E353D4D50559BDA68EE52BBC342FB985BA9E5BA0FE66706DF8B8A2494A87444AC5C18C427A045223908D41268A991E27931A474B1EC34C1E83EC04BA26A1D6F95ED26D4A6CB030D3531AA74F7879E7ED290E1F8A3239D9864B13275B893AE7683615EADD5403564D67F1D2E57CE3F7FF905BBFF2F5F912982C2A77FC6C21811535B6A979E905F8921A1BE5F5E79EE5B99FFC9081934749CB6105AA3BADB5D85C339AAAD9E516A791424B5131DADAA759BD5667EDBA342B57C6E9EC76136A4859685ADC0DACECB46B25B45AD75C8EC044220CF72FE695172779F3CD694686BB5567A6B25D692BBCC82130933EB66C6DE2915F6F66D59A7364C5C3E7F2E31215D8482A55D86AF4E3942CD7E0D8292430DB293336DCC2A1FD098687A3343686E85E94A1AB2B4D7D839C2F9652B6CFD85896A9A90C01BF9BCE4E3FC1BA3449FF83785ABF8EABE106D0562BED81F40066F22C66EA1CA4CE43E6025A760AB253981921B6610C439AC30AD3A915D2B5DD178FB672ECE834BB5E91BCD056627171C21494A154C537EB3DE94C969696761EFEE7FF827BBEF59B7824C630BF2BD710A790C0FE1AF8AD798D67EFAF998C73F6E4095E78EC6F79E7B95F128B4CE3566DB3CB70EC020956FE9D0EE5CA513C93F87C715A5B0D56AEF2B27A4D035D8B749A9B0C1A1B32F802269A2E9E4B717038F551F6A8559AE2CC6BBD250FC94C6599BD1796F1F493E3BCFBEE24F1586157AF590CD082B17204A6F5B1FDC6261E79B495652BCF28350DD5ABD1B0BAE93A6EFF794E5E6D9706E94488E929AB636E2018C4E38EA1EB115CE228D2A4F59ACFB27D6C8795AE5BDEC3B4BE0E4F681B2EB1855D1D901E259B18269DE823931CB025D4940AB1B84CF17026702147050BC3A91ED09EEBB24C33CCE484C9FB7BC3BCFC629AF317222A7DAD08EFCA684CA56C299DCED0D0D8CC977FE79F71FF77BE4BA8BE7EBE59F6B943FB0A094C728F36CE757116177590D9501D5DDFFCC5CF78E6AFFE82FE8B171442CC858B977BBF5338ABBBB304032E1A9A927476C1CA152956AE4CD3D6E926589FC0670735AD4E5D4EAFF93C64D5346B60F6F38181ACF1A353CB79E2F149F6EF1FC5CC76166CCE0C2BB3A20C53B4A3F771C38D0D3CFC682B4B569CC1C88078BAAED455A4252903B220EC5384FFD6B9D9A61D637412300CB30E975E8FA6CB81823E30E360C4C090366E31D55ACD71E358B6A73DF37938A06A5AB30DDED3C717F1CC53510E1F9A249E68773A9ACE18A2922F4034AEFAFA061EF8CE6FF3C0B7BF4BAB1464DAE72AD4348FFC4D47354DDB64F3311530140BF57294E21CE68A2E7B66FF3E9EFFD1DFB1EFB5DDC44687ACD41385E7B571F2998BB19F535902695CAE38816096A6C62CCDCD26ED9D6E3ABBFD74760654A0BAA9C9833F984577C991AA293497132712CE2C9D1AAC785951B7DE1204CE739EB24662C91425DBC0E4F851717B4739F2C108D055D09BA486753BF05171D73E6EB8A989871F6D61C98AD3578DC02C55CD6240B3DA9C455256BAFE4A7F7FF1D6B9314C69636775FB92343C973A27E00A72835A305B6C4AD120CE4B264D943DEF4A268D64A8E450BC9651948A180ED7B3F39BDFE2C16F7F577510D6E65FF12C798951CBDF629AB7036FD6348BB237E5BD63F2536A629C3DBB77F1CC0FFE8A8B870F58596E4E4FF70AD9CD737BB7A5543B5D998375295A5A5CB4B465696915A2CBD2D49441F236A5D5765DD0201834903E945EAFA1BC64927920FD6C9CF304843B4B8280922005C90139F967FFE0E0A45A714EFDF4128DA639F87E3B2F3C6772FA9424FB4A115F8D2233D7DFD0FE4108ECC666BEF1ADE6AB4260738375FEEE19F1BF6A3D296DB65BE26E98EFEB677D4E086CA0B78B37764779EBAD28FD7DED2AD3642EDA93C4D342E130777EFDD779F0DBBFC5A2A54BD17201E7394F7B87A6696F3904F64F3E6E8BFD5FE63C44D10396CDA4FE6F66557BE5577EF613DE7AE6970CF5F7A9D048F1622F87CB3912CDE651AE142EF589E3D2D348D7E470189A9AA0A1C14B28EC261CF65017F2E2F3C9091E1A1E49D7715B7DEC45C5915CB9E6E6186DED490201D131EDA4E8724EBFA2D78B1AD5C0E0409CD75FF5F1D66B410687E4707AE9046C11D80CF9554E47299060281BAC9947BED5CCD255A7C94A2698D521AEE6AB9C442AE72D2D1C70C6F72583546BF25A3AB96AEFAB7931E56E2C999B84DC067BBB7963778CB7DF8AD0D7D7564C60B3D8FC0E584582CD46604EAB861A89F69F7EDC5EFBCF1C02FB0F1F4731FFF9652DB884D812F1988A8B3DFBC31FB0E7B5DDC8A17C82694EABFACB21AF99F394E4589128D29E572839AB54062BD154D46813DD6DAAAC7149367529FB2CCFDDDCEE69BABB036CBF21C5E6EBA33436FB31C5E55CE552A4A349DE602BC78F8DF3DCD3698E1EEA229912674B3EB360860556D1AB65E7F8697DDC704333DFF87633CBE64B6036800B89D2D2332A573BCDF8FE2A578457836FC5EF0B8A05140B936D7043FFC56E76BF14E19D77220C0D75E409AC8A17D1D99F9422B07AEE1115F13BDFA573D1E2CB698AF31F354DFB4387C07E05DC3FEF05176C5C814281D489EDDDFD2A2F3CFE133E3A7480742AA124598D8A53D5E9E419BAD38F50FE226101C3EAB6249D969457517ADDDB5D976C035C71232DA10E8DE8E9811B6E846DDBFD2C599AC2EB57394933DE5FC43415A64AD72B393CA29377DF89B0FB9571FA2EB5ABD0447155542154EC9F0B55CEC25455954AD5C7F6ED2D3CF2AD2645607270456918672ED2CC96F345874895138665254E81049F93442A95FC5577738E37143010E5A771C3C5B34B79E199882A179A9C142747810E5B20C14A1508E7F7543A8B1C90F8A038397EE3BBB448BAD4FC9C1CB29897344D7BC021B0B967D017C0A312E0CD4C9A91A141F63EFF0CAF3DF5732E9C3985914CCC492F9E0DEC332483C825C5DDACE20BC99C28DFF548CA2224B83AC5D2657E6EBC39CDF5DB627474F8F07863D6A93065AE1C8797730714517888C733BCFF5E23BB5ED138733A413CD6A4CA34E6575F654B30FAD8A608AC91E5ABCF5C1102B3EAB26ACBB69FA1EA157096D92460EEB94F58F22902D3E1D4B1A53CF5B3690E1F1E2795CEE75696AEA7128125C54DDFD0CC577FF79F29020B8A9D31AFDE25EA8D2AB35EB31BDC4890E2B2AEF20CCBC4CC66E83BFA012F3FF138AFBFF83C93837DEA14436BCF6658276564616556987FDA427D8F27AACA224CC34B3C9E553DE44D49145689A082F5863A5151774F12AECFB26A8DA1DCE11B3706686E9944778BD49AD1B7A4106FEC598BE7CC4D64BA99D3A752BCB63BC2C1033AF198BC2F6CAFA1BA123C73F57902DBBAAD49D9602B1C02B36751CEB6AA65E39C0642CA7E50990E96A4B74F032B622AEA1E3B30ED74622ADCAE9A4CC1AB2DC18A16ED279E3039F85E2BCF3C99E0CC4793689A7811CBE1576568A53206CDAD1D3CF2077FC47DDFFA0EFAFC1D1CCE4BFC4260EB8063B56CD27CEE9174A1C1532778E5C927D8FDF4534CF55D402F22304776DBF2A1A8CF5EAD755459D56DA9AB2BC99225A21ED6D337106774D8241AF192CE48CD8FEA4F85CFE3A2B9759C751BBDDC74B38BD56B26A80BB9D1754972ADBE42413EC37013930EBF275B78F38D341F1C8A3131D13A67AFD5CCB739C68248B066BEF16833CB5789049B991A5C1392CF10451A869CF4999106C99A2A8074ABBA2CEB236B530425458F022FB1550BAA8A9DE12CB5A72019BE3AD8AEDA1D6A3FB2F55CBC18E1B55D5EDE7D2BCCD8580234893CCDD4712A4DC44A9572B368E90ABEF17BFF9CDBBEFA6B97932AE5BC66BD10D803C08B570502D90CD3A323EC7DF94576FDFC679C3D718C4C4C3205C446B93C09A636D9EE56659811BABBC2DCBEC3C7A6EBE2E89E3A4646A7F9E8749C93C722F4F59BC4E21A5EAFC9E2C52E365F1FE4BACD017A7A5C044313B6BD555CE652C880F374E7C3C8F8989CA8E7C48938FBF6443876D46472520A062B54C196F55E9572D662C33458D7C7CD377BF8E2D73A58B4B45711C55C08AA9CCA2E889888353138E0A2BF3F4A22E5271CF2D050EF555E53AF4F8A25DD2ABD4B1AE4C831BB5EDF048D4D29553829F6AAA22BC7AC99C5369B93AD765988A7AB033AA626BAD8B76F8A5D2F4F70F17CABAA2793CE5EE57B6B94F1EADA070EBA8361D66EDECA57BFF73B5C7FCF7D7373DB965FC7834260FF08F8FE65ADB3C2C3C98931DE7FEB0D7EF593C738B56F8F3AA3574E8FBF12578EC014708658B5BA89AF7ECDC3D66DFD78FC5E92E924437D01CE9FD138752AC3D07088FAC64956AFF6B17E839BCEAE29E5A22F676F290429744258BE1352F120FD7D098E7E50C7A1FD5ECE9C491099AE57070D169E259D5BDF6CDEC2A278A0C569A5D39110C2F2E503DCBDD3CF4DB7D5D3D43660D9607300DA0C6FA01ADBA4F7521B7BDF4971FCF824C95433A13A93909C2FEE37F17AA5A45F10D62099D2D4A7AD7D821B6EF4D0B3A40ECD258CA8FC55FABE99EF9FC3E46BBD55006278894C67F8E05023AFBF06C78FC588455B953D26CEADFC552CC9ACDFACDC58871988A655D7D6C92D3BEFE573DFFC16CBB76CBFBCD359AD97FF6321B0FFF963F4F9DF6B5DD7ACF715B0AE743CCE850F0FAB5E89EFBEFA0A46440AEC0A239335E863053CA8A22345A93553747786D9799FC9ADB727686D97CC9131B2E930995488A1A12C63E32E42A134AD6D52C29E42770BC2949983CD99ADFA63A96A1547461D63A31ABD97348E7F38CD8747A20CF4FB48A57C48DA9075F0834591F92DB3C7AE518249BE9FAE4FAACC945B6E35D971A79BEE456EBCFE09DB7153DB0E39D9FD168FB0FA4AA6D3CD0C0D9ABCBF2FC39BAF4F73A937AB7A5F885A285E54275D540859A53A0A7A1A72542FDC7B7F3D37DD524F63F3809D593D339770B69DAC640515318C5A459EAA4C10FBDD4F2AE9626428C0E99329F6BC3BCD89E32EE231AFCAB0CF65811772BADCCF4E9E7D9EC0642E72426BDBCAB53CF4E86F70D717BE48B86BD19570C6FD2F4260FF09F8FDDAB66F96BB0A81649A0C9C3FCF1BBF7C82377FF904BDE7CFA9569C9647A6D0E6AAFED6528F8F235C1403CB25935B15C06BD68D70D7BD1EAEDB5C47383C927300A5D31A998C6D734806876D6BCC787B2EBEA2A913399249379188C9A58B218E1F353971DCA4EF528848244B26EDB11BB7281F96DD3DC9EA722512AD9078CBD258D1CB2D77434BF3285BAE0FB0E34E9D556B47955D59CC89AD876673743804663594D149A70CFAFB5AD421157BDF8DD3DFDBA6E62D81768F278BD767E2B69B0B2593D641F04EA97E5D68980D1BEAB8FB5E17D75D3FA64E1D95F045452FABC353ECC6516AAF0A28A9A264B33B38971E349F7BD61E437AED275326B1989FA1C10C1F7E10E0D0010F972E2689C7C5B954BEE94DE93E1711B76D664808A973C3F53CF24FFF80DBEEBD0F3D14B61954751C9DE58E3F1102ABB9C96855E9E5605222C6FE77DEE2E77FF9E79CDEB707232B796A85CB2F4493D2514BDC4F390ACBFF3D4F748EE817D69BA1B16584CD9BE1CEBB5DEAD8598F474ADC2D025095B9767CACFA3AE498A23417CEC3871FC24767A0BF0FC6C7A4B4DC421A27902DDC3F9B8194D41866455D9583F944B2F9F3AF29C7258A26912458E766C3A62877DD1D60C3461FC1D080DD43416278055701782AA98DD28A5C8E5A4A241AE9EF3538B07F88438720320DD2867D714F03AD6D3EC2F592D9228D67ACA2D2745267623CC199D3494E9D8A33319EC2EFF7B365ABC68E3B42AC5C152050370E9219EF4A574D392CCDFC984D50E5D8AE9A8A14D24ABD970FD314A914209DF2303E2E6A6E94B3E7A25CBC90A0BF575347FB4AE7294D733267F22CBCD23E9725B0749AD6A52BF8DCC38F70D797BE42D39265B6F7792ECAF98C37FE5408EC65E0DECBA253875E14E7321939779A579E7A82979FF8191317CEE70F83A85A9753E235AC7A1E961C27245EBD8CB2A73A3B27D9B4C9C3ADB70B818DABE38FE41836E72ACDA5ABB466D3F4333991E4C4313FC78FF9181991D85800BF0FFC3E39D4CDB03E1E4DE53466323A89B8C1F87880BE4BA63A013316935E14360B2FB3EE629A9BA2B32BC85D3B53DC7E678CF636C92499CECFDBE14DB608982DC82CDF1986CC3FCDA9935E4E1CF7303C348DCFDBC0E29E8CFAB4779834B5A408D6B970B92DF8288D20EB21369DE5C2F946F6EFCFB07F5F82C1FE561A9AC659B7DEC796AD26ABD7456969F5E0F54971A5A54254926865E15BA142DC6A806365DE67533A8998A10ED39898D4181F73333622017D0FFDFD2EFAFA4CC6C67C76C5B89D487E996512627BBA8375AC5ABF91BB7FED1B6CBBEF011A9A5BD024823DFFEB1521B0F7A50273FE631487AE64A28776BFC4937FF5179C3874906CB4D06B38BB0CB790CE62D1396E67B336EB2F768684995559F59A16231030696A4ED1D1092B5779D8B021C492A5100A8D2915B1B0237EF935CE54E024535CCACF47865CCA8991CD4ACEA257151DCAC717D4F1FA35ABBF9F6692311A30686622BA820F4F07F9F0BDF7387BFC1813A319B299A0A5CBABF043C10C1C0A93234F99A6677123F7DC0FB7DC1EA5B945905624857D399D044AFA753A87FE49AD9804BDD3293FD393268383492E5D8C323464924EA360B36AD5223A3BC563184353399B728861561D52E110989C7D265EB94CB68D8B1733BCB93BCD9E7734C6C7C794845DDC63B07E7D1DCB5684686933A90FCB714052792E19454E11A89D313D03D8B652EFF44FB4199F30BD6422C4C4B89B89095D1DCD9B889B4C4F25191B4B313A92606828C9E82844A3A22D487F8E20D9AC726DDAF14D2BF5CDC19EF9E272C630F10783ACBBF156EE7FF811D5E9D7D76855FF97E855B5BE62BF10981C7FB9AAD62766DC57F2E6442CCEEE9FFC8027FFE24F181E1CC45DD8F8A68A8EEC287C8EAE5E805F56DC45B8A55816BA6125F4D6C7E8EED659B721C3EAB542641AF50D49A51A0AF2145EB9AC791B5A963473DE38D370CF662DD5CF949EEF763C48084AF21A11EFA334CEB45F90CC761108AF83C65F63227E0B170EEF62EF0B3F64EF3B179918F1CFB0C9E4C11CD8D46223B4B64AFF8D28B7DF9966C9D2001EEF64AE15A87075E7FEC2AE54E290902653D247309ED4181F0970E9BCC1B9B33152C926962C4BB06295482C9D70BD0317ABA7A023CDCB4A75CD4D329DE5C8A12E9E7D2AC9B10F27308C0EBCDE34E1A0542D24E85E6CB268B14967579AA6668D60288DDB23B99E56C3512B8666BB7EEC8EBE52CAE2716BF87CD2F7C3EA8B2F6DDA067A1B397430C58747D28C8C34939233CDE493D648C927659292BD502789BA2C95B628ABF23209CC6160D2C752DC5AF54DDC74B7E54D5CB2792BFE606056BB7716DA392D0426DD472AE795CC85F23269067B2FF1FC0FFE9A577EFA43A2D35378249259D6C93C9327146ABB163FB208409599CB479FC6ED49D0DC0CCB97FB58B12AC8E21E2F9D9D1A4DCD697C3EA94512754E3232F2E242F478C9EE300C2F981E5CAE189A1ECD770DCA615911492A0F9C9501E25C56E6834AC12A609722C17CE11E687D14425F81893EF6ED7E96E71E7F858F3EE8239992D9F87250C8D1B6E314409013BA174FB1755B802D5B5AE8EA3608F835552560A57C196886D82622C53DA4B31AB188C9A8F40B1C8CD3DB1F617438A3ECC0F67658BE42F22A03B4B683CF9BC15470C9AB83B36DABF2A0EA3ABDE77B78E19949F6EC19676AAA13D390360D32D70475218370D8541F7FC0C4178060502710D0F17AA5524153CCD55259219D35F07B637475F958B1D24D736B145DFAE5A7B31C3F1666F72E29949466A37EDB6124546A9DD0A9BA53291BDA6188E5644AF9F8D65CD0D71255266953A3ADAB9BDB3EFF25EE7BF89B2C5ABD0653B5BE98F335200426FEEA7CD7C9398F917F201B8B70FCF0415E78EC071CD8F512F15854958628442DD2906ACCD050FABD4823B117247695A4674996254BD32C5B9EA17BB14E7D631CDD65C5798AC8C32E8F11DA8946DC8C8E64191F37C8A6FDB4B6A5E8E8922EB3B2714E538FF9672618A60F5D0F92AEFB353C6DDF41AB0BD07BF4035E7CECE71CD8F53623A3690C1A66C92BB0E62F764D5BBB87A54B4DBA1725696AD2A80B65140CC59B98C9B8484BF7B384462C26C72679D4010E23C32653D31E1A1AC6D9B0C1CFD6ED6E962E97360B52F056D9EBE7C0CB6116858D54C5A61D19ECE49D37A679FDF518972E74E45A0728155EF653698342F052BDA0E1F71AEA107B8FD7AA5A502AB4D4379B9ACAA60987C7D8B8A18E5BEFF0B062F528BACB4D2A95E1F0C1165E7929CBB10F6344232D5609510DBDF24B51B59206540DA54B7D504E6275D7BA4D7CEED7BFAD5AB985DAA542BDDA4833BE9F140293107DD583F66A193A3539C17B6FBCC60B3FF93BCEBCBF876432A97AB62B29546282CCA6D5AAEA58496B0A44A9AFCFD0D22A87F3B959BEA28E552BC3B4B68BA341FA7D48E03A6E7139F5B1AA6CD3292FD188A68CE4C9711743C369FA7A630C0D45557BE6EE6E0F2B5737B268918BD6B60CC13A03972EADA7ADBE8065AF12FBA9D0552E5E3BD37013F7ECA4AEEB615C2DCB18FF68985D3FFB25EF3CFB1297FAA2983456CC8C73BA4EC9F96D9A2B8D4B9F520E1539134EDA42C80110227DC49E4A26201A93CEB6F9A36145FD5DBCD8C36DB7D7B375BB87B63669652DCD446596D57B60942530378C0E2EE3EDD793BCFEFA38972E3415A482D9164FA1285661016968235A84A85A52C0E6989ED2E8D4A4A171822D5B245EE965CDFA51DCBA97B44D602FBF6470ECC3A845600A656CC697B3AD724A72D9F85429EE17B3DBF25B5A8E5E9CB7A8366EE146366EBF8987BEFD1B5CB7E32E5C929B3837224B0A810946D5DE1675164A4B8E8DAA638C5EF8C90FE93B71587127E96358EB9C9CFB74574AA5F1F42C8DB372B5C18AD5D0B5384E7D18EAA41580D4BCB84465B234417142A492904C8B2D0213A33EFA7B4D2E9CF770F19C87E1912CD1A857A50061E8F8FC09E5095BAC7694B50000200049444154B336C1864D19162F75D3D01423E093424CBBFD76819DE25439E738BEA83D857555361E27DC3711687B00AD650B031F2578E5A73F67DF0BAF3030286A9ED56EB2945BE61561CBC694B082631F8ABDE75155D796CD215DB644DD52F6A1CA1794989B8B96D6016EBEA58E9DF70559B26CC0527D0BE86AAE85924E8F8E8B6717F1D2F311F6EE996262A253A94FA228399D1F6622B193ACEC58D1CEEF2E95EE55DF38C296EB43DCF780471D72AFEB5E32C934070FB6F0D2AFB27C7834AA3231A46E4F1D1EE19C27AD34752B015908B59CD772A6ABAABA482854381DA533B726BB677D736B3BF77CE351EEF9E6A3B47775CFB53E2C2B04560BB1579FAD44474687D9F5F453BCF0D3C7D4417C19D5B66DAEB4AB515F3FC6FAF5416EBE2DCCD295711A1AA5B424894B65C367C81A1ECBA6CA4A7CC4CBC484A1EC90818138FD2AC937C3D4A4A60E0E1029964C27944751A6221F65C8BA2C09D1D2025D8BC4666964D9B210EDED6247A470E9D3762F0FBB3D9C9D87E75049A104B3747748BB96E10D5F8716DCCCC923099EFED12E8EEE394F3426441BB038BA93F1519072916740CE4F8E84109BA9D02BE7648C58B6A19C62221AC2FA8D63DC7BBF8FCDD7070835486A55893D5252DA5FECD828444D416219B79EA9699D0F0E0478E55751CE9C8990C9B454641079E4B0C226D61901E2E8B0EAF1E45FC348D1D010E5BACD2EEEB92FC4BA0D53E8BA875432CDE1C36E5EDD95E1F42914A31427883016C93211DBD4299CCD663D4C4EA6999CF0934C5666583521AB6DDDE7EF9DE98594C33BA4D9EDCAED37F2855FFF0E37DE79379E06E95655FB7545094C0E437FE5A95FF0C24F7FC4E8B9D3AA1DB16E27F6D642C516CE692C5ED2CF5D77FBB9FDCE065ABB06AC6E6C22A9D26E62912C1372EAC6988BB17137A3A33AA3233AA3A32E4686754646A46C44DCF8F9D3421A1A132C5F1964F1B20E82612F667A8C44A49F91211FBD97201E9FA2A129444F4F869E9E349DDD593ABB4435D555F98B0AF62B23D2B209ED00509167C9D296EA70799A989A5CC2DB6F4DF3F273E7E93D17C4B4E33B8ECBC61A4D54A0521E3A7B90B4F46E239BC5ED7173DB1D637CEEA1348B7B82787D1155EBA6A6534175282630AB8C47A965A69B64D2606438CC891329DEDFEBE2D8876175FA8A26DDA366BBD4492BE2E6B762A1329E6489F8FD282788DF6FD0D636C5FAF51EAEDFE661D19209C57CA50F465FAF9F8FCE48BC2B896948D353493CB6ABD0EDFE29F2B74CBA4E85200E1E30F9E874B8C026AC3CB1721A43FEEEEA569BDCE16E6CE6BE2F7F8DAFFCE66FD3B864F99C52A8AE988A285B9A181DE25525C17EC4F099938AC0F299F3E58050EC37B454198DCEAE08DBB637B0656B88A69631920939CE06A4EBC0C4789AD1616996299F0C63A34220E2A9924C70BF8AFA8B4D24ED953DEE095A5B4D566DD9CCF63BEF60FDA67504C301B2536F111F7D95C1FE041F9D19E3E8D149CE9D053914A62E085DDD1A4B96D6B168511DCD2DBAF294D585B2048326C180A1DA4EE312CDDA912ED63A52C90615143D72C4C53B6FC7387332422212B6D49BD24E4B857A5B2DDCA78C2F564E60F1B83DDCBA23CAE71ED2E9592A59F1A3B60AE55476CF8C4B954ADF74AA91B1519D817E181FF5313098E6D4A971CE9F33884E37AB2EBA33CF0F933567AC66A25A421D4B1412CF62C850366D5DC82418D209D6E904836E5512D4D26CD0D5E9A1B53D4BB06ECA4E3193D6DC61B2D930A6E901D5FA5AB29B6D3BCEEEA528FD144DA39ED191344F3F15E5B55775E49C65EB7C0847D2DB04A37AE9DBB6BFAD94973F3FAC18FF4A31540D6D98A45C3A37ECD8C1D7BEF7BBACD87613FE605DAD99F64A45BC6C2787B361A9F161DE7CF1395EF8C98FE83D7694743AADCEBC55CB288B44E539881C32D0DEE965D9522FF5E129A6A6BD8C8E994C4DC8491B1E52EA1C2939E2466225567729A53CD9F1172B33DDA4B979889B6F0E73E3E77E8BE5377C81BAD656952D6E8CFC258CFD35A9A4F4714C73FC68136FBD6172EC589CC854B34216BF5F082A4D5393AE245A475786F63683D6E634C17A17BA4F0E26CF4B9CAC61323516E6ECC914FB0F989C3A15269910762E9CDFB6494AE35F15325B6AB52754F681AEB36EE30877EE74B16193B4BD1E53369AD86AE25F12352B1F37B250C8B190945963C0F0402BEFEF4BB06F6F9CE1C176D219B1650D5249B1FB743BA7B3F89411E10F52431708B80887D334B76A2CEACEB2A82B4D7B9749734B0A5F50324532564F14DD3A3F4CF5BE17355D357A74BA685949A02A6EA6629D5625BA7350A74AFE10ED335BC7D06082277FE6E69597E48CE98C3A8BCE512785A8447A4B0B3D39C95379A095419947C0D9255A3189A97B0D93B4064B57AD64E7D77F9D5BBEF015DABA17D55AE9AC9C1C97EDA67768273D39CEDED776F1C28F7FC84707DE2795B2BD883388AB9CEE920B0AA95C378F3BA35AAD793C4975D2A144F7A584423ACD6A121FD13C79EFA16263F953E64D126AE3D7AF1FE7BEFB435C7FF777D097DE01EE044CF6931E791157FC0D656F4865B2F4333F7830CA6BBBA63975BC9E644AAAA265C3934ACD91984F483872C0501F411CAF6A01279BAB91C98AF44B139972333E9A65644432412437CE8EE314EE5B29F5D44A4D457B6FC34FB525B3CE705EB55A67CBF5CD2A8B259B4D2BD837354B1B843481A0885CE91F9F27304B85B454B443FB1B79E9C534C7C58B371DC2A54B22B3C0D88ABB9572484D8BA3BB53B4B5C758BF3EC0CA558DB4B44183783D4582854425CCA0A9135654B4DE96F692332ABD52F292DFB17C66C81247E81B2EB286A48E05999E6CE0C3A3D3BCFACA04C73E14557292A646686C9204031DB7DB4B3291626222C3F83844226ED2E9463B9450128F9DE9D62E808E351BB535AA1053A3BEB1816DF77F81877EE37B2C5BB7BE5602536EFA2B1668CE44A639F2FE3E5EF8D10FF8E08DDD24E371DB4D5F4EF8E66D99DCB7251C5DD93B8A0B0922595CAEC83D6EFF21EFF991EFAD34A3C58B43DCF760865B6F9FA0B1FB4E5CA12D688C6046CF91497C84AE966D5F5A3D7DFD515E7BC5CFDBAF87181E968E52A15C205A6590C8C766E2E2E112C9A06C05B71C18E752D906998CF05E5D9DDA68B9296A8CF75530212A73DB92F21853E2845EBABB4D5ADB9264B309F5FBF5DBB26CD818A7BE5EEC51A9F2B538B96383B95C1EE2890C2F3E1FE6D9A7834C8D25D1CC80155B9FA579A82F304D4F8F9FED3764D8BC3946D7620F8150D4D222ECDCC422DF59418F0EDBCCCE4952AB499148AB82FDB52516869B745C4A8D3C0C0E999CFB28C487475C9C3B3F8ED7D3C29A3506CB972595F40C8693E82E4917CB3035E56770C0E0F4690F673FF22A1BD2549A445E63521272866635FB7EADBDED2E1EFD837FC1FAED3758DEB2EA970A345F5EAA54C14B8C5492DEB31FF1C20FFF86377EF138D148441D7B33F39A45F72DE2E8794E6205AAADCEBE48BF7397D81F724ABC481229B9108F9A643E0873C9B07A8D8FFBEE6F64C5AA3132AE36D234E326AE8E5A75318DAE49DCCBC9B8F1118B6539FA41032FBF18E7E48998AAF592CA58B1E59C189B253545825A7E798BE8AD73B42CE7877CEC2363738A588E8AAB6F47C91D3309CCF94B81B456B97DA2E527F17813AA80B22E04ABD7C06D3B3CAC5E93C1AFFA3C1648309B2389932199C8F2D69BA88F64DB27E36E22514D9D2099C9B8C194542FBBA789AA5973D1B5689C5B77D473DB6D0DB4770CABDC465C89D9B3EBED77E68E7075AC06A5665BE77AC9BB445B999E763335E5627AD2C5F898C1E040828B17A7B878511280A1A905B66CED60DBF64EA4B35AC01FC5A50A42AD3D103B7C7ACAE0F4A90C070F8CF3E1D11423238D2A5629F57D79C6576E4B9C4858F177E9648AA5DB6EE43B7FF4DFB07DC71DE0A92974AC52A52E3FD9D7998B2146F1142F3FF6B73CFDFD3F657C6CAC0281D5866B96F74E8C5B0B713D6EA95FB2527FC42B2546757D83A69A8CFA8319D554D4236705FBA659B4C8C7EAB53EEA9BA6943D526803E6BC6B4EFD97C4B54C181C6867CF3B71A52A45224DAA2E4A0AFBD219AB9E4C72E452490DB1B714B77606AA6C64D6B6D0595850B1766D13B18A955944EED63555912C191475A1942A28EDE989B27A8DC9AA353E1A9AA6EDCE0AC59E45795C7201C5A53F30E0A1B7576362DCA3BCB103FD2E8606DC4C2835CBA38E73B53C84726E9B9B8D9B87B9F701171B3785A80B8FA9316ABDAC3D2DDE0F816F2229A95F5EC6460C7A2F79B9784EA7AF4F6374D44F2C66924C88CD1DA33E1CE0B6BBDDDC757F90EE45F578BC718CCC209A611DE8E7CC44F63C160971E9429A375ED3796FAF784325954C0EBB9821BACA4FDFD1A84CC82453746EBC8E477EF7F7B8EDDEFB71871B6AF126AA64DF2B53AE624FD1C86478E3891FF3B3FFFCC7F4F7F65AF9EF05957379AE5CBA29A5B9644E19BE9C4C3FAE62532DED5EBA7B1AE95CD445434B238DA10821FF043E6F4AD96A9252A4AA74F594720D4B4B6DDD13ABE060B1276C332C996332D1A05CFDE31306A954804C5A8A0F856B6618198933D01FA7AF3FCBE484B88CEB556EA369F87312AD76342BDECFBC3CCF5711D83D92AD1B2D63C0928EA2324B2EA516C3EDCFD2DC1260E9B2204B9706E86887C6C624F5F5691A1A244345CA7822F9CC5E67ACC2D70BF264EA48A524B6A4AB14AC48440E1F37B8783ECD89E3139C3F2769594D2ACFD1E3F1B361D324F7DC1760D3660FA1FA3EC5C08AACEA0255DEC27A51B165EED2754B3480B43A575A3C17126BEAEBADE7E4098DF3E722AA907272C2CAC2894434924989794A2F7C0FE1FA09365D57CFDD5FFE1C5B76DC843BEC87748CECC4CB9891DDEA8C32C902B22623F853473CAA73E47090DDBBE4A8DC18516929A002F7D5335C1CD88BA29249A7695BB58E2F7DE7B7B8E3F30FA9D4A91A3AFCAA72952B5370696F9AF43678FD673FE6F1FFF4EF19ECEB45A5D1151198A50316979158BA6FCE6B6469E52ADDC6E376D1BD38CA9AB5263D2B1A59B2B291CE65ABA96BEEC4C347103F423639864B9376D5025651D7CA47FBAB7259A7839232FDC49E70914D9B44A6A510118687A51E49E3FC592F67CF78181C4C914AD5D5DC07B1D2FBF39681B5EEBC9FAFC4D612496E6A04EA22742FF6B2624D334B5635B2746996F6F608758131BCFA902D21EC0E5105BDF6AD585D05666DF9BB6D2D4B4EB634181B0E71E654863DEFB838F24158F5DF073F9D5DFDDC71671D77EE6CA0AD5308CCDA3B2B905E78C687F532232B8462A8F435514103C1B44A01D3DD3EE51C7AF3F510BB5FF6D2DF9F211A09A8F8964857DB77A554F46CC664514F2F9F7FA8959BBEF8AF695AF3309AA74EEA6C61F44F3147FF946C7A0217B19CA9651D07653236BA88375F9FE4A517230C0D74CF39D75156914D67685EB68A071EFE263BBFF465AB20B37AF757557079655A06D852379588F3ABBFFB2B9EF8D3FFC8C4F8185E773E55CA221AEB468BC08A6DB1A2DF4C51794659B6CCC5E6ED4BD8B87511ED4BB752D7BA167763481C74107903465E22151BC46D13585522AAE1060711AD0D12E7865755D666B34192492FFD7D2E0E1D1CE5E0FE04972E8495EA28D9F2F3BDCA4930CB5DE37C63A87893DB9BA4B523C09235ABD9B87D2B1BB7ACA37D512BFE602FC40F939ADC873B73CC0E8C5BB329D705AA96792A4237EA559F8BFFBFBDF7008EEBCAB204CF4F6F002412096F0847C2D1825E34A2E89D4851DE95E9ADDDE99DEE8EAEE999D88D98DD9988ED8D98D999888DD88D9DD931DDDB35DDEA2A95BAE468245AD188DE889E040D087A7897DE9BBFBAEFFD9FF93391402640902575212352AC427EF3FEFDEFBE7BDF35E75CB9ACC3B1233E7474F8E1F715C060E84753B3092FAFB2A1B6DE0783816A25C32CD8435C66D466421D04A110B9D5E419003E2F051F02080644D4D605D0D4222237CF0C8FD785DD5F8838B4DF8430C13008266978099413FE1C221A9AFBF0CE7BA598B3E67F024A37018201A03DB2FDBF01037F83709014CC9F985652E83F12AAC6C50B76ECD9E5C4A3FB6549F07A19BD0E69DDA19C6E7E650D566FDB8175AFBF89E2E90DD92818830C983CD09B580CF681011CFCF5DF62FFAF7F05B7D309AD96C2BD7C2589AB94B4B74A57C9C06705E11C6A5037BD1FAB5ED1A179C15C1456954353B40D30BE02086E88FE7E88CE3D105D7B100D0D4223243A80479B40D9D4E4A5EB8F4AC5860887CCE8EF0DE1D277B938755C83A79D44F836290D09494367964D0AEEE8F42A54D46AB068D934CC5ABE0DC50D2F21CF5A0295C60CC4DA10739C4570E0100CE10B1CCD78144B952A9BB1BABC59EE2906743E29C5F1633E9C3CE1C2F06005349A10CC392AD4D60631637A248EE54F2E66C027C0EB15E0F650D04480C7C3713EC221354221E27AD662D1522756AF8DA2ACC20A8F6F105F7EAAC537FB6DAC0C8E083994E162AE005168752ACC6EEDC38EB772307DC1FF0895752304BD19318A79D93F061C9F408C52002B011CCB174A5A204BD17663087BF78470A7AD0CA120956F319498F4E9598590E4066C52B0BCF22ABCBC712B6BC62C6F9E998D8231D09B49836D134321067073E0E3BFC3892F3E85D7E396FAC1464EF991164CF9546E94969AB172B509CB56E9515CBF019AE2A580C90A443580FB26C28E6B88F9DBA08EDC0544E268268EE0D13FA9134976C4C6734EFC5881228C5ADC6F2FC7D7BB9DB87AA51FE170497CE5CDC642F063922D78EA7972A85F6BF43277F0A5B5EB316FF94A9452F5734E1E10ED067C0F01CF75843D3710F33F8056EC1A7969791B976660632D3AD2BA88A1815A9C3C1EC03707FB30D057060D2B8826BC0E2F2C7961294A1941242AB07D2B6B980C9305E3568C2C1BEF388842AFD761F15237366CA6EE882278BD7DF8F2732D8E1EB2214AA8CBD47A14CFC748F211E83C0DE62EE8C3B6D775A86E5C0AC15006ADCE80703806F8AF4115BEC9705988AB4CF9E1FD6825B87BC785037BC3B871B5043E5F304E319BBD058B22AFAC122B366CC686B7DF4545CBAC6C148CC1B63D1BF0A8C2D38B05FC78D47E17FB3FFE7B9CDBB71B3EAF87551AC87B0CF9C133AE1C622F1A1BF3F1DABB7598B7540375F1CF20E6BE0321721DA2E32CC28E63D004CF438C11352935138EBEB7483BD9E5BC4C86557EB4D59D05E6B5406F672DF6EDB1E3EC69073C9E925119154757B8C4EE2BDD5A4A7D563A9D06D35BF458BB6506E6AEFA23E44D7B1950FB20FAFA20BA8F02DE6F11F5DF872A4AA4E8A360CF4F002B9E55553014E3183A9F94E1DBA31E06F946FB196AA6646857727E50512FCEF725B2054D1E0F356EE8B42ACC691DC6BA8D2A343694C2EBE9C2979FAB71EC6821A8B692BA03D8E5E2DD0C2A9692A1BCE39CF93D78FD2D3D66CCA0F2AD21A8887D932A73D8464C823E4879A72C692216E3F61D2757B06BA460B4971C0FFFB28068240A4B7915566DDE8A756FBE8DB2A6966C148C018F4E1A7476D4EFC3833BB759C325113E109DAC462E954A996563AE1C620F66CD2AC05B3F6B41F3522D605D07A89640749C4470F85BC4820FA11728512CB35566693314378D5BB031942C3E6F14C7B0F81375CB68888FAA1E07BE72E1CCE901B85DDCB7CFDA371BD582F168216FC074A26A9A1E2BB76CC2CA573723B7AA1E501B00CF5584EDDF21E4260BFE006AC1057526175929702504018B4CD08696EA97F8BFD108C1BD090804B4703945DC6AD3B0F4C583FBB407B32A8204D202A16CC81875E32F22160DB2CA9796D98358BB41839933CBE1763FC1179F03A74F18A0D150E995C06B19CD226B8825B7D1EFD73232F6B2CA2876BC61C4EC390550AB79A180BCA74FD0CFF0B920E7DB98158E56E1DA353BBEDAED41FB9D72D6459DDCA93EF6124877A12047FEB41AAC79ED0DACDDF1068AEB676433E9187436EDCE2744FE90F2CE205B3052B0B35FEF81CF474D911340F2650A9687377EDA8296456A08A616C4A295883ABE853A70863745CACD6063548D2749406617517AA2A95E5AEA22203F60D2844C2858CF933A7CB5D38E7367ED29A4E7D9C83EDD317225018F9AD90AFBF1F2AA22AC7CE32F50D5FA3A049D0370DD47D8FE1554BE436CCFA1168319F75C4A448478948F418D081009AB9E1A39239467A21A4F15FC5E4AF28A18A2C2DF1E8187D01F1A100850529B1AD4C636FD4A0BC44335DC92A9555118F56A34CE1CC42B6B35686A2981D7FB14870F4571E35A217272222828105058144649690C168B01B1A80F8383B9B8D71E4628ECC0824546CC6BCD81257F60A40047A9180906AA70F6CC20BEDAED47D7D3F204544416AF49F63122A1306C750DD8FCFE877865EB36582AAAB2381B0626295114274C5FA45CB3C570089D8F1FE1E06F3EC2892F7E07CF187BB0B146278A039831BD00AFBE5584390BFDD01BAD88109E46F829B4628F9477CAE868A6BD059B60A92B43AAD28DB13BE2964F8DA8A8C283BBD5D8F3A50757AFF6214AA4E793F2E1168C5C92AA9A41BCF96E1D566CFBA740C97CC07B05E1A173087B6E422BDEA7A3E2791FC55A3062144A05A31F633133A231334201239C947E180C60603088A1C120ECF608DCAE30027EEA5250B38085CBA945C06FE2D8182998EF72BE8E2B12AF8257A902EC4B500F328624214F51C3ACAD408586A618E6B46A505161414C74A1AB93300FF3599135B360A628B36004264B8BA9CFA767166C68B09F55D04FAB56A3B25203958AEA1A154CA4F293CB5B3768118D08E87C4A2EAE17A74F0DC1612F91E0DB33EEBEE2722413110E0651DA321B6FFE0F7F82E5EB374067E1FD68637C387D91A460CF4CC0C76E148B61789047110F7CF42BB85D3C8A38EE8FE846619111CB57FAB06A4D1065E514BA758D08ECF3B1F3AB674E49A49A27650B4922659F6EA28E0890A84C8CC1E3FCE97C1C3DA465653C10C6D788974926E46ED637F5E1ED0F2B31FF957711D54F43CC79186ACF71C4623EA884E4E2DDF84237A63C789781C361C6D3C7847F08F4F71A60B7ABD897FAECDC2E0D0241824E20C01A9E182446D0E43AA8C4DE91D7BEAB5835874A452E9E9AF163134F765E3E90638EC224B5B0E4E610C11D505814454121752BA8A05613745CCADE51DE83B117CCDF2D7D3D6E3DFAFBA288C622B0D904582C5AA834A178D79032CFC7BBBA690109E3CC69338E1FD3A2AB9B0AC773797374C6F861E20D51B1442414C2B4F94BF0C12FFF45B6A55249047C9346214B05BE877FFB11BEF8AFFF11F6A141E8C660081C3D861686562B625AB513CB96E7A275411E0A8B5C8CC01C4290458B184A2FA12D49E17FA664192C51A649ADFC5DEE27621B7979E5A65AB98080814123EEDCF1E1C2D9003AEE9AE0F713FAEEC4F360234D0E9FC0D39BBBF1E63B4598BB6401C2F4AC810E68634F24EC0B05A0AAE2027CC54CBF15E4D5F331DCBA69C689633EDCBDC36BFB62045C23522F9D9EA112B3BACA24E2B9546F419634EFD9D21B5CC8B786515424A0B84485A2623D8A8A7528B01A61B168186091CE40C9E310080E826A17D95748ECA1651802F61E47312E3446EA0DECE9F6C3E924BC12036C85B9AC544EADA1026D39D34DB82C60D8F5ED77023875CA83DBB7F5888469B13748A97C7925CA22564F765BA346F3CA3578E79FFE391A5B5B256B3EE68C4AA2909D38097ACACBA44A8E33BB3FC7E7FFE53FA0EBC96308B128CBCAA75B30468FA1F1E30D462FCACB75685D10C2ECB97E14166960300498F251CD619C574FDED44A00827C3A70949D0C81C25125C438B262146226C8310121AA97F3E931D417415B9B0137AE6BD1D31D818FB5A54CCC5D1DFDE66A863D5153DF8537DF3160E1A232A835BD1029E9C35AF047CE4065B89DADF892754FF28655D4B11CC5B7872DD8F7950EFDFD21D6252CF7D131776F5C02A3DA4415AA6B5C983B8F5C3F2D8A4BBDD01B4506444AC8C75A09758D61A828C424EFD3D8EDD24F8F64F1B012317A1F31F4765B70FD5A1803033E54561210AA0EE63C17EB90A6EB46425A381D21B4DFCEC1D54B547D1F82D747B583B4202447BA522DFFC8C54E445410505852C27AC1D6BDF3212AEBEBB369574922415F0EE0D47856F8D18E258B72E3DBC3D8FDB77F83DBD72E23EC718F4A6496EE5D26F2631426F643AB0DC36AF3A1B28A90934C282BD5C16633C092AF81D1AC651061044BC00A0F0825374A2FD705BDC1CD1A02A9EE2DB31BC9559DEA0B7D5E134B8CD26A47F8105E6F084E570483C301F4F70631D017465F9F80E161CAC168019188DE64B3319AF918DD56A797A30A91B08892B26EACDF588C652BCCB0157642A5A25074729E277E67297A41810BB94652A50AF22A77492105958E052ABEDE6DC0D7BB0CF0FBC9359320BEA58997BEF33775941CB64DAF73A2AC5C83A52B4B306F8915C5054E980D3DAC235964D5FB325D4B0ABEFE18B1D6A477A5D005A608D2C2E1F594E3CCA9011C3D1A462C22A0B4428F7C2BEDD9A8DA260A8F3B0A872388C1012D06FB09A35F0B51C891D68E941AC4783839FD9BA0F91C1654689E3B0F9BDFFF29E6AC5A070B01B964DE93AC1004E1B4BC07A359E2992C057B72FD2A0E7EFA09CE1E3E044F7F0F33AF636D2913962C3DA73225200967DE9A1F41510160B18A30E751453DA0D14559F126C3DF23C4A19880CA2A2F9A9A0514D8B40C2433B382515041446F4F1EDA6E86D1D3E5472492C7AA0F68127ABC04EB4CD5E622BC5E2A3CA58D7CA29029F16CA3F5138D6EAB4753307A16B379180D4D26AC5D2F60DEFC21E868D3CF26ED88C59DF35B886A84FC51F4F751D5BF0EB64202F6211838B62161B81A544FB8FB4B13F6EEC9631DE76A96A794D19F92FBED94CB86EC82F35BF33D97AD7010CB97DBB076FB3C94D6EB1075DF84267C3FEBBCA46CD064E9B0FB29F7908A6E07F6E778074035CE9EEDC367FFE0C793C715ACB3C264A242640D0BEBFBFC225B24D998E50D5C7C11CC3EB8C1C72322A63360E5864D78F3177F8CD2A6598C6B218B4F8E2008DEF8D22A8AE24D0033B33871CC436840DD6DD770F8B34F70E2D041B87AB351307918891AC5C45F24C952EE4908F22FF9F104A8C94B05E33E3B557B93319B331758BB01686CCC8529C79D9E1A36C9B5D53032F35B37CC38B0CF8BBB77F923F2D587F627C4964298E8BC26317986278F34FD0628D9828DB467D2644834F3B331AB541E8605D23A9F7ABB4CA8A9D1C1924FB8F2BC0F8D0211E4C2FA7C5AB85C60189003BD513C7E32C0BA7BE7B66A5137DDCF6A05793F98112E6718BB77EA71709F85291887D54B8C68B4E997FA3EA82AA36646003BDE6EC6B24D6B00831A81BE43D085BE8B17DB663397C68A7EC675422130B694C66A70FEDC203EFFD48D278FAA587045A592833EB42F277CCCD11A223329189F186C4962B0786AE4575563F3DBEF63E31B6FC158941500699B2008B3E27348D2D4BF03F0F36C8432D631A460B74E1DC3571FFD0D6E5EBC88A09B7CE34CB9B0912B7CEAB4A51947CD8FBCCB59423115F83E8C2E4FE936FA33350436B60C60F55A3566CD31212F7F28DE891C1FF788CADFFDDF19000020004944415406DEF57AF552310EEC8DA1BDDD8568B4885945F69A24D01ACEFD95D833903B26ED76B2DB294B0348FFB4BC7B80056FA46E027A205A812DF94E3434E8D13A5F8D9A3A178C66C2C9A0E25AB2B0110CF419D1F90478423D545D7A385D8328292DC02B6B2258B8C4098B85A73AC5580EEC4321ECD9ADC53787F2100993F5CFAA3337E59513C63CD0D40ABCF1610B5A56BE06316281BFF7773084BEE12BDE08FF5FD988CA2F97D9B31839D3481EE1D0349C3DD38F2F3FA3BC5605271004B9A552F7015F19273095933D10DAEF99CC66CC5BB3119BDEFF299AE6CC81CA488037192FFD9120087F94AA607F0AE03F653C756CFB855838CCBA993FFFABFF173D4F9F40CD9A85328D68B43D8AF47791DC9B188B3CA9D501A8052A1A25EA5380007E8C26C2D253312239FA565485307B8E809A3A134C666F7A86C8A4A5530BAF278C5B6D5A9C3915C6FD0EB20A1CE093376B126215C7B66751362661E5A2C19D9DD12DC1782D183F9EBB45A4D42E98CD9C76A8C016414E8E8E85B7A9629D5860A8A8D6ED56C1ED52C1E7D12212F3A1B4CC8A975705B1F295204A4A88E1C58D68C48CC1FE20BEDAADC5D123D609E256B2BA06561B386B610C6F7C3003F5CBDE8318AD44A0EFB7D0F9BFE67D598A3442C21F4804C7D9D647E90E6635F17819D5D0600D4E7CEBC13707FB3134502E956EC950B0F285322BD8C85929470078AB4F54A541D9B41ABCFAB3FF0E2BB7BF0E1301698E1115573CC29F0982F09F5315AC15C0E5AC9E73B483621138878670E8E38FB0EFA35FC1E5703C534733BD4A66AC62215636632B0CA3B8248A421B906F89B2D6782AAB61F4393AC2C910410805E69C30A300CAC95543AD65BD2423169DE4974BA541510C0C709CC4E1A1187C5E2D3C5E353C5E153C2ECA0FA9189029B9619427628036F1CD83DCCFC611B446C614C767E9525F3CBB9E84F84BF5773A0AECA86371F611AA17A4081BC702A1F44500967C03162F7160DD8618AAAB7320A8EC88B22E8000BEDAA3C3B7472505CB6EC224BD71BA07755237CDF5E28D0F6BD0F2F29F00DA79880E7F02C1F519A26127D4042390F249B7E7521E9249E1088827148AE2FA151B8E1CE250DB3EEF3362D92BB60ACAF151F57C4E511996AFDB888DEF7F80AAD9F3C6A31AF30541B892A4607CB1148701644C518FAA5F011F1EB6DFC5412AF6DDBB075E2AF64D8BC9915ADE3D728567FEAFE066597D6B911EE5D3F25159D7848ADA065455EA919BE3872E760F3AB11D22C343A7DC18E55AE8BC10A0A28AE9B0F4F70CB2916891588543D4CCF65C8447E1F3C6E07687199AACC311C6F0608801E20C0DD22A4A8C97D48A41D4A50C878C951E29AAE314371DCD428F3DAE116E323B9CBB921CBB9D52A0149A9660CFD8EFB49247A0D5AB317BF620B66ECF4153B3196A75376251034B907FBD5B8D6F0E9A18508F4A208B4CFB17AA44D7F12A736AE5A00EE4841D4D513072D7639856E7C4AB3BAAB16CDD06E888C6C57F01709D41384C9827894478AA4D49B780286F20EF48897380B7956819E780DF9B8B278F833879C28F4BDF890CBD3916CD4D00C38E10E7D8724FE7579192112484D66044F3E265D8F6C1CF30F7A597A0CAE114B5597CEC82207052B1D468A9288ABBBFB762DBB3B848DA43226E27AE5F388B039F7C8C5BA74F22100CA447951A8107387285A77D9BC5E2465DBD0EB31656A2B9B51CD6CA57A0B32E8629C78B68F0092283BBA00F7C8398A2FD5B9EE47C351C694BC67C36791892196258F01111E128E172500B06299488C1DE5C74DC8DE2D62D118F1F99E1F311180F81B624146CA2329C9CF328544F89FA1E6CDE62C6A2A516E4E675431074AC92FCDB2339387CC8C0405C094957A727A6196AEAD4B31037E5CA68528F2E3F9AD83114D806B160610E96AF2E477DB30A069D07B1483FC418C19CCBE904D9A6CB2E6F62C720871358FF9A341BF9F689AE4F1C61224B1887C26AC67FD6FDD48A6B9722B8712380FE018B84D01DC7EF4A23BAF1790E6CA1A2AF568FFAE666BCB2E31D2C58BF058565590536E4FBEFF9DE7ABD369A82FD7300FFD7445F72C8318C73478F60FFEF3EC6936B97110A87460F7024E43EB2B35970C166D360E6FC52CC5F5A8D197397C156338BC3EED279A17B80F31A42C3E7A00EDD4AF2FF922E3B8EDAF67485F07CEB48FFE1A8473CE441188D343981071D3A9C3BEBC49D5B7E783C858A6AFAD1D6C6747F9FA8B413E78D5CA7B902E45938D9C2EAB54634B650D91A108906F0E4511EAE5F25727727638C2C2AB2C06A35A1AFD782AB57BCE8EDB5732C7DF649B797E17B14ADC689029B8859F372B070B18D45394D26473CDA1B47E865095E65FE8E339512A829DBDF82F6B8F4BF698F4BF9471503A8191EE20C97834341562BD9DFAB425F8F00974B8348344FD249C57E354994B2EF97E8A2573E8D6C25952916B25C6A8D06B6EA5AACDAB20DAB5FDD0EDBB43AA84970D9BFBA7F2108C2FF3D9A82CD057075A2AF9CD8554E1DDC8FFD9FFE16DDB76F4861E04C11C49177A39674A22A5DF5EA222C78B919BAF24D88AAE741E5BF06D17B19F05F0102575927B34A748D88A1287D69B9962DD333A5F3FFD975A43400C7FA90A09AE96F6A627129C6C5F36E1C3F16C2FD8E6296E4644C28232CD9B3E123661AFBC8759ABB086AB51F05053A2C5FE5C5AAD57E1497504B8897C11ED887A3AC80965096AC16A26D75E1DCD91C9C3D63C2C08097E1EC67FA90925154AFB0D083FA7A356A6A81D2F200727305063C4A08605A796F4C9537121432617430E2F82079045454AC82CF47A8522A78DD80DBA386CBADE2F4530E151C0E159C4E3A962CAB2E4D6D64EA4893E59DCE8E25144CCAA18A31882A358A4ACBB078E316BCF2FA5B98367D065484303BBECF3C4110AEA55530A6E1CF50594F0A76E2C03EC6AED273E7E68415CC661BC692250578E5D5A5A85E540BE454001E0D02F66B88786F4188F6428341BE522AF0FE647B23BB1B720D0E5FC33278FE693894930A421900AAF4A1FD964A0DBFB70C1D77633874D08B4B170D081316BF1CC71FF15292126FE37B65198E4E8E5E2A77ED21A83531D4D47A317FA18131D654544661CA3530D4DD48D0049F4B8DFE3E11376FF6E3E2771E7475E5B2AE64EE224A85816306E42855E28646E36318FEC4AE999F6F6055F184C748C97142FBA2A82FA55048865406469DC8048413F013B554041E2F2123C7583E8FB8CF08DB834AD5780E926A24759207415EC468AE7FEA4065354A0830F908FE7B54A2812AA89C86852FBF8235DB77A06EF65C08C407360ED3058055D02B5FD708C3278AE25F01F8E389CC80675630A9A0AEA8A80F4B97E660C5A6C5A8995D0168BC80A70B51FF63A8A23DBCFF49D2A6B81727DB7F86A19888BAF12824E7DE8A7F58C90D2FD3563A184C0D59E63F39EC487FE3FE39BF56344670D9025C8E7CDCBB1BC0F16F63686BB332D67BAE6013CBC24C44E67141A48B5F4ADCC83A1DD1EE6A30A3C18759B36228AB36406BF620E43161A03B8C9B3734B8739B5A42C2088769C54EACF9E91170A5BBCAB895526733059874942A218F8AF8BDA8DA8555C273646659B42CF3C1F29AB45794BE51522A5EFBC95223F1F72B0770F8FB4A798D29821E9FA740DDD03493347A034A2A2B31E7E5D57869F336D4B7CC8496F25DE3552FE0AF0541A0BA5EE5544B7EADA228EE00B073222F9B14ECF4A18338F0E9C7E8BC757DC216CC64B2A3A9290F2BD63460C62C0B8C8610C4A81DAA98176A78391D903479B8EBC6B3BFAC383742FB8C18C35C8F8463AC048A12860CD69ABD2322D1E61B6D3E016478300E15C6E0C258C89BD773B2426549C1E85A14CEA7521C873380AEA73174B4FBF0F09108A74362804C52D931A498BA599C88C0D3BEC691ABB828FA59A5435E1E295A14668B1A6A5D0491A00A7E4F0C43831AB8DD4686FBCFC94E958BD1086AD2949126F63AE442CB4C2771FC79D6ED9042E6C05C6FDA859145A34A122EEC38277622FFA158AA128B6A625BA8B450FCF7B1B05E92F7AA02A2820A1A830915D3A7E3A5D56B98F52A9BDE00BD394791D51C97E7F1BA2008BB32291803449B08AD6CD861C7A513C7B1FF77BF41C7E50B08058350497916F9E132A7FF683E531E4787FAFA18A64DF323D7A282DE10869A42B6B118235B602C8FB4E2318522B45DFADF9C88815B1811B1306DF6392B223142F26836670B61896BA650F2824D0A96E83D62E17ECA2B71B3C6CE25286D725D8201353C6E2220275E32AA50A734C138FADE46615579261D1BF364EE52315AA72827EEE3AB333DA3B498C805C1D275B2794F99C62B8B96592C897C9030E83989BC9498579AA44C174C1836C95ECBF899BCF62553CC9857F38BCC25D4E9F428ACAA46C3DC56B42C79098D0B17A1B4B24A720B95C996C402926178046745F587491CC46963231305238D7A3DB87DF50A0E7EF26B5C3DF60DFC7E1F2B26954DEDC89796BAA6C812E4792D8DC605A321CA2A350C465E0E45E15B9AE4A448F42F5330FA57A255958315D272169749FCDE8A052975F33B4218D21F94C6865D87292B15969A58989BAF9CFC6AE97C7C3E8894A74FB260C97218ED456677D46867D3FDA99E8C972C2582377C9F954D15FD78EF9FB4A82A9F97FDC05FC4A8242769328A4CC6D27564DB95789DB2054BFFFC04A8439952BDC90C6B6919AAA6CF40CBBC05685DB20C15F5F5D098CDAC4A23B91E2731CE2C74FF534110DE4D3D6E34057B1FC06FB3B868D22122913F3C7A8C831FFF1D8E7FF1BBB113CD71B593252F4FD1C416962B8BECAE717E60569328B98772DA82ED8DC65A72152F34B9765052B1314F563C621CF157AA162437930D51B2108A600A1F4EAA0A8FA53A09393CDB51D9BF35E5E852CF4A27CE6C9F26D302215F3B9357C3ED536224AC9B4BDE378FD3C4EAF57AE41616A1BCA61E8D8B16A171D112544CAB436E7E21B4FA7184E147F7183F1004E1936C158C1C71E7B8DD44227F703A71F0E38FB0E7577F05978323FB8E2E8B74168C3F416282D262479B51E55FE4F364AC6BF9B1D2AE17D28FA99219976F9D24377E17F9A994FF26EE9F34FE74162CCD15D35ABA64FD8EFF3FA54CC76B59D2492BE3A44FB21CD9047146E69F322954FAC9997852A5051BCF32A2329A307DE62C2C5EB51A752DB3513C6D1AAC25A56CFFC516C1A46933A17941EEA1452042B994CFA8335214C5BF07F0D3EC1F841F190D877166CF97D8F9D7FF199D8F1E428852B9D258135F79879151A0244F4A3A74E48B1A99F750AAC0789F219305917FE7063619B538B31D9AACD124AEF32C96259D7C478C70DC7B463E22D90271FBFEE23F54CDA2D3EA503B6F3E566DDF81052FBF024B59657CDB327244F2486589663DE65F0B82F0B374478FA5605B015069F4B83E147EEDB8781EFB3EFE35BE3B790C81E1416834540591C547E9CA4927643501D8A52574145909C7087E8D77259597B844518EC252B1018EACA3CFEA79B31049FC903104919A07CBD6A2657B1C1B83E2FE639F97F85559C494CC9D339E071F796C36E3A648B2A037A2A6A1096B5F7F032FADDF84FCE212CA7C67B8F9842CD8AB8220EC1D9782B1293B9EA4B3342EFAC7D3D78B9307F661DF6F3F42FFBD5B50A949C1B2B062E35829D32A8982CF692C294E4CC1E82CB9C8565AE1E2F74B61414973F3F1DF53719114B98CD4B5641B369A454B1D033B8E16A26C3031E4854BF1EF48CB947AE7911621DD18A4E531ED2B8B13F62956ACB12C36CF6D09D0E90DA8686AC18A4D5BB164ED7A56FE440BFD73F88C482E2BEF31E6AC1745F1DF7CDF0AFBAFB21A9442C1847008B7AF5CC5DEDFFC2D6E9C3C029FC793D43D95B85E9AB5284B93359A82716396BCA348F790E3B330CABBA5EC5692C63BF279461370EAFD332A608A0549DE83F1B3F9DFE4A58C07C2D3599ED4FDD658133CB592411974E02EB2D2FF4B4C7D194087E5C3C62A82CEF4E069E6435A0B26712953858DDA9483E93367E3E54D5B3077D90A14555442A09EA6E7F3F9B7DF87E6FFF56897CEA460840FDC9ED5B8949655A43ABD215C3FF60D0E7EF2F7B873F33A34145F1FB1171B6B2DCAEAAE4907C97C4D2CE1298781D92493BAA015F3617C0A96692CF21E90628A233B77D3AD68E356B0318630728ECA3886729E68A29B20F9FDC8374FB15963744564A560E3F058C67C0394DB8A46A1D61B5056518986854BD0FAF21AB42C5888DCE2922C3AEA33BDDF317F6F1004816898D37EC654306E0C44CA4CC7CBEFB31D8A188DC1FEF421BED9F9398EECD9057BE76366595865447CE553DC5E094596947CCC5E15A84F8A880062310AE6C8FD4854A941BC5354242A61B0C733FE7C28C4711C8B117A38A1C5CAC7294B9EE89A1C9D4AA5D240C57A9412CD9572628160D588278B03D3A4A03FB147A5AA054A7453DF55622FC092A42CFD10842886D8B569AC34165EC52FD918318C98482C32D26F52027CE43B21AB41B2A0B110BF0F2D38F455DE9FAA36D2BD7E4AAA13BC008105D138B41088E982FAC446A472A52A8D188D89EA30F5E49C4925A0F27BA3670BB21616966312D4ACEF8C5F2FD502CA952054093016A686D471CC881F002DE5B64A4A50554FB9ADF998BF6C05AA6634424D09D4D486D24C5D9DD94E707EDC6E4110A8F269D44F360AB60DC09EF1DD971F4D64100FEFDEC1D12F7E87EF0EED857D68082AA9B032C9B74ED9034C04EB82262875F912C08BD1487B595E784B7F0F3174282010882116A5E64869C24A0F454D9D39393411F4F07A22710C76798A683451188D8442AB43C01F422048CAA3E43DE395E2063DA11B09D06A692211A8269F41BC76925659354241918F25288188B0BC0EEF10A6A8B1C144D3500BBF8F3017A38C26491EAF4E1B418E598570540BAF37CA7ABE52958455B83366502E078651C8E0E4A9729E933AF802220284DFCA0A3A945380EF258D240F33659D38CC9BD71745384CCD8FA9B7A3425F01B9391A683561783D22A3A14DE52FA5CA7A82C2D6A8F5088522F0FAA8E46C64FA46ADA61618AAC451315EE8919F44B458ADD6406734C19C9B87A2EA5A342F5884998B96A0B4763A2C0505D012E458BA4F3AFF7822939B9FB35D1084AF9E49C1D85414C5EB00668F7B1C620C619F0F77BE3B87C33B3FC7D5B3A7E11D1A90387295B12FF9C5A5DB6D67B660947E50ABC328287063FA0C1D6AEBAC28B0A9A0D56A19EEC4D0A088FBF71DE8B81B867D98F0D0E9E55225468C612ACE9A17C2A297D408074A70F9BB01B4B73B100AE5733C0C4180ADC88DE61603F22D35B8DDD6858EFBC380688DD3D788F03118E78626118D8D220A0A721887166B5D913629E4B6067C6AF4F6BA71E35A0C0FEE9B58CD24ADE85499662BD062E61C2D1A9B694C36DCBDD387CB975CB00FDB58153A294E79B91B0B17E46268B800DF5D742218084BE7F3FB08084360F0D5C3282B03EAEA73515165445E9E1E1A751481800A43435EDCEF08E1C183309C0E2D22E17C49C7B8F520BAA4965961B4CEA78522174F9FF4A1EDA61FDDDDD4E5AD0344DE9347CFA3D3D951542C62EEDC5AE8F5415CB9EC46E7530373D7787919D10EA931A381AAF9D5B0E415A1BB6B0857AE04F1F4491E937F62DB20C26AF5A2BC8238B0F3D0D9C99F59B9AB90D7C58800D88A8AD1D0BA104DAD0B513DA30125555528282D839A81D264B41BE39ECA694EB82108C29C4C17CA6A24A2283E13204EC03E8C9B17BFC3A9AF77A1EDF4B7181E1E66139B15DA266D0F141392158366B77750ABDD282B3560D1E228E6CCF5A1AC42855C8B9FE13152898CD369C1FD8E00CE9F51E3E6953C385C21888211629426800A1B5E1DC68E7783F0399BB06F570FCE9C71C0EB2D23DC2E36CEBA19BD58B3DE8042DB3C1CF9E62ECE9D1B82282A48B0C541D4D5E763D35635E6B6F6C19CAB815A1396CB3CA4E27C11A1A019FD7D211CF85A876F8FE4211426945E0D44A10F0D0DF9D8B6438739AD7D10C40A5CBD3C80BD5F07D0D15EC6DAF3495967B6F462EBAB3A3C785083DD7B5C08F808768D5C4D8EB645804079160D9A9BBD983B2F8CEA1A150A4B02309BE837B2421A381D513C7A58800BE723B87CC90BE77029A36262A84C620866B30EEB37BAB069AB0F46830DBDBD4E5CB964C4C50B3A3C79E2472060918AA54594940E62D11213162DAAC5D0D05DECFDCA8F071D65F1944C2C1A86D1A0C5BA4D4E6CD91E408EB9184F1F0FE1EB3DC0F97345713E30B2EEE401CC687062F16201F7EFDB70F6345968A9BF4E9AC56CB6C480A000CC6C6DC5E6F77F8EE665AB602DB441180D9A2293064CFCF738B0CD335B30C98A1121539C42645CD9025ABD1D0EB45FB9889307F6E2CAB9B370F4F530042A0D533479888AED7A9AE8D18807911BFE8AFBB168B109AB5615A1B2CA05953A04414D2CF6E4E713FAAE0D030322CE9E1470FC48085DDD0ED650C8154C8DCD3B9C78F3FD203CF606ECDDD58BD3A786E171974B164E8DA6997DD8B8D508ABA515FBF7B6E1CC99640513453B1A1A8AB1FD752366CFED81CE40FB161E2E66CB3DF53545A948380F7DBD220E1D0CE0E4B72242616A6FA13D56375A1794E0DD0F0A5037A303D1481EBA9E7870F4B080736738D184466BC19C39FDD8BC598BF6BB95D8B5CBCD006054B43F625E460CF9D601CC9967C2F2E556CC6888406F8C40A526A613096B0E84EDA886DF538DB3A7EDD8B5F3217ABA8A183D2B57300273D562F19220D6ACD3A1A6D6CC38CAFA7A0CB87EDD854B17DDB87F8FDCED306C853A26F365CBA8B3B814A74FDFC7F9B30E0C0D15491E0AD587866036E9F1FADB216C798D703AF230D0EBC5EE5D028E1DB128142CC68065E7CFF760DD3A03AE5FCBC7DEAF3D9282251A763926A2C848625F5AB306EFFFC92F51397B3E54CC071EDD23CCCA8A8C4FD17A054128CBE694ACEF2D8AE2FFFAFD6CFDB7A94625DB0B90B90FBA9C7870FB362E1F3F82DB17CEA0AFB3133E8783410BF0CA6E1E38C8C6C433FD8BF1956FDE82416CD822A0A1C104B3D9C1F1020322BC3E2018A60A7C23ECC3415CB968C0A5733A46D703E48002314CC15E77E08D0F02F00C3760EFCE1E9C3EE184D75DCE2C072D00CDB37BB0F1552DAC9605D8B7F70ECE9CB6275B30B81934DACA57FC58FEB21F46530E1C2E2F471A267C09AAFA0F032E470E1E3F8AE2EAD5281E3E20801D5EDD2F0ADD98BFC886F73E2C4075FD3D88613502DE18AE5F2DC6C17D51DCBD3B0CA88A99826DDAAA41FBED69D8B3D38B6088507B49C138877153731FD66FD461D6EC3C987206108D6AE0F347E1F1D23E54C3BA0388A235E42FC3D54B761C3EE8415F6F39345A59C1780F5751D130E6CE3362E972E2C9B643AB35C1EDF4E3F6AD3C5C380BF4F6D9513FDD82152BADB05ABB70FE5C0E8E7FAB457F5F1061C2BA975C8F68842BD89BEFF9B1E5353BD4C8C5409F1FBB766A70F4708142C1F8F8172C18C6FA0D02AE5D2EC1D75F11EE630C82825F4E7EE70141C0B235EBF0DE9F9282B58E5A9991A8AF97F394D9A84456C7FC2B4110FE8F6C8ECC563FC81FA60E342200666CDFE3B260F248A43DD97077271EDEB9859B972EE2E6A54BE8EBEE449408A9A2610834EB14C5B7BCE046EAF251F8D68CDE9442B32A15D66CF060FB1B020A6D640D1D181EB2E2DE3D011DF71D181CA0C90504FC2286078DB00F99199E2059366EC134D8FCBA1D6FBCEF87C75E87037BBA70E654105E770E0B2250D4B0A9C5890D9B75B0E6A757300141180C02E6B40E61E366C06EB7E1F4E921765F3943400105D6E6E2224C093DFCFE5C29C8A0620AB6606101DEFDD086EAE9F79832AA440DBA3B4B70EC1B3BCE9EF5C1E12CC5EC39BDD8BC4587F63BA4603E8582B9504C0AFE72082FBF42E475664445178606F370F74E08F7EE39601FE6FD6D460391FBE5A2B73B88CEA7D43D6C95F68A726A83026F0E58AD31B4CC12B0E4250B66CCC881D9EC82C76D44E7D32086ED84C55188BCDC62B4DF798213271C78703F87054212EC25D4E91084C9A4C39BEF06B8829105EBF361B7A460B457E3D695A0D1B982AD5B0F5CBB5A8ABDA460315278399AC8FD015A5449C15E5AB30EEFFFC99F73051B23811C6F8BC9461BB23B866A742B08163B9BC3B35630C94DFCDFBEFFF72FB3B9F0D8C788F07BBDE87BF4104FEEDEC1D38EBBE8BA7F0F3D0FEF63B8A71B3EAF371E60E085BF52F7B1C41BCC8C1CA323A380801A1BB6DAB1E3ED20AC1623A2511FAE5CB2E2E837221E3C08B10D3323CA26BE2BEA7D8A47C208C79ED841B882BDF6AE1F41770D4E1D1DC4D52B1EF83C85BCCF2C2AA06A5A3F56BDA287C5323FAD056308C02A155A667563CB363D3ADA6BF0F9672E848204902A85AD694F29954CC4118259B480F2B0DD58B8B000EFC80A1601084EDEE7B6E1769B17870E86D076B3082D33FBD81E8C59B05DA46004194D7BB85E343559F1EA761DE6CCED85CE908BE1610FAE5C36E3C2391D1EDE0FC0EDCA639144BD8E43BD914CE2DD088A97C53D73EE8A59AC4E34341AB060611433677960B3E9A1127C08457470BAA2B879CD82332705DCEFF0C21F50A2FD71211365ACC9A8C36B6F79B1F53527B4EA3C0CF48FAE60F3170C63ED3AE0FAD552ECDB1B912C981AD4432627D065055BB6763D3EF8935FA262D6BC78CF6136C542CF3E77F1978220FCEFD95E67BC0A46568CD8B6278C9D181F18092D46C82761B88606F0F87E072350273460E21523F2BEA0C78B4830886894787A7DF0391D88FAFD127A1329488CB907CB5F76E3D5D7B4A8ACA2BDCF00CE9D16B17F2F41AA91E5A27E2DCA2719D86A49392669B1804EEB4159991EEBB786B072AD1362B8084F1E04D1DB1341389C1F0FAB43E8464D8D0646C35CECDBDB813367925D445230A2CA6D9AD98D57B753B4AD12972E0FB16E6A8D9A22081C723B1C326078308CAEAE28EC76E2E1E2758CB4075BB828A160419F0AD13045ECCC0C04E6F8B7219C381E4145951F1B36EAD1715776116505EBC6BC794578EB5D0BA6373C8418B3E1F6ED41ECFB3A86B61BC45F16E1E90986EC24F31393B5278531B02E6FB9FE239E5A609EBA0B7A7D00D5B5112C599A83F90B7298FBE87416E1C60D3FCE9E72E3DE5D8282A3F3CD0A64635EEF118B8660346AB1ED751FB66E7743AFCFC3E0801BBBBF2417D1C6A28D4A0B367FFE30D6AC05AE5F2BC5FE7D5CC112B0EBC9166CC5FA0DF8F0CFFE19CA5AE6B0F167B3ADC85629C638CE0EA02A5BEB251B8271DD5714C57FF97D1BCBBF1BD749190E26572F180820E0F32114F4C1EF766378A01FCEFE7E045D6E8443010C0DF4E361DB0D3CBD7B1B6EC2BB97DAF8E9DFE90D4358B94A8B79F38DB0150FA1F3B115972E8470E77604FD7D1604FC02FC7E01A1102526798B3A59BF9CDC01CC9E6DC69A0D1AB4CC26D67A3DFC9E308304207787F115FB088825CC88E4349A39D8F7F5C35115ACB1A51BAFBD6E4079651186ECBD9CF591B5C2533083E0B8F35934F3E277313C7860610AC8200F5214CC6DD762A89FF26611580B34E87C5282E3C73C80CA89652BF478D05E8D3D3BDD9205A33C5937E62F28C0DBEF5B513BFD0142810A5C3C3F842F3EF5E3F1A372E45944B06F3180000018FF49444154E4E646A0D6905271E79EC6E6F7A9E1F302E108056492D1BF94964CAB1F4643632ED66FD4A265662FEEDD2DC5916F42B8D7EE87DB45BC5B9481E7169ABBF47C0B41410E8A226ED9E6655FB3D982C12127767FA9C53149C1C8F28B42145AAD0AADF3EC58BD46C4F56B2538B03F22B988CA2087E42242C0CB9B36E3277FFE17286E6A91A006245B31A1BD4BD6B3F97F1104E1DF677DF428A9FC8CE7A72D024E2E8ECB788D1107B0F3A557138B221C0820E8F331EA4E311A81DBE9C4DD8B177064F797686F238EE244E995D93C88BA3A35162D2D40F34C1D0C86428650343C14C6407F007D7D2E74760EE1E9134283CD63DDC8144D33183CA8A9CBC5FACD112C5A3608315C88AE2761747646E07018181389CB118639C787B9AD3AE4E6B462DFDEF611410E9E28260BD6836DAFE9A1D556A3ADCD817088F8C9380A12EDC5084FB1B72780C74F22B0DB8D7C0FC618342517F1273616E4700EE5E1F60D2FBABBA3686EB6A2A4A416D7AF77A0A7D785961601EDB76BB06767802B989A506F932D58D05F8A73677AF0F96731F4F59463FE4260C1220116AB1E6A2DF5F56AE1F304D17E47836B9743E8279836506F14FF24DC1A5E31118383B156BEB2268AA52FF970F9623EBEDEED87CB454792EBC9DF5D6A4F015930E2EC5ABDDE8D4D5B43B015E6C3E118C0AE2F48C10A797913033F893038F0B9F3DC58B952C4F5EB858C189DA727D22BD89AADDBF0935FFE73D8A637A69DC6CF41CFC62CEA1D6DC28FCB45942F228AE23F01F0D709772FCDE52774E5E4EB287596AC5CFFBD3BD8FBF1DFE3C4C1FD0839883585272A297F63326A50511541557514252522AC05415E61A0A67E34039CAE10DA6E1871FDAA1643C37E88E4320A9C4861D3760FB6ECF021E89E8633C70771F1A207C3C345F0BA0504FC6AD437F460F356136CD6F9D8B7AF2DAD82A9D5025A66F562EB761D7A3A6BB17FAF038140186A954EAA5617118DF04A0E0ACFC7A8D44A66E49414ECDD9F14625A7D3B1C8365387FCA852B57BD6898918B152B2B118ADCC3407F0405561D2E9C2BC29E9D314590A30F8DCD566CDBAE67690201D5387FAE1B9FFD2E84BE9E0AACDFECC4ABDB7D28AE3042A5F342881AE0768670E95C210E7C2DE2E1432720D892144CCE92F0252F0C93498B454B1C58B32E8A2B174BB167671811529031B0ED89AB8B12D78B970E63FD2611357585F0F9FBB0F3332D0E1F2C50B88841E4E46831679E1FF3178471E39A15278EF33DB65C5F2A2B3E0BD30B6A6C78ED757CF8E77F014B4D7DFAB57AC46231FE353FE58C3F1604E1FF1BEF5526AC06A2289EA174445A259BC055475B71947FF7F776E3F0179FE2C0979FC1FEF43122948864818F0820922239405B1E8257C8B702D67CFA1A50516940D534133C9E2A1C3BD28D9B377B208A36C6F54C987D9B77B8F1C67B61781DB5D8BFE7094E9F0AB3A000ED5BD482010DCDBDD8B8C5005BC102EC1F55C1549839AB075BB7E970BFA3105F7ED1CD4AA2E4F9C70D34B9A75A4045FB1E03C7C7500439E20A365086B3271D3876D40F9331171B365BD132D303953A0211211CD86BC657BB742C88C2C3F46E9496529A208C15ABC2282EAA40DBCD76ECFA5244FBED5CD4CD08635EAB11F905224C39015454E44025B871E6640E4E1C35300B9F001A4DAEB0E18B5C041AAD80D6F983D8B459859BD72BB17B5768547616F9F5938268352AD4370C60CD3A03162C2E02D44FB06F3770689F166E37EDA3A9F2C28EB20A03162CB0A2B8C4876B57B4B87A99BC8C84058B6748A9B0576FC2A637DEC2BB7FFCA7C8ADAA4E3BE727D9829D150461D978952BD91B18E7D9DF2BD886EF15ECE0384F1B79B824896C4AC4BC3DDDD8FBC96F70F08B4FE1EBEF612F8036372AE6C30B8C814525D03E8BE376A85584B9AE4679D510E62FD020DF3213278E3FC0C58BC31063A5CC026AD46A6C7ACD8E373E08C2E7E0951CA74E3AA44433D537AA30A3A91B1B371B50645B80FDFB475A308A56908B387376375EDDA6C340FF341C3EE24030402E1CA12F703B4050D104B6E9F1100323112C701460EE22DAF0EE4F6CDC820D94E1DC2927F67EED8373B81CABD6B8B176831F1555B988C281DD5F98B1E7CB5C8442642149C12230E82921DE8FB594079B5506B7E731CE9F36E1FC19338B286AB5669873BCA8A8D061C5CA6268740FB1774F0837AF97B28A12168591DA4A46E6F8638C22A8B575005BB6A871F3660576ED0A307E318AE2CACEBDD2C5644F2C95A2596D3D58B62217EB3615C25AF808972EE4E1F811018F1F0611F0E7436F1C4053730E1A1A2B313CF404572E87D1D5992F954A25AFD6B4A01A0B4BB0F1CD77B0ED839FC25C56F1CC53308B0B6CFC5EC10E6571DC884326606B12D71045715248FBE417946930AEA78FF1D9DFFC571CDAF905049F8797E40802745A37CACAF5686C34212FCF058F370497875E1EB9305A945710A2AD190EBB0DE7CE0EE07E07D51216B009A0556BB0619B1DAFBF1742C0DD8C7DBB7B70FAD4103CEE0A290DA042FD8C5EACDF684471F17C1C3CD086B329951CA460E42A35CFECC2F61D061495D4A0B7DFCD10B0183B08A1360940246046EF533F2E5FF6A1E39E86C1C9C9418EF90B8BF1EE0736D44CEFC0506F39CE9CF4E1E0FE01F4F516A3B67E102B5719B16C45294CB97DD8FD85167B7719A43D18452979F57C41E130E6CD3763D9F2224CAB0EC1316CC09D5B4EDC7FD00FB79B5BF6BADA32CC9A538E9EBE367CF959000FEF95B0825DBEC0C9314445B30F0521444ED33BB775009BB76871EB6639F6ECF6730A5A221E4F995671DA56A665C499DD87A6E63CACDF6445638B0B417F2EEEB53BD07ED70E97C3C0F686D3AA8B110DE7E3E28507B873C78D6030E1B2CA97A7BC24D59796B7CCC6C6773FC08AF51B612828548C7C222A90F19C38995EC623D31C90694E8F794D51142B0110E16A62873C915164798EEBF1037CF25FFE230EEEFA129A0891BCF11220B3B91F336799B07A752EAAA6F5B24A750F81017B29914A391F03868622B8735B85870F8C8C6C0FA2962B984683B51B87B0E39D30FC9E26ECDDD38D73671DF0792B589E8C36E135B5BD7879B501C5C57371ECD81D7C77C10EC4887143110E1004CC68ECC61B6F193077A10D82B62B1E2C6060C36A20E8B4A1FD860707F64771ED4A31B3005C017BD0D49C8F1D6F98D13CAB0B5D8FCB70E28817E7CFBB611F2E87C138C8B89A57AF33A3725A17BEFD260F870F98100C4720301F94E3366A34011458B56899ED45EB82302A2B88B6C805B74780DB43E47C3144C31A149795A0B7BF0F5FEDF4A3F35105D45A1AE04872754AF26A34545E4555FD11CC9CDD870D1B3568BF53897D7B03CC456451C094F747E7194D268687E1F51216BE03168B0EB3E678B0646914F533CCD0EA8618FD93CBA1E57935670477DA8CB8794D0BBB3D000823A71481C91A8D262CDEB20D9B7EFA47A86B6C869AF0FC261AADCB3CEF7C001A0541E8CC7C68FA239E49C198E511C55F7E9F17FB7F263A80F19CE7EA7C84CF7FF5D738B8F30BC0E3E2D524820A068317D5D5B99833271F2525D477A4652D0F4435E47685D0DBE7C6D3A7C38C1C3CE0A7A817E7BF622D2E540A353388050BC87D2BC2952B837870DF8548C41AEF5F2B28F4604603719255A0BDBD078F1E3B59357DF247445189038B16E7A3BAD602414D097FF9C3D8BB11F219D1F9C88D9B3743E8EECAE18954A6A46E1416E9317B8E01D535410CF61BD176C3859E6EAA80B73086CB7CAB0AD3A76B515C12606556EDB7D52CC8108FB2B1FE1F5E4D9F9BE740551550535388C2422374BA5C46BDD4DFEF64D5ECB979398889515CBFEA81DD5E000D435CE560A4B2B230D96875C8C9B5201A0EC1EB71A1B4CC8399B3F4E8EFCB43DB8D000FA34B8B4C42C904083A3DAA6AEB515C5888FB1DF7D0DFF3045A5514967C07A64FD7A1AEBE00053635D4AA1C04FC2A0C0FFBF0F0711F1E3D08C1EDCC953896C93227B272546B19811A85A5E578F58F7E81356FBF07739E05224B833CB7CF3FFB9EEBEB3F3CCBD527656CA2281E06B0F6590692CDB9BEBE1ED6C079E0F37F80FDF1C3789E4450F15A36A341804E23039B738C734E34A0422044C8BF1451908B8B1320CB06BD08A381B0D235F007632CCA2713D031E3A3212458DAEB11C322E1B753DE48D910C8F7581A4D0C46A31A5A9D9CD4E54F25A32BC5441523BD0B0639D71807EAE1E792A25357BB4ECBA38DC10087008FB17D11AFB924727BAD5A442842393DE9F42435E6AE1EA11613E38E5E4F2D27742E5F4CC2617E1ED523526A21102494640ABC48F53229DD42A65C0B8ACB2B11F0B8D0D7F5142A751446830A91880AC160123506574EB68EA8A0CF2FC09257D6A0717A3D4E7E7B0CD72F5D641DEDB427D6E954D013EB0AB5F348B94C1A175D2F188A418C2993C67C6434D668240CBDA500F35E5A81CD3FF9391A5F5ACEDCD34999C0E927DF114110D665332FC73A6652C6F73D71DFB3D3CF66F12461B713372E5EC0814F7E839BA78E23180CB0625C164010296F4274B14A66458A30D20BA38E666A90945BFAA5B59A3527D2C408B3735927B19A3A9A93115EA9439942CEBCA359665D8CC7B51423A731D0B568F3955074DEAC4DFFE1AC2CBCC35AEAE8654AC6ABE179D774987511B34E62458505DD9CAADDE9CBCE571167594A68886F4A41992B3E66B9BB5ADA61910C282822412A50253E2D14FC49F831F45F0A10198C4694D7CF40554313FA1F3F44FB954B8844A98E9DBBB534BED40FED91A872A5AC792636BDFB015A9A1A71FCC8511CDBBB1BEE9E2E50FB8A2052D5BE625CAC658964426323AB95B048727509A36810045435CFC6ABEFFD042FADDF004361F1F3542E7AB4380D6C165373D4432645C1F8EA35F9151EA9A3162361D8070770FCCBCF70F8771FA3BFBB0B02E3EC92DB31A4447516126139348230A0D7C4AA09469EC4D7CF918DF28923256E66560591C0474CBD52E6EB2492BBCAFD4C428547BB42321EA4FC4C8C3546EA4C48DD1F8D269A78E4903AC06322AA6A6AB162F3564C9B3907578F1FC5C9AF77B36A1B0A88B071A5B930B9BCB4475AB4651BB6FCFC17A8AEAA42C7BD0E1CF9EC135C397A082E879DD5152A735BCAF1A4BE021E2311111354A8AAABC3CA6DAF63F9D61D28A9A9E151CFE7F71977C5C658729DB4618AA248A1CCF5937641E93D2604CF1818F0F0FA551CDEF9192E9C388EA1CEA7AC2A9EDC1EC68CC2AA2614D8478CDD83BB2FB4C212F1814AA787ADA414369B0D4E970B83BD3D8806FD4C4D6436158E994EC7F32FA9006D55E4DF198437E3F3E51438EC777227558463912C013625E3E9086966D27898B520CBC513E6E45EB167501847C6762F3D03FD99FF9E3886942A4C913A9D1EF985C5C82B2884DFE5C4404F17A2A120678C612EA144CDC45743698092ED626B8388083D8B20C06C2B66D5EA9BDF7C1BC53575B87AF238F6FEC36F71AFED06223E0F4B493007591A28C987259D8D66CC98391B9BDEFB108BD66F8429271761BF1FB72F9EC3F1BD7B58D3ED60E753444321760DFEBE12E3625D1312D93B1B8B4ACD2001CAEA6760D9DA7558BE7E238AABEB3841031BFAE8F64112F744A6E2378220500A6A523E9366C1242BD6F43D400EB1AB4F0A4656BAD59CEE432FF9DECDEB38B37F2FEE5C38C7EA16437E1F2B0C8E45228832A86DFEE2E84B6E8B56A78756AF87C16482A5B80CCDADADA89FD180279D9DB87EFE0C061E3F80D7ED66A5595435C226A646039D41CF30F6483983013FC2740F29B8A0D51B6032E72227978206223C4E27FC1E0F2211E23E2657487E02E56ACBAD2C595D793C1471A3C9E5F7FA10F0F9D9F9E4C6119E2445F1F44603B47A1D629128025EAAA20F32379414929E4B6F36A3A4B20A8DAD0B51D5D8CC92F037CE9FC5406F37026EAA59A43EAD108B9A322565E033521994C4C946DDDF1AA309F98585685CB414CB376F434BEB7CE8722D70F574E3C2B7477172DF57E869BF039FD78D7090808278312E3D87D16C46D98C6666F516AF5E8BFCF2AAF8DE2FE471A1E3F64D5C3A7A84BDAF819E6E847C5E560E4748D07C81E10A4BF59224579DDE08B3D58669D31B307FF55ACC7C69390A4B4AA126DACC78B5A36CD9937561B4799385C650A360AB200877B23836AB432655C12425FBC5F715C7BFCAEAEE591C94762512630879DCE87FFC08F7DB6EE26EDB4D743D7E84E1C101785C2EB637E395F6C4B0A887392717569B0D25E51598565B87CADA3A94555723DF5A0097DB8D8EB6EBAC37EDFEDD3B18ECEB638A4479AD9C3C0B8ACB4A515C528A70248AEEA74F30D0DB8B80DFCFF23144373ABDA919331A1B118A4671FBFA353CBC7B17F6E1A1F804649B7425FA93849EA5D16A61B515A176FA74D4D6D72322C6F0B0BD1D4F1F3E82CBE960938EF641F9562BCAA755C35A5404BFDB83CE870FD1D3D38560C0C7AC56515131EA9A9A317BC142D437CF84A5B01841B7134FEEB5A3E3EE1D3C6A6F474F77179CF661366E7AE15A9D96050828CC4E5F0AF5E7592CA8ACABC7ACD6F90CEE8CF65FA6DC3C8AF030FA1A677F1FDAAF5DC1B5F36771B7ED06B3FA81401044AA40DE40E3CC9998BBE42534CC9DCF70DF599445FED0FBF27A30D4D589CE8E7BB877FB161EDD6B475F77375C763B7B5FF4D1EA286A998382E2625456D7B2307CF5F40694D7D521A7B0106049EDB833FB3C2CD87F2F08C27FCB625A667DC8A42B98A4641366C91C5727A74436D1DFD589E1FE5EA65C019F9759210A2112379956AB63E843A6BC5CE4D90A612B29437E41015F09A5A7A73698DEA78FD1DFD9058F7D98ADF60C25CA64469ED586BCFC7CE63E390606E0B60F23442E8E46835C6B0163462CA9A8646E5ACFC307CC05F2B89D2CB42DB3C328A784FC66541A35CC79F9282AAB4071792968DB3FD8D9057B5F2F7C5E0FCFD1E9F430E5E620BFB814264B3E223E1F86FBFAE0181E402414804AA345AEC58A9269D528ABAE650B0203CCA08861C0CF8E1DE8EE826370107E0F591D0A5250E297020A2A6611C91A533D1759A082D20A94D7D6A1A0A8082AA58248830E7ADCE879F2183D8F1FC1333C8450380CAD46077381952D58E5D36AA1CFC91DA3734444D0EFC7506F3706BA3AE11A1A66169FE4CD92F55A2DDBC399F3F351505282C2B24A98F30B40759E2FE033829D7232EEF9DC462E8AE205008B2663904C6947AB99A68818B9188CD3480A72C8FF4A0168CE5D4A5FA2AC94C2C04AE421760D89BB9441A1495F168154848DD9710A0784E58FA46BD2BDD835A8235B62FB1B2BCEC5BC1BB5623CAC83947F95744A9C8A532A65621B4999A02CEE5631D41AFA263D9374AC2C1FA56CD2A12EB1FBD07808D62E95B5467A8B7159A7F0BCB2CD29C9819A3F53D0C2522700DB0C4BE72BF9A7E4371C7F4F12D3BCA29A7E5C73697C9BB0EF0441583CAEEB6779F0F354B0B900CE4DC67E6C749F5A5686645FFC197CF00962216429ED493F2CFDF34FFA6D64FD525C38DDC47926B9A704269F69628E6F20E49F2E1504E1DAF390DB333D47A60189A2382122BF74D71D7D41E2BF287F1F9F7C333DC5E4FC3EBE0555B17DC9580694C24D394A183C396E38F167CAF41C997E1FEBCE29B1CD0C7B2C259D489A699CFD40D212E74D5C42C9673E570593F6639384E331FA23A72AD40F4DC1263A9E6CED53A6EB67FA7DB226D3E45D67EC2757B231F3093CE19CD8B8F03526F27CCF5DC124259BB4AAFBD11E3275C1CA7E019B88D8C67FCE44C793ADE5C974FD4CBF8FFF899EF719638F58E28E910631A169FC4C55F2D93EFD844696EDC595C7BDA87AC5898C6DEA9C3F38094C4A9D6136527B910A5604E0188099D90C6CEA9829093C2709B401582D08C2C073BA7ED2655F988249AE620B80234A08EE17F19053F798928024815EEAFA1004E1D68B92C80B553049C908DBE09B17D5A4F9A20439759F1FBC04A87972FDF775868425F3C23E2F5CC124259B1C3C8F1726A6A91BFD2390C08471359EE5D97F2F0A2629D98489FD9EE581A7CEFD83944046A2BCE72595DF9B82494A46F49B3B9FD7C34D5D774A02005E17048168907F2F9FDFAB824D59B2DFCB3BFF43BAE9EFCD72C942FEBD2B98624F4696EC85A053FD21CDB03FD067A5800659AE0961194EA6CC7E100A2629194517BF980AE14FE6EBFD83BC1685E2DF7CD1D1C2D124FD83513049C9284FF6E95432FA0F523126E3A12989FCCE8BCC73651AF40F4AC12425A38A8F4F5E040C5C26E14CFDFEA392001530BCFFA22A34B295CC0F4EC1E4814F262C77B6C2983AEE472B811752B83B11E9FC60154CB266CFBDD56522429B3AE7072581E7DE72F22C4FFB83563049C9A8699380482605A9EA59843575EE0F4A02D489FC0B4110683BF183FDFCE0154C5232821F20F2B349C3F8F8C1BE91A981652381EF00FC93E7D5E69FCD00B23DE647A1608A7DD9C4D1AAB295C8D4713F74093C17F4A7E7F5D03F2A0593AC19E12EFEA72997F1794D891FEC75C925FCB3C9C62D7CDE4FFBA3533049C908419868652615A6FB790B7BEAFA139600B537FD72321177273C92719EF8A3543085CBF82F01FCBB713EF3D4E13F2E094C1A11C3EFE3B17FD40A265933A24EFA3FA712D3BF8FE9F35CEF4989E3FF591004E23AF8D17E7EF40AA6B066C4B449D66CAA60F8473B1DD9C0A95097ACD633314BFE5044F08F46C1246B469CD1FF06C0CF7F28029E1AC7B824F0D1F7E439FFFA593891C775B71770F03F2A055358338224F84B002FBD00194EDDE2D9257096DED70FA1BDE4D91F25F90AFF28156CB2853475BD29094C5402530A3651C94D9D3725812C2430A560590869EA9029094C5402530A3651C94D9D3725812C2430A560590869EA9029094C5402530A3651C94D9D3725812C2430A560590869EA9029094C5402530A3651C94D9D3725812C2430A560590869EA9029094C5402530A3651C94D9D3725812C2430A560590869EA9029094C5402530A3651C94D9D3725812C2430A560590869EA9029094C5402530A3651C94D9D3725812C24F0FF037E9E90ECB40788B60000000049454E44AE426082, '1', '2024-08-21 00:06:16', '1', '2024-08-21 00:06:16', b'0');

-- ----------------------------
-- Table structure for infra_job
-- ----------------------------
DROP TABLE IF EXISTS `infra_job`;
CREATE TABLE `infra_job`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '任务编号',
  `name` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '任务名称',
  `status` tinyint NOT NULL COMMENT '任务状态',
  `handler_name` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '处理器的名字',
  `handler_param` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '处理器的参数',
  `cron_expression` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'CRON 表达式',
  `retry_count` int NOT NULL DEFAULT 0 COMMENT '重试次数',
  `retry_interval` int NOT NULL DEFAULT 0 COMMENT '重试间隔',
  `monitor_timeout` int NOT NULL DEFAULT 0 COMMENT '监控超时时间',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 28 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '定时任务表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of infra_job
-- ----------------------------
INSERT INTO `infra_job` VALUES (25, '访问日志清理 Job', 2, 'accessLogCleanJob', '', '0 0 0 * * ?', 3, 0, 0, '1', '2023-10-03 10:59:41', '1', '2023-10-03 11:01:10', b'0');
INSERT INTO `infra_job` VALUES (26, '错误日志清理 Job', 2, 'errorLogCleanJob', '', '0 0 0 * * ?', 3, 0, 0, '1', '2023-10-03 11:00:43', '1', '2023-10-03 11:01:12', b'0');
INSERT INTO `infra_job` VALUES (27, '任务日志清理 Job', 2, 'jobLogCleanJob', '', '0 0 0 * * ?', 3, 0, 0, '1', '2023-10-03 11:01:33', '1', '2023-10-03 11:01:42', b'0');

-- ----------------------------
-- Table structure for infra_job_log
-- ----------------------------
DROP TABLE IF EXISTS `infra_job_log`;
CREATE TABLE `infra_job_log`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '日志编号',
  `job_id` bigint NOT NULL COMMENT '任务编号',
  `handler_name` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '处理器的名字',
  `handler_param` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '处理器的参数',
  `execute_index` tinyint NOT NULL DEFAULT 1 COMMENT '第几次执行',
  `begin_time` datetime NOT NULL COMMENT '开始执行时间',
  `end_time` datetime NULL DEFAULT NULL COMMENT '结束执行时间',
  `duration` int NULL DEFAULT NULL COMMENT '执行时长',
  `status` tinyint NOT NULL COMMENT '任务状态',
  `result` varchar(4000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '结果数据',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 233 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '定时任务日志表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of infra_job_log
-- ----------------------------

-- ----------------------------
-- Table structure for platform_dept
-- ----------------------------
DROP TABLE IF EXISTS `platform_dept`;
CREATE TABLE `platform_dept`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '部门id',
  `name` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '部门名称',
  `parent_id` bigint NOT NULL DEFAULT 0 COMMENT '父部门id',
  `sort` int NOT NULL DEFAULT 0 COMMENT '显示顺序',
  `leader_user_id` bigint NULL DEFAULT NULL COMMENT '负责人',
  `phone` varchar(11) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '联系电话',
  `email` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '邮箱',
  `status` tinyint NOT NULL COMMENT '部门状态（0正常 1停用）',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '部门表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of platform_dept
-- ----------------------------

-- ----------------------------
-- Table structure for platform_dict_data
-- ----------------------------
DROP TABLE IF EXISTS `platform_dict_data`;
CREATE TABLE `platform_dict_data`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '字典编码',
  `sort` int NOT NULL DEFAULT 0 COMMENT '字典排序',
  `label` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '字典标签',
  `value` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '字典键值',
  `dict_type` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '字典类型',
  `status` tinyint NOT NULL DEFAULT 0 COMMENT '状态（0正常 1停用）',
  `color_type` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '颜色类型',
  `css_class` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT 'css 样式',
  `remark` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '备注',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1764304958750314499 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '字典数据表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of platform_dict_data
-- ----------------------------
INSERT INTO `platform_dict_data` VALUES (1, 1, '男', '1', 'system_user_sex', 0, 'default', 'A', '性别男', 'admin', '2021-01-05 17:03:48', '1', '2022-03-29 00:14:39', b'0');
INSERT INTO `platform_dict_data` VALUES (2, 2, '女', '2', 'system_user_sex', 0, 'success', '', '性别女', 'admin', '2021-01-05 17:03:48', '1', '2023-11-15 23:30:37', b'0');
INSERT INTO `platform_dict_data` VALUES (8, 1, '正常', '1', 'infra_job_status', 0, 'success', '', '正常状态', 'admin', '2021-01-05 17:03:48', '1', '2022-02-16 19:33:38', b'0');
INSERT INTO `platform_dict_data` VALUES (9, 2, '暂停', '2', 'infra_job_status', 0, 'danger', '', '停用状态', 'admin', '2021-01-05 17:03:48', '1', '2022-02-16 19:33:45', b'0');
INSERT INTO `platform_dict_data` VALUES (12, 1, '系统内置', '1', 'infra_config_type', 0, 'danger', '', '参数类型 - 系统内置', 'admin', '2021-01-05 17:03:48', '1', '2022-02-16 19:06:02', b'0');
INSERT INTO `platform_dict_data` VALUES (13, 2, '自定义', '2', 'infra_config_type', 0, 'primary', '', '参数类型 - 自定义', 'admin', '2021-01-05 17:03:48', '1', '2022-02-16 19:06:07', b'0');
INSERT INTO `platform_dict_data` VALUES (14, 1, '通知', '1', 'system_notice_type', 0, 'success', '', '通知', 'admin', '2021-01-05 17:03:48', '1', '2022-02-16 13:05:57', b'0');
INSERT INTO `platform_dict_data` VALUES (15, 2, '公告', '2', 'system_notice_type', 0, 'info', '', '公告', 'admin', '2021-01-05 17:03:48', '1', '2022-02-16 13:06:01', b'0');
INSERT INTO `platform_dict_data` VALUES (16, 0, '其它', '0', 'system_operate_type', 0, 'default', '', '其它操作', 'admin', '2021-01-05 17:03:48', '1', '2022-02-16 09:32:46', b'0');
INSERT INTO `platform_dict_data` VALUES (17, 1, '查询', '1', 'system_operate_type', 0, 'info', '', '查询操作', 'admin', '2021-01-05 17:03:48', '1', '2022-02-16 09:33:16', b'0');
INSERT INTO `platform_dict_data` VALUES (18, 2, '新增', '2', 'system_operate_type', 0, 'primary', '', '新增操作', 'admin', '2021-01-05 17:03:48', '1', '2022-02-16 09:33:13', b'0');
INSERT INTO `platform_dict_data` VALUES (19, 3, '修改', '3', 'system_operate_type', 0, 'warning', '', '修改操作', 'admin', '2021-01-05 17:03:48', '1', '2022-02-16 09:33:22', b'0');
INSERT INTO `platform_dict_data` VALUES (20, 4, '删除', '4', 'system_operate_type', 0, 'danger', '', '删除操作', 'admin', '2021-01-05 17:03:48', '1', '2022-02-16 09:33:27', b'0');
INSERT INTO `platform_dict_data` VALUES (22, 5, '导出', '5', 'system_operate_type', 0, 'default', '', '导出操作', 'admin', '2021-01-05 17:03:48', '1', '2022-02-16 09:33:32', b'0');
INSERT INTO `platform_dict_data` VALUES (23, 6, '导入', '6', 'system_operate_type', 0, 'default', '', '导入操作', 'admin', '2021-01-05 17:03:48', '1', '2022-02-16 09:33:35', b'0');
INSERT INTO `platform_dict_data` VALUES (27, 1, '开启', '0', 'common_status', 0, 'primary', '', '开启状态', 'admin', '2021-01-05 17:03:48', '1', '2022-02-16 08:00:39', b'0');
INSERT INTO `platform_dict_data` VALUES (28, 2, '关闭', '1', 'common_status', 0, 'info', '', '关闭状态', 'admin', '2021-01-05 17:03:48', '1', '2022-02-16 08:00:44', b'0');
INSERT INTO `platform_dict_data` VALUES (29, 1, '目录', '1', 'system_menu_type', 0, '', '', '目录', 'admin', '2021-01-05 17:03:48', '', '2022-02-01 16:43:45', b'0');
INSERT INTO `platform_dict_data` VALUES (30, 2, '菜单', '2', 'system_menu_type', 0, '', '', '菜单', 'admin', '2021-01-05 17:03:48', '', '2022-02-01 16:43:41', b'0');
INSERT INTO `platform_dict_data` VALUES (31, 3, '按钮', '3', 'system_menu_type', 0, '', '', '按钮', 'admin', '2021-01-05 17:03:48', '', '2022-02-01 16:43:39', b'0');
INSERT INTO `platform_dict_data` VALUES (32, 1, '内置', '1', 'system_role_type', 0, 'danger', '', '内置角色', 'admin', '2021-01-05 17:03:48', '1', '2022-02-16 13:02:08', b'0');
INSERT INTO `platform_dict_data` VALUES (33, 2, '自定义', '2', 'system_role_type', 0, 'primary', '', '自定义角色', 'admin', '2021-01-05 17:03:48', '1', '2022-02-16 13:02:12', b'0');
INSERT INTO `platform_dict_data` VALUES (34, 1, '全部数据权限', '1', 'system_data_scope', 0, '', '', '全部数据权限', 'admin', '2021-01-05 17:03:48', '', '2022-02-01 16:47:17', b'0');
INSERT INTO `platform_dict_data` VALUES (35, 2, '指定部门数据权限', '2', 'system_data_scope', 0, '', '', '指定部门数据权限', 'admin', '2021-01-05 17:03:48', '', '2022-02-01 16:47:18', b'0');
INSERT INTO `platform_dict_data` VALUES (36, 3, '本部门数据权限', '3', 'system_data_scope', 0, '', '', '本部门数据权限', 'admin', '2021-01-05 17:03:48', '', '2022-02-01 16:47:16', b'0');
INSERT INTO `platform_dict_data` VALUES (37, 4, '本部门及以下数据权限', '4', 'system_data_scope', 0, '', '', '本部门及以下数据权限', 'admin', '2021-01-05 17:03:48', '', '2022-02-01 16:47:21', b'0');
INSERT INTO `platform_dict_data` VALUES (38, 5, '仅本人数据权限', '5', 'system_data_scope', 0, '', '', '仅本人数据权限', 'admin', '2021-01-05 17:03:48', '', '2022-02-01 16:47:23', b'0');
INSERT INTO `platform_dict_data` VALUES (39, 0, '成功', '0', 'system_login_result', 0, 'success', '', '登陆结果 - 成功', '', '2021-01-18 06:17:36', '1', '2022-02-16 13:23:49', b'0');
INSERT INTO `platform_dict_data` VALUES (40, 10, '账号或密码不正确', '10', 'system_login_result', 0, 'primary', '', '登陆结果 - 账号或密码不正确', '', '2021-01-18 06:17:54', '1', '2022-02-16 13:24:27', b'0');
INSERT INTO `platform_dict_data` VALUES (41, 20, '用户被禁用', '20', 'system_login_result', 0, 'warning', '', '登陆结果 - 用户被禁用', '', '2021-01-18 06:17:54', '1', '2022-02-16 13:23:57', b'0');
INSERT INTO `platform_dict_data` VALUES (42, 30, '验证码不存在', '30', 'system_login_result', 0, 'info', '', '登陆结果 - 验证码不存在', '', '2021-01-18 06:17:54', '1', '2022-02-16 13:24:07', b'0');
INSERT INTO `platform_dict_data` VALUES (43, 31, '验证码不正确', '31', 'system_login_result', 0, 'info', '', '登陆结果 - 验证码不正确', '', '2021-01-18 06:17:54', '1', '2022-02-16 13:24:11', b'0');
INSERT INTO `platform_dict_data` VALUES (44, 100, '未知异常', '100', 'system_login_result', 0, 'danger', '', '登陆结果 - 未知异常', '', '2021-01-18 06:17:54', '1', '2022-02-16 13:24:23', b'0');
INSERT INTO `platform_dict_data` VALUES (45, 1, '是', 'true', 'infra_boolean_string', 0, 'danger', '', 'Boolean 是否类型 - 是', '', '2021-01-19 03:20:55', '1', '2022-03-15 23:01:45', b'0');
INSERT INTO `platform_dict_data` VALUES (46, 1, '否', 'false', 'infra_boolean_string', 0, 'info', '', 'Boolean 是否类型 - 否', '', '2021-01-19 03:20:55', '1', '2022-03-15 23:09:45', b'0');
INSERT INTO `platform_dict_data` VALUES (50, 1, '单表（增删改查）', '1', 'infra_codegen_template_type', 0, '', '', NULL, '', '2021-02-05 07:09:06', '', '2022-03-10 16:33:15', b'0');
INSERT INTO `platform_dict_data` VALUES (51, 2, '树表（增删改查）', '2', 'infra_codegen_template_type', 0, '', '', NULL, '', '2021-02-05 07:14:46', '', '2022-03-10 16:33:19', b'0');
INSERT INTO `platform_dict_data` VALUES (53, 0, '初始化中', '0', 'infra_job_status', 0, 'primary', '', NULL, '', '2021-02-07 07:46:49', '1', '2022-02-16 19:33:29', b'0');
INSERT INTO `platform_dict_data` VALUES (57, 0, '运行中', '0', 'infra_job_log_status', 0, 'primary', '', 'RUNNING', '', '2021-02-08 10:04:24', '1', '2022-02-16 19:07:48', b'0');
INSERT INTO `platform_dict_data` VALUES (58, 1, '成功', '1', 'infra_job_log_status', 0, 'success', '', NULL, '', '2021-02-08 10:06:57', '1', '2022-02-16 19:07:52', b'0');
INSERT INTO `platform_dict_data` VALUES (59, 2, '失败', '2', 'infra_job_log_status', 0, 'warning', '', '失败', '', '2021-02-08 10:07:38', '1', '2022-02-16 19:07:56', b'0');
INSERT INTO `platform_dict_data` VALUES (60, 1, '会员', '1', 'user_type', 0, 'primary', '', NULL, '', '2021-02-26 00:16:27', '1', '2022-02-16 10:22:19', b'0');
INSERT INTO `platform_dict_data` VALUES (61, 2, '管理员', '2', 'user_type', 0, 'success', '', NULL, '', '2021-02-26 00:16:34', '1', '2022-02-16 10:22:22', b'0');
INSERT INTO `platform_dict_data` VALUES (62, 0, '未处理', '0', 'infra_api_error_log_process_status', 0, 'primary', '', NULL, '', '2021-02-26 07:07:19', '1', '2022-02-16 20:14:17', b'0');
INSERT INTO `platform_dict_data` VALUES (63, 1, '已处理', '1', 'infra_api_error_log_process_status', 0, 'success', '', NULL, '', '2021-02-26 07:07:26', '1', '2022-02-16 20:14:08', b'0');
INSERT INTO `platform_dict_data` VALUES (64, 2, '已忽略', '2', 'infra_api_error_log_process_status', 0, 'danger', '', NULL, '', '2021-02-26 07:07:34', '1', '2022-02-16 20:14:14', b'0');
INSERT INTO `platform_dict_data` VALUES (66, 2, '阿里云', 'ALIYUN', 'system_sms_channel_code', 0, 'primary', '', NULL, '1', '2021-04-05 01:05:26', '1', '2022-02-16 10:09:52', b'0');
INSERT INTO `platform_dict_data` VALUES (67, 1, '验证码', '1', 'system_sms_template_type', 0, 'warning', '', NULL, '1', '2021-04-05 21:50:57', '1', '2022-02-16 12:48:30', b'0');
INSERT INTO `platform_dict_data` VALUES (68, 2, '通知', '2', 'system_sms_template_type', 0, 'primary', '', NULL, '1', '2021-04-05 21:51:08', '1', '2022-02-16 12:48:27', b'0');
INSERT INTO `platform_dict_data` VALUES (69, 0, '营销', '3', 'system_sms_template_type', 0, 'danger', '', NULL, '1', '2021-04-05 21:51:15', '1', '2022-02-16 12:48:22', b'0');
INSERT INTO `platform_dict_data` VALUES (70, 0, '初始化', '0', 'system_sms_send_status', 0, 'primary', '', NULL, '1', '2021-04-11 20:18:33', '1', '2022-02-16 10:26:07', b'0');
INSERT INTO `platform_dict_data` VALUES (71, 1, '发送成功', '10', 'system_sms_send_status', 0, 'success', '', NULL, '1', '2021-04-11 20:18:43', '1', '2022-02-16 10:25:56', b'0');
INSERT INTO `platform_dict_data` VALUES (72, 2, '发送失败', '20', 'system_sms_send_status', 0, 'danger', '', NULL, '1', '2021-04-11 20:18:49', '1', '2022-02-16 10:26:03', b'0');
INSERT INTO `platform_dict_data` VALUES (73, 3, '不发送', '30', 'system_sms_send_status', 0, 'info', '', NULL, '1', '2021-04-11 20:19:44', '1', '2022-02-16 10:26:10', b'0');
INSERT INTO `platform_dict_data` VALUES (74, 0, '等待结果', '0', 'system_sms_receive_status', 0, 'primary', '', NULL, '1', '2021-04-11 20:27:43', '1', '2022-02-16 10:28:24', b'0');
INSERT INTO `platform_dict_data` VALUES (75, 1, '接收成功', '10', 'system_sms_receive_status', 0, 'success', '', NULL, '1', '2021-04-11 20:29:25', '1', '2022-02-16 10:28:28', b'0');
INSERT INTO `platform_dict_data` VALUES (76, 2, '接收失败', '20', 'system_sms_receive_status', 0, 'danger', '', NULL, '1', '2021-04-11 20:29:31', '1', '2022-02-16 10:28:32', b'0');
INSERT INTO `platform_dict_data` VALUES (77, 0, '调试(钉钉)', 'DEBUG_DING_TALK', 'system_sms_channel_code', 0, 'info', '', NULL, '1', '2021-04-13 00:20:37', '1', '2022-02-16 10:10:00', b'0');
INSERT INTO `platform_dict_data` VALUES (1586, 2, '腾讯云', 'TENCENT', 'system_sms_channel_code', 0, '', '', '', '1', '2024-07-22 22:23:16', '1', '2024-07-22 22:23:16', b'0');
INSERT INTO `platform_dict_data` VALUES (1587, 3, '华为云', 'HUAWEI', 'system_sms_channel_code', 0, '', '', '', '1', '2024-07-22 22:23:46', '1', '2024-07-22 22:23:53', b'0');
INSERT INTO `platform_dict_data` VALUES (1591, 4, '七牛云', 'QINIU', 'system_sms_channel_code', 0, '', '', '', '1', '2024-08-31 08:45:03', '1', '2024-08-31 08:45:24', b'0');
INSERT INTO `platform_dict_data` VALUES (78, 1, '自动生成', '1', 'system_error_code_type', 0, 'warning', '', NULL, '1', '2021-04-21 00:06:48', '1', '2022-02-16 13:57:20', b'0');
INSERT INTO `platform_dict_data` VALUES (79, 2, '手动编辑', '2', 'system_error_code_type', 0, 'primary', '', NULL, '1', '2021-04-21 00:07:14', '1', '2022-02-16 13:57:24', b'0');
INSERT INTO `platform_dict_data` VALUES (80, 100, '账号登录', '100', 'system_login_type', 0, 'primary', '', '账号登录', '1', '2021-10-06 00:52:02', '1', '2022-02-16 13:11:34', b'0');
INSERT INTO `platform_dict_data` VALUES (81, 101, '社交登录', '101', 'system_login_type', 0, 'info', '', '社交登录', '1', '2021-10-06 00:52:17', '1', '2022-02-16 13:11:40', b'0');
INSERT INTO `platform_dict_data` VALUES (83, 200, '主动登出', '200', 'system_login_type', 0, 'primary', '', '主动登出', '1', '2021-10-06 00:52:58', '1', '2022-02-16 13:11:49', b'0');
INSERT INTO `platform_dict_data` VALUES (85, 202, '强制登出', '202', 'system_login_type', 0, 'danger', '', '强制退出', '1', '2021-10-06 00:53:41', '1', '2022-02-16 13:11:57', b'0');
INSERT INTO `platform_dict_data` VALUES (86, 0, '病假', '1', 'bpm_oa_leave_type', 0, 'primary', '', NULL, '1', '2021-09-21 22:35:28', '1', '2022-02-16 10:00:41', b'0');
INSERT INTO `platform_dict_data` VALUES (87, 1, '事假', '2', 'bpm_oa_leave_type', 0, 'info', '', NULL, '1', '2021-09-21 22:36:11', '1', '2022-02-16 10:00:49', b'0');
INSERT INTO `platform_dict_data` VALUES (88, 2, '婚假', '3', 'bpm_oa_leave_type', 0, 'warning', '', NULL, '1', '2021-09-21 22:36:38', '1', '2022-02-16 10:00:53', b'0');
INSERT INTO `platform_dict_data` VALUES (113, 1, '微信公众号支付', 'wx_pub', 'pay_channel_code', 0, 'success', '', '微信公众号支付', '1', '2021-12-03 10:40:24', '1', '2023-07-19 20:08:47', b'0');
INSERT INTO `platform_dict_data` VALUES (114, 2, '微信小程序支付', 'wx_lite', 'pay_channel_code', 0, 'success', '', '微信小程序支付', '1', '2021-12-03 10:41:06', '1', '2023-07-19 20:08:50', b'0');
INSERT INTO `platform_dict_data` VALUES (115, 3, '微信 App 支付', 'wx_app', 'pay_channel_code', 0, 'success', '', '微信 App 支付', '1', '2021-12-03 10:41:20', '1', '2023-07-19 20:08:56', b'0');
INSERT INTO `platform_dict_data` VALUES (116, 10, '支付宝 PC 网站支付', 'alipay_pc', 'pay_channel_code', 0, 'primary', '', '支付宝 PC 网站支付', '1', '2021-12-03 10:42:09', '1', '2023-07-19 20:09:12', b'0');
INSERT INTO `platform_dict_data` VALUES (117, 11, '支付宝 Wap 网站支付', 'alipay_wap', 'pay_channel_code', 0, 'primary', '', '支付宝 Wap 网站支付', '1', '2021-12-03 10:42:26', '1', '2023-07-19 20:09:16', b'0');
INSERT INTO `platform_dict_data` VALUES (118, 12, '支付宝 App 支付', 'alipay_app', 'pay_channel_code', 0, 'primary', '', '支付宝 App 支付', '1', '2021-12-03 10:42:55', '1', '2023-07-19 20:09:20', b'0');
INSERT INTO `platform_dict_data` VALUES (119, 14, '支付宝扫码支付', 'alipay_qr', 'pay_channel_code', 0, 'primary', '', '支付宝扫码支付', '1', '2021-12-03 10:43:10', '1', '2023-07-19 20:09:28', b'0');
INSERT INTO `platform_dict_data` VALUES (120, 10, '通知成功', '10', 'pay_notify_status', 0, 'success', '', '通知成功', '1', '2021-12-03 11:02:41', '1', '2023-07-19 10:08:19', b'0');
INSERT INTO `platform_dict_data` VALUES (121, 20, '通知失败', '20', 'pay_notify_status', 0, 'danger', '', '通知失败', '1', '2021-12-03 11:02:59', '1', '2023-07-19 10:08:21', b'0');
INSERT INTO `platform_dict_data` VALUES (122, 0, '等待通知', '0', 'pay_notify_status', 0, 'info', '', '未通知', '1', '2021-12-03 11:03:10', '1', '2023-07-19 10:08:24', b'0');
INSERT INTO `platform_dict_data` VALUES (123, 10, '支付成功', '10', 'pay_order_status', 0, 'success', '', '支付成功', '1', '2021-12-03 11:18:29', '1', '2023-07-19 18:04:28', b'0');
INSERT INTO `platform_dict_data` VALUES (124, 30, '支付关闭', '30', 'pay_order_status', 0, 'info', '', '支付关闭', '1', '2021-12-03 11:18:42', '1', '2023-07-19 18:05:07', b'0');
INSERT INTO `platform_dict_data` VALUES (125, 0, '等待支付', '0', 'pay_order_status', 0, 'info', '', '未支付', '1', '2021-12-03 11:18:18', '1', '2023-07-19 18:04:15', b'0');
INSERT INTO `platform_dict_data` VALUES (600, 5, '首页', '1', 'promotion_banner_position', 0, 'warning', '', '', '1', '2023-10-11 07:45:24', '1', '2023-10-11 07:45:38', b'0');
INSERT INTO `platform_dict_data` VALUES (601, 4, '秒杀活动页', '2', 'promotion_banner_position', 0, 'warning', '', '', '1', '2023-10-11 07:45:24', '1', '2023-10-11 07:45:38', b'0');
INSERT INTO `platform_dict_data` VALUES (602, 3, '砍价活动页', '3', 'promotion_banner_position', 0, 'warning', '', '', '1', '2023-10-11 07:45:24', '1', '2023-10-11 07:45:38', b'0');
INSERT INTO `platform_dict_data` VALUES (603, 2, '限时折扣页', '4', 'promotion_banner_position', 0, 'warning', '', '', '1', '2023-10-11 07:45:24', '1', '2023-10-11 07:45:38', b'0');
INSERT INTO `platform_dict_data` VALUES (604, 1, '满减送页', '5', 'promotion_banner_position', 0, 'warning', '', '', '1', '2023-10-11 07:45:24', '1', '2023-10-11 07:45:38', b'0');
INSERT INTO `platform_dict_data` VALUES (1118, 0, '等待退款', '0', 'pay_refund_status', 0, 'info', '', '等待退款', '1', '2021-12-10 16:44:59', '1', '2023-07-19 10:14:39', b'0');
INSERT INTO `platform_dict_data` VALUES (1119, 20, '退款失败', '20', 'pay_refund_status', 0, 'danger', '', '退款失败', '1', '2021-12-10 16:45:10', '1', '2023-07-19 10:15:10', b'0');
INSERT INTO `platform_dict_data` VALUES (1124, 10, '退款成功', '10', 'pay_refund_status', 0, 'success', '', '退款成功', '1', '2021-12-10 16:46:26', '1', '2023-07-19 10:15:00', b'0');
INSERT INTO `platform_dict_data` VALUES (1125, 0, '默认', '1', 'bpm_model_category', 0, 'primary', '', '流程分类 - 默认', '1', '2022-01-02 08:41:11', '1', '2022-02-16 20:01:42', b'0');
INSERT INTO `platform_dict_data` VALUES (1126, 0, 'OA', '2', 'bpm_model_category', 0, 'success', '', '流程分类 - OA', '1', '2022-01-02 08:41:22', '1', '2022-02-16 20:01:50', b'0');
INSERT INTO `platform_dict_data` VALUES (1127, 0, '进行中', '1', 'bpm_process_instance_status', 0, 'primary', '', '流程实例的状态 - 进行中', '1', '2022-01-07 23:47:22', '1', '2022-02-16 20:07:49', b'0');
INSERT INTO `platform_dict_data` VALUES (1128, 2, '已完成', '2', 'bpm_process_instance_status', 0, 'success', '', '流程实例的状态 - 已完成', '1', '2022-01-07 23:47:49', '1', '2022-02-16 20:07:54', b'0');
INSERT INTO `platform_dict_data` VALUES (1129, 1, '处理中', '1', 'bpm_process_instance_result', 0, 'primary', '', '流程实例的结果 - 处理中', '1', '2022-01-07 23:48:32', '1', '2022-02-16 09:53:26', b'0');
INSERT INTO `platform_dict_data` VALUES (1130, 2, '通过', '2', 'bpm_process_instance_result', 0, 'success', '', '流程实例的结果 - 通过', '1', '2022-01-07 23:48:45', '1', '2022-02-16 09:53:31', b'0');
INSERT INTO `platform_dict_data` VALUES (1131, 3, '不通过', '3', 'bpm_process_instance_result', 0, 'danger', '', '流程实例的结果 - 不通过', '1', '2022-01-07 23:48:55', '1', '2022-02-16 09:53:38', b'0');
INSERT INTO `platform_dict_data` VALUES (1132, 4, '已取消', '4', 'bpm_process_instance_result', 0, 'info', '', '流程实例的结果 - 撤销', '1', '2022-01-07 23:49:06', '1', '2022-02-16 09:53:42', b'0');
INSERT INTO `platform_dict_data` VALUES (1133, 10, '流程表单', '10', 'bpm_model_form_type', 0, '', '', '流程的表单类型 - 流程表单', '103', '2022-01-11 23:51:30', '103', '2022-01-11 23:51:30', b'0');
INSERT INTO `platform_dict_data` VALUES (1134, 20, '业务表单', '20', 'bpm_model_form_type', 0, '', '', '流程的表单类型 - 业务表单', '103', '2022-01-11 23:51:47', '103', '2022-01-11 23:51:47', b'0');
INSERT INTO `platform_dict_data` VALUES (1135, 10, '角色', '10', 'bpm_task_assign_rule_type', 0, 'info', '', '任务分配规则的类型 - 角色', '103', '2022-01-12 23:21:22', '1', '2022-02-16 20:06:14', b'0');
INSERT INTO `platform_dict_data` VALUES (1136, 20, '部门的成员', '20', 'bpm_task_assign_rule_type', 0, 'primary', '', '任务分配规则的类型 - 部门的成员', '103', '2022-01-12 23:21:47', '1', '2022-02-16 20:05:28', b'0');
INSERT INTO `platform_dict_data` VALUES (1137, 21, '部门的负责人', '21', 'bpm_task_assign_rule_type', 0, 'primary', '', '任务分配规则的类型 - 部门的负责人', '103', '2022-01-12 23:33:36', '1', '2022-02-16 20:05:31', b'0');
INSERT INTO `platform_dict_data` VALUES (1138, 30, '用户', '30', 'bpm_task_assign_rule_type', 0, 'info', '', '任务分配规则的类型 - 用户', '103', '2022-01-12 23:34:02', '1', '2022-02-16 20:05:50', b'0');
INSERT INTO `platform_dict_data` VALUES (1139, 40, '用户组', '40', 'bpm_task_assign_rule_type', 0, 'warning', '', '任务分配规则的类型 - 用户组', '103', '2022-01-12 23:34:21', '1', '2022-02-16 20:05:57', b'0');
INSERT INTO `platform_dict_data` VALUES (1140, 50, '自定义脚本', '50', 'bpm_task_assign_rule_type', 0, 'danger', '', '任务分配规则的类型 - 自定义脚本', '103', '2022-01-12 23:34:43', '1', '2022-02-16 20:06:01', b'0');
INSERT INTO `platform_dict_data` VALUES (1141, 22, '岗位', '22', 'bpm_task_assign_rule_type', 0, 'success', '', '任务分配规则的类型 - 岗位', '103', '2022-01-14 18:41:55', '1', '2022-02-16 20:05:39', b'0');
INSERT INTO `platform_dict_data` VALUES (1142, 10, '流程发起人', '10', 'bpm_task_assign_script', 0, '', '', '任务分配自定义脚本 - 流程发起人', '103', '2022-01-15 00:10:57', '103', '2022-01-15 21:24:10', b'0');
INSERT INTO `platform_dict_data` VALUES (1143, 20, '流程发起人的一级领导', '20', 'bpm_task_assign_script', 0, '', '', '任务分配自定义脚本 - 流程发起人的一级领导', '103', '2022-01-15 21:24:31', '103', '2022-01-15 21:24:31', b'0');
INSERT INTO `platform_dict_data` VALUES (1144, 21, '流程发起人的二级领导', '21', 'bpm_task_assign_script', 0, '', '', '任务分配自定义脚本 - 流程发起人的二级领导', '103', '2022-01-15 21:24:46', '103', '2022-01-15 21:24:57', b'0');
INSERT INTO `platform_dict_data` VALUES (1145, 1, '管理后台', '1', 'infra_codegen_scene', 0, '', '', '代码生成的场景枚举 - 管理后台', '1', '2022-02-02 13:15:06', '1', '2022-03-10 16:32:59', b'0');
INSERT INTO `platform_dict_data` VALUES (1146, 2, '用户 APP', '2', 'infra_codegen_scene', 0, '', '', '代码生成的场景枚举 - 用户 APP', '1', '2022-02-02 13:15:19', '1', '2022-03-10 16:33:03', b'0');
INSERT INTO `platform_dict_data` VALUES (1150, 1, '数据库', '1', 'infra_file_storage', 0, 'default', '', NULL, '1', '2022-03-15 00:25:28', '1', '2022-03-15 00:25:28', b'0');
INSERT INTO `platform_dict_data` VALUES (1151, 10, '本地磁盘', '10', 'infra_file_storage', 0, 'default', '', NULL, '1', '2022-03-15 00:25:41', '1', '2022-03-15 00:25:56', b'0');
INSERT INTO `platform_dict_data` VALUES (1152, 11, 'FTP 服务器', '11', 'infra_file_storage', 0, 'default', '', NULL, '1', '2022-03-15 00:26:06', '1', '2022-03-15 00:26:10', b'0');
INSERT INTO `platform_dict_data` VALUES (1153, 12, 'SFTP 服务器', '12', 'infra_file_storage', 0, 'default', '', NULL, '1', '2022-03-15 00:26:22', '1', '2022-03-15 00:26:22', b'0');
INSERT INTO `platform_dict_data` VALUES (1154, 20, 'S3 对象存储', '20', 'infra_file_storage', 0, 'default', '', NULL, '1', '2022-03-15 00:26:31', '1', '2022-03-15 00:26:45', b'0');
INSERT INTO `platform_dict_data` VALUES (1155, 103, '短信登录', '103', 'system_login_type', 0, 'default', '', NULL, '1', '2022-05-09 23:57:58', '1', '2022-05-09 23:58:09', b'0');
INSERT INTO `platform_dict_data` VALUES (1156, 1, 'password', 'password', 'system_oauth2_grant_type', 0, 'default', '', '密码模式', '1', '2022-05-12 00:22:05', '1', '2022-05-11 16:26:01', b'0');
INSERT INTO `platform_dict_data` VALUES (1157, 2, 'authorization_code', 'authorization_code', 'system_oauth2_grant_type', 0, 'primary', '', '授权码模式', '1', '2022-05-12 00:22:59', '1', '2022-05-11 16:26:02', b'0');
INSERT INTO `platform_dict_data` VALUES (1158, 3, 'implicit', 'implicit', 'system_oauth2_grant_type', 0, 'success', '', '简化模式', '1', '2022-05-12 00:23:40', '1', '2022-05-11 16:26:05', b'0');
INSERT INTO `platform_dict_data` VALUES (1159, 4, 'client_credentials', 'client_credentials', 'system_oauth2_grant_type', 0, 'default', '', '客户端模式', '1', '2022-05-12 00:23:51', '1', '2022-05-11 16:26:08', b'0');
INSERT INTO `platform_dict_data` VALUES (1160, 5, 'refresh_token', 'refresh_token', 'system_oauth2_grant_type', 0, 'info', '', '刷新模式', '1', '2022-05-12 00:24:02', '1', '2022-05-11 16:26:11', b'0');
INSERT INTO `platform_dict_data` VALUES (1162, 1, '销售中', '1', 'product_spu_status', 0, 'success', '', '商品 SPU 状态 - 销售中', '1', '2022-10-24 21:19:47', '1', '2022-10-24 21:20:38', b'0');
INSERT INTO `platform_dict_data` VALUES (1163, 0, '仓库中', '0', 'product_spu_status', 0, 'info', '', '商品 SPU 状态 - 仓库中', '1', '2022-10-24 21:20:54', '1', '2022-10-24 21:21:22', b'0');
INSERT INTO `platform_dict_data` VALUES (1164, 0, '回收站', '-1', 'product_spu_status', 0, 'default', '', '商品 SPU 状态 - 回收站', '1', '2022-10-24 21:21:11', '1', '2022-10-24 21:21:11', b'0');
INSERT INTO `platform_dict_data` VALUES (1165, 1, '满减', '1', 'promotion_discount_type', 0, 'success', '', '优惠类型 - 满减', '1', '2022-11-01 12:46:41', '1', '2022-11-01 12:50:11', b'0');
INSERT INTO `platform_dict_data` VALUES (1166, 2, '折扣', '2', 'promotion_discount_type', 0, 'primary', '', '优惠类型 - 折扣', '1', '2022-11-01 12:46:51', '1', '2022-11-01 12:50:08', b'0');
INSERT INTO `platform_dict_data` VALUES (1167, 1, '固定日期', '1', 'promotion_coupon_template_validity_type', 0, 'default', '', '优惠劵模板的有限期类型 - 固定日期', '1', '2022-11-02 00:07:34', '1', '2022-11-04 00:07:49', b'0');
INSERT INTO `platform_dict_data` VALUES (1168, 2, '领取之后', '2', 'promotion_coupon_template_validity_type', 0, 'default', '', '优惠劵模板的有限期类型 - 领取之后', '1', '2022-11-02 00:07:54', '1', '2022-11-04 00:07:52', b'0');
INSERT INTO `platform_dict_data` VALUES (1169, 1, '通用劵', '1', 'promotion_product_scope', 0, 'default', '', '营销的商品范围 - 全部商品参与', '1', '2022-11-02 00:28:22', '1', '2023-09-28 00:27:42', b'0');
INSERT INTO `platform_dict_data` VALUES (1170, 2, '商品劵', '2', 'promotion_product_scope', 0, 'default', '', '营销的商品范围 - 指定商品参与', '1', '2022-11-02 00:28:34', '1', '2023-09-28 00:27:44', b'0');
INSERT INTO `platform_dict_data` VALUES (1171, 1, '未使用', '1', 'promotion_coupon_status', 0, 'primary', '', '优惠劵的状态 - 已领取', '1', '2022-11-04 00:15:08', '1', '2023-10-03 12:54:38', b'0');
INSERT INTO `platform_dict_data` VALUES (1172, 2, '已使用', '2', 'promotion_coupon_status', 0, 'success', '', '优惠劵的状态 - 已使用', '1', '2022-11-04 00:15:21', '1', '2022-11-04 19:16:08', b'0');
INSERT INTO `platform_dict_data` VALUES (1173, 3, '已过期', '3', 'promotion_coupon_status', 0, 'info', '', '优惠劵的状态 - 已过期', '1', '2022-11-04 00:15:43', '1', '2022-11-04 19:16:12', b'0');
INSERT INTO `platform_dict_data` VALUES (1174, 1, '直接领取', '1', 'promotion_coupon_take_type', 0, 'primary', '', '优惠劵的领取方式 - 直接领取', '1', '2022-11-04 19:13:00', '1', '2022-11-04 19:13:25', b'0');
INSERT INTO `platform_dict_data` VALUES (1175, 2, '指定发放', '2', 'promotion_coupon_take_type', 0, 'success', '', '优惠劵的领取方式 - 指定发放', '1', '2022-11-04 19:13:13', '1', '2022-11-04 19:14:48', b'0');
INSERT INTO `platform_dict_data` VALUES (1176, 10, '未开始', '10', 'promotion_activity_status', 0, 'primary', '', '促销活动的状态枚举 - 未开始', '1', '2022-11-04 22:54:49', '1', '2022-11-04 22:55:53', b'0');
INSERT INTO `platform_dict_data` VALUES (1177, 20, '进行中', '20', 'promotion_activity_status', 0, 'success', '', '促销活动的状态枚举 - 进行中', '1', '2022-11-04 22:55:06', '1', '2022-11-04 22:55:20', b'0');
INSERT INTO `platform_dict_data` VALUES (1178, 30, '已结束', '30', 'promotion_activity_status', 0, 'info', '', '促销活动的状态枚举 - 已结束', '1', '2022-11-04 22:55:41', '1', '2022-11-04 22:55:41', b'0');
INSERT INTO `platform_dict_data` VALUES (1179, 40, '已关闭', '40', 'promotion_activity_status', 0, 'warning', '', '促销活动的状态枚举 - 已关闭', '1', '2022-11-04 22:56:10', '1', '2022-11-04 22:56:18', b'0');
INSERT INTO `platform_dict_data` VALUES (1180, 10, '满 N 元', '10', 'promotion_condition_type', 0, 'primary', '', '营销的条件类型 - 满 N 元', '1', '2022-11-04 22:59:45', '1', '2022-11-04 22:59:45', b'0');
INSERT INTO `platform_dict_data` VALUES (1181, 20, '满 N 件', '20', 'promotion_condition_type', 0, 'success', '', '营销的条件类型 - 满 N 件', '1', '2022-11-04 23:00:02', '1', '2022-11-04 23:00:02', b'0');
INSERT INTO `platform_dict_data` VALUES (1182, 10, '申请售后', '10', 'trade_after_sale_status', 0, 'primary', '', '交易售后状态 - 申请售后', '1', '2022-11-19 20:53:33', '1', '2022-11-19 20:54:42', b'0');
INSERT INTO `platform_dict_data` VALUES (1183, 20, '商品待退货', '20', 'trade_after_sale_status', 0, 'primary', '', '交易售后状态 - 商品待退货', '1', '2022-11-19 20:54:36', '1', '2022-11-19 20:58:58', b'0');
INSERT INTO `platform_dict_data` VALUES (1184, 30, '商家待收货', '30', 'trade_after_sale_status', 0, 'primary', '', '交易售后状态 - 商家待收货', '1', '2022-11-19 20:56:56', '1', '2022-11-19 20:59:20', b'0');
INSERT INTO `platform_dict_data` VALUES (1185, 40, '等待退款', '40', 'trade_after_sale_status', 0, 'primary', '', '交易售后状态 - 等待退款', '1', '2022-11-19 20:59:54', '1', '2022-11-19 21:00:01', b'0');
INSERT INTO `platform_dict_data` VALUES (1186, 50, '退款成功', '50', 'trade_after_sale_status', 0, 'default', '', '交易售后状态 - 退款成功', '1', '2022-11-19 21:00:33', '1', '2022-11-19 21:00:33', b'0');
INSERT INTO `platform_dict_data` VALUES (1187, 61, '买家取消', '61', 'trade_after_sale_status', 0, 'info', '', '交易售后状态 - 买家取消', '1', '2022-11-19 21:01:29', '1', '2022-11-19 21:01:29', b'0');
INSERT INTO `platform_dict_data` VALUES (1188, 62, '商家拒绝', '62', 'trade_after_sale_status', 0, 'info', '', '交易售后状态 - 商家拒绝', '1', '2022-11-19 21:02:17', '1', '2022-11-19 21:02:17', b'0');
INSERT INTO `platform_dict_data` VALUES (1189, 63, '商家拒收货', '63', 'trade_after_sale_status', 0, 'info', '', '交易售后状态 - 商家拒收货', '1', '2022-11-19 21:02:37', '1', '2022-11-19 21:03:07', b'0');
INSERT INTO `platform_dict_data` VALUES (1190, 10, '售中退款', '10', 'trade_after_sale_type', 0, 'success', '', '交易售后的类型 - 售中退款', '1', '2022-11-19 21:05:05', '1', '2022-11-19 21:38:23', b'0');
INSERT INTO `platform_dict_data` VALUES (1191, 20, '售后退款', '20', 'trade_after_sale_type', 0, 'primary', '', '交易售后的类型 - 售后退款', '1', '2022-11-19 21:05:32', '1', '2022-11-19 21:38:32', b'0');
INSERT INTO `platform_dict_data` VALUES (1192, 10, '仅退款', '10', 'trade_after_sale_way', 0, 'primary', '', '交易售后的方式 - 仅退款', '1', '2022-11-19 21:39:19', '1', '2022-11-19 21:39:19', b'0');
INSERT INTO `platform_dict_data` VALUES (1193, 20, '退货退款', '20', 'trade_after_sale_way', 0, 'success', '', '交易售后的方式 - 退货退款', '1', '2022-11-19 21:39:38', '1', '2022-11-19 21:39:49', b'0');
INSERT INTO `platform_dict_data` VALUES (1194, 10, '微信小程序', '10', 'terminal', 0, 'default', '', '终端 - 微信小程序', '1', '2022-12-10 10:51:11', '1', '2022-12-10 10:51:57', b'0');
INSERT INTO `platform_dict_data` VALUES (1195, 20, 'H5 网页', '20', 'terminal', 0, 'default', '', '终端 - H5 网页', '1', '2022-12-10 10:51:30', '1', '2022-12-10 10:51:59', b'0');
INSERT INTO `platform_dict_data` VALUES (1196, 11, '微信公众号', '11', 'terminal', 0, 'default', '', '终端 - 微信公众号', '1', '2022-12-10 10:54:16', '1', '2022-12-10 10:52:01', b'0');
INSERT INTO `platform_dict_data` VALUES (1197, 31, '苹果 App', '31', 'terminal', 0, 'default', '', '终端 - 苹果 App', '1', '2022-12-10 10:54:42', '1', '2022-12-10 10:52:18', b'0');
INSERT INTO `platform_dict_data` VALUES (1198, 32, '安卓 App', '32', 'terminal', 0, 'default', '', '终端 - 安卓 App', '1', '2022-12-10 10:55:02', '1', '2022-12-10 10:59:17', b'0');
INSERT INTO `platform_dict_data` VALUES (1199, 0, '普通订单', '0', 'trade_order_type', 0, 'default', '', '交易订单的类型 - 普通订单', '1', '2022-12-10 16:34:14', '1', '2022-12-10 16:34:14', b'0');
INSERT INTO `platform_dict_data` VALUES (1200, 1, '秒杀订单', '1', 'trade_order_type', 0, 'default', '', '交易订单的类型 - 秒杀订单', '1', '2022-12-10 16:34:26', '1', '2022-12-10 16:34:26', b'0');
INSERT INTO `platform_dict_data` VALUES (1201, 2, '拼团订单', '2', 'trade_order_type', 0, 'default', '', '交易订单的类型 - 拼团订单', '1', '2022-12-10 16:34:36', '1', '2022-12-10 16:34:36', b'0');
INSERT INTO `platform_dict_data` VALUES (1202, 3, '砍价订单', '3', 'trade_order_type', 0, 'default', '', '交易订单的类型 - 砍价订单', '1', '2022-12-10 16:34:48', '1', '2022-12-10 16:34:48', b'0');
INSERT INTO `platform_dict_data` VALUES (1203, 0, '待支付', '0', 'trade_order_status', 0, 'default', '', '交易订单状态 - 待支付', '1', '2022-12-10 16:49:29', '1', '2022-12-10 16:49:29', b'0');
INSERT INTO `platform_dict_data` VALUES (1204, 10, '待发货', '10', 'trade_order_status', 0, 'primary', '', '交易订单状态 - 待发货', '1', '2022-12-10 16:49:53', '1', '2022-12-10 16:51:17', b'0');
INSERT INTO `platform_dict_data` VALUES (1205, 20, '已发货', '20', 'trade_order_status', 0, 'primary', '', '交易订单状态 - 已发货', '1', '2022-12-10 16:50:13', '1', '2022-12-10 16:51:31', b'0');
INSERT INTO `platform_dict_data` VALUES (1206, 30, '已完成', '30', 'trade_order_status', 0, 'success', '', '交易订单状态 - 已完成', '1', '2022-12-10 16:50:30', '1', '2022-12-10 16:51:06', b'0');
INSERT INTO `platform_dict_data` VALUES (1207, 40, '已取消', '40', 'trade_order_status', 0, 'danger', '', '交易订单状态 - 已取消', '1', '2022-12-10 16:50:50', '1', '2022-12-10 16:51:00', b'0');
INSERT INTO `platform_dict_data` VALUES (1208, 0, '未售后', '0', 'trade_order_item_after_sale_status', 0, 'info', '', '交易订单项的售后状态 - 未售后', '1', '2022-12-10 20:58:42', '1', '2022-12-10 20:59:29', b'0');
INSERT INTO `platform_dict_data` VALUES (1209, 1, '售后中', '1', 'trade_order_item_after_sale_status', 0, 'primary', '', '交易订单项的售后状态 - 售后中', '1', '2022-12-10 20:59:21', '1', '2022-12-10 20:59:21', b'0');
INSERT INTO `platform_dict_data` VALUES (1210, 2, '已退款', '2', 'trade_order_item_after_sale_status', 0, 'success', '', '交易订单项的售后状态 - 已退款', '1', '2022-12-10 20:59:46', '1', '2022-12-10 20:59:46', b'0');
INSERT INTO `platform_dict_data` VALUES (1211, 1, '完全匹配', '1', 'mp_auto_reply_request_match', 0, 'primary', '', '公众号自动回复的请求关键字匹配模式 - 完全匹配', '1', '2023-01-16 23:30:39', '1', '2023-01-16 23:31:00', b'0');
INSERT INTO `platform_dict_data` VALUES (1212, 2, '半匹配', '2', 'mp_auto_reply_request_match', 0, 'success', '', '公众号自动回复的请求关键字匹配模式 - 半匹配', '1', '2023-01-16 23:30:55', '1', '2023-01-16 23:31:10', b'0');
INSERT INTO `platform_dict_data` VALUES (1213, 1, '文本', 'text', 'mp_message_type', 0, 'default', '', '公众号的消息类型 - 文本', '1', '2023-01-17 22:17:32', '1', '2023-01-17 22:17:39', b'0');
INSERT INTO `platform_dict_data` VALUES (1214, 2, '图片', 'image', 'mp_message_type', 0, 'default', '', '公众号的消息类型 - 图片', '1', '2023-01-17 22:17:32', '1', '2023-01-17 14:19:47', b'0');
INSERT INTO `platform_dict_data` VALUES (1215, 3, '语音', 'voice', 'mp_message_type', 0, 'default', '', '公众号的消息类型 - 语音', '1', '2023-01-17 22:17:32', '1', '2023-01-17 14:20:08', b'0');
INSERT INTO `platform_dict_data` VALUES (1216, 4, '视频', 'video', 'mp_message_type', 0, 'default', '', '公众号的消息类型 - 视频', '1', '2023-01-17 22:17:32', '1', '2023-01-17 14:21:08', b'0');
INSERT INTO `platform_dict_data` VALUES (1217, 5, '小视频', 'shortvideo', 'mp_message_type', 0, 'default', '', '公众号的消息类型 - 小视频', '1', '2023-01-17 22:17:32', '1', '2023-01-17 14:19:59', b'0');
INSERT INTO `platform_dict_data` VALUES (1218, 6, '图文', 'news', 'mp_message_type', 0, 'default', '', '公众号的消息类型 - 图文', '1', '2023-01-17 22:17:32', '1', '2023-01-17 14:22:54', b'0');
INSERT INTO `platform_dict_data` VALUES (1219, 7, '音乐', 'music', 'mp_message_type', 0, 'default', '', '公众号的消息类型 - 音乐', '1', '2023-01-17 22:17:32', '1', '2023-01-17 14:22:54', b'0');
INSERT INTO `platform_dict_data` VALUES (1220, 8, '地理位置', 'location', 'mp_message_type', 0, 'default', '', '公众号的消息类型 - 地理位置', '1', '2023-01-17 22:17:32', '1', '2023-01-17 14:23:51', b'0');
INSERT INTO `platform_dict_data` VALUES (1221, 9, '链接', 'link', 'mp_message_type', 0, 'default', '', '公众号的消息类型 - 链接', '1', '2023-01-17 22:17:32', '1', '2023-01-17 14:24:49', b'0');
INSERT INTO `platform_dict_data` VALUES (1222, 10, '事件', 'event', 'mp_message_type', 0, 'default', '', '公众号的消息类型 - 事件', '1', '2023-01-17 22:17:32', '1', '2023-01-17 14:24:49', b'0');
INSERT INTO `platform_dict_data` VALUES (1223, 0, '初始化', '0', 'system_mail_send_status', 0, 'primary', '', '邮件发送状态 - 初始化\n', '1', '2023-01-26 09:53:49', '1', '2023-01-26 16:36:14', b'0');
INSERT INTO `platform_dict_data` VALUES (1224, 10, '发送成功', '10', 'system_mail_send_status', 0, 'success', '', '邮件发送状态 - 发送成功', '1', '2023-01-26 09:54:28', '1', '2023-01-26 16:36:22', b'0');
INSERT INTO `platform_dict_data` VALUES (1225, 20, '发送失败', '20', 'system_mail_send_status', 0, 'danger', '', '邮件发送状态 - 发送失败', '1', '2023-01-26 09:54:50', '1', '2023-01-26 16:36:26', b'0');
INSERT INTO `platform_dict_data` VALUES (1226, 30, '不发送', '30', 'system_mail_send_status', 0, 'info', '', '邮件发送状态 -  不发送', '1', '2023-01-26 09:55:06', '1', '2023-01-26 16:36:36', b'0');
INSERT INTO `platform_dict_data` VALUES (1227, 1, '通知公告', '1', 'system_notify_template_type', 0, 'primary', '', '站内信模版的类型 - 通知公告', '1', '2023-01-28 10:35:59', '1', '2023-01-28 10:35:59', b'0');
INSERT INTO `platform_dict_data` VALUES (1228, 2, '系统消息', '2', 'system_notify_template_type', 0, 'success', '', '站内信模版的类型 - 系统消息', '1', '2023-01-28 10:36:20', '1', '2023-01-28 10:36:25', b'0');
INSERT INTO `platform_dict_data` VALUES (1230, 13, '支付宝条码支付', 'alipay_bar', 'pay_channel_code', 0, 'primary', '', '支付宝条码支付', '1', '2023-02-18 23:32:24', '1', '2023-07-19 20:09:23', b'0');
INSERT INTO `platform_dict_data` VALUES (1231, 10, 'Vue2 Element UI 标准模版', '10', 'infra_codegen_front_type', 0, '', '', '', '1', '2023-04-13 00:03:55', '1', '2023-04-13 00:03:55', b'0');
INSERT INTO `platform_dict_data` VALUES (1232, 20, 'Vue3 Element Plus 标准模版', '20', 'infra_codegen_front_type', 0, '', '', '', '1', '2023-04-13 00:04:08', '1', '2023-04-13 00:04:08', b'0');
INSERT INTO `platform_dict_data` VALUES (1233, 21, 'Vue3 Element Plus Schema 模版', '21', 'infra_codegen_front_type', 0, '', '', '', '1', '2023-04-13 00:04:26', '1', '2023-04-13 00:04:26', b'0');
INSERT INTO `platform_dict_data` VALUES (1234, 30, 'Vue3 vben 模版', '30', 'infra_codegen_front_type', 0, '', '', '', '1', '2023-04-13 00:04:26', '1', '2023-04-13 00:04:26', b'0');
INSERT INTO `platform_dict_data` VALUES (1235, 1, '个', '1', 'product_unit', 0, '', '', '', '1', '2023-05-23 14:38:38', '1', '2023-05-23 14:38:38', b'0');
INSERT INTO `platform_dict_data` VALUES (1236, 1, '件', '2', 'product_unit', 0, '', '', '', '1', '2023-05-23 14:38:38', '1', '2023-05-23 14:38:38', b'0');
INSERT INTO `platform_dict_data` VALUES (1237, 1, '盒', '3', 'product_unit', 0, '', '', '', '1', '2023-05-23 14:38:38', '1', '2023-05-23 14:38:38', b'0');
INSERT INTO `platform_dict_data` VALUES (1238, 1, '袋', '4', 'product_unit', 0, '', '', '', '1', '2023-05-23 14:38:38', '1', '2023-05-23 14:38:38', b'0');
INSERT INTO `platform_dict_data` VALUES (1239, 1, '箱', '5', 'product_unit', 0, '', '', '', '1', '2023-05-23 14:38:38', '1', '2023-05-23 14:38:38', b'0');
INSERT INTO `platform_dict_data` VALUES (1240, 1, '套', '6', 'product_unit', 0, '', '', '', '1', '2023-05-23 14:38:38', '1', '2023-05-23 14:38:38', b'0');
INSERT INTO `platform_dict_data` VALUES (1241, 1, '包', '7', 'product_unit', 0, '', '', '', '1', '2023-05-23 14:38:38', '1', '2023-05-23 14:38:38', b'0');
INSERT INTO `platform_dict_data` VALUES (1242, 1, '双', '8', 'product_unit', 0, '', '', '', '1', '2023-05-23 14:38:38', '1', '2023-05-23 14:38:38', b'0');
INSERT INTO `platform_dict_data` VALUES (1243, 1, '卷', '9', 'product_unit', 0, '', '', '', '1', '2023-05-23 14:38:38', '1', '2023-05-23 14:38:38', b'0');
INSERT INTO `platform_dict_data` VALUES (1244, 0, '按件', '1', 'trade_delivery_express_charge_mode', 0, '', '', '', '1', '2023-05-21 22:46:40', '1', '2023-05-21 22:46:40', b'0');
INSERT INTO `platform_dict_data` VALUES (1245, 1, '按重量', '2', 'trade_delivery_express_charge_mode', 0, '', '', '', '1', '2023-05-21 22:46:58', '1', '2023-05-21 22:46:58', b'0');
INSERT INTO `platform_dict_data` VALUES (1246, 2, '按体积', '3', 'trade_delivery_express_charge_mode', 0, '', '', '', '1', '2023-05-21 22:47:18', '1', '2023-05-21 22:47:18', b'0');
INSERT INTO `platform_dict_data` VALUES (1335, 11, '订单积分抵扣', '11', 'member_point_biz_type', 0, '', '', '', '1', '2023-06-10 12:15:27', '1', '2023-10-11 07:41:43', b'0');
INSERT INTO `platform_dict_data` VALUES (1336, 1, '签到', '1', 'member_point_biz_type', 0, '', '', '', '1', '2023-06-10 12:15:48', '1', '2023-08-20 11:59:53', b'0');
INSERT INTO `platform_dict_data` VALUES (1341, 20, '已退款', '20', 'pay_order_status', 0, 'danger', '', '已退款', '1', '2023-07-19 18:05:37', '1', '2023-07-19 18:05:37', b'0');
INSERT INTO `platform_dict_data` VALUES (1342, 21, '请求成功，但是结果失败', '21', 'pay_notify_status', 0, 'warning', '', '请求成功，但是结果失败', '1', '2023-07-19 18:10:47', '1', '2023-07-19 18:11:38', b'0');
INSERT INTO `platform_dict_data` VALUES (1343, 22, '请求失败', '22', 'pay_notify_status', 0, 'warning', '', NULL, '1', '2023-07-19 18:11:05', '1', '2023-07-19 18:11:27', b'0');
INSERT INTO `platform_dict_data` VALUES (1344, 4, '微信扫码支付', 'wx_native', 'pay_channel_code', 0, 'success', '', '微信扫码支付', '1', '2023-07-19 20:07:47', '1', '2023-07-19 20:09:03', b'0');
INSERT INTO `platform_dict_data` VALUES (1345, 5, '微信条码支付', 'wx_bar', 'pay_channel_code', 0, 'success', '', '微信条码支付\n', '1', '2023-07-19 20:08:06', '1', '2023-07-19 20:09:08', b'0');
INSERT INTO `platform_dict_data` VALUES (1346, 1, '支付单', '1', 'pay_notify_type', 0, 'primary', '', '支付单', '1', '2023-07-20 12:23:17', '1', '2023-07-20 12:23:17', b'0');
INSERT INTO `platform_dict_data` VALUES (1347, 2, '退款单', '2', 'pay_notify_type', 0, 'danger', '', NULL, '1', '2023-07-20 12:23:26', '1', '2023-07-20 12:23:26', b'0');
INSERT INTO `platform_dict_data` VALUES (1348, 20, '模拟支付', 'mock', 'pay_channel_code', 0, 'default', '', '模拟支付', '1', '2023-07-29 11:10:51', '1', '2023-07-29 03:14:10', b'0');
INSERT INTO `platform_dict_data` VALUES (1349, 12, '订单积分抵扣（整单取消）', '12', 'member_point_biz_type', 0, '', '', '', '1', '2023-08-20 12:00:03', '1', '2023-10-11 07:42:01', b'0');
INSERT INTO `platform_dict_data` VALUES (1350, 0, '管理员调整', '0', 'member_experience_biz_type', 0, '', '', NULL, '', '2023-08-22 12:41:01', '', '2023-08-22 12:41:01', b'0');
INSERT INTO `platform_dict_data` VALUES (1351, 1, '邀新奖励', '1', 'member_experience_biz_type', 0, '', '', NULL, '', '2023-08-22 12:41:01', '', '2023-08-22 12:41:01', b'0');
INSERT INTO `platform_dict_data` VALUES (1352, 11, '下单奖励', '11', 'member_experience_biz_type', 0, 'success', '', NULL, '', '2023-08-22 12:41:01', '1', '2023-10-11 07:45:09', b'0');
INSERT INTO `platform_dict_data` VALUES (1353, 12, '下单奖励（整单取消）', '12', 'member_experience_biz_type', 0, 'warning', '', NULL, '', '2023-08-22 12:41:01', '1', '2023-10-11 07:45:01', b'0');
INSERT INTO `platform_dict_data` VALUES (1354, 4, '签到奖励', '4', 'member_experience_biz_type', 0, '', '', NULL, '', '2023-08-22 12:41:01', '', '2023-08-22 12:41:01', b'0');
INSERT INTO `platform_dict_data` VALUES (1355, 5, '抽奖奖励', '5', 'member_experience_biz_type', 0, '', '', NULL, '', '2023-08-22 12:41:01', '', '2023-08-22 12:41:01', b'0');
INSERT INTO `platform_dict_data` VALUES (1356, 1, '快递发货', '1', 'trade_delivery_type', 0, '', '', '', '1', '2023-08-23 00:04:55', '1', '2023-08-23 00:04:55', b'0');
INSERT INTO `platform_dict_data` VALUES (1357, 2, '用户自提', '2', 'trade_delivery_type', 0, '', '', '', '1', '2023-08-23 00:05:05', '1', '2023-08-23 00:05:05', b'0');
INSERT INTO `platform_dict_data` VALUES (1358, 3, '品类劵', '3', 'promotion_product_scope', 0, 'default', '', '', '1', '2023-09-01 23:43:07', '1', '2023-09-28 00:27:47', b'0');
INSERT INTO `platform_dict_data` VALUES (1359, 1, '人人分销', '1', 'brokerage_enabled_condition', 0, '', '', '所有用户都可以分销', '', '2023-09-28 02:46:05', '', '2023-09-28 02:46:05', b'0');
INSERT INTO `platform_dict_data` VALUES (1360, 2, '指定分销', '2', 'brokerage_enabled_condition', 0, '', '', '仅可后台手动设置推广员', '', '2023-09-28 02:46:05', '', '2023-09-28 02:46:05', b'0');
INSERT INTO `platform_dict_data` VALUES (1361, 1, '首次绑定', '1', 'brokerage_bind_mode', 0, '', '', '只要用户没有推广人，随时都可以绑定推广关系', '', '2023-09-28 02:46:05', '', '2023-09-28 02:46:05', b'0');
INSERT INTO `platform_dict_data` VALUES (1362, 2, '注册绑定', '2', 'brokerage_bind_mode', 0, '', '', '仅新用户注册时才能绑定推广关系', '', '2023-09-28 02:46:05', '', '2023-09-28 02:46:05', b'0');
INSERT INTO `platform_dict_data` VALUES (1363, 3, '覆盖绑定', '3', 'brokerage_bind_mode', 0, '', '', '如果用户已经有推广人，推广人会被变更', '', '2023-09-28 02:46:05', '', '2023-09-28 02:46:05', b'0');
INSERT INTO `platform_dict_data` VALUES (1364, 1, '钱包', '1', 'brokerage_withdraw_type', 0, '', '', NULL, '', '2023-09-28 02:46:05', '', '2023-09-28 02:46:05', b'0');
INSERT INTO `platform_dict_data` VALUES (1365, 2, '银行卡', '2', 'brokerage_withdraw_type', 0, '', '', NULL, '', '2023-09-28 02:46:05', '', '2023-09-28 02:46:05', b'0');
INSERT INTO `platform_dict_data` VALUES (1366, 3, '微信', '3', 'brokerage_withdraw_type', 0, '', '', NULL, '', '2023-09-28 02:46:05', '', '2023-09-28 02:46:05', b'0');
INSERT INTO `platform_dict_data` VALUES (1367, 4, '支付宝', '4', 'brokerage_withdraw_type', 0, '', '', NULL, '', '2023-09-28 02:46:05', '', '2023-09-28 02:46:05', b'0');
INSERT INTO `platform_dict_data` VALUES (1368, 1, '订单返佣', '1', 'brokerage_record_biz_type', 0, '', '', NULL, '', '2023-09-28 02:46:05', '', '2023-09-28 02:46:05', b'0');
INSERT INTO `platform_dict_data` VALUES (1369, 2, '申请提现', '2', 'brokerage_record_biz_type', 0, '', '', NULL, '', '2023-09-28 02:46:05', '', '2023-09-28 02:46:05', b'0');
INSERT INTO `platform_dict_data` VALUES (1370, 3, '申请提现驳回', '3', 'brokerage_record_biz_type', 0, '', '', NULL, '', '2023-09-28 02:46:05', '', '2023-09-28 02:46:05', b'0');
INSERT INTO `platform_dict_data` VALUES (1371, 0, '待结算', '0', 'brokerage_record_status', 0, '', '', NULL, '', '2023-09-28 02:46:05', '', '2023-09-28 02:46:05', b'0');
INSERT INTO `platform_dict_data` VALUES (1372, 1, '已结算', '1', 'brokerage_record_status', 0, '', '', NULL, '', '2023-09-28 02:46:05', '', '2023-09-28 02:46:05', b'0');
INSERT INTO `platform_dict_data` VALUES (1373, 2, '已取消', '2', 'brokerage_record_status', 0, '', '', NULL, '', '2023-09-28 02:46:05', '', '2023-09-28 02:46:05', b'0');
INSERT INTO `platform_dict_data` VALUES (1374, 0, '审核中', '0', 'brokerage_withdraw_status', 0, '', '', NULL, '', '2023-09-28 02:46:05', '', '2023-09-28 02:46:05', b'0');
INSERT INTO `platform_dict_data` VALUES (1375, 10, '审核通过', '10', 'brokerage_withdraw_status', 0, 'success', '', NULL, '', '2023-09-28 02:46:05', '', '2023-09-28 02:46:05', b'0');
INSERT INTO `platform_dict_data` VALUES (1376, 11, '提现成功', '11', 'brokerage_withdraw_status', 0, 'success', '', NULL, '', '2023-09-28 02:46:05', '', '2023-09-28 02:46:05', b'0');
INSERT INTO `platform_dict_data` VALUES (1377, 20, '审核不通过', '20', 'brokerage_withdraw_status', 0, 'danger', '', NULL, '', '2023-09-28 02:46:05', '', '2023-09-28 02:46:05', b'0');
INSERT INTO `platform_dict_data` VALUES (1378, 21, '提现失败', '21', 'brokerage_withdraw_status', 0, 'danger', '', NULL, '', '2023-09-28 02:46:05', '', '2023-09-28 02:46:05', b'0');
INSERT INTO `platform_dict_data` VALUES (1379, 0, '工商银行', '0', 'brokerage_bank_name', 0, '', '', NULL, '', '2023-09-28 02:46:05', '', '2023-09-28 02:46:05', b'0');
INSERT INTO `platform_dict_data` VALUES (1380, 1, '建设银行', '1', 'brokerage_bank_name', 0, '', '', NULL, '', '2023-09-28 02:46:05', '', '2023-09-28 02:46:05', b'0');
INSERT INTO `platform_dict_data` VALUES (1381, 2, '农业银行', '2', 'brokerage_bank_name', 0, '', '', NULL, '', '2023-09-28 02:46:05', '', '2023-09-28 02:46:05', b'0');
INSERT INTO `platform_dict_data` VALUES (1382, 3, '中国银行', '3', 'brokerage_bank_name', 0, '', '', NULL, '', '2023-09-28 02:46:05', '', '2023-09-28 02:46:05', b'0');
INSERT INTO `platform_dict_data` VALUES (1383, 4, '交通银行', '4', 'brokerage_bank_name', 0, '', '', NULL, '', '2023-09-28 02:46:05', '', '2023-09-28 02:46:05', b'0');
INSERT INTO `platform_dict_data` VALUES (1384, 5, '招商银行', '5', 'brokerage_bank_name', 0, '', '', NULL, '', '2023-09-28 02:46:05', '', '2023-09-28 02:46:05', b'0');
INSERT INTO `platform_dict_data` VALUES (1385, 21, '钱包', 'wallet', 'pay_channel_code', 0, 'primary', '', '', '1', '2023-10-01 21:46:19', '1', '2023-10-01 21:48:01', b'0');
INSERT INTO `platform_dict_data` VALUES (1386, 1, '砍价中', '1', 'promotion_bargain_record_status', 0, 'default', '', '', '1', '2023-10-05 10:41:26', '1', '2023-10-05 10:41:26', b'0');
INSERT INTO `platform_dict_data` VALUES (1387, 2, '砍价成功', '2', 'promotion_bargain_record_status', 0, 'success', '', '', '1', '2023-10-05 10:41:39', '1', '2023-10-05 10:41:39', b'0');
INSERT INTO `platform_dict_data` VALUES (1388, 3, '砍价失败', '3', 'promotion_bargain_record_status', 0, 'warning', '', '', '1', '2023-10-05 10:41:57', '1', '2023-10-05 10:41:57', b'0');
INSERT INTO `platform_dict_data` VALUES (1389, 1, '拼团中', '1', 'promotion_combination_record_status', 0, '', '', '', '1', '2023-10-08 07:24:44', '1', '2023-10-08 07:24:44', b'0');
INSERT INTO `platform_dict_data` VALUES (1390, 2, '拼团成功', '2', 'promotion_combination_record_status', 0, 'success', '', '', '1', '2023-10-08 07:24:56', '1', '2023-10-08 07:24:56', b'0');
INSERT INTO `platform_dict_data` VALUES (1391, 3, '拼团失败', '3', 'promotion_combination_record_status', 0, 'warning', '', '', '1', '2023-10-08 07:25:11', '1', '2023-10-08 07:25:11', b'0');
INSERT INTO `platform_dict_data` VALUES (1392, 2, '管理员修改', '2', 'member_point_biz_type', 0, 'default', '', '', '1', '2023-10-11 07:41:34', '1', '2023-10-11 07:41:34', b'0');
INSERT INTO `platform_dict_data` VALUES (1393, 13, '订单积分抵扣（单个退款）', '13', 'member_point_biz_type', 0, '', '', '', '1', '2023-10-11 07:42:29', '1', '2023-10-11 07:42:29', b'0');
INSERT INTO `platform_dict_data` VALUES (1394, 21, '订单积分奖励', '21', 'member_point_biz_type', 0, 'default', '', '', '1', '2023-10-11 07:42:44', '1', '2023-10-11 07:42:44', b'0');
INSERT INTO `platform_dict_data` VALUES (1395, 22, '订单积分奖励（整单取消）', '22', 'member_point_biz_type', 0, 'default', '', '', '1', '2023-10-11 07:42:55', '1', '2023-10-11 07:43:01', b'0');
INSERT INTO `platform_dict_data` VALUES (1396, 23, '订单积分奖励（单个退款）', '23', 'member_point_biz_type', 0, 'default', '', '', '1', '2023-10-11 07:43:16', '1', '2023-10-11 07:43:16', b'0');
INSERT INTO `platform_dict_data` VALUES (1397, 13, '下单奖励（单个退款）', '13', 'member_experience_biz_type', 0, 'warning', '', '', '1', '2023-10-11 07:45:24', '1', '2023-10-11 07:45:38', b'0');
INSERT INTO `platform_dict_data` VALUES (1402, 1, 'A 农、林、牧、渔业', '1', 'crm_customer_industry', 0, 'default', '', '', '1', '2023-10-28 23:02:15', '1', '2023-10-28 23:02:15', b'0');
INSERT INTO `platform_dict_data` VALUES (1403, 2, 'B 采矿业', '2', 'crm_customer_industry', 0, 'default', '', '', '1', '2023-10-28 23:02:29', '1', '2023-10-28 23:02:29', b'0');
INSERT INTO `platform_dict_data` VALUES (1404, 3, 'C 制造业', '3', 'crm_customer_industry', 0, 'default', '', '', '1', '2023-10-28 23:02:41', '1', '2023-10-28 23:02:41', b'0');
INSERT INTO `platform_dict_data` VALUES (1405, 4, 'D 电力、热力、燃气及水生产和供应业', '4', 'crm_customer_industry', 0, 'default', '', '', '1', '2023-10-28 23:02:54', '1', '2023-10-28 23:02:54', b'0');
INSERT INTO `platform_dict_data` VALUES (1406, 5, 'E 建筑业', '5', 'crm_customer_industry', 0, 'default', '', '', '1', '2023-10-28 23:03:03', '1', '2023-10-28 23:03:03', b'0');
INSERT INTO `platform_dict_data` VALUES (1407, 6, 'F 批发和零售业', '6', 'crm_customer_industry', 0, 'default', '', '', '1', '2023-10-28 23:03:13', '1', '2023-10-28 23:03:13', b'0');
INSERT INTO `platform_dict_data` VALUES (1408, 7, 'G 交通运输、仓储和邮政业', '7', 'crm_customer_industry', 0, 'default', '', '', '1', '2023-10-28 23:03:27', '1', '2023-10-28 23:03:27', b'0');
INSERT INTO `platform_dict_data` VALUES (1409, 8, 'H 住宿和餐饮业', '8', 'crm_customer_industry', 0, 'default', '', '', '1', '2023-10-28 23:03:37', '1', '2023-10-28 23:03:37', b'0');
INSERT INTO `platform_dict_data` VALUES (1410, 9, 'I 信息传输、软件和信息技术服务业', '9', 'crm_customer_industry', 0, 'default', '', '', '1', '2023-10-28 23:03:47', '1', '2023-10-28 23:03:47', b'0');
INSERT INTO `platform_dict_data` VALUES (1411, 10, 'J 金融业', '10', 'crm_customer_industry', 0, 'default', '', '', '1', '2023-10-28 23:03:57', '1', '2023-10-28 23:03:57', b'0');
INSERT INTO `platform_dict_data` VALUES (1412, 11, 'K 房地产业', '11', 'crm_customer_industry', 0, 'default', '', '', '1', '2023-10-28 23:04:15', '1', '2023-10-28 23:04:22', b'0');
INSERT INTO `platform_dict_data` VALUES (1413, 12, 'L 租赁和商务服务业', '12', 'crm_customer_industry', 0, 'default', '', '', '1', '2023-10-28 23:04:33', '1', '2023-10-28 23:04:33', b'0');
INSERT INTO `platform_dict_data` VALUES (1414, 13, 'M 科学研究和技术服务业', '13', 'crm_customer_industry', 0, 'default', '', '', '1', '2023-10-28 23:04:43', '1', '2023-10-28 23:04:43', b'0');
INSERT INTO `platform_dict_data` VALUES (1415, 14, 'N 水利、环境和公共设施管理业', '14', 'crm_customer_industry', 0, 'default', '', '', '1', '2023-10-28 23:04:53', '1', '2023-10-28 23:04:53', b'0');
INSERT INTO `platform_dict_data` VALUES (1416, 15, 'O 居民服务、修理和其他服务业', '15', 'crm_customer_industry', 0, 'default', '', '', '1', '2023-10-28 23:05:05', '1', '2023-10-28 23:05:05', b'0');
INSERT INTO `platform_dict_data` VALUES (1417, 16, 'P 教育', '16', 'crm_customer_industry', 0, 'default', '', '', '1', '2023-10-28 23:05:15', '1', '2023-10-28 23:05:15', b'0');
INSERT INTO `platform_dict_data` VALUES (1418, 17, 'Q 卫生和社会工作', '17', 'crm_customer_industry', 0, 'default', '', '', '1', '2023-10-28 23:05:44', '1', '2023-10-28 23:05:44', b'0');
INSERT INTO `platform_dict_data` VALUES (1419, 18, 'R 文化、体育和娱乐业', '18', 'crm_customer_industry', 0, 'default', '', '', '1', '2023-10-28 23:05:55', '1', '2023-10-28 23:05:55', b'0');
INSERT INTO `platform_dict_data` VALUES (1420, 19, 'S 公共管理、社会保障和社会组织', '19', 'crm_customer_industry', 0, 'default', '', '', '1', '2023-10-28 23:06:05', '1', '2023-10-28 23:06:05', b'0');
INSERT INTO `platform_dict_data` VALUES (1421, 20, 'T 国际组织', '20', 'crm_customer_industry', 0, 'default', '', '', '1', '2023-10-28 23:06:15', '1', '2023-10-28 23:06:15', b'0');
INSERT INTO `platform_dict_data` VALUES (1422, 1, 'A （重点客户）', '1', 'crm_customer_level', 0, 'primary', '', '', '1', '2023-10-28 23:07:13', '1', '2023-10-28 23:07:13', b'0');
INSERT INTO `platform_dict_data` VALUES (1423, 2, 'B （普通客户）', '2', 'crm_customer_level', 0, 'info', '', '', '1', '2023-10-28 23:07:35', '1', '2023-10-28 23:07:35', b'0');
INSERT INTO `platform_dict_data` VALUES (1424, 3, 'C （非优先客户）', '3', 'crm_customer_level', 0, 'default', '', '', '1', '2023-10-28 23:07:53', '1', '2023-10-28 23:07:53', b'0');
INSERT INTO `platform_dict_data` VALUES (1425, 1, '促销', '1', 'crm_customer_source', 0, 'default', '', '', '1', '2023-10-28 23:08:29', '1', '2023-10-28 23:08:29', b'0');
INSERT INTO `platform_dict_data` VALUES (1426, 2, '搜索引擎', '2', 'crm_customer_source', 0, 'default', '', '', '1', '2023-10-28 23:08:39', '1', '2023-10-28 23:08:39', b'0');
INSERT INTO `platform_dict_data` VALUES (1427, 3, '广告', '3', 'crm_customer_source', 0, 'default', '', '', '1', '2023-10-28 23:08:47', '1', '2023-10-28 23:08:47', b'0');
INSERT INTO `platform_dict_data` VALUES (1428, 4, '转介绍', '4', 'crm_customer_source', 0, 'default', '', '', '1', '2023-10-28 23:08:58', '1', '2023-10-28 23:08:58', b'0');
INSERT INTO `platform_dict_data` VALUES (1429, 5, '线上注册', '5', 'crm_customer_source', 0, 'default', '', '', '1', '2023-10-28 23:09:12', '1', '2023-10-28 23:09:12', b'0');
INSERT INTO `platform_dict_data` VALUES (1430, 6, '线上咨询', '6', 'crm_customer_source', 0, 'default', '', '', '1', '2023-10-28 23:09:22', '1', '2023-10-28 23:09:22', b'0');
INSERT INTO `platform_dict_data` VALUES (1431, 7, '预约上门', '7', 'crm_customer_source', 0, 'default', '', '', '1', '2023-10-28 23:09:39', '1', '2023-10-28 23:09:39', b'0');
INSERT INTO `platform_dict_data` VALUES (1432, 8, '陌拜', '8', 'crm_customer_source', 0, 'default', '', '', '1', '2023-10-28 23:10:04', '1', '2023-10-28 23:10:04', b'0');
INSERT INTO `platform_dict_data` VALUES (1433, 9, '电话咨询', '9', 'crm_customer_source', 0, 'default', '', '', '1', '2023-10-28 23:10:18', '1', '2023-10-28 23:10:18', b'0');
INSERT INTO `platform_dict_data` VALUES (1434, 10, '邮件咨询', '10', 'crm_customer_source', 0, 'default', '', '', '1', '2023-10-28 23:10:33', '1', '2023-10-28 23:10:33', b'0');
INSERT INTO `platform_dict_data` VALUES (1435, 10, 'Gitee', '10', 'system_social_type', 0, '', '', '', '1', '2023-11-04 13:04:42', '1', '2023-11-04 13:04:42', b'0');
INSERT INTO `platform_dict_data` VALUES (1436, 20, '钉钉', '20', 'system_social_type', 0, '', '', '', '1', '2023-11-04 13:04:54', '1', '2023-11-04 13:04:54', b'0');
INSERT INTO `platform_dict_data` VALUES (1437, 30, '企业微信', '30', 'system_social_type', 0, '', '', '', '1', '2023-11-04 13:05:09', '1', '2023-11-04 13:05:09', b'0');
INSERT INTO `platform_dict_data` VALUES (1438, 31, '微信公众平台', '31', 'system_social_type', 0, '', '', '', '1', '2023-11-04 13:05:18', '1', '2023-11-04 13:05:18', b'0');
INSERT INTO `platform_dict_data` VALUES (1439, 32, '微信开放平台', '32', 'system_social_type', 0, '', '', '', '1', '2023-11-04 13:05:30', '1', '2023-11-04 13:05:30', b'0');
INSERT INTO `platform_dict_data` VALUES (1440, 34, '微信小程序', '34', 'system_social_type', 0, '', '', '', '1', '2023-11-04 13:05:38', '1', '2023-11-04 13:07:16', b'0');
INSERT INTO `platform_dict_data` VALUES (1441, 1, '上架', '1', 'crm_product_status', 0, 'success', '', '', '1', '2023-10-30 21:49:34', '1', '2023-10-30 21:49:34', b'0');
INSERT INTO `platform_dict_data` VALUES (1442, 0, '下架', '0', 'crm_product_status', 0, 'success', '', '', '1', '2023-10-30 21:49:13', '1', '2023-10-30 21:49:13', b'0');
INSERT INTO `platform_dict_data` VALUES (1443, 15, '子表', '15', 'infra_codegen_template_type', 0, 'default', '', '', '1', '2023-11-13 23:06:16', '1', '2023-11-13 23:06:16', b'0');
INSERT INTO `platform_dict_data` VALUES (1444, 10, '主表（标准模式）', '10', 'infra_codegen_template_type', 0, 'default', '', '', '1', '2023-11-14 12:32:49', '1', '2023-11-14 12:32:49', b'0');
INSERT INTO `platform_dict_data` VALUES (1445, 11, '主表（ERP 模式）', '11', 'infra_codegen_template_type', 0, 'default', '', '', '1', '2023-11-14 12:33:05', '1', '2023-11-14 12:33:05', b'0');
INSERT INTO `platform_dict_data` VALUES (1446, 12, '主表（内嵌模式）', '12', 'infra_codegen_template_type', 0, '', '', '', '1', '2023-11-14 12:33:31', '1', '2023-11-14 12:33:31', b'0');
INSERT INTO `platform_dict_data` VALUES (1447, 1, '负责人', '1', 'crm_permission_level', 0, 'default', '', '', '1', '2023-11-30 09:53:12', '1', '2023-11-30 09:53:12', b'0');
INSERT INTO `platform_dict_data` VALUES (1448, 2, '只读', '2', 'crm_permission_level', 0, '', '', '', '1', '2023-11-30 09:53:29', '1', '2023-11-30 09:53:29', b'0');
INSERT INTO `platform_dict_data` VALUES (1449, 3, '读写', '3', 'crm_permission_level', 0, '', '', '', '1', '2023-11-30 09:53:36', '1', '2023-11-30 09:53:36', b'0');
INSERT INTO `platform_dict_data` VALUES (1450, 0, '未提交', '0', 'crm_audit_status', 0, '', '', '', '1', '2023-11-30 18:56:59', '1', '2023-11-30 18:56:59', b'0');
INSERT INTO `platform_dict_data` VALUES (1451, 10, '审批中', '10', 'crm_audit_status', 0, '', '', '', '1', '2023-11-30 18:57:10', '1', '2023-11-30 18:57:10', b'0');
INSERT INTO `platform_dict_data` VALUES (1452, 20, '审核通过', '20', 'crm_audit_status', 0, '', '', '', '1', '2023-11-30 18:57:24', '1', '2023-11-30 18:57:24', b'0');
INSERT INTO `platform_dict_data` VALUES (1453, 30, '审核不通过', '30', 'crm_audit_status', 0, '', '', '', '1', '2023-11-30 18:57:32', '1', '2023-11-30 18:57:32', b'0');
INSERT INTO `platform_dict_data` VALUES (1454, 40, '已取消', '40', 'crm_audit_status', 0, '', '', '', '1', '2023-11-30 18:57:42', '1', '2023-11-30 18:57:42', b'0');
INSERT INTO `platform_dict_data` VALUES (1478, 4, '钱包余额', '4', 'pay_transfer_type', 0, 'info', '', '', '1', '2023-10-28 16:28:37', '1', '2023-10-28 16:28:37', b'0');
INSERT INTO `platform_dict_data` VALUES (1479, 3, '银行卡', '3', 'pay_transfer_type', 0, 'default', '', '', '1', '2023-10-28 16:28:21', '1', '2023-10-28 16:28:21', b'0');
INSERT INTO `platform_dict_data` VALUES (1480, 2, '微信余额', '2', 'pay_transfer_type', 0, 'info', '', '', '1', '2023-10-28 16:28:07', '1', '2023-10-28 16:28:07', b'0');
INSERT INTO `platform_dict_data` VALUES (1481, 1, '支付宝余额', '1', 'pay_transfer_type', 0, 'default', '', '', '1', '2023-10-28 16:27:44', '1', '2023-10-28 16:27:44', b'0');
INSERT INTO `platform_dict_data` VALUES (1482, 4, '转账失败', '30', 'pay_transfer_status', 0, 'warning', '', '', '1', '2023-10-28 16:24:16', '1', '2023-10-28 16:24:16', b'0');
INSERT INTO `platform_dict_data` VALUES (1483, 3, '转账成功', '20', 'pay_transfer_status', 0, 'success', '', '', '1', '2023-10-28 16:23:50', '1', '2023-10-28 16:23:50', b'0');
INSERT INTO `platform_dict_data` VALUES (1484, 2, '转账进行中', '10', 'pay_transfer_status', 0, 'info', '', '', '1', '2023-10-28 16:23:12', '1', '2023-10-28 16:23:12', b'0');
INSERT INTO `platform_dict_data` VALUES (1485, 1, '等待转账', '0', 'pay_transfer_status', 0, 'default', '', '', '1', '2023-10-28 16:21:43', '1', '2023-10-28 16:23:22', b'0');
INSERT INTO `platform_dict_data` VALUES (504171598528581, 0, '普通菜单', '0', 'tenant_menu_dimension', 0, 'primary', '', '', '1', '2024-01-14 17:39:31', '1', '2024-01-14 17:39:31', b'0');
INSERT INTO `platform_dict_data` VALUES (504171769614405, 0, '应用菜单', '1', 'tenant_menu_dimension', 0, 'default', '', '', '1', '2024-01-14 17:40:13', '1', '2024-01-14 17:40:13', b'0');
INSERT INTO `platform_dict_data` VALUES (504172405145669, 0, 'web端', '0', 'plug_type', 0, '', '', '', '1', '2024-01-14 17:42:48', '1', '2024-01-14 17:42:48', b'0');
INSERT INTO `platform_dict_data` VALUES (504173096546373, 0, '待审核', '0', 'plug_order_status', 0, 'default', '', '', '1', '2024-01-14 17:45:37', '1', '2024-01-14 17:45:37', b'0');
INSERT INTO `platform_dict_data` VALUES (504173210660933, 0, '通过', '1', 'plug_order_status', 0, 'success', '', '', '1', '2024-01-14 17:46:05', '1', '2024-01-14 17:46:05', b'0');
INSERT INTO `platform_dict_data` VALUES (504173346943045, 0, '不通过', '2', 'plug_order_status', 0, 'warning', '', '', '1', '2024-01-14 17:46:38', '1', '2024-01-14 17:46:38', b'0');
INSERT INTO `platform_dict_data` VALUES (504173471572037, 0, '拒绝审核', '3', 'plug_order_status', 0, 'danger', '', '', '1', '2024-01-14 17:47:08', '1', '2024-01-14 17:47:08', b'0');
INSERT INTO `platform_dict_data` VALUES (1764304958750314498, 0, '平台管理员', '0', 'user_type', 0, '', '', '', '1', '2024-03-03 23:00:56', '1', '2024-03-03 23:00:56', b'0');

-- ----------------------------
-- Table structure for platform_dict_type
-- ----------------------------
DROP TABLE IF EXISTS `platform_dict_type`;
CREATE TABLE `platform_dict_type`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '字典主键',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '字典名称',
  `type` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '字典类型',
  `status` tinyint NOT NULL DEFAULT 0 COMMENT '状态（0正常 1停用）',
  `remark` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '备注',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `deleted_time` datetime NULL DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `dict_type`(`type` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 504172890992710 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '字典类型表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of platform_dict_type
-- ----------------------------
INSERT INTO `platform_dict_type` VALUES (1, '用户性别', 'system_user_sex', 0, NULL, 'admin', '2021-01-05 17:03:48', '1', '2022-05-16 20:29:32', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (6, '参数类型', 'infra_config_type', 0, NULL, 'admin', '2021-01-05 17:03:48', '', '2022-02-01 16:36:54', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (7, '通知类型', 'system_notice_type', 0, NULL, 'admin', '2021-01-05 17:03:48', '', '2022-02-01 16:35:26', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (9, '操作类型', 'system_operate_type', 0, NULL, 'admin', '2021-01-05 17:03:48', '1', '2022-02-16 09:32:21', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (10, '系统状态', 'common_status', 0, NULL, 'admin', '2021-01-05 17:03:48', '', '2022-02-01 16:21:28', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (11, 'Boolean 是否类型', 'infra_boolean_string', 0, 'boolean 转是否', '', '2021-01-19 03:20:08', '', '2022-02-01 16:37:10', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (104, '登陆结果', 'system_login_result', 0, '登陆结果', '', '2021-01-18 06:17:11', '', '2022-02-01 16:36:00', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (106, '代码生成模板类型', 'infra_codegen_template_type', 0, NULL, '', '2021-02-05 07:08:06', '1', '2022-05-16 20:26:50', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (107, '定时任务状态', 'infra_job_status', 0, NULL, '', '2021-02-07 07:44:16', '', '2022-02-01 16:51:11', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (108, '定时任务日志状态', 'infra_job_log_status', 0, NULL, '', '2021-02-08 10:03:51', '', '2022-02-01 16:50:43', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (109, '用户类型', 'user_type', 0, NULL, '', '2021-02-26 00:15:51', '', '2021-02-26 00:15:51', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (110, 'API 异常数据的处理状态', 'infra_api_error_log_process_status', 0, NULL, '', '2021-02-26 07:07:01', '', '2022-02-01 16:50:53', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (111, '短信渠道编码', 'system_sms_channel_code', 0, NULL, '1', '2021-04-05 01:04:50', '1', '2022-02-16 02:09:08', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (112, '短信模板的类型', 'system_sms_template_type', 0, NULL, '1', '2021-04-05 21:50:43', '1', '2022-02-01 16:35:06', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (113, '短信发送状态', 'system_sms_send_status', 0, NULL, '1', '2021-04-11 20:18:03', '1', '2022-02-01 16:35:09', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (114, '短信接收状态', 'system_sms_receive_status', 0, NULL, '1', '2021-04-11 20:27:14', '1', '2022-02-01 16:35:14', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (115, '错误码的类型', 'system_error_code_type', 0, NULL, '1', '2021-04-21 00:06:30', '1', '2022-02-01 16:36:49', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (116, '登陆日志的类型', 'system_login_type', 0, '登陆日志的类型', '1', '2021-10-06 00:50:46', '1', '2022-02-01 16:35:56', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (117, 'OA 请假类型', 'bpm_oa_leave_type', 0, NULL, '1', '2021-09-21 22:34:33', '1', '2022-01-22 10:41:37', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (130, '支付渠道编码类型', 'pay_channel_code', 0, '支付渠道的编码', '1', '2021-12-03 10:35:08', '1', '2023-07-10 10:11:39', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (131, '支付回调状态', 'pay_notify_status', 0, '支付回调状态（包括退款回调）', '1', '2021-12-03 10:53:29', '1', '2023-07-19 18:09:43', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (132, '支付订单状态', 'pay_order_status', 0, '支付订单状态', '1', '2021-12-03 11:17:50', '1', '2021-12-03 11:17:50', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (134, '退款订单状态', 'pay_refund_status', 0, '退款订单状态', '1', '2021-12-10 16:42:50', '1', '2023-07-19 10:13:17', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (138, '流程分类', 'bpm_model_category', 0, '流程分类', '1', '2022-01-02 08:40:45', '1', '2022-01-02 08:40:45', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (139, '流程实例的状态', 'bpm_process_instance_status', 0, '流程实例的状态', '1', '2022-01-07 23:46:42', '1', '2022-01-07 23:46:42', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (140, '流程实例的结果', 'bpm_process_instance_result', 0, '流程实例的结果', '1', '2022-01-07 23:48:10', '1', '2022-01-07 23:48:10', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (141, '流程的表单类型', 'bpm_model_form_type', 0, '流程的表单类型', '103', '2022-01-11 23:50:45', '103', '2022-01-11 23:50:45', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (142, '任务分配规则的类型', 'bpm_task_assign_rule_type', 0, '任务分配规则的类型', '103', '2022-01-12 23:21:04', '103', '2022-01-12 15:46:10', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (143, '任务分配自定义脚本', 'bpm_task_assign_script', 0, '任务分配自定义脚本', '103', '2022-01-15 00:10:35', '103', '2022-01-15 00:10:35', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (144, '代码生成的场景枚举', 'infra_codegen_scene', 0, '代码生成的场景枚举', '1', '2022-02-02 13:14:45', '1', '2022-03-10 16:33:46', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (145, '角色类型', 'system_role_type', 0, '角色类型', '1', '2022-02-16 13:01:46', '1', '2022-02-16 13:01:46', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (146, '文件存储器', 'infra_file_storage', 0, '文件存储器', '1', '2022-03-15 00:24:38', '1', '2022-03-15 00:24:38', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (147, 'OAuth 2.0 授权类型', 'system_oauth2_grant_type', 0, 'OAuth 2.0 授权类型（模式）', '1', '2022-05-12 00:20:52', '1', '2022-05-11 16:25:49', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (149, '商品 SPU 状态', 'product_spu_status', 0, '商品 SPU 状态', '1', '2022-10-24 21:19:04', '1', '2022-10-24 21:19:08', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (150, '优惠类型', 'promotion_discount_type', 0, '优惠类型', '1', '2022-11-01 12:46:06', '1', '2022-11-01 12:46:06', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (151, '优惠劵模板的有限期类型', 'promotion_coupon_template_validity_type', 0, '优惠劵模板的有限期类型', '1', '2022-11-02 00:06:20', '1', '2022-11-04 00:08:26', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (152, '营销的商品范围', 'promotion_product_scope', 0, '营销的商品范围', '1', '2022-11-02 00:28:01', '1', '2022-11-02 00:28:01', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (153, '优惠劵的状态', 'promotion_coupon_status', 0, '优惠劵的状态', '1', '2022-11-04 00:14:49', '1', '2022-11-04 00:14:49', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (154, '优惠劵的领取方式', 'promotion_coupon_take_type', 0, '优惠劵的领取方式', '1', '2022-11-04 19:12:27', '1', '2022-11-04 19:12:27', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (155, '促销活动的状态', 'promotion_activity_status', 0, '促销活动的状态', '1', '2022-11-04 22:54:23', '1', '2022-11-04 22:54:23', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (156, '营销的条件类型', 'promotion_condition_type', 0, '营销的条件类型', '1', '2022-11-04 22:59:23', '1', '2022-11-04 22:59:23', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (157, '交易售后状态', 'trade_after_sale_status', 0, '交易售后状态', '1', '2022-11-19 20:52:56', '1', '2022-11-19 20:52:56', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (158, '交易售后的类型', 'trade_after_sale_type', 0, '交易售后的类型', '1', '2022-11-19 21:04:09', '1', '2022-11-19 21:04:09', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (159, '交易售后的方式', 'trade_after_sale_way', 0, '交易售后的方式', '1', '2022-11-19 21:39:04', '1', '2022-11-19 21:39:04', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (160, '终端', 'terminal', 0, '终端', '1', '2022-12-10 10:50:50', '1', '2022-12-10 10:53:11', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (161, '交易订单的类型', 'trade_order_type', 0, '交易订单的类型', '1', '2022-12-10 16:33:54', '1', '2022-12-10 16:33:54', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (162, '交易订单的状态', 'trade_order_status', 0, '交易订单的状态', '1', '2022-12-10 16:48:44', '1', '2022-12-10 16:48:44', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (163, '交易订单项的售后状态', 'trade_order_item_after_sale_status', 0, '交易订单项的售后状态', '1', '2022-12-10 20:58:08', '1', '2022-12-10 20:58:08', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (164, '公众号自动回复的请求关键字匹配模式', 'mp_auto_reply_request_match', 0, '公众号自动回复的请求关键字匹配模式', '1', '2023-01-16 23:29:56', '1', '2023-01-16 23:29:56', b'0', '1970-01-01 00:00:00');
INSERT INTO `platform_dict_type` VALUES (165, '公众号的消息类型', 'mp_message_type', 0, '公众号的消息类型', '1', '2023-01-17 22:17:09', '1', '2023-01-17 22:17:09', b'0', '1970-01-01 00:00:00');
INSERT INTO `platform_dict_type` VALUES (166, '邮件发送状态', 'system_mail_send_status', 0, '邮件发送状态', '1', '2023-01-26 09:53:13', '1', '2023-01-26 09:53:13', b'0', '1970-01-01 00:00:00');
INSERT INTO `platform_dict_type` VALUES (167, '站内信模版的类型', 'system_notify_template_type', 0, '站内信模版的类型', '1', '2023-01-28 10:35:10', '1', '2023-01-28 10:35:10', b'0', '1970-01-01 00:00:00');
INSERT INTO `platform_dict_type` VALUES (168, '代码生成的前端类型', 'infra_codegen_front_type', 0, '', '1', '2023-04-12 23:57:52', '1', '2023-04-12 23:57:52', b'0', '1970-01-01 00:00:00');
INSERT INTO `platform_dict_type` VALUES (169, '商品的单位', 'product_unit', 0, '商品的单位', '1', '2023-05-24 21:23:59', '1', '2023-05-24 21:23:59', b'0', '1970-01-01 00:00:00');
INSERT INTO `platform_dict_type` VALUES (170, '快递计费方式', 'trade_delivery_express_charge_mode', 0, '用于商城交易模块配送管理', '1', '2023-05-21 22:45:03', '1', '2023-05-21 22:45:03', b'0', '1970-01-01 00:00:00');
INSERT INTO `platform_dict_type` VALUES (171, '积分业务类型', 'member_point_biz_type', 0, '', '1', '2023-06-10 12:15:00', '1', '2023-06-28 13:48:20', b'0', '1970-01-01 00:00:00');
INSERT INTO `platform_dict_type` VALUES (173, '支付通知类型', 'pay_notify_type', 0, NULL, '1', '2023-07-20 12:23:03', '1', '2023-07-20 12:23:03', b'0', '1970-01-01 00:00:00');
INSERT INTO `platform_dict_type` VALUES (174, '会员经验业务类型', 'member_experience_biz_type', 0, NULL, '', '2023-08-22 12:41:01', '', '2023-08-22 12:41:01', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (175, '交易配送类型', 'trade_delivery_type', 0, '', '1', '2023-08-23 00:03:14', '1', '2023-08-23 00:03:14', b'0', '1970-01-01 00:00:00');
INSERT INTO `platform_dict_type` VALUES (176, '分佣模式', 'brokerage_enabled_condition', 0, NULL, '', '2023-09-28 02:46:05', '', '2023-09-28 02:46:05', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (177, '分销关系绑定模式', 'brokerage_bind_mode', 0, NULL, '', '2023-09-28 02:46:05', '', '2023-09-28 02:46:05', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (178, '佣金提现类型', 'brokerage_withdraw_type', 0, NULL, '', '2023-09-28 02:46:05', '', '2023-09-28 02:46:05', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (179, '佣金记录业务类型', 'brokerage_record_biz_type', 0, NULL, '', '2023-09-28 02:46:05', '', '2023-09-28 02:46:05', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (180, '佣金记录状态', 'brokerage_record_status', 0, NULL, '', '2023-09-28 02:46:05', '', '2023-09-28 02:46:05', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (181, '佣金提现状态', 'brokerage_withdraw_status', 0, NULL, '', '2023-09-28 02:46:05', '', '2023-09-28 02:46:05', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (182, '佣金提现银行', 'brokerage_bank_name', 0, NULL, '', '2023-09-28 02:46:05', '', '2023-09-28 02:46:05', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (183, '砍价记录的状态', 'promotion_bargain_record_status', 0, '', '1', '2023-10-05 10:41:08', '1', '2023-10-05 10:41:08', b'0', '1970-01-01 00:00:00');
INSERT INTO `platform_dict_type` VALUES (184, '拼团记录的状态', 'promotion_combination_record_status', 0, '', '1', '2023-10-08 07:24:25', '1', '2023-10-08 07:24:25', b'0', '1970-01-01 00:00:00');
INSERT INTO `platform_dict_type` VALUES (186, '客户所属行业', 'crm_customer_industry', 0, 'CRM 客户所属行业', '1', '2023-10-28 22:57:07', '1', '2023-10-28 15:11:16', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (187, '客户等级', 'crm_customer_level', 0, 'CRM 客户等级', '1', '2023-10-28 22:59:12', '1', '2023-10-28 15:11:16', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (188, '客户来源', 'crm_customer_source', 0, 'CRM 客户来源', '1', '2023-10-28 23:00:34', '1', '2023-10-28 15:11:16', b'0', NULL);
INSERT INTO `platform_dict_type` VALUES (600, 'Banner 位置', 'promotion_banner_position', 0, '', '1', '2023-10-08 07:24:25', '1', '2023-11-04 13:04:02', b'0', '1970-01-01 00:00:00');
INSERT INTO `platform_dict_type` VALUES (601, '社交类型', 'system_social_type', 0, '', '1', '2023-11-04 13:03:54', '1', '2023-11-04 13:03:54', b'0', '1970-01-01 00:00:00');
INSERT INTO `platform_dict_type` VALUES (604, '产品状态', 'crm_product_status', 0, '', '1', '2023-10-30 21:47:59', '1', '2023-10-30 21:48:45', b'0', '1970-01-01 00:00:00');
INSERT INTO `platform_dict_type` VALUES (605, 'CRM 数据权限的级别', 'crm_permission_level', 0, '', '1', '2023-11-30 09:51:59', '1', '2023-11-30 09:51:59', b'0', '1970-01-01 00:00:00');
INSERT INTO `platform_dict_type` VALUES (606, 'CRM 审批状态', 'crm_audit_status', 0, '', '1', '2023-11-30 18:56:23', '1', '2023-11-30 18:56:23', b'0', '1970-01-01 00:00:00');
INSERT INTO `platform_dict_type` VALUES (609, '支付转账类型', 'pay_transfer_type', 0, '', '1', '2023-10-28 16:27:18', '1', '2023-10-28 16:27:18', b'0', '1970-01-01 00:00:00');
INSERT INTO `platform_dict_type` VALUES (610, '转账订单状态', 'pay_transfer_status', 0, '', '1', '2023-10-28 16:18:32', '1', '2023-10-28 16:18:32', b'0', '1970-01-01 00:00:00');
INSERT INTO `platform_dict_type` VALUES (504171413491781, '租户菜单维度', 'tenant_menu_dimension', 0, '', '1', '2024-01-14 17:38:46', '1', '2024-01-14 17:38:46', b'0', '1970-01-01 00:00:00');
INSERT INTO `platform_dict_type` VALUES (504172157050949, '应用类型', 'plug_type', 0, '', '1', '2024-01-14 17:41:48', '1', '2024-01-14 17:41:48', b'0', '1970-01-01 00:00:00');
INSERT INTO `platform_dict_type` VALUES (504172890992709, '应用订单状态', 'plug_order_status', 0, '', '1', '2024-01-14 17:44:47', '1', '2024-01-14 17:44:47', b'0', '1970-01-01 00:00:00');

-- ----------------------------
-- Table structure for platform_error_code
-- ----------------------------
DROP TABLE IF EXISTS `platform_error_code`;
CREATE TABLE `platform_error_code`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '错误码编号',
  `type` tinyint NOT NULL DEFAULT 0 COMMENT '错误码类型',
  `application_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '应用名',
  `code` int NOT NULL DEFAULT 0 COMMENT '错误码编码',
  `message` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '错误码错误提示',
  `memo` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '备注',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1825903265452462083 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '错误码表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of platform_error_code
-- ----------------------------
INSERT INTO `platform_error_code` VALUES (1825903224981622786, 1, 'shengyu-server', 1001000001, '参数配置不存在', '', NULL, '2024-08-20 22:30:27', NULL, '2024-08-20 22:30:27', b'0');
INSERT INTO `platform_error_code` VALUES (1825903225279418369, 1, 'shengyu-server', 1001000002, '参数配置 key 重复', '', NULL, '2024-08-20 22:30:27', NULL, '2024-08-20 22:30:27', b'0');
INSERT INTO `platform_error_code` VALUES (1825903225463967745, 1, 'shengyu-server', 1001000003, '不能删除类型为系统内置的参数配置', '', NULL, '2024-08-20 22:30:27', NULL, '2024-08-20 22:30:27', b'0');
INSERT INTO `platform_error_code` VALUES (1825903225627545601, 1, 'shengyu-server', 1001000004, '获取参数配置失败，原因：不允许获取不可见配置', '', NULL, '2024-08-20 22:30:27', NULL, '2024-08-20 22:30:27', b'0');
INSERT INTO `platform_error_code` VALUES (1825903225967284226, 1, 'shengyu-server', 1001001000, '插件应用不存在', '', NULL, '2024-08-20 22:30:27', NULL, '2024-08-20 23:25:16', b'0');
INSERT INTO `platform_error_code` VALUES (1825903226181193729, 1, 'shengyu-server', 1001001001, '插件订单不存在', '', NULL, '2024-08-20 22:30:27', NULL, '2024-08-20 23:25:16', b'0');
INSERT INTO `platform_error_code` VALUES (1825903226382520322, 1, 'shengyu-server', 1001001002, '订单项不存在', '', NULL, '2024-08-20 22:30:27', NULL, '2024-08-20 23:25:16', b'0');
INSERT INTO `platform_error_code` VALUES (1825903226562875394, 1, 'shengyu-server', 1001001003, '租户应用不存在', '', NULL, '2024-08-20 22:30:28', NULL, '2024-08-20 23:25:16', b'0');
INSERT INTO `platform_error_code` VALUES (1825903226843893761, 1, 'shengyu-server', 1001001004, '插件应用已下架或已禁用，无法下单', '', NULL, '2024-08-20 22:30:28', NULL, '2024-08-20 23:25:16', b'0');
INSERT INTO `platform_error_code` VALUES (1825903227049414657, 1, 'shengyu-server', 1001001005, '租户应用中已存在该插件', '', NULL, '2024-08-20 22:30:28', NULL, '2024-08-20 23:25:16', b'0');
INSERT INTO `platform_error_code` VALUES (1825903227246546946, 1, 'shengyu-server', 1001002000, 'API 错误日志不存在', '', NULL, '2024-08-20 22:30:28', NULL, '2024-08-20 22:30:28', b'0');
INSERT INTO `platform_error_code` VALUES (1825903227422707713, 1, 'shengyu-server', 1001002001, 'API 错误日志已处理', '', NULL, '2024-08-20 22:30:28', NULL, '2024-08-20 22:30:28', b'0');
INSERT INTO `platform_error_code` VALUES (1825903227603062785, 1, 'shengyu-server', 1001003000, '文件路径已存在', '', NULL, '2024-08-20 22:30:28', NULL, '2024-08-20 22:30:28', b'0');
INSERT INTO `platform_error_code` VALUES (1825903227779223553, 1, 'shengyu-server', 1001003001, '文件不存在', '', NULL, '2024-08-20 22:30:28', NULL, '2024-08-20 22:30:28', b'0');
INSERT INTO `platform_error_code` VALUES (1825903227959578626, 1, 'shengyu-server', 1001003002, '文件为空', '', NULL, '2024-08-20 22:30:28', NULL, '2024-08-20 22:30:28', b'0');
INSERT INTO `platform_error_code` VALUES (1825903228198653954, 1, 'shengyu-server', 1003001000, '表定义已经存在', '', NULL, '2024-08-20 22:30:28', NULL, '2024-08-20 22:30:28', b'0');
INSERT INTO `platform_error_code` VALUES (1825903228550975489, 1, 'shengyu-server', 1003001001, '导入的表不存在', '', NULL, '2024-08-20 22:30:28', NULL, '2024-08-20 22:30:28', b'0');
INSERT INTO `platform_error_code` VALUES (1825903229020737538, 1, 'shengyu-server', 1003001002, '导入的字段不存在', '', NULL, '2024-08-20 22:30:28', NULL, '2024-08-20 22:30:28', b'0');
INSERT INTO `platform_error_code` VALUES (1825903229473722370, 1, 'shengyu-server', 1003001004, '表定义不存在', '', NULL, '2024-08-20 22:30:28', NULL, '2024-08-20 22:30:28', b'0');
INSERT INTO `platform_error_code` VALUES (1825903229737963522, 1, 'shengyu-server', 1003001005, '字段义不存在', '', NULL, '2024-08-20 22:30:28', NULL, '2024-08-20 22:30:28', b'0');
INSERT INTO `platform_error_code` VALUES (1825903230119645185, 1, 'shengyu-server', 1003001006, '同步的字段不存在', '', NULL, '2024-08-20 22:30:28', NULL, '2024-08-20 22:30:28', b'0');
INSERT INTO `platform_error_code` VALUES (1825903230329360385, 1, 'shengyu-server', 1003001007, '同步失败，不存在改变', '', NULL, '2024-08-20 22:30:28', NULL, '2024-08-20 22:30:28', b'0');
INSERT INTO `platform_error_code` VALUES (1825903230572630017, 1, 'shengyu-server', 1003001008, '数据库的表注释未填写', '', NULL, '2024-08-20 22:30:28', NULL, '2024-08-20 22:30:28', b'0');
INSERT INTO `platform_error_code` VALUES (1825903230920757250, 1, 'shengyu-server', 1003001009, '数据库的表字段({})注释未填写', '', NULL, '2024-08-20 22:30:29', NULL, '2024-08-20 22:30:29', b'0');
INSERT INTO `platform_error_code` VALUES (1825903231126278146, 1, 'shengyu-server', 1003001010, '主表(id={})定义不存在，请检查', '', NULL, '2024-08-20 22:30:29', NULL, '2024-08-20 22:30:29', b'0');
INSERT INTO `platform_error_code` VALUES (1825903231319216130, 1, 'shengyu-server', 1003001011, '子表的字段(id={})不存在，请检查', '', NULL, '2024-08-20 22:30:29', NULL, '2024-08-20 22:30:29', b'0');
INSERT INTO `platform_error_code` VALUES (1825903231507959810, 1, 'shengyu-server', 1003001012, '主表生成代码失败，原因：它没有子表', '', NULL, '2024-08-20 22:30:29', NULL, '2024-08-20 22:30:29', b'0');
INSERT INTO `platform_error_code` VALUES (1825903231675731969, 1, 'shengyu-server', 1003001013, '主表生成代码失败，原因：它的子表({})没有字段', '', NULL, '2024-08-20 22:30:29', NULL, '2024-08-20 22:30:29', b'0');
INSERT INTO `platform_error_code` VALUES (1825903231835115521, 1, 'shengyu-server', 1001006000, '文件配置不存在', '', NULL, '2024-08-20 22:30:29', NULL, '2024-08-20 22:30:29', b'0');
INSERT INTO `platform_error_code` VALUES (1825903231998693377, 1, 'shengyu-server', 1001006001, '该文件配置不允许删除，原因：它是主配置，删除会导致无法上传文件', '', NULL, '2024-08-20 22:30:29', NULL, '2024-08-20 22:30:29', b'0');
INSERT INTO `platform_error_code` VALUES (1825903232174854146, 1, 'shengyu-server', 1001007000, '数据源配置不存在', '', NULL, '2024-08-20 22:30:29', NULL, '2024-08-20 22:30:29', b'0');
INSERT INTO `platform_error_code` VALUES (1825903232317460482, 1, 'shengyu-server', 1001007001, '数据源配置不正确，无法进行连接', '', NULL, '2024-08-20 22:30:29', NULL, '2024-08-20 22:30:29', b'0');
INSERT INTO `platform_error_code` VALUES (1825903232485232642, 1, 'shengyu-server', 1001107000, '学生不存在', '', NULL, '2024-08-20 22:30:29', NULL, '2024-08-20 22:30:29', b'0');
INSERT INTO `platform_error_code` VALUES (1825903232682364930, 1, 'shengyu-server', 1001201000, '示例联系人不存在', '', NULL, '2024-08-20 22:30:29', NULL, '2024-08-20 22:30:29', b'0');
INSERT INTO `platform_error_code` VALUES (1825903232837554177, 1, 'shengyu-server', 1001201001, '示例分类不存在', '', NULL, '2024-08-20 22:30:29', NULL, '2024-08-20 22:30:29', b'0');
INSERT INTO `platform_error_code` VALUES (1825903233030492161, 1, 'shengyu-server', 1001201002, '存在存在子示例分类，无法删除', '', NULL, '2024-08-20 22:30:29', NULL, '2024-08-20 22:30:29', b'0');
INSERT INTO `platform_error_code` VALUES (1825903233189875713, 1, 'shengyu-server', 1001201003, '父级示例分类不存在', '', NULL, '2024-08-20 22:30:29', NULL, '2024-08-20 22:30:29', b'0');
INSERT INTO `platform_error_code` VALUES (1825903233428951042, 1, 'shengyu-server', 1001201004, '不能设置自己为父示例分类', '', NULL, '2024-08-20 22:30:29', NULL, '2024-08-20 22:30:29', b'0');
INSERT INTO `platform_error_code` VALUES (1825903233584140290, 1, 'shengyu-server', 1001201005, '已经存在该名字的示例分类', '', NULL, '2024-08-20 22:30:29', NULL, '2024-08-20 22:30:29', b'0');
INSERT INTO `platform_error_code` VALUES (1825903233764495361, 1, 'shengyu-server', 1001201006, '不能设置自己的子示例分类为父示例分类', '', NULL, '2024-08-20 22:30:29', NULL, '2024-08-20 22:30:29', b'0');
INSERT INTO `platform_error_code` VALUES (1825903234011959298, 1, 'shengyu-server', 1001201007, '学生不存在', '', NULL, '2024-08-20 22:30:29', NULL, '2024-08-20 22:30:29', b'0');
INSERT INTO `platform_error_code` VALUES (1825903234599161857, 1, 'shengyu-server', 1001201008, '学生班级不存在', '', NULL, '2024-08-20 22:30:29', NULL, '2024-08-20 22:30:29', b'0');
INSERT INTO `platform_error_code` VALUES (1825903234754351106, 1, 'shengyu-server', 1001201009, '学生班级已存在', '', NULL, '2024-08-20 22:30:29', NULL, '2024-08-20 22:30:29', b'0');
INSERT INTO `platform_error_code` VALUES (1825903235052146690, 1, 'shengyu-server', 1001000000, '租户正在使用该菜单，请给租户重新设置没有选择该菜单的套餐后再尝试删除', '', NULL, '2024-08-20 22:30:30', NULL, '2024-08-20 22:30:30', b'0');
INSERT INTO `platform_error_code` VALUES (1825903235215724545, 1, 'shengyu-server', 1001001000, '插件应用不存在', '', NULL, '2024-08-20 22:30:30', NULL, '2024-08-20 22:30:30', b'0');
INSERT INTO `platform_error_code` VALUES (1825903235404468225, 1, 'shengyu-server', 1001001001, '插件订单不存在', '', NULL, '2024-08-20 22:30:30', NULL, '2024-08-20 22:30:30', b'0');
INSERT INTO `platform_error_code` VALUES (1825903235584823297, 1, 'shengyu-server', 1001001002, '订单项不存在', '', NULL, '2024-08-20 22:30:30', NULL, '2024-08-20 22:30:30', b'0');
INSERT INTO `platform_error_code` VALUES (1825903235752595458, 1, 'shengyu-server', 1001001003, '租户应用不存在', '', NULL, '2024-08-20 22:30:30', NULL, '2024-08-20 22:30:30', b'0');
INSERT INTO `platform_error_code` VALUES (1825903235907784705, 1, 'shengyu-server', 1001001004, '插件应用已下架或已禁用，无法下单', '', NULL, '2024-08-20 22:30:30', NULL, '2024-08-20 22:30:30', b'0');
INSERT INTO `platform_error_code` VALUES (1825903236071362561, 1, 'shengyu-server', 1001001005, '租户应用中已存在该插件', '', NULL, '2024-08-20 22:30:30', NULL, '2024-08-20 22:30:30', b'0');
INSERT INTO `platform_error_code` VALUES (1825903236247523330, 1, 'shengyu-server', 1001001006, '当前租户没有任何应用插件授权', '', NULL, '2024-08-20 22:30:30', NULL, '2024-08-20 22:30:30', b'0');
INSERT INTO `platform_error_code` VALUES (1825903236641787906, 1, 'shengyu-server', 1001001007, '当前租户需要获取：{} 等应用插件授权才能使用该功能', '', NULL, '2024-08-20 22:30:30', NULL, '2024-08-20 22:30:30', b'0');
INSERT INTO `platform_error_code` VALUES (1825903236876668930, 1, 'shengyu-server', 1001001008, '当前系统管理员下架了该：{} 插件应用', '', NULL, '2024-08-20 22:30:30', NULL, '2024-08-20 22:30:30', b'0');
INSERT INTO `platform_error_code` VALUES (1825903237044441090, 1, 'shengyu-server', 1001001009, '该：{} 插件应用已被平台运营方停用', '', NULL, '2024-08-20 22:30:30', NULL, '2024-08-20 22:30:30', b'0');
INSERT INTO `platform_error_code` VALUES (1825903237195436034, 1, 'shengyu-server', 1001001010, '添加插件应用菜单时,所属应用插件条码必传', '', NULL, '2024-08-20 22:30:30', NULL, '2024-08-20 22:30:30', b'0');
INSERT INTO `platform_error_code` VALUES (1825903237375791106, 1, 'shengyu-server', 1001001011, '已存在该模块条码插件应用', '', NULL, '2024-08-20 22:30:30', NULL, '2024-08-20 22:30:30', b'0');
INSERT INTO `platform_error_code` VALUES (1825903237681975297, 1, 'shengyu-server', 1001001012, '该笔插件订单已完成审核，请勿重复操作', '', NULL, '2024-08-20 22:30:30', NULL, '2024-08-20 22:30:30', b'0');
INSERT INTO `platform_error_code` VALUES (1825903237832970242, 1, 'shengyu-server', 1001001013, '当前存在未审批通过或待审批的插件订单，不能下单', '', NULL, '2024-08-20 22:30:30', NULL, '2024-08-20 22:30:30', b'0');
INSERT INTO `platform_error_code` VALUES (1825903237979770882, 1, 'shengyu-server', 1001001014, '审核不通过的订单才能重新申请提交审核', '', NULL, '2024-08-20 22:30:30', NULL, '2024-08-20 22:30:30', b'0');
INSERT INTO `platform_error_code` VALUES (1825903238202068994, 1, 'shengyu-server', 1002000000, '登录失败，账号密码不正确', '', NULL, '2024-08-20 22:30:30', NULL, '2024-08-20 22:30:30', b'0');
INSERT INTO `platform_error_code` VALUES (1825903238361452545, 1, 'shengyu-server', 1002000001, '登录失败，账号被禁用', '', NULL, '2024-08-20 22:30:30', NULL, '2024-08-20 22:30:30', b'0');
INSERT INTO `platform_error_code` VALUES (1825903238541807618, 1, 'shengyu-server', 1002000004, '验证码不正确，原因：{}', '', NULL, '2024-08-20 22:30:30', NULL, '2024-08-20 22:30:30', b'0');
INSERT INTO `platform_error_code` VALUES (1825903238692802561, 1, 'shengyu-server', 1002000005, '未绑定账号，需要进行绑定', '', NULL, '2024-08-20 22:30:30', NULL, '2024-08-20 22:30:30', b'0');
INSERT INTO `platform_error_code` VALUES (1825903238843797505, 1, 'shengyu-server', 1002000006, 'Token 已经过期', '', NULL, '2024-08-20 22:30:30', NULL, '2024-08-20 22:30:30', b'0');
INSERT INTO `platform_error_code` VALUES (1825903239032541185, 1, 'shengyu-server', 1002000007, '手机号不存在', '', NULL, '2024-08-20 22:30:30', NULL, '2024-08-20 22:30:30', b'0');
INSERT INTO `platform_error_code` VALUES (1825903239447777282, 1, 'shengyu-server', 1002000008, '当前用户登录的租户数据异常或切换的租户用户已被禁用', '', NULL, '2024-08-20 22:30:31', NULL, '2024-08-20 22:30:31', b'0');
INSERT INTO `platform_error_code` VALUES (1825903239691046914, 1, 'shengyu-server', 1002000009, '切换租户失败，对应用户已被禁用或已删除', '', NULL, '2024-08-20 22:30:31', NULL, '2024-08-20 22:30:31', b'0');
INSERT INTO `platform_error_code` VALUES (1825903240429244418, 1, 'shengyu-server', 1002001000, '已经存在该名字的菜单', '', NULL, '2024-08-20 22:30:31', NULL, '2024-08-20 22:30:31', b'0');
INSERT INTO `platform_error_code` VALUES (1825903240756400129, 1, 'shengyu-server', 1002001001, '父菜单不存在', '', NULL, '2024-08-20 22:30:31', NULL, '2024-08-20 22:30:31', b'0');
INSERT INTO `platform_error_code` VALUES (1825903241553317890, 1, 'shengyu-server', 1002001002, '不能设置自己为父菜单', '', NULL, '2024-08-20 22:30:31', NULL, '2024-08-20 22:30:31', b'0');
INSERT INTO `platform_error_code` VALUES (1825903242010497026, 1, 'shengyu-server', 1002001003, '菜单不存在', '', NULL, '2024-08-20 22:30:31', NULL, '2024-08-20 22:30:31', b'0');
INSERT INTO `platform_error_code` VALUES (1825903242408955905, 1, 'shengyu-server', 1002001004, '存在子菜单，无法删除', '', NULL, '2024-08-20 22:30:31', NULL, '2024-08-20 22:30:31', b'0');
INSERT INTO `platform_error_code` VALUES (1825903242559950850, 1, 'shengyu-server', 1002001005, '父菜单的类型必须是目录或者菜单', '', NULL, '2024-08-20 22:30:31', NULL, '2024-08-20 22:30:31', b'0');
INSERT INTO `platform_error_code` VALUES (1825903242794831873, 1, 'shengyu-server', 1002002000, '角色不存在', '', NULL, '2024-08-20 22:30:31', NULL, '2024-08-20 22:30:31', b'0');
INSERT INTO `platform_error_code` VALUES (1825903242941632514, 1, 'shengyu-server', 1002002001, '已经存在名为【{}】的角色', '', NULL, '2024-08-20 22:30:31', NULL, '2024-08-20 22:30:31', b'0');
INSERT INTO `platform_error_code` VALUES (1825903243201679362, 1, 'shengyu-server', 1002002002, '已经存在编码为【{}】的角色', '', NULL, '2024-08-20 22:30:31', NULL, '2024-08-20 22:30:31', b'0');
INSERT INTO `platform_error_code` VALUES (1825903243382034433, 1, 'shengyu-server', 1002002003, '不能操作类型为系统内置的角色', '', NULL, '2024-08-20 22:30:32', NULL, '2024-08-20 22:30:32', b'0');
INSERT INTO `platform_error_code` VALUES (1825903243558195202, 1, 'shengyu-server', 1002002004, '名字为【{}】的角色已被禁用', '', NULL, '2024-08-20 22:30:32', NULL, '2024-08-20 22:30:32', b'0');
INSERT INTO `platform_error_code` VALUES (1825903243700801537, 1, 'shengyu-server', 1002002005, '编码【{}】不能使用', '', NULL, '2024-08-20 22:30:32', NULL, '2024-08-20 22:30:32', b'0');
INSERT INTO `platform_error_code` VALUES (1825903243847602178, 1, 'shengyu-server', 1002003000, '用户账号已经存在', '', NULL, '2024-08-20 22:30:32', NULL, '2024-08-20 22:30:32', b'0');
INSERT INTO `platform_error_code` VALUES (1825903243994402817, 1, 'shengyu-server', 1002003001, '手机号已经存在', '', NULL, '2024-08-20 22:30:32', NULL, '2024-08-20 22:30:32', b'0');
INSERT INTO `platform_error_code` VALUES (1825903244141203458, 1, 'shengyu-server', 1002003002, '邮箱已经存在', '', NULL, '2024-08-20 22:30:32', NULL, '2024-08-20 22:30:32', b'0');
INSERT INTO `platform_error_code` VALUES (1825903244292198402, 1, 'shengyu-server', 1002003003, '用户不存在', '', NULL, '2024-08-20 22:30:32', NULL, '2024-08-20 22:30:32', b'0');
INSERT INTO `platform_error_code` VALUES (1825903244438999041, 1, 'shengyu-server', 1002003004, '导入用户数据不能为空！', '', NULL, '2024-08-20 22:30:32', NULL, '2024-08-20 22:30:32', b'0');
INSERT INTO `platform_error_code` VALUES (1825903244669685761, 1, 'shengyu-server', 1002003005, '用户密码校验失败', '', NULL, '2024-08-20 22:30:32', NULL, '2024-08-20 22:30:32', b'0');
INSERT INTO `platform_error_code` VALUES (1825903244812292098, 1, 'shengyu-server', 1002003006, '名字为【{}】的用户已被禁用', '', NULL, '2024-08-20 22:30:32', NULL, '2024-08-20 22:30:32', b'0');
INSERT INTO `platform_error_code` VALUES (1825903245030395905, 1, 'shengyu-server', 1002003008, '创建用户失败，原因：超过租户最大租户配额({})！', '', NULL, '2024-08-20 22:30:32', NULL, '2024-08-20 22:30:32', b'0');
INSERT INTO `platform_error_code` VALUES (1825903245223333890, 1, 'shengyu-server', 1002003009, '不能操作超管用户！', '', NULL, '2024-08-20 22:30:32', NULL, '2024-08-20 22:30:32', b'0');
INSERT INTO `platform_error_code` VALUES (1825903245663735810, 1, 'shengyu-server', 1002003010, '添加用户时，邮箱账号和手机号不能都为空', '', NULL, '2024-08-20 22:30:32', NULL, '2024-08-20 22:30:32', b'0');
INSERT INTO `platform_error_code` VALUES (1825903245898616833, 1, 'shengyu-server', 1002003011, '邮箱账号对应体系用户不存在', '', NULL, '2024-08-20 22:30:32', NULL, '2024-08-20 22:30:32', b'0');
INSERT INTO `platform_error_code` VALUES (1825903246062194689, 1, 'shengyu-server', 1002003012, '手机号对应体系用户不存在', '', NULL, '2024-08-20 22:30:32', NULL, '2024-08-20 22:30:32', b'0');
INSERT INTO `platform_error_code` VALUES (1825903246221578241, 1, 'shengyu-server', 1002003013, '输入的邮箱账号或手机号已被昵称为【{}】员工绑定', '', NULL, '2024-08-20 22:30:32', NULL, '2024-08-20 22:30:32', b'0');
INSERT INTO `platform_error_code` VALUES (1825903246422904834, 1, 'shengyu-server', 1002004000, '已经存在该名字的部门', '', NULL, '2024-08-20 22:30:32', NULL, '2024-08-20 22:30:32', b'0');
INSERT INTO `platform_error_code` VALUES (1825903246569705473, 1, 'shengyu-server', 1002004001, '父级部门不存在', '', NULL, '2024-08-20 22:30:32', NULL, '2024-08-20 22:30:32', b'0');
INSERT INTO `platform_error_code` VALUES (1825903246779420673, 1, 'shengyu-server', 1002004002, '当前部门不存在', '', NULL, '2024-08-20 22:30:32', NULL, '2024-08-20 22:30:32', b'0');
INSERT INTO `platform_error_code` VALUES (1825903247278542849, 1, 'shengyu-server', 1002004003, '存在子部门，无法删除', '', NULL, '2024-08-20 22:30:32', NULL, '2024-08-20 22:30:32', b'0');
INSERT INTO `platform_error_code` VALUES (1825903247601504258, 1, 'shengyu-server', 1002004004, '不能设置自己为父部门', '', NULL, '2024-08-20 22:30:33', NULL, '2024-08-20 22:30:33', b'0');
INSERT INTO `platform_error_code` VALUES (1825903247756693506, 1, 'shengyu-server', 1002004005, '部门中存在员工，无法删除', '', NULL, '2024-08-20 22:30:33', NULL, '2024-08-20 22:30:33', b'0');
INSERT INTO `platform_error_code` VALUES (1825903248947875842, 1, 'shengyu-server', 1002004006, '部门({})不处于开启状态，不允许选择', '', NULL, '2024-08-20 22:30:33', NULL, '2024-08-20 22:30:33', b'0');
INSERT INTO `platform_error_code` VALUES (1825903249107259394, 1, 'shengyu-server', 1002004007, '不能设置自己的子部门为父部门', '', NULL, '2024-08-20 22:30:33', NULL, '2024-08-20 22:30:33', b'0');
INSERT INTO `platform_error_code` VALUES (1825903249312780290, 1, 'shengyu-server', 1002005000, '当前岗位不存在', '', NULL, '2024-08-20 22:30:33', NULL, '2024-08-20 22:30:33', b'0');
INSERT INTO `platform_error_code` VALUES (1825903249459580930, 1, 'shengyu-server', 1002005001, '岗位({}) 不处于开启状态，不允许选择', '', NULL, '2024-08-20 22:30:33', NULL, '2024-08-20 22:30:33', b'0');
INSERT INTO `platform_error_code` VALUES (1825903249958703106, 1, 'shengyu-server', 1002005002, '已经存在该名字的岗位', '', NULL, '2024-08-20 22:30:33', NULL, '2024-08-20 22:30:33', b'0');
INSERT INTO `platform_error_code` VALUES (1825903250449436673, 1, 'shengyu-server', 1002005003, '已经存在该标识的岗位', '', NULL, '2024-08-20 22:30:33', NULL, '2024-08-20 22:30:33', b'0');
INSERT INTO `platform_error_code` VALUES (1825903250604625922, 1, 'shengyu-server', 1002006001, '当前字典类型不存在', '', NULL, '2024-08-20 22:30:33', NULL, '2024-08-20 22:30:33', b'0');
INSERT INTO `platform_error_code` VALUES (1825903250885644290, 1, 'shengyu-server', 1002006002, '字典类型不处于开启状态，不允许选择', '', NULL, '2024-08-20 22:30:33', NULL, '2024-08-20 22:30:33', b'0');
INSERT INTO `platform_error_code` VALUES (1825903251028250626, 1, 'shengyu-server', 1002006003, '已经存在该名字的字典类型', '', NULL, '2024-08-20 22:30:33', NULL, '2024-08-20 22:30:33', b'0');
INSERT INTO `platform_error_code` VALUES (1825903251170856962, 1, 'shengyu-server', 1002006004, '已经存在该类型的字典类型', '', NULL, '2024-08-20 22:30:33', NULL, '2024-08-20 22:30:33', b'0');
INSERT INTO `platform_error_code` VALUES (1825903251326046209, 1, 'shengyu-server', 1002006005, '无法删除，该字典类型还有字典数据', '', NULL, '2024-08-20 22:30:33', NULL, '2024-08-20 22:30:33', b'0');
INSERT INTO `platform_error_code` VALUES (1825903251493818369, 1, 'shengyu-server', 1002007001, '当前字典数据不存在', '', NULL, '2024-08-20 22:30:33', NULL, '2024-08-20 22:30:33', b'0');
INSERT INTO `platform_error_code` VALUES (1825903251653201922, 1, 'shengyu-server', 1002007002, '字典数据({})不处于开启状态，不允许选择', '', NULL, '2024-08-20 22:30:33', NULL, '2024-08-20 22:30:33', b'0');
INSERT INTO `platform_error_code` VALUES (1825903251808391169, 1, 'shengyu-server', 1002007003, '已经存在该值的字典数据', '', NULL, '2024-08-20 22:30:34', NULL, '2024-08-20 22:30:34', b'0');
INSERT INTO `platform_error_code` VALUES (1825903251950997506, 1, 'shengyu-server', 1002008001, '当前通知公告不存在', '', NULL, '2024-08-20 22:30:34', NULL, '2024-08-20 22:30:34', b'0');
INSERT INTO `platform_error_code` VALUES (1825903252093603841, 1, 'shengyu-server', 1002011000, '短信渠道不存在', '', NULL, '2024-08-20 22:30:34', NULL, '2024-08-20 22:30:34', b'0');
INSERT INTO `platform_error_code` VALUES (1825903252240404482, 1, 'shengyu-server', 1002011001, '短信渠道不处于开启状态，不允许选择', '', NULL, '2024-08-20 22:30:34', NULL, '2024-08-20 22:30:34', b'0');
INSERT INTO `platform_error_code` VALUES (1825903252403982337, 1, 'shengyu-server', 1002011002, '无法删除，该短信渠道还有短信模板', '', NULL, '2024-08-20 22:30:34', NULL, '2024-08-20 22:30:34', b'0');
INSERT INTO `platform_error_code` VALUES (1825903252584337409, 1, 'shengyu-server', 1002012000, '短信模板不存在', '', NULL, '2024-08-20 22:30:34', NULL, '2024-08-20 22:30:34', b'0');
INSERT INTO `platform_error_code` VALUES (1825903252743720962, 1, 'shengyu-server', 1002012001, '已经存在编码为【{}】的短信模板', '', NULL, '2024-08-20 22:30:34', NULL, '2024-08-20 22:30:34', b'0');
INSERT INTO `platform_error_code` VALUES (1825903252907298817, 1, 'shengyu-server', 1002012002, '短信 API 模板调用失败，原因是：{}', '', NULL, '2024-08-20 22:30:34', NULL, '2024-08-20 22:30:34', b'0');
INSERT INTO `platform_error_code` VALUES (1825903253083459585, 1, 'shengyu-server', 1002012003, '短信 API 模版无法使用，原因：审批中', '', NULL, '2024-08-20 22:30:34', NULL, '2024-08-20 22:30:34', b'0');
INSERT INTO `platform_error_code` VALUES (1825903253221871618, 1, 'shengyu-server', 1002012004, '短信 API 模版无法使用，原因：审批不通过，{}', '', NULL, '2024-08-20 22:30:34', NULL, '2024-08-20 22:30:34', b'0');
INSERT INTO `platform_error_code` VALUES (1825903253423198210, 1, 'shengyu-server', 1002012005, '短信 API 模版无法使用，原因：模版不存在', '', NULL, '2024-08-20 22:30:34', NULL, '2024-08-20 22:30:34', b'0');
INSERT INTO `platform_error_code` VALUES (1825903253863600130, 1, 'shengyu-server', 1002013000, '手机号不存在', '', NULL, '2024-08-20 22:30:34', NULL, '2024-08-20 22:30:34', b'0');
INSERT INTO `platform_error_code` VALUES (1825903254018789378, 1, 'shengyu-server', 1002013001, '模板参数({})缺失', '', NULL, '2024-08-20 22:30:34', NULL, '2024-08-20 22:30:34', b'0');
INSERT INTO `platform_error_code` VALUES (1825903254161395713, 1, 'shengyu-server', 1002013002, '短信模板不存在', '', NULL, '2024-08-20 22:30:34', NULL, '2024-08-20 22:30:34', b'0');
INSERT INTO `platform_error_code` VALUES (1825903254304002049, 1, 'shengyu-server', 1002014000, '验证码不存在', '', NULL, '2024-08-20 22:30:34', NULL, '2024-08-20 22:30:34', b'0');
INSERT INTO `platform_error_code` VALUES (1825903254459191298, 1, 'shengyu-server', 1002014001, '验证码已过期', '', NULL, '2024-08-20 22:30:34', NULL, '2024-08-20 22:30:34', b'0');
INSERT INTO `platform_error_code` VALUES (1825903254622769153, 1, 'shengyu-server', 1002014002, '验证码已使用', '', NULL, '2024-08-20 22:30:34', NULL, '2024-08-20 22:30:34', b'0');
INSERT INTO `platform_error_code` VALUES (1825903254786347010, 1, 'shengyu-server', 1002014003, '验证码不正确', '', NULL, '2024-08-20 22:30:34', NULL, '2024-08-20 22:30:34', b'0');
INSERT INTO `platform_error_code` VALUES (1825903254945730562, 1, 'shengyu-server', 1002014004, '超过每日短信发送数量', '', NULL, '2024-08-20 22:30:34', NULL, '2024-08-20 22:30:34', b'0');
INSERT INTO `platform_error_code` VALUES (1825903255100919810, 1, 'shengyu-server', 1002014005, '短信发送过于频率', '', NULL, '2024-08-20 22:30:34', NULL, '2024-08-20 22:30:34', b'0');
INSERT INTO `platform_error_code` VALUES (1825903255298052098, 1, 'shengyu-server', 1002014006, '手机号已被使用', '', NULL, '2024-08-20 22:30:34', NULL, '2024-08-20 22:30:34', b'0');
INSERT INTO `platform_error_code` VALUES (1825903255440658434, 1, 'shengyu-server', 1002014007, '验证码未被使用', '', NULL, '2024-08-20 22:30:34', NULL, '2024-08-20 22:30:34', b'0');
INSERT INTO `platform_error_code` VALUES (1825903255641985025, 1, 'shengyu-server', 1002015000, '租户不存在', '', NULL, '2024-08-20 22:30:34', NULL, '2024-08-20 22:30:34', b'0');
INSERT INTO `platform_error_code` VALUES (1825903255872671746, 1, 'shengyu-server', 1002015001, '名字为【{}】的租户已被禁用', '', NULL, '2024-08-20 22:30:35', NULL, '2024-08-20 22:30:35', b'0');
INSERT INTO `platform_error_code` VALUES (1825903256032055298, 1, 'shengyu-server', 1002015002, '名字为【{}】的租户已过期', '', NULL, '2024-08-20 22:30:35', NULL, '2024-08-20 22:30:35', b'0');
INSERT INTO `platform_error_code` VALUES (1825903256178855938, 1, 'shengyu-server', 1002015003, '系统租户不能进行修改、删除等操作！', '', NULL, '2024-08-20 22:30:35', NULL, '2024-08-20 22:30:35', b'0');
INSERT INTO `platform_error_code` VALUES (1825903256321462273, 1, 'shengyu-server', 1002015004, '名字为【{}】的租户已存在', '', NULL, '2024-08-20 22:30:35', NULL, '2024-08-20 22:30:35', b'0');
INSERT INTO `platform_error_code` VALUES (1825903256480845825, 1, 'shengyu-server', 1002015005, '域名为【{}】的租户已存在', '', NULL, '2024-08-20 22:30:35', NULL, '2024-08-20 22:30:35', b'0');
INSERT INTO `platform_error_code` VALUES (1825903256883499010, 1, 'shengyu-server', 1002016000, '租户套餐不存在', '', NULL, '2024-08-20 22:30:35', NULL, '2024-08-20 22:30:35', b'0');
INSERT INTO `platform_error_code` VALUES (1825903257068048385, 1, 'shengyu-server', 1002016001, '租户正在使用该套餐，请给租户重新设置套餐后再尝试删除', '', NULL, '2024-08-20 22:30:35', NULL, '2024-08-20 22:30:35', b'0');
INSERT INTO `platform_error_code` VALUES (1825903257223237634, 1, 'shengyu-server', 1002016002, '名字为【{}】的租户套餐已被禁用', '', NULL, '2024-08-20 22:30:35', NULL, '2024-08-20 22:30:35', b'0');
INSERT INTO `platform_error_code` VALUES (1825903258116624386, 1, 'shengyu-server', 1002017000, '错误码不存在', '', NULL, '2024-08-20 22:30:35', NULL, '2024-08-20 22:30:35', b'0');
INSERT INTO `platform_error_code` VALUES (1825903258305368065, 1, 'shengyu-server', 1002017001, '已经存在编码为【{}】的错误码', '', NULL, '2024-08-20 22:30:35', NULL, '2024-08-20 22:30:35', b'0');
INSERT INTO `platform_error_code` VALUES (1825903258443780098, 1, 'shengyu-server', 1002018000, '社交授权失败，原因是：{}', '', NULL, '2024-08-20 22:30:35', NULL, '2024-08-20 22:30:35', b'0');
INSERT INTO `platform_error_code` VALUES (1825903258980651009, 1, 'shengyu-server', 1002018001, '社交授权失败，找不到对应的用户', '', NULL, '2024-08-20 22:30:35', NULL, '2024-08-20 22:30:35', b'0');
INSERT INTO `platform_error_code` VALUES (1825903259572047873, 1, 'shengyu-server', 1002018200, '获得手机号失败', '', NULL, '2024-08-20 22:30:35', NULL, '2024-08-20 22:30:35', b'0');
INSERT INTO `platform_error_code` VALUES (1825903259735625730, 1, 'shengyu-server', 1002018201, '社交客户端已存在配置', '', NULL, '2024-08-20 22:30:35', NULL, '2024-08-20 23:25:16', b'0');
INSERT INTO `platform_error_code` VALUES (1825903259882426370, 1, 'shengyu-server', 1002018201, '社交客户端已存在配置', '', NULL, '2024-08-20 22:30:35', NULL, '2024-08-20 22:30:35', b'0');
INSERT INTO `platform_error_code` VALUES (1825903260025032706, 1, 'shengyu-server', 1002019000, '系统敏感词在所有标签中都不存在', '', NULL, '2024-08-20 22:30:35', NULL, '2024-08-20 22:30:35', b'0');
INSERT INTO `platform_error_code` VALUES (1825903260234747906, 1, 'shengyu-server', 1002019001, '系统敏感词已在标签中存在', '', NULL, '2024-08-20 22:30:36', NULL, '2024-08-20 22:30:36', b'0');
INSERT INTO `platform_error_code` VALUES (1825903260385742849, 1, 'shengyu-server', 1002020000, 'OAuth2 客户端不存在', '', NULL, '2024-08-20 22:30:36', NULL, '2024-08-20 22:30:36', b'0');
INSERT INTO `platform_error_code` VALUES (1825903260603846658, 1, 'shengyu-server', 1002020001, 'OAuth2 客户端编号已存在', '', NULL, '2024-08-20 22:30:36', NULL, '2024-08-20 22:30:36', b'0');
INSERT INTO `platform_error_code` VALUES (1825903260750647298, 1, 'shengyu-server', 1002020002, 'OAuth2 客户端已禁用', '', NULL, '2024-08-20 22:30:36', NULL, '2024-08-20 22:30:36', b'0');
INSERT INTO `platform_error_code` VALUES (1825903260918419457, 1, 'shengyu-server', 1002020003, '不支持该授权类型', '', NULL, '2024-08-20 22:30:36', NULL, '2024-08-20 22:30:36', b'0');
INSERT INTO `platform_error_code` VALUES (1825903261098774529, 1, 'shengyu-server', 1002020004, '授权范围过大', '', NULL, '2024-08-20 22:30:36', NULL, '2024-08-20 22:30:36', b'0');
INSERT INTO `platform_error_code` VALUES (1825903261237186561, 1, 'shengyu-server', 1002020005, '无效 redirect_uri: {}', '', NULL, '2024-08-20 22:30:36', NULL, '2024-08-20 22:30:36', b'0');
INSERT INTO `platform_error_code` VALUES (1825903261383987201, 1, 'shengyu-server', 1002020006, '无效 client_secret: {}', '', NULL, '2024-08-20 22:30:36', NULL, '2024-08-20 22:30:36', b'0');
INSERT INTO `platform_error_code` VALUES (1825903261526593538, 1, 'shengyu-server', 1002021000, 'client_id 不匹配', '', NULL, '2024-08-20 22:30:36', NULL, '2024-08-20 22:30:36', b'0');
INSERT INTO `platform_error_code` VALUES (1825903261673394177, 1, 'shengyu-server', 1002021001, 'redirect_uri 不匹配', '', NULL, '2024-08-20 22:30:36', NULL, '2024-08-20 22:30:36', b'0');
INSERT INTO `platform_error_code` VALUES (1825903261845360642, 1, 'shengyu-server', 1002021002, 'state 不匹配', '', NULL, '2024-08-20 22:30:36', NULL, '2024-08-20 22:30:36', b'0');
INSERT INTO `platform_error_code` VALUES (1825903262000549889, 1, 'shengyu-server', 1002021003, 'code 不存在', '', NULL, '2024-08-20 22:30:36', NULL, '2024-08-20 22:30:36', b'0');
INSERT INTO `platform_error_code` VALUES (1825903262214459393, 1, 'shengyu-server', 1002022000, 'code 不存在', '', NULL, '2024-08-20 22:30:36', NULL, '2024-08-20 22:30:36', b'0');
INSERT INTO `platform_error_code` VALUES (1825903262382231554, 1, 'shengyu-server', 1002022001, 'code 已过期', '', NULL, '2024-08-20 22:30:36', NULL, '2024-08-20 22:30:36', b'0');
INSERT INTO `platform_error_code` VALUES (1825903262537420802, 1, 'shengyu-server', 1002023000, '邮箱账号不存在', '', NULL, '2024-08-20 22:30:36', NULL, '2024-08-20 22:30:36', b'0');
INSERT INTO `platform_error_code` VALUES (1825903262810050561, 1, 'shengyu-server', 1002023001, '无法删除，该邮箱账号还有邮件模板', '', NULL, '2024-08-20 22:30:36', NULL, '2024-08-20 22:30:36', b'0');
INSERT INTO `platform_error_code` VALUES (1825903263023960066, 1, 'shengyu-server', 1002024000, '邮件模版不存在', '', NULL, '2024-08-20 22:30:36', NULL, '2024-08-20 22:30:36', b'0');
INSERT INTO `platform_error_code` VALUES (1825903263334338561, 1, 'shengyu-server', 1002024001, '邮件模版 code({}) 已存在', '', NULL, '2024-08-20 22:30:36', NULL, '2024-08-20 22:30:36', b'0');
INSERT INTO `platform_error_code` VALUES (1825903263716020226, 1, 'shengyu-server', 1002025000, '模板参数({})缺失', '', NULL, '2024-08-20 22:30:36', NULL, '2024-08-20 22:30:36', b'0');
INSERT INTO `platform_error_code` VALUES (1825903264131256322, 1, 'shengyu-server', 1002025001, '邮箱不存在', '', NULL, '2024-08-20 22:30:36', NULL, '2024-08-20 22:30:36', b'0');
INSERT INTO `platform_error_code` VALUES (1825903265037225985, 1, 'shengyu-server', 1002026000, '站内信模版不存在', '', NULL, '2024-08-20 22:30:37', NULL, '2024-08-20 22:30:37', b'0');
INSERT INTO `platform_error_code` VALUES (1825903265246941186, 1, 'shengyu-server', 1002026001, '已经存在编码为【{}】的站内信模板', '', NULL, '2024-08-20 22:30:37', NULL, '2024-08-20 22:30:37', b'0');
INSERT INTO `platform_error_code` VALUES (1825903265452462082, 1, 'shengyu-server', 1002028000, '模板参数({})缺失', '', NULL, '2024-08-20 22:30:37', NULL, '2024-08-20 22:30:37', b'0');

-- ----------------------------
-- Table structure for platform_login_log
-- ----------------------------
DROP TABLE IF EXISTS `platform_login_log`;
CREATE TABLE `platform_login_log`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '访问ID',
  `log_type` bigint NOT NULL COMMENT '日志类型',
  `trace_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '链路追踪编号',
  `user_id` bigint NOT NULL DEFAULT 0 COMMENT '用户编号',
  `user_type` tinyint NOT NULL DEFAULT 0 COMMENT '用户类型',
  `username` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '用户账号',
  `result` tinyint NOT NULL COMMENT '登陆结果',
  `user_ip` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '用户 IP',
  `user_agent` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '浏览器 UA',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1825927743221796867 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '系统访问记录' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of platform_login_log
-- ----------------------------
INSERT INTO `platform_login_log` VALUES (1825926925215076353, 100, '', 1, 0, 'admin', 0, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', NULL, '2024-08-21 00:04:38', NULL, '2024-08-21 00:04:38', b'0');
INSERT INTO `platform_login_log` VALUES (1825927684795142146, 200, '', 1, 0, 'admin', 0, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', '1', '2024-08-21 00:07:39', '1', '2024-08-21 00:07:39', b'0');
INSERT INTO `platform_login_log` VALUES (1825927743221796866, 100, '', 1, 0, 'admin', 0, '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', NULL, '2024-08-21 00:07:53', NULL, '2024-08-21 00:07:53', b'0');

-- ----------------------------
-- Table structure for platform_menu
-- ----------------------------
DROP TABLE IF EXISTS `platform_menu`;
CREATE TABLE `platform_menu`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '菜单ID',
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '菜单名称',
  `permission` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '权限标识',
  `type` tinyint NOT NULL COMMENT '菜单类型',
  `sort` int NOT NULL DEFAULT 0 COMMENT '显示顺序',
  `parent_id` bigint NOT NULL DEFAULT 0 COMMENT '父菜单ID',
  `path` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '路由地址',
  `icon` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '#' COMMENT '菜单图标',
  `component` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '组件路径',
  `component_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '组件名',
  `status` tinyint NOT NULL DEFAULT 0 COMMENT '菜单状态',
  `visible` bit(1) NOT NULL DEFAULT b'1' COMMENT '是否可见',
  `keep_alive` bit(1) NOT NULL DEFAULT b'1' COMMENT '是否缓存',
  `always_show` bit(1) NOT NULL DEFAULT b'1' COMMENT '是否总是显示',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 505303413260358 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '菜单权限表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of platform_menu
-- ----------------------------
INSERT INTO `platform_menu` VALUES (1, '系统管理', '', 1, 10, 0, '/system', 'system', NULL, NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (2, '基础设施', '', 1, 20, 0, '/infra', 'monitor', NULL, NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (5, 'OA 示例', '', 1, 40, 1185, 'oa', 'people', NULL, NULL, 0, b'1', b'1', b'1', 'admin', '2021-09-20 16:26:19', '1', '2024-01-13 20:44:14', b'1');
INSERT INTO `platform_menu` VALUES (100, '用户管理', 'system:user:list', 2, 1, 1, 'user', 'user', 'system/user/index', 'SystemUser', 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2023-04-08 08:31:59', b'0');
INSERT INTO `platform_menu` VALUES (101, '角色管理', '', 2, 2, 1, 'role', 'peoples', 'system/role/index', 'SystemRole', 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2023-04-08 08:33:59', b'0');
INSERT INTO `platform_menu` VALUES (102, '菜单管理', '', 2, 3, 1, 'menu', 'tree-table', 'system/menu/index', 'SystemMenu', 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2023-04-08 08:34:32', b'0');
INSERT INTO `platform_menu` VALUES (103, '部门管理', '', 2, 4, 1, 'dept', 'tree', 'system/dept/index', 'SystemDept', 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2023-04-08 08:35:32', b'0');
INSERT INTO `platform_menu` VALUES (104, '岗位管理', '', 2, 5, 1, 'post', 'post', 'system/post/index', 'SystemPost', 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2023-04-08 08:36:21', b'0');
INSERT INTO `platform_menu` VALUES (105, '字典管理', '', 2, 6, 1, 'dict', 'dict', 'system/dict/index', 'SystemDictType', 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2023-04-08 08:36:45', b'0');
INSERT INTO `platform_menu` VALUES (106, '配置管理', '', 2, 6, 2, 'config', 'edit', 'infra/config/index', 'InfraConfig', 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2023-04-08 10:31:17', b'0');
INSERT INTO `platform_menu` VALUES (107, '通知公告', '', 2, 8, 1, 'notice', 'message', 'system/notice/index', 'SystemNotice', 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2023-04-08 08:45:06', b'0');
INSERT INTO `platform_menu` VALUES (108, '审计日志', '', 1, 9, 1, 'log', 'log', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (109, '令牌管理', '', 2, 2, 1261, 'token', 'online', 'system/oauth2/token/index', 'SystemTokenClient', 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2023-04-08 08:47:41', b'0');
INSERT INTO `platform_menu` VALUES (110, '定时任务', '', 2, 12, 2, 'job', 'job', 'infra/job/index', 'InfraJob', 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2023-04-08 10:36:49', b'0');
INSERT INTO `platform_menu` VALUES (111, 'MySQL 监控', '', 2, 9, 2, 'druid', 'druid', 'infra/druid/index', 'InfraDruid', 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2023-04-08 09:09:30', b'0');
INSERT INTO `platform_menu` VALUES (112, 'Java 监控', '', 2, 11, 2, 'admin-server', 'server', 'infra/server/index', 'InfraAdminServer', 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2023-04-08 10:34:08', b'0');
INSERT INTO `platform_menu` VALUES (113, 'Redis 监控', '', 2, 10, 2, 'redis', 'redis', 'infra/redis/index', 'InfraRedis', 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2023-04-08 10:33:30', b'0');
INSERT INTO `platform_menu` VALUES (114, '表单构建', 'infra:build:list', 2, 2, 2, 'build', 'build', 'infra/build/index', 'InfraBuild', 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2023-04-08 09:06:12', b'0');
INSERT INTO `platform_menu` VALUES (115, '代码生成', 'infra:codegen:query', 2, 1, 2, 'codegen', 'code', 'infra/codegen/index', 'InfraCodegen', 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2023-04-08 09:02:24', b'0');
INSERT INTO `platform_menu` VALUES (116, '系统接口', 'infra:swagger:list', 2, 3, 2, 'swagger', 'swagger', 'infra/swagger/index', 'InfraSwagger', 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2023-04-08 09:11:28', b'0');
INSERT INTO `platform_menu` VALUES (500, '操作日志', '', 2, 1, 108, 'operate-log', 'form', 'system/operatelog/index', 'SystemOperateLog', 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2023-04-08 08:47:00', b'0');
INSERT INTO `platform_menu` VALUES (501, '登录日志', '', 2, 2, 108, 'login-log', 'logininfor', 'system/loginlog/index', 'SystemLoginLog', 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2023-04-08 08:46:18', b'0');
INSERT INTO `platform_menu` VALUES (1001, '用户查询', 'system:user:query', 3, 1, 100, '', '#', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1002, '用户新增', 'system:user:create', 3, 2, 100, '', '', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1003, '用户修改', 'system:user:update', 3, 3, 100, '', '', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1004, '用户删除', 'system:user:delete', 3, 4, 100, '', '', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1005, '用户导出', 'system:user:export', 3, 5, 100, '', '#', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1006, '用户导入', 'system:user:import', 3, 6, 100, '', '#', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1007, '重置密码', 'system:user:update-password', 3, 7, 100, '', '', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1008, '角色查询', 'system:role:query', 3, 1, 101, '', '#', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1009, '角色新增', 'system:role:create', 3, 2, 101, '', '', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1010, '角色修改', 'system:role:update', 3, 3, 101, '', '', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1011, '角色删除', 'system:role:delete', 3, 4, 101, '', '', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1012, '角色导出', 'system:role:export', 3, 5, 101, '', '#', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1013, '菜单查询', 'system:menu:query', 3, 1, 102, '', '#', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1014, '菜单新增', 'system:menu:create', 3, 2, 102, '', '#', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1015, '菜单修改', 'system:menu:update', 3, 3, 102, '', '#', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1016, '菜单删除', 'system:menu:delete', 3, 4, 102, '', '#', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1017, '部门查询', 'system:dept:query', 3, 1, 103, '', '#', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1018, '部门新增', 'system:dept:create', 3, 2, 103, '', '', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1019, '部门修改', 'system:dept:update', 3, 3, 103, '', '', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1020, '部门删除', 'system:dept:delete', 3, 4, 103, '', '', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1021, '岗位查询', 'system:post:query', 3, 1, 104, '', '#', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1022, '岗位新增', 'system:post:create', 3, 2, 104, '', '', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1023, '岗位修改', 'system:post:update', 3, 3, 104, '', '', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1024, '岗位删除', 'system:post:delete', 3, 4, 104, '', '', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1025, '岗位导出', 'system:post:export', 3, 5, 104, '', '#', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1026, '字典查询', 'system:dict:query', 3, 1, 105, '#', '#', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1027, '字典新增', 'system:dict:create', 3, 2, 105, '', '', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1028, '字典修改', 'system:dict:update', 3, 3, 105, '', '', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1029, '字典删除', 'system:dict:delete', 3, 4, 105, '', '', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1030, '字典导出', 'system:dict:export', 3, 5, 105, '#', '#', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1031, '配置查询', 'infra:config:query', 3, 1, 106, '', '', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1032, '配置新增', 'infra:config:create', 3, 2, 106, '', '', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1033, '配置修改', 'infra:config:update', 3, 3, 106, '', '', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1034, '配置删除', 'infra:config:delete', 3, 4, 106, '', '', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1035, '配置导出', 'infra:config:export', 3, 5, 106, '', '', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1036, '公告查询', 'system:notice:query', 3, 1, 107, '#', '#', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1037, '公告新增', 'system:notice:create', 3, 2, 107, '', '', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1038, '公告修改', 'system:notice:update', 3, 3, 107, '', '', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1039, '公告删除', 'system:notice:delete', 3, 4, 107, '', '', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1040, '操作查询', 'system:operate-log:query', 3, 1, 500, '', '', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1042, '日志导出', 'system:operate-log:export', 3, 2, 500, '', '', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1043, '登录查询', 'system:login-log:query', 3, 1, 501, '#', '#', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1045, '日志导出', 'system:login-log:export', 3, 3, 501, '#', '#', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1046, '令牌列表', 'system:oauth2-token:page', 3, 1, 109, '', '', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2022-05-09 23:54:42', b'0');
INSERT INTO `platform_menu` VALUES (1048, '令牌删除', 'system:oauth2-token:delete', 3, 2, 109, '', '', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2022-05-09 23:54:53', b'0');
INSERT INTO `platform_menu` VALUES (1050, '任务新增', 'infra:job:create', 3, 2, 110, '', '', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1051, '任务修改', 'infra:job:update', 3, 3, 110, '', '', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1052, '任务删除', 'infra:job:delete', 3, 4, 110, '', '', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1053, '状态修改', 'infra:job:update', 3, 5, 110, '', '', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1054, '任务导出', 'infra:job:export', 3, 7, 110, '', '', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1056, '生成修改', 'infra:codegen:update', 3, 2, 115, '', '', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1057, '生成删除', 'infra:codegen:delete', 3, 3, 115, '', '', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1058, '导入代码', 'infra:codegen:create', 3, 2, 115, '', '', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1059, '预览代码', 'infra:codegen:preview', 3, 4, 115, '', '', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1060, '生成代码', 'infra:codegen:download', 3, 5, 115, '', '', '', NULL, 0, b'1', b'1', b'1', 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1063, '设置角色菜单权限', 'system:permission:assign-role-menu', 3, 6, 101, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-01-06 17:53:44', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1064, '设置角色数据权限', 'system:permission:assign-role-data-scope', 3, 7, 101, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-01-06 17:56:31', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1065, '设置用户角色', 'system:permission:assign-user-role', 3, 8, 101, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-01-07 10:23:28', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1066, '获得 Redis 监控信息', 'infra:redis:get-monitor-info', 3, 1, 113, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-01-26 01:02:31', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1067, '获得 Redis Key 列表', 'infra:redis:get-key-list', 3, 2, 113, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-01-26 01:02:52', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1070, '代码生成案例', '', 1, 1, 2, 'demo', 'ep:aim', 'infra/testDemo/index', NULL, 0, b'1', b'1', b'1', '', '2021-02-06 12:42:49', '1', '2023-11-15 23:45:53', b'0');
INSERT INTO `platform_menu` VALUES (1075, '任务触发', 'infra:job:trigger', 3, 8, 110, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-02-07 13:03:10', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1076, '数据库文档', '', 2, 4, 2, 'db-doc', 'table', 'infra/dbDoc/index', 'InfraDBDoc', 0, b'1', b'1', b'1', '', '2021-02-08 01:41:47', '1', '2023-04-08 09:13:38', b'0');
INSERT INTO `platform_menu` VALUES (1077, '监控平台', '', 2, 13, 2, 'skywalking', 'eye-open', 'infra/skywalking/index', 'InfraSkyWalking', 0, b'1', b'1', b'1', '', '2021-02-08 20:41:31', '1', '2023-04-08 10:39:06', b'0');
INSERT INTO `platform_menu` VALUES (1078, '访问日志', '', 2, 1, 1083, 'api-access-log', 'log', 'infra/apiAccessLog/index', 'InfraApiAccessLog', 0, b'1', b'1', b'1', '', '2021-02-26 01:32:59', '1', '2023-04-08 10:31:34', b'0');
INSERT INTO `platform_menu` VALUES (1082, '日志导出', 'infra:api-access-log:export', 3, 2, 1078, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-02-26 01:32:59', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1083, 'API 日志', '', 2, 8, 2, 'log', 'log', NULL, NULL, 0, b'1', b'1', b'1', '', '2021-02-26 02:18:24', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1084, '错误日志', 'infra:api-error-log:query', 2, 2, 1083, 'api-error-log', 'log', 'infra/apiErrorLog/index', 'InfraApiErrorLog', 0, b'1', b'1', b'1', '', '2021-02-26 07:53:20', '1', '2023-04-08 10:32:25', b'0');
INSERT INTO `platform_menu` VALUES (1085, '日志处理', 'infra:api-error-log:update-status', 3, 2, 1084, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-02-26 07:53:20', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1086, '日志导出', 'infra:api-error-log:export', 3, 3, 1084, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-02-26 07:53:20', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1087, '任务查询', 'infra:job:query', 3, 1, 110, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2021-03-10 01:26:19', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1088, '日志查询', 'infra:api-access-log:query', 3, 1, 1078, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2021-03-10 01:28:04', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1089, '日志查询', 'infra:api-error-log:query', 3, 1, 1084, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2021-03-10 01:29:09', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1090, '文件列表', '', 2, 5, 1243, 'file', 'upload', 'infra/file/index', 'InfraFile', 0, b'1', b'1', b'1', '', '2021-03-12 20:16:20', '1', '2023-04-08 09:21:31', b'0');
INSERT INTO `platform_menu` VALUES (1091, '文件查询', 'infra:file:query', 3, 1, 1090, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-03-12 20:16:20', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1092, '文件删除', 'infra:file:delete', 3, 4, 1090, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-03-12 20:16:20', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1093, '短信管理', '', 1, 11, 1, 'sms', 'validCode', NULL, NULL, 0, b'1', b'1', b'1', '1', '2021-04-05 01:10:16', '1', '2024-04-02 22:03:34', b'0');
INSERT INTO `platform_menu` VALUES (1094, '短信渠道', '', 2, 0, 1093, 'sms-channel', 'phone', 'system/sms/channel/index', 'SystemSmsChannel', 0, b'1', b'1', b'1', '', '2021-04-01 11:07:15', '1', '2024-04-02 22:03:34', b'0');
INSERT INTO `platform_menu` VALUES (1095, '短信渠道查询', 'system:sms-channel:query', 3, 1, 1094, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-04-01 11:07:15', '', '2024-04-02 22:03:34', b'0');
INSERT INTO `platform_menu` VALUES (1096, '短信渠道创建', 'system:sms-channel:create', 3, 2, 1094, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-04-01 11:07:15', '', '2024-04-02 22:03:34', b'0');
INSERT INTO `platform_menu` VALUES (1097, '短信渠道更新', 'system:sms-channel:update', 3, 3, 1094, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-04-01 11:07:15', '', '2024-04-02 22:03:34', b'0');
INSERT INTO `platform_menu` VALUES (1098, '短信渠道删除', 'system:sms-channel:delete', 3, 4, 1094, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-04-01 11:07:15', '', '2024-04-02 22:03:34', b'0');
INSERT INTO `platform_menu` VALUES (1100, '短信模板', '', 2, 1, 1093, 'sms-template', 'phone', 'system/sms/template/index', 'SystemSmsTemplate', 0, b'1', b'1', b'1', '', '2021-04-01 17:35:17', '1', '2024-04-02 22:03:34', b'0');
INSERT INTO `platform_menu` VALUES (1101, '短信模板查询', 'system:sms-template:query', 3, 1, 1100, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-04-01 17:35:17', '', '2024-04-02 22:03:34', b'0');
INSERT INTO `platform_menu` VALUES (1102, '短信模板创建', 'system:sms-template:create', 3, 2, 1100, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-04-01 17:35:17', '', '2024-04-02 22:03:34', b'0');
INSERT INTO `platform_menu` VALUES (1103, '短信模板更新', 'system:sms-template:update', 3, 3, 1100, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-04-01 17:35:17', '', '2024-04-02 22:03:34', b'0');
INSERT INTO `platform_menu` VALUES (1104, '短信模板删除', 'system:sms-template:delete', 3, 4, 1100, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-04-01 17:35:17', '', '2024-04-02 22:03:34', b'0');
INSERT INTO `platform_menu` VALUES (1105, '短信模板导出', 'system:sms-template:export', 3, 5, 1100, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-04-01 17:35:17', '', '2024-04-02 22:03:34', b'0');
INSERT INTO `platform_menu` VALUES (1106, '发送测试短信', 'system:sms-template:send-sms', 3, 6, 1100, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2021-04-11 00:26:40', '1', '2024-04-02 22:03:34', b'0');
INSERT INTO `platform_menu` VALUES (1107, '短信日志', '', 2, 2, 1093, 'sms-log', 'phone', 'system/sms/log/index', 'SystemSmsLog', 0, b'1', b'1', b'1', '', '2021-04-11 08:37:05', '1', '2024-04-02 22:03:34', b'0');
INSERT INTO `platform_menu` VALUES (1108, '短信日志查询', 'system:sms-log:query', 3, 1, 1107, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-04-11 08:37:05', '', '2024-04-02 22:03:34', b'0');
INSERT INTO `platform_menu` VALUES (1109, '短信日志导出', 'system:sms-log:export', 3, 5, 1107, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-04-11 08:37:05', '', '2024-04-02 22:03:34', b'0');
INSERT INTO `platform_menu` VALUES (1110, '错误码管理', '', 2, 12, 1, 'error-code', 'code', 'system/errorCode/index', 'SystemErrorCode', 0, b'1', b'1', b'1', '', '2021-04-13 21:46:42', '1', '2023-04-08 09:01:15', b'0');
INSERT INTO `platform_menu` VALUES (1111, '错误码查询', 'system:error-code:query', 3, 1, 1110, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-04-13 21:46:42', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1112, '错误码创建', 'system:error-code:create', 3, 2, 1110, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-04-13 21:46:42', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1113, '错误码更新', 'system:error-code:update', 3, 3, 1110, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-04-13 21:46:42', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1114, '错误码删除', 'system:error-code:delete', 3, 4, 1110, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-04-13 21:46:42', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1115, '错误码导出', 'system:error-code:export', 3, 5, 1110, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-04-13 21:46:42', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1117, '支付管理', '', 1, 30, 0, '/pay', 'money', NULL, NULL, 0, b'1', b'1', b'1', '1', '2021-12-25 16:43:41', '1', '2024-01-13 18:47:30', b'1');
INSERT INTO `platform_menu` VALUES (1118, '请假查询', '', 2, 0, 5, 'leave', 'user', 'bpm/oa/leave/index', 'BpmOALeave', 0, b'1', b'1', b'1', '', '2021-09-20 08:51:03', '1', '2024-01-13 20:44:10', b'1');
INSERT INTO `platform_menu` VALUES (1119, '请假申请查询', 'bpm:oa-leave:query', 3, 1, 1118, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-09-20 08:51:03', '1', '2024-01-13 20:43:28', b'1');
INSERT INTO `platform_menu` VALUES (1120, '请假申请创建', 'bpm:oa-leave:create', 3, 2, 1118, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-09-20 08:51:03', '1', '2024-01-13 20:43:14', b'1');
INSERT INTO `platform_menu` VALUES (1126, '应用信息', '', 2, 1, 1117, 'app', 'table', 'pay/app/index', 'PayApp', 0, b'1', b'1', b'1', '', '2021-11-10 01:13:30', '1', '2024-01-13 18:47:24', b'1');
INSERT INTO `platform_menu` VALUES (1127, '支付应用信息查询', 'pay:app:query', 3, 1, 1126, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-11-10 01:13:31', '', '2024-01-13 18:47:19', b'1');
INSERT INTO `platform_menu` VALUES (1128, '支付应用信息创建', 'pay:app:create', 3, 2, 1126, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-11-10 01:13:31', '', '2024-01-13 18:47:14', b'1');
INSERT INTO `platform_menu` VALUES (1129, '支付应用信息更新', 'pay:app:update', 3, 3, 1126, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-11-10 01:13:31', '', '2024-01-13 18:47:09', b'1');
INSERT INTO `platform_menu` VALUES (1130, '支付应用信息删除', 'pay:app:delete', 3, 4, 1126, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-11-10 01:13:31', '', '2024-01-13 18:39:11', b'1');
INSERT INTO `platform_menu` VALUES (1132, '秘钥解析', 'pay:channel:parsing', 3, 6, 1129, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2021-11-08 15:15:47', '1', '2024-01-13 18:47:03', b'1');
INSERT INTO `platform_menu` VALUES (1133, '支付商户信息查询', 'pay:merchant:query', 3, 1, 1132, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-11-10 01:13:41', '', '2024-01-13 18:40:23', b'1');
INSERT INTO `platform_menu` VALUES (1134, '支付商户信息创建', 'pay:merchant:create', 3, 2, 1132, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-11-10 01:13:41', '', '2024-01-13 18:39:26', b'1');
INSERT INTO `platform_menu` VALUES (1135, '支付商户信息更新', 'pay:merchant:update', 3, 3, 1132, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-11-10 01:13:41', '', '2024-01-13 18:39:22', b'1');
INSERT INTO `platform_menu` VALUES (1136, '支付商户信息删除', 'pay:merchant:delete', 3, 4, 1132, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-11-10 01:13:41', '', '2024-01-13 18:39:19', b'1');
INSERT INTO `platform_menu` VALUES (1137, '支付商户信息导出', 'pay:merchant:export', 3, 5, 1132, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-11-10 01:13:41', '', '2024-01-13 18:39:15', b'1');
INSERT INTO `platform_menu` VALUES (1138, '租户列表', '', 2, 0, 1224, 'list', 'peoples', 'system/tenant/index', 'SystemTenant', 0, b'1', b'1', b'1', '', '2021-12-14 12:31:43', '1', '2023-04-08 08:29:08', b'0');
INSERT INTO `platform_menu` VALUES (1139, '租户查询', 'system:tenant:query', 3, 1, 1138, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-12-14 12:31:44', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1140, '租户创建', 'system:tenant:create', 3, 2, 1138, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-12-14 12:31:44', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1141, '租户更新', 'system:tenant:update', 3, 3, 1138, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-12-14 12:31:44', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1142, '租户删除', 'system:tenant:delete', 3, 4, 1138, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-12-14 12:31:44', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1143, '租户导出', 'system:tenant:export', 3, 5, 1138, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-12-14 12:31:44', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1150, '秘钥解析', '', 3, 6, 1129, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2021-11-08 15:15:47', '1', '2024-01-13 18:38:44', b'1');
INSERT INTO `platform_menu` VALUES (1161, '退款订单', '', 2, 3, 1117, 'refund', 'order', 'pay/refund/index', 'PayRefund', 0, b'1', b'1', b'1', '', '2021-12-25 08:29:07', '1', '2024-01-13 18:37:58', b'1');
INSERT INTO `platform_menu` VALUES (1162, '退款订单查询', 'pay:refund:query', 3, 1, 1161, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-12-25 08:29:07', '', '2024-01-13 18:37:53', b'1');
INSERT INTO `platform_menu` VALUES (1163, '退款订单创建', 'pay:refund:create', 3, 2, 1161, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-12-25 08:29:07', '', '2024-01-13 18:37:48', b'1');
INSERT INTO `platform_menu` VALUES (1164, '退款订单更新', 'pay:refund:update', 3, 3, 1161, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-12-25 08:29:07', '', '2024-01-13 18:37:44', b'1');
INSERT INTO `platform_menu` VALUES (1165, '退款订单删除', 'pay:refund:delete', 3, 4, 1161, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-12-25 08:29:07', '', '2024-01-13 18:37:40', b'1');
INSERT INTO `platform_menu` VALUES (1166, '退款订单导出', 'pay:refund:export', 3, 5, 1161, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-12-25 08:29:07', '', '2024-01-13 18:37:35', b'1');
INSERT INTO `platform_menu` VALUES (1173, '支付订单', '', 2, 2, 1117, 'order', 'pay', 'pay/order/index', 'PayOrder', 0, b'1', b'1', b'1', '', '2021-12-25 08:49:43', '1', '2024-01-13 18:38:33', b'1');
INSERT INTO `platform_menu` VALUES (1174, '支付订单查询', 'pay:order:query', 3, 1, 1173, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-12-25 08:49:43', '', '2024-01-13 18:38:29', b'1');
INSERT INTO `platform_menu` VALUES (1175, '支付订单创建', 'pay:order:create', 3, 2, 1173, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-12-25 08:49:43', '', '2024-01-13 18:38:18', b'1');
INSERT INTO `platform_menu` VALUES (1176, '支付订单更新', 'pay:order:update', 3, 3, 1173, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-12-25 08:49:43', '', '2024-01-13 18:38:14', b'1');
INSERT INTO `platform_menu` VALUES (1177, '支付订单删除', 'pay:order:delete', 3, 4, 1173, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-12-25 08:49:43', '', '2024-01-13 18:38:09', b'1');
INSERT INTO `platform_menu` VALUES (1178, '支付订单导出', 'pay:order:export', 3, 5, 1173, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-12-25 08:49:43', '', '2024-01-13 18:38:06', b'1');
INSERT INTO `platform_menu` VALUES (1185, '工作流程', '', 1, 50, 0, '/bpm', 'tool', NULL, NULL, 0, b'1', b'1', b'1', '1', '2021-12-30 20:26:36', '103', '2024-01-13 20:48:44', b'1');
INSERT INTO `platform_menu` VALUES (1186, '流程管理', '', 1, 10, 1185, 'manager', 'nested', NULL, NULL, 0, b'1', b'1', b'1', '1', '2021-12-30 20:28:30', '1', '2024-01-13 20:48:40', b'1');
INSERT INTO `platform_menu` VALUES (1187, '流程表单', '', 2, 0, 1186, 'form', 'form', 'bpm/form/index', 'BpmForm', 0, b'1', b'1', b'1', '', '2021-12-30 12:38:22', '1', '2024-01-13 20:48:37', b'1');
INSERT INTO `platform_menu` VALUES (1188, '表单查询', 'bpm:form:query', 3, 1, 1187, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-12-30 12:38:22', '1', '2024-01-13 20:48:34', b'1');
INSERT INTO `platform_menu` VALUES (1189, '表单创建', 'bpm:form:create', 3, 2, 1187, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-12-30 12:38:22', '1', '2024-01-13 20:48:17', b'1');
INSERT INTO `platform_menu` VALUES (1190, '表单更新', 'bpm:form:update', 3, 3, 1187, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-12-30 12:38:22', '1', '2024-01-13 20:48:14', b'1');
INSERT INTO `platform_menu` VALUES (1191, '表单删除', 'bpm:form:delete', 3, 4, 1187, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-12-30 12:38:22', '1', '2024-01-13 20:48:11', b'1');
INSERT INTO `platform_menu` VALUES (1192, '表单导出', 'bpm:form:export', 3, 5, 1187, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2021-12-30 12:38:22', '1', '2024-01-13 20:48:09', b'1');
INSERT INTO `platform_menu` VALUES (1193, '流程模型', '', 2, 5, 1186, 'model', 'guide', 'bpm/model/index', 'BpmModel', 0, b'1', b'1', b'1', '1', '2021-12-31 23:24:58', '1', '2024-01-13 20:47:45', b'1');
INSERT INTO `platform_menu` VALUES (1194, '模型查询', 'bpm:model:query', 3, 1, 1193, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2022-01-03 19:01:10', '1', '2024-01-13 20:47:42', b'1');
INSERT INTO `platform_menu` VALUES (1195, '模型创建', 'bpm:model:create', 3, 2, 1193, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2022-01-03 19:01:24', '1', '2024-01-13 20:47:39', b'1');
INSERT INTO `platform_menu` VALUES (1196, '模型导入', 'bpm:model:import', 3, 3, 1193, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2022-01-03 19:01:35', '1', '2024-01-13 20:47:37', b'1');
INSERT INTO `platform_menu` VALUES (1197, '模型更新', 'bpm:model:update', 3, 4, 1193, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2022-01-03 19:02:28', '1', '2024-01-13 20:47:34', b'1');
INSERT INTO `platform_menu` VALUES (1198, '模型删除', 'bpm:model:delete', 3, 5, 1193, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2022-01-03 19:02:43', '1', '2024-01-13 20:47:31', b'1');
INSERT INTO `platform_menu` VALUES (1199, '模型发布', 'bpm:model:deploy', 3, 6, 1193, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2022-01-03 19:03:24', '1', '2024-01-13 20:47:29', b'1');
INSERT INTO `platform_menu` VALUES (1200, '任务管理', '', 1, 20, 1185, 'task', 'cascader', NULL, NULL, 0, b'1', b'1', b'1', '1', '2022-01-07 23:51:48', '1', '2024-01-13 20:45:11', b'1');
INSERT INTO `platform_menu` VALUES (1201, '我的流程', '', 2, 0, 1200, 'my', 'people', 'bpm/processInstance/index', 'BpmProcessInstance', 0, b'1', b'1', b'1', '', '2022-01-07 15:53:44', '1', '2024-01-13 20:45:08', b'1');
INSERT INTO `platform_menu` VALUES (1202, '流程实例的查询', 'bpm:process-instance:query', 3, 1, 1201, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-01-07 15:53:44', '1', '2024-01-13 20:45:01', b'1');
INSERT INTO `platform_menu` VALUES (1207, '待办任务', '', 2, 10, 1200, 'todo', 'eye-open', 'bpm/task/todo/index', 'BpmTodoTask', 0, b'1', b'1', b'1', '1', '2022-01-08 10:33:37', '1', '2024-01-13 20:44:45', b'1');
INSERT INTO `platform_menu` VALUES (1208, '已办任务', '', 2, 20, 1200, 'done', 'eye', 'bpm/task/done/index', 'BpmDoneTask', 0, b'1', b'1', b'1', '1', '2022-01-08 10:34:13', '1', '2024-01-13 20:44:21', b'1');
INSERT INTO `platform_menu` VALUES (1209, '用户分组', '', 2, 2, 1186, 'user-group', 'people', 'bpm/group/index', 'BpmUserGroup', 0, b'1', b'1', b'1', '', '2022-01-14 02:14:20', '1', '2024-01-13 20:48:04', b'1');
INSERT INTO `platform_menu` VALUES (1210, '用户组查询', 'bpm:user-group:query', 3, 1, 1209, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-01-14 02:14:20', '', '2024-01-13 20:48:01', b'1');
INSERT INTO `platform_menu` VALUES (1211, '用户组创建', 'bpm:user-group:create', 3, 2, 1209, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-01-14 02:14:20', '', '2024-01-13 20:47:58', b'1');
INSERT INTO `platform_menu` VALUES (1212, '用户组更新', 'bpm:user-group:update', 3, 3, 1209, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-01-14 02:14:20', '', '2024-01-13 20:47:55', b'1');
INSERT INTO `platform_menu` VALUES (1213, '用户组删除', 'bpm:user-group:delete', 3, 4, 1209, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-01-14 02:14:20', '', '2024-01-13 20:47:51', b'1');
INSERT INTO `platform_menu` VALUES (1215, '流程定义查询', 'bpm:process-definition:query', 3, 10, 1193, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2022-01-23 00:21:43', '1', '2024-01-13 20:47:26', b'1');
INSERT INTO `platform_menu` VALUES (1216, '流程任务分配规则查询', 'bpm:task-assign-rule:query', 3, 20, 1193, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2022-01-23 00:26:53', '1', '2024-01-13 20:47:23', b'1');
INSERT INTO `platform_menu` VALUES (1217, '流程任务分配规则创建', 'bpm:task-assign-rule:create', 3, 21, 1193, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2022-01-23 00:28:15', '1', '2024-01-13 20:47:20', b'1');
INSERT INTO `platform_menu` VALUES (1218, '流程任务分配规则更新', 'bpm:task-assign-rule:update', 3, 22, 1193, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2022-01-23 00:28:41', '1', '2024-01-13 20:45:23', b'1');
INSERT INTO `platform_menu` VALUES (1219, '流程实例的创建', 'bpm:process-instance:create', 3, 2, 1201, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2022-01-23 00:36:15', '1', '2024-01-13 20:44:57', b'1');
INSERT INTO `platform_menu` VALUES (1220, '流程实例的取消', 'bpm:process-instance:cancel', 3, 3, 1201, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2022-01-23 00:36:33', '1', '2024-01-13 20:44:51', b'1');
INSERT INTO `platform_menu` VALUES (1221, '流程任务的查询', 'bpm:task:query', 3, 1, 1207, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2022-01-23 00:38:52', '1', '2024-01-13 20:44:42', b'1');
INSERT INTO `platform_menu` VALUES (1222, '流程任务的更新', 'bpm:task:update', 3, 2, 1207, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2022-01-23 00:39:24', '1', '2024-01-13 20:44:29', b'1');
INSERT INTO `platform_menu` VALUES (1224, '租户管理', '', 2, 0, 1, 'tenant', 'peoples', NULL, NULL, 0, b'1', b'1', b'1', '1', '2022-02-20 01:41:13', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1225, '租户套餐', '', 2, 0, 1224, 'package', 'eye', 'system/tenantPackage/index', 'SystemTenantPackage', 0, b'1', b'1', b'1', '', '2022-02-19 17:44:06', '1', '2023-04-08 08:17:08', b'0');
INSERT INTO `platform_menu` VALUES (1226, '租户套餐查询', 'system:tenant-package:query', 3, 1, 1225, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-02-19 17:44:06', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1227, '租户套餐创建', 'system:tenant-package:create', 3, 2, 1225, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-02-19 17:44:06', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1228, '租户套餐更新', 'system:tenant-package:update', 3, 3, 1225, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-02-19 17:44:06', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1229, '租户套餐删除', 'system:tenant-package:delete', 3, 4, 1225, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-02-19 17:44:06', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1237, '文件配置', '', 2, 0, 1243, 'file-config', 'config', 'infra/fileConfig/index', 'InfraFileConfig', 0, b'1', b'1', b'1', '', '2022-03-15 14:35:28', '1', '2023-04-08 09:16:05', b'0');
INSERT INTO `platform_menu` VALUES (1238, '文件配置查询', 'infra:file-config:query', 3, 1, 1237, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-03-15 14:35:28', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1239, '文件配置创建', 'infra:file-config:create', 3, 2, 1237, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-03-15 14:35:28', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1240, '文件配置更新', 'infra:file-config:update', 3, 3, 1237, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-03-15 14:35:28', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1241, '文件配置删除', 'infra:file-config:delete', 3, 4, 1237, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-03-15 14:35:28', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1242, '文件配置导出', 'infra:file-config:export', 3, 5, 1237, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-03-15 14:35:28', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `platform_menu` VALUES (1243, '文件管理', '', 2, 5, 2, 'file', 'download', NULL, '', 0, b'1', b'1', b'1', '1', '2022-03-16 23:47:40', '1', '2023-02-10 13:47:46', b'0');
INSERT INTO `platform_menu` VALUES (1247, '敏感词管理', '', 2, 13, 1, 'sensitive-word', 'education', 'system/sensitiveWord/index', 'SystemSensitiveWord', 0, b'1', b'1', b'1', '', '2022-04-07 16:55:03', '1', '2024-01-13 18:21:58', b'1');
INSERT INTO `platform_menu` VALUES (1248, '敏感词查询', 'system:sensitive-word:query', 3, 1, 1247, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-04-07 16:55:03', '', '2024-01-13 18:21:54', b'1');
INSERT INTO `platform_menu` VALUES (1249, '敏感词创建', 'system:sensitive-word:create', 3, 2, 1247, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-04-07 16:55:03', '', '2024-01-13 18:21:50', b'1');
INSERT INTO `platform_menu` VALUES (1250, '敏感词更新', 'system:sensitive-word:update', 3, 3, 1247, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-04-07 16:55:03', '', '2024-01-13 18:21:46', b'1');
INSERT INTO `platform_menu` VALUES (1251, '敏感词删除', 'system:sensitive-word:delete', 3, 4, 1247, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-04-07 16:55:03', '', '2024-01-13 18:21:42', b'1');
INSERT INTO `platform_menu` VALUES (1252, '敏感词导出', 'system:sensitive-word:export', 3, 5, 1247, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-04-07 16:55:03', '', '2024-01-13 18:21:38', b'1');
INSERT INTO `platform_menu` VALUES (1254, '作者动态', '', 1, 0, 0, 'https://gitee.com/jinzheyi/yubb-saas-pro', 'people', NULL, NULL, 0, b'1', b'1', b'1', '1', '2022-04-23 01:03:15', '1', '2024-08-20 23:28:53', b'0');
INSERT INTO `platform_menu` VALUES (1255, '数据源配置', '', 2, 1, 2, 'data-source-config', 'rate', 'infra/dataSourceConfig/index', 'InfraDataSourceConfig', 0, b'1', b'1', b'1', '', '2022-04-27 14:37:32', '1', '2023-04-08 09:05:21', b'0');
INSERT INTO `platform_menu` VALUES (1256, '数据源配置查询', 'infra:data-source-config:query', 3, 1, 1255, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-04-27 14:37:32', '', '2022-04-27 14:37:32', b'0');
INSERT INTO `platform_menu` VALUES (1257, '数据源配置创建', 'infra:data-source-config:create', 3, 2, 1255, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-04-27 14:37:32', '', '2022-04-27 14:37:32', b'0');
INSERT INTO `platform_menu` VALUES (1258, '数据源配置更新', 'infra:data-source-config:update', 3, 3, 1255, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-04-27 14:37:32', '', '2022-04-27 14:37:32', b'0');
INSERT INTO `platform_menu` VALUES (1259, '数据源配置删除', 'infra:data-source-config:delete', 3, 4, 1255, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-04-27 14:37:32', '', '2022-04-27 14:37:32', b'0');
INSERT INTO `platform_menu` VALUES (1260, '数据源配置导出', 'infra:data-source-config:export', 3, 5, 1255, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-04-27 14:37:32', '', '2022-04-27 14:37:32', b'0');
INSERT INTO `platform_menu` VALUES (1261, 'OAuth 2.0', '', 1, 10, 1, 'oauth2', 'people', NULL, NULL, 0, b'1', b'1', b'1', '1', '2022-05-09 23:38:17', '1', '2022-05-11 23:51:46', b'0');
INSERT INTO `platform_menu` VALUES (1263, '应用管理', '', 2, 0, 1261, 'oauth2/application', 'tool', 'system/oauth2/client/index', 'SystemOAuth2Client', 0, b'1', b'1', b'1', '', '2022-05-10 16:26:33', '1', '2023-04-08 08:47:31', b'0');
INSERT INTO `platform_menu` VALUES (1264, '客户端查询', 'system:oauth2-client:query', 3, 1, 1263, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-05-10 16:26:33', '1', '2022-05-11 00:31:06', b'0');
INSERT INTO `platform_menu` VALUES (1265, '客户端创建', 'system:oauth2-client:create', 3, 2, 1263, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-05-10 16:26:33', '1', '2022-05-11 00:31:23', b'0');
INSERT INTO `platform_menu` VALUES (1266, '客户端更新', 'system:oauth2-client:update', 3, 3, 1263, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-05-10 16:26:33', '1', '2022-05-11 00:31:28', b'0');
INSERT INTO `platform_menu` VALUES (1267, '客户端删除', 'system:oauth2-client:delete', 3, 4, 1263, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-05-10 16:26:33', '1', '2022-05-11 00:31:33', b'0');
INSERT INTO `platform_menu` VALUES (1281, '报表管理', '', 1, 40, 0, '/report', 'chart', NULL, NULL, 0, b'1', b'1', b'1', '1', '2022-07-10 20:22:15', '1', '2024-01-13 20:49:15', b'1');
INSERT INTO `platform_menu` VALUES (1282, '报表设计器', '', 2, 1, 1281, 'jimu-report', 'example', 'report/jmreport/index', 'GoView', 0, b'1', b'1', b'1', '1', '2022-07-10 20:26:36', '1', '2024-01-13 20:49:10', b'1');
INSERT INTO `platform_menu` VALUES (2000, '商品中心', '', 1, 60, 2362, 'product', 'fa:product-hunt', NULL, NULL, 0, b'1', b'1', b'1', '', '2022-07-29 15:53:53', '1', '2024-01-13 20:37:20', b'1');
INSERT INTO `platform_menu` VALUES (2002, '商品分类', '', 2, 2, 2000, 'category', 'ep:cellphone', 'mall/product/category/index', 'ProductCategory', 0, b'1', b'1', b'1', '', '2022-07-29 15:53:53', '1', '2024-01-13 20:27:49', b'1');
INSERT INTO `platform_menu` VALUES (2003, '分类查询', 'product:category:query', 3, 1, 2002, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-07-29 15:53:53', '', '2024-01-13 20:27:40', b'1');
INSERT INTO `platform_menu` VALUES (2004, '分类创建', 'product:category:create', 3, 2, 2002, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-07-29 15:53:53', '', '2024-01-13 20:27:37', b'1');
INSERT INTO `platform_menu` VALUES (2005, '分类更新', 'product:category:update', 3, 3, 2002, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-07-29 15:53:53', '', '2024-01-13 20:27:34', b'1');
INSERT INTO `platform_menu` VALUES (2006, '分类删除', 'product:category:delete', 3, 4, 2002, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-07-29 15:53:53', '', '2024-01-13 20:27:31', b'1');
INSERT INTO `platform_menu` VALUES (2008, '商品品牌', '', 2, 3, 2000, 'brand', 'ep:chicken', 'mall/product/brand/index', 'ProductBrand', 0, b'1', b'1', b'1', '', '2022-07-30 13:52:44', '1', '2024-01-13 20:27:26', b'1');
INSERT INTO `platform_menu` VALUES (2009, '品牌查询', 'product:brand:query', 3, 1, 2008, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-07-30 13:52:44', '', '2024-01-13 20:27:23', b'1');
INSERT INTO `platform_menu` VALUES (2010, '品牌创建', 'product:brand:create', 3, 2, 2008, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-07-30 13:52:44', '', '2024-01-13 20:27:20', b'1');
INSERT INTO `platform_menu` VALUES (2011, '品牌更新', 'product:brand:update', 3, 3, 2008, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-07-30 13:52:44', '', '2024-01-13 20:27:17', b'1');
INSERT INTO `platform_menu` VALUES (2012, '品牌删除', 'product:brand:delete', 3, 4, 2008, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-07-30 13:52:44', '', '2024-01-13 20:27:13', b'1');
INSERT INTO `platform_menu` VALUES (2014, '商品列表', '', 2, 1, 2000, 'spu', 'ep:apple', 'mall/product/spu/index', 'ProductSpu', 0, b'1', b'1', b'1', '', '2022-07-30 14:22:58', '1', '2024-01-13 20:37:17', b'1');
INSERT INTO `platform_menu` VALUES (2015, '商品查询', 'product:spu:query', 3, 1, 2014, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-07-30 14:22:58', '', '2024-01-13 20:37:14', b'1');
INSERT INTO `platform_menu` VALUES (2016, '商品创建', 'product:spu:create', 3, 2, 2014, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-07-30 14:22:58', '', '2024-01-13 20:37:12', b'1');
INSERT INTO `platform_menu` VALUES (2017, '商品更新', 'product:spu:update', 3, 3, 2014, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-07-30 14:22:58', '', '2024-01-13 20:37:09', b'1');
INSERT INTO `platform_menu` VALUES (2018, '商品删除', 'product:spu:delete', 3, 4, 2014, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-07-30 14:22:58', '', '2024-01-13 20:37:05', b'1');
INSERT INTO `platform_menu` VALUES (2019, '商品属性', '', 2, 4, 2000, 'property', 'ep:cold-drink', 'mall/product/property/index', 'ProductProperty', 0, b'1', b'1', b'1', '', '2022-08-01 14:55:35', '1', '2024-01-13 20:27:06', b'1');
INSERT INTO `platform_menu` VALUES (2020, '规格查询', 'product:property:query', 3, 1, 2019, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-08-01 14:55:35', '', '2024-01-13 20:27:02', b'1');
INSERT INTO `platform_menu` VALUES (2021, '规格创建', 'product:property:create', 3, 2, 2019, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-08-01 14:55:35', '', '2024-01-13 20:27:00', b'1');
INSERT INTO `platform_menu` VALUES (2022, '规格更新', 'product:property:update', 3, 3, 2019, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-08-01 14:55:35', '', '2024-01-13 20:26:57', b'1');
INSERT INTO `platform_menu` VALUES (2023, '规格删除', 'product:property:delete', 3, 4, 2019, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-08-01 14:55:35', '', '2024-01-13 20:26:54', b'1');
INSERT INTO `platform_menu` VALUES (2025, 'Banner', '', 2, 100, 2387, 'banner', 'fa:bandcamp', 'mall/promotion/banner/index', NULL, 0, b'1', b'1', b'1', '', '2022-08-01 14:56:14', '1', '2024-01-13 20:21:34', b'1');
INSERT INTO `platform_menu` VALUES (2026, 'Banner查询', 'promotion:banner:query', 3, 1, 2025, '', '', '', '', 0, b'1', b'1', b'1', '', '2022-08-01 14:56:14', '1', '2024-01-13 20:21:30', b'1');
INSERT INTO `platform_menu` VALUES (2027, 'Banner创建', 'promotion:banner:create', 3, 2, 2025, '', '', '', '', 0, b'1', b'1', b'1', '', '2022-08-01 14:56:14', '1', '2024-01-13 20:21:26', b'1');
INSERT INTO `platform_menu` VALUES (2028, 'Banner更新', 'promotion:banner:update', 3, 3, 2025, '', '', '', '', 0, b'1', b'1', b'1', '', '2022-08-01 14:56:14', '1', '2024-01-13 20:21:23', b'1');
INSERT INTO `platform_menu` VALUES (2029, 'Banner删除', 'promotion:banner:delete', 3, 4, 2025, '', '', '', '', 0, b'1', b'1', b'1', '', '2022-08-01 14:56:14', '1', '2024-01-13 20:21:20', b'1');
INSERT INTO `platform_menu` VALUES (2030, '营销中心', '', 1, 70, 2362, 'promotion', 'ep:present', NULL, NULL, 0, b'1', b'1', b'1', '1', '2022-10-31 21:25:09', '1', '2024-01-13 20:22:23', b'1');
INSERT INTO `platform_menu` VALUES (2032, '优惠劵列表', '', 2, 1, 2365, 'template', 'ep:discount', 'mall/promotion/coupon/template/index', 'PromotionCouponTemplate', 0, b'1', b'1', b'1', '', '2022-10-31 22:27:14', '1', '2024-01-13 20:21:08', b'1');
INSERT INTO `platform_menu` VALUES (2033, '优惠劵模板查询', 'promotion:coupon-template:query', 3, 1, 2032, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-10-31 22:27:14', '', '2024-01-13 20:21:05', b'1');
INSERT INTO `platform_menu` VALUES (2034, '优惠劵模板创建', 'promotion:coupon-template:create', 3, 2, 2032, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-10-31 22:27:14', '', '2024-01-13 20:21:01', b'1');
INSERT INTO `platform_menu` VALUES (2035, '优惠劵模板更新', 'promotion:coupon-template:update', 3, 3, 2032, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-10-31 22:27:14', '', '2024-01-13 20:20:58', b'1');
INSERT INTO `platform_menu` VALUES (2036, '优惠劵模板删除', 'promotion:coupon-template:delete', 3, 4, 2032, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-10-31 22:27:14', '', '2024-01-13 20:20:54', b'1');
INSERT INTO `platform_menu` VALUES (2038, '领取记录', '', 2, 2, 2365, 'list', 'ep:collection-tag', 'mall/promotion/coupon/index', 'PromotionCoupon', 0, b'1', b'1', b'1', '', '2022-11-03 23:21:31', '1', '2024-01-13 20:20:43', b'1');
INSERT INTO `platform_menu` VALUES (2039, '优惠劵查询', 'promotion:coupon:query', 3, 1, 2038, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-11-03 23:21:31', '', '2024-01-13 20:20:38', b'1');
INSERT INTO `platform_menu` VALUES (2040, '优惠劵删除', 'promotion:coupon:delete', 3, 4, 2038, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-11-03 23:21:31', '', '2024-01-13 20:20:30', b'1');
INSERT INTO `platform_menu` VALUES (2041, '满减送', '', 2, 10, 2390, 'reward-activity', 'ep:goblet-square-full', 'mall/promotion/rewardActivity/index', 'PromotionRewardActivity', 0, b'1', b'1', b'1', '', '2022-11-04 23:47:49', '1', '2024-01-13 20:13:49', b'1');
INSERT INTO `platform_menu` VALUES (2042, '满减送活动查询', 'promotion:reward-activity:query', 3, 1, 2041, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-11-04 23:47:49', '', '2024-01-13 20:13:44', b'1');
INSERT INTO `platform_menu` VALUES (2043, '满减送活动创建', 'promotion:reward-activity:create', 3, 2, 2041, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-11-04 23:47:49', '', '2024-01-13 20:13:40', b'1');
INSERT INTO `platform_menu` VALUES (2044, '满减送活动更新', 'promotion:reward-activity:update', 3, 3, 2041, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-11-04 23:47:50', '', '2024-01-13 20:13:21', b'1');
INSERT INTO `platform_menu` VALUES (2045, '满减送活动删除', 'promotion:reward-activity:delete', 3, 4, 2041, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-11-04 23:47:50', '', '2024-01-13 20:13:17', b'1');
INSERT INTO `platform_menu` VALUES (2046, '满减送活动关闭', 'promotion:reward-activity:close', 3, 5, 2041, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2022-11-05 10:42:53', '1', '2024-01-13 20:13:14', b'1');
INSERT INTO `platform_menu` VALUES (2047, '限时折扣', '', 2, 7, 2390, 'discount-activity', 'ep:timer', 'mall/promotion/discountActivity/index', 'PromotionDiscountActivity', 0, b'1', b'1', b'1', '', '2022-11-05 17:12:15', '1', '2024-01-13 20:14:12', b'1');
INSERT INTO `platform_menu` VALUES (2048, '限时折扣活动查询', 'promotion:discount-activity:query', 3, 1, 2047, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-11-05 17:12:15', '', '2024-01-13 20:14:07', b'1');
INSERT INTO `platform_menu` VALUES (2049, '限时折扣活动创建', 'promotion:discount-activity:create', 3, 2, 2047, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-11-05 17:12:15', '', '2024-01-13 20:14:03', b'1');
INSERT INTO `platform_menu` VALUES (2050, '限时折扣活动更新', 'promotion:discount-activity:update', 3, 3, 2047, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-11-05 17:12:16', '', '2024-01-13 20:14:00', b'1');
INSERT INTO `platform_menu` VALUES (2051, '限时折扣活动删除', 'promotion:discount-activity:delete', 3, 4, 2047, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-11-05 17:12:16', '', '2024-01-13 20:13:56', b'1');
INSERT INTO `platform_menu` VALUES (2052, '限时折扣活动关闭', 'promotion:discount-activity:close', 3, 5, 2047, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-11-05 17:12:16', '', '2024-01-13 20:13:52', b'1');
INSERT INTO `platform_menu` VALUES (2059, '秒杀商品', '', 2, 2, 2209, 'activity', 'ep:basketball', 'mall/promotion/seckill/activity/index', 'PromotionSeckillActivity', 0, b'1', b'1', b'1', '', '2022-11-06 22:24:49', '1', '2024-01-13 20:19:31', b'1');
INSERT INTO `platform_menu` VALUES (2060, '秒杀活动查询', 'promotion:seckill-activity:query', 3, 1, 2059, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-11-06 22:24:49', '', '2024-01-13 20:19:22', b'1');
INSERT INTO `platform_menu` VALUES (2061, '秒杀活动创建', 'promotion:seckill-activity:create', 3, 2, 2059, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-11-06 22:24:49', '', '2024-01-13 20:19:19', b'1');
INSERT INTO `platform_menu` VALUES (2062, '秒杀活动更新', 'promotion:seckill-activity:update', 3, 3, 2059, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-11-06 22:24:49', '', '2024-01-13 20:19:16', b'1');
INSERT INTO `platform_menu` VALUES (2063, '秒杀活动删除', 'promotion:seckill-activity:delete', 3, 4, 2059, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-11-06 22:24:49', '', '2024-01-13 20:19:13', b'1');
INSERT INTO `platform_menu` VALUES (2066, '秒杀时段', '', 2, 1, 2209, 'config', 'ep:baseball', 'mall/promotion/seckill/config/index', 'PromotionSeckillConfig', 0, b'1', b'1', b'1', '', '2022-11-15 19:46:50', '1', '2024-01-13 20:19:58', b'1');
INSERT INTO `platform_menu` VALUES (2067, '秒杀时段查询', 'promotion:seckill-config:query', 3, 1, 2066, '', '', '', '', 0, b'1', b'1', b'1', '', '2022-11-15 19:46:51', '1', '2024-01-13 20:19:54', b'1');
INSERT INTO `platform_menu` VALUES (2068, '秒杀时段创建', 'promotion:seckill-config:create', 3, 2, 2066, '', '', '', '', 0, b'1', b'1', b'1', '', '2022-11-15 19:46:51', '1', '2024-01-13 20:19:51', b'1');
INSERT INTO `platform_menu` VALUES (2069, '秒杀时段更新', 'promotion:seckill-config:update', 3, 3, 2066, '', '', '', '', 0, b'1', b'1', b'1', '', '2022-11-15 19:46:51', '1', '2024-01-13 20:19:37', b'1');
INSERT INTO `platform_menu` VALUES (2070, '秒杀时段删除', 'promotion:seckill-config:delete', 3, 4, 2066, '', '', '', '', 0, b'1', b'1', b'1', '', '2022-11-15 19:46:51', '1', '2024-01-13 20:19:34', b'1');
INSERT INTO `platform_menu` VALUES (2072, '订单中心', '', 1, 65, 2362, 'trade', 'ep:eleme', NULL, NULL, 0, b'1', b'1', b'1', '1', '2022-11-19 18:57:19', '1', '2024-01-13 20:26:23', b'1');
INSERT INTO `platform_menu` VALUES (2073, '售后退款', '', 2, 2, 2072, 'after-sale', 'ep:refrigerator', 'mall/trade/afterSale/index', 'TradeAfterSale', 0, b'1', b'1', b'1', '', '2022-11-19 20:15:32', '1', '2024-01-13 20:25:52', b'1');
INSERT INTO `platform_menu` VALUES (2074, '售后查询', 'trade:after-sale:query', 3, 1, 2073, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-11-19 20:15:33', '1', '2024-01-13 20:25:49', b'1');
INSERT INTO `platform_menu` VALUES (2075, '秒杀活动关闭', 'promotion:seckill-activity:close', 3, 5, 2059, '', '', '', '', 0, b'1', b'1', b'1', '1', '2022-11-28 20:20:15', '1', '2024-01-13 20:19:01', b'1');
INSERT INTO `platform_menu` VALUES (2076, '订单列表', '', 2, 1, 2072, 'order', 'ep:list', 'mall/trade/order/index', 'TradeOrder', 0, b'1', b'1', b'1', '1', '2022-12-10 21:05:44', '1', '2024-01-13 20:26:05', b'1');
INSERT INTO `platform_menu` VALUES (2083, '地区管理', '', 2, 14, 1, 'area', 'row', 'system/area/index', 'SystemArea', 0, b'1', b'1', b'1', '1', '2022-12-23 17:35:05', '1', '2024-01-13 18:22:06', b'1');
INSERT INTO `platform_menu` VALUES (2084, '公众号管理', '', 1, 100, 0, '/mp', 'wechat', NULL, NULL, 0, b'1', b'1', b'1', '1', '2023-01-01 20:11:04', '1', '2024-01-13 20:12:25', b'1');
INSERT INTO `platform_menu` VALUES (2085, '账号管理', '', 2, 1, 2084, 'account', 'phone', 'mp/account/index', 'MpAccount', 0, b'1', b'1', b'1', '1', '2023-01-01 20:13:31', '1', '2024-01-13 20:12:21', b'1');
INSERT INTO `platform_menu` VALUES (2086, '新增账号', 'mp:account:create', 3, 1, 2085, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2023-01-01 20:21:40', '1', '2024-01-13 20:12:14', b'1');
INSERT INTO `platform_menu` VALUES (2087, '修改账号', 'mp:account:update', 3, 2, 2085, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2023-01-07 17:32:46', '1', '2024-01-13 20:12:11', b'1');
INSERT INTO `platform_menu` VALUES (2088, '查询账号', 'mp:account:query', 3, 0, 2085, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2023-01-07 17:33:07', '1', '2024-01-13 20:12:17', b'1');
INSERT INTO `platform_menu` VALUES (2089, '删除账号', 'mp:account:delete', 3, 3, 2085, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2023-01-07 17:33:21', '1', '2024-01-13 20:12:07', b'1');
INSERT INTO `platform_menu` VALUES (2090, '生成二维码', 'mp:account:qr-code', 3, 4, 2085, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2023-01-07 17:33:58', '1', '2024-01-13 20:12:04', b'1');
INSERT INTO `platform_menu` VALUES (2091, '清空 API 配额', 'mp:account:clear-quota', 3, 5, 2085, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2023-01-07 18:20:32', '1', '2024-01-13 20:12:00', b'1');
INSERT INTO `platform_menu` VALUES (2092, '数据统计', 'mp:statistics:query', 2, 2, 2084, 'statistics', 'chart', 'mp/statistics/index', 'MpStatistics', 0, b'1', b'1', b'1', '1', '2023-01-07 20:17:36', '1', '2024-01-13 20:11:48', b'1');
INSERT INTO `platform_menu` VALUES (2093, '标签管理', '', 2, 3, 2084, 'tag', 'rate', 'mp/tag/index', 'MpTag', 0, b'1', b'1', b'1', '1', '2023-01-08 11:37:32', '1', '2024-01-13 20:11:45', b'1');
INSERT INTO `platform_menu` VALUES (2094, '查询标签', 'mp:tag:query', 3, 0, 2093, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2023-01-08 11:59:03', '1', '2024-01-13 20:11:42', b'1');
INSERT INTO `platform_menu` VALUES (2095, '新增标签', 'mp:tag:create', 3, 1, 2093, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2023-01-08 11:59:23', '1', '2024-01-13 20:11:38', b'1');
INSERT INTO `platform_menu` VALUES (2096, '修改标签', 'mp:tag:update', 3, 2, 2093, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2023-01-08 11:59:41', '1', '2024-01-13 20:11:34', b'1');
INSERT INTO `platform_menu` VALUES (2097, '删除标签', 'mp:tag:delete', 3, 3, 2093, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2023-01-08 12:00:04', '1', '2024-01-13 20:11:29', b'1');
INSERT INTO `platform_menu` VALUES (2098, '同步标签', 'mp:tag:sync', 3, 4, 2093, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2023-01-08 12:00:29', '1', '2024-01-13 20:11:26', b'1');
INSERT INTO `platform_menu` VALUES (2099, '粉丝管理', '', 2, 4, 2084, 'user', 'people', 'mp/user/index', 'MpUser', 0, b'1', b'1', b'1', '1', '2023-01-08 16:51:20', '1', '2024-01-13 20:11:19', b'1');
INSERT INTO `platform_menu` VALUES (2100, '查询粉丝', 'mp:user:query', 3, 0, 2099, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2023-01-08 17:16:59', '1', '2024-01-13 20:11:15', b'1');
INSERT INTO `platform_menu` VALUES (2101, '修改粉丝', 'mp:user:update', 3, 1, 2099, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2023-01-08 17:17:11', '1', '2024-01-13 20:11:12', b'1');
INSERT INTO `platform_menu` VALUES (2102, '同步粉丝', 'mp:user:sync', 3, 2, 2099, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2023-01-08 17:17:40', '1', '2024-01-13 18:59:09', b'1');
INSERT INTO `platform_menu` VALUES (2103, '消息管理', '', 2, 5, 2084, 'message', 'email', 'mp/message/index', 'MpMessage', 0, b'1', b'1', b'1', '1', '2023-01-08 18:44:19', '1', '2024-01-13 18:59:04', b'1');
INSERT INTO `platform_menu` VALUES (2104, '图文发表记录', '', 2, 10, 2084, 'free-publish', 'education', 'mp/freePublish/index', 'MpFreePublish', 0, b'1', b'1', b'1', '1', '2023-01-13 00:30:50', '1', '2024-01-13 18:57:27', b'1');
INSERT INTO `platform_menu` VALUES (2105, '查询发布列表', 'mp:free-publish:query', 3, 1, 2104, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2023-01-13 07:19:17', '1', '2024-01-13 18:57:24', b'1');
INSERT INTO `platform_menu` VALUES (2106, '发布草稿', 'mp:free-publish:submit', 3, 2, 2104, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2023-01-13 07:19:46', '1', '2024-01-13 18:57:21', b'1');
INSERT INTO `platform_menu` VALUES (2107, '删除发布记录', 'mp:free-publish:delete', 3, 3, 2104, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2023-01-13 07:20:01', '1', '2024-01-13 18:57:18', b'1');
INSERT INTO `platform_menu` VALUES (2108, '图文草稿箱', '', 2, 9, 2084, 'draft', 'edit', 'mp/draft/index', 'MpDraft', 0, b'1', b'1', b'1', '1', '2023-01-13 07:40:21', '1', '2024-01-13 18:57:48', b'1');
INSERT INTO `platform_menu` VALUES (2109, '新建草稿', 'mp:draft:create', 3, 1, 2108, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2023-01-13 23:15:30', '1', '2024-01-13 18:57:41', b'1');
INSERT INTO `platform_menu` VALUES (2110, '修改草稿', 'mp:draft:update', 3, 2, 2108, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2023-01-14 10:08:47', '1', '2024-01-13 18:57:38', b'1');
INSERT INTO `platform_menu` VALUES (2111, '查询草稿', 'mp:draft:query', 3, 0, 2108, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2023-01-14 10:09:01', '1', '2024-01-13 18:57:44', b'1');
INSERT INTO `platform_menu` VALUES (2112, '删除草稿', 'mp:draft:delete', 3, 3, 2108, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2023-01-14 10:09:19', '1', '2024-01-13 18:57:34', b'1');
INSERT INTO `platform_menu` VALUES (2113, '素材管理', '', 2, 8, 2084, 'material', 'skill', 'mp/material/index', 'MpMaterial', 0, b'1', b'1', b'1', '1', '2023-01-14 14:12:07', '1', '2024-01-13 18:58:10', b'1');
INSERT INTO `platform_menu` VALUES (2114, '上传临时素材', 'mp:material:upload-temporary', 3, 1, 2113, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2023-01-14 15:33:55', '1', '2024-01-13 18:58:06', b'1');
INSERT INTO `platform_menu` VALUES (2115, '上传永久素材', 'mp:material:upload-permanent', 3, 2, 2113, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2023-01-14 15:34:14', '1', '2024-01-13 18:58:03', b'1');
INSERT INTO `platform_menu` VALUES (2116, '删除素材', 'mp:material:delete', 3, 3, 2113, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2023-01-14 15:35:37', '1', '2024-01-13 18:58:00', b'1');
INSERT INTO `platform_menu` VALUES (2117, '上传图文图片', 'mp:material:upload-news-image', 3, 4, 2113, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2023-01-14 15:36:31', '1', '2024-01-13 18:57:57', b'1');
INSERT INTO `platform_menu` VALUES (2118, '查询素材', 'mp:material:query', 3, 5, 2113, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2023-01-14 15:39:22', '1', '2024-01-13 18:57:54', b'1');
INSERT INTO `platform_menu` VALUES (2119, '菜单管理', '', 2, 6, 2084, 'menu', 'button', 'mp/menu/index', 'MpMenu', 0, b'1', b'1', b'1', '1', '2023-01-14 17:43:54', '1', '2024-01-13 18:58:50', b'1');
INSERT INTO `platform_menu` VALUES (2120, '自动回复', '', 2, 7, 2084, 'auto-reply', 'eye', 'mp/autoReply/index', 'MpAutoReply', 0, b'1', b'1', b'1', '1', '2023-01-15 22:13:09', '1', '2024-01-13 18:58:27', b'1');
INSERT INTO `platform_menu` VALUES (2121, '查询回复', 'mp:auto-reply:query', 3, 0, 2120, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2023-01-16 22:28:41', '1', '2024-01-13 18:58:24', b'1');
INSERT INTO `platform_menu` VALUES (2122, '新增回复', 'mp:auto-reply:create', 3, 1, 2120, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2023-01-16 22:28:54', '1', '2024-01-13 18:58:21', b'1');
INSERT INTO `platform_menu` VALUES (2123, '修改回复', 'mp:auto-reply:update', 3, 2, 2120, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2023-01-16 22:29:05', '1', '2024-01-13 18:58:18', b'1');
INSERT INTO `platform_menu` VALUES (2124, '删除回复', 'mp:auto-reply:delete', 3, 3, 2120, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2023-01-16 22:29:34', '1', '2024-01-13 18:58:15', b'1');
INSERT INTO `platform_menu` VALUES (2125, '查询菜单', 'mp:menu:query', 3, 0, 2119, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2023-01-17 23:05:41', '1', '2024-01-13 18:58:41', b'1');
INSERT INTO `platform_menu` VALUES (2126, '保存菜单', 'mp:menu:save', 3, 1, 2119, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2023-01-17 23:06:01', '1', '2024-01-13 18:58:38', b'1');
INSERT INTO `platform_menu` VALUES (2127, '删除菜单', 'mp:menu:delete', 3, 2, 2119, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2023-01-17 23:06:16', '1', '2024-01-13 18:58:34', b'1');
INSERT INTO `platform_menu` VALUES (2128, '查询消息', 'mp:message:query', 3, 0, 2103, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2023-01-17 23:07:14', '1', '2024-01-13 18:59:00', b'1');
INSERT INTO `platform_menu` VALUES (2129, '发送消息', 'mp:message:send', 3, 1, 2103, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2023-01-17 23:07:26', '1', '2024-01-13 18:58:57', b'1');
INSERT INTO `platform_menu` VALUES (2130, '邮箱管理', '', 2, 11, 1, 'mail', 'email', NULL, NULL, 0, b'1', b'1', b'1', '1', '2023-01-25 17:27:44', '1', '2024-04-02 22:01:49', b'0');
INSERT INTO `platform_menu` VALUES (2131, '邮箱账号', '', 2, 0, 2130, 'mail-account', 'user', 'system/mail/account/index', 'SystemMailAccount', 0, b'1', b'1', b'1', '', '2023-01-25 09:33:48', '1', '2024-04-02 22:01:49', b'0');
INSERT INTO `platform_menu` VALUES (2132, '账号查询', 'system:mail-account:query', 3, 1, 2131, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-01-25 09:33:48', '', '2024-04-02 22:01:49', b'0');
INSERT INTO `platform_menu` VALUES (2133, '账号创建', 'system:mail-account:create', 3, 2, 2131, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-01-25 09:33:48', '', '2024-04-02 22:01:49', b'0');
INSERT INTO `platform_menu` VALUES (2134, '账号更新', 'system:mail-account:update', 3, 3, 2131, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-01-25 09:33:48', '', '2024-04-02 22:01:49', b'0');
INSERT INTO `platform_menu` VALUES (2135, '账号删除', 'system:mail-account:delete', 3, 4, 2131, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-01-25 09:33:48', '', '2024-04-02 22:01:49', b'0');
INSERT INTO `platform_menu` VALUES (2136, '邮件模版', '', 2, 0, 2130, 'mail-template', 'education', 'system/mail/template/index', 'SystemMailTemplate', 0, b'1', b'1', b'1', '', '2023-01-25 12:05:31', '1', '2024-04-02 22:01:49', b'0');
INSERT INTO `platform_menu` VALUES (2137, '模版查询', 'system:mail-template:query', 3, 1, 2136, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-01-25 12:05:31', '', '2024-04-02 22:01:49', b'0');
INSERT INTO `platform_menu` VALUES (2138, '模版创建', 'system:mail-template:create', 3, 2, 2136, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-01-25 12:05:31', '', '2024-04-02 22:01:49', b'0');
INSERT INTO `platform_menu` VALUES (2139, '模版更新', 'system:mail-template:update', 3, 3, 2136, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-01-25 12:05:31', '', '2024-04-02 22:01:49', b'0');
INSERT INTO `platform_menu` VALUES (2140, '模版删除', 'system:mail-template:delete', 3, 4, 2136, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-01-25 12:05:31', '', '2024-04-02 22:01:49', b'0');
INSERT INTO `platform_menu` VALUES (2141, '邮件记录', '', 2, 0, 2130, 'mail-log', 'log', 'system/mail/log/index', 'SystemMailLog', 0, b'1', b'1', b'1', '', '2023-01-26 02:16:50', '1', '2024-04-02 22:01:49', b'0');
INSERT INTO `platform_menu` VALUES (2142, '日志查询', 'system:mail-log:query', 3, 1, 2141, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-01-26 02:16:50', '', '2024-04-02 22:01:49', b'0');
INSERT INTO `platform_menu` VALUES (2143, '发送测试邮件', 'system:mail-template:send-mail', 3, 5, 2136, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2023-01-26 23:29:15', '1', '2024-04-02 22:01:49', b'0');
INSERT INTO `platform_menu` VALUES (2144, '站内信管理', '', 1, 11, 1, 'notify', 'message', NULL, NULL, 0, b'1', b'1', b'1', '1', '2023-01-28 10:25:18', '1', '2024-01-13 18:21:18', b'1');
INSERT INTO `platform_menu` VALUES (2145, '模板管理', '', 2, 0, 2144, 'notify-template', 'education', 'system/notify/template/index', 'SystemNotifyTemplate', 0, b'1', b'1', b'1', '', '2023-01-28 02:26:42', '1', '2024-01-13 18:19:22', b'1');
INSERT INTO `platform_menu` VALUES (2146, '站内信模板查询', 'system:notify-template:query', 3, 1, 2145, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-01-28 02:26:42', '', '2024-01-13 18:19:13', b'1');
INSERT INTO `platform_menu` VALUES (2147, '站内信模板创建', 'system:notify-template:create', 3, 2, 2145, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-01-28 02:26:42', '', '2024-01-13 18:19:09', b'1');
INSERT INTO `platform_menu` VALUES (2148, '站内信模板更新', 'system:notify-template:update', 3, 3, 2145, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-01-28 02:26:42', '', '2024-01-13 18:19:05', b'1');
INSERT INTO `platform_menu` VALUES (2149, '站内信模板删除', 'system:notify-template:delete', 3, 4, 2145, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-01-28 02:26:42', '', '2024-01-13 18:19:01', b'1');
INSERT INTO `platform_menu` VALUES (2150, '发送测试站内信', 'system:notify-template:send-notify', 3, 5, 2145, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2023-01-28 10:54:43', '1', '2024-01-13 18:18:57', b'1');
INSERT INTO `platform_menu` VALUES (2151, '消息记录', '', 2, 0, 2144, 'notify-message', 'edit', 'system/notify/message/index', 'SystemNotifyMessage', 0, b'1', b'1', b'1', '', '2023-01-28 04:28:22', '1', '2024-01-13 18:19:18', b'1');
INSERT INTO `platform_menu` VALUES (2152, '站内信消息查询', 'system:notify-message:query', 3, 1, 2151, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-01-28 04:28:22', '', '2024-01-13 18:18:31', b'1');
INSERT INTO `platform_menu` VALUES (2153, '大屏设计器', '', 2, 2, 1281, 'go-view', 'dashboard', 'report/goview/index', 'JimuReport', 0, b'1', b'1', b'1', '1', '2023-02-07 00:03:19', '1', '2024-01-13 20:49:07', b'1');
INSERT INTO `platform_menu` VALUES (2154, '创建项目', 'report:go-view-project:create', 3, 1, 2153, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2023-02-07 19:25:14', '1', '2024-01-13 20:49:01', b'1');
INSERT INTO `platform_menu` VALUES (2155, '更新项目', 'report:go-view-project:delete', 3, 2, 2153, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2023-02-07 19:25:34', '1', '2024-01-13 20:48:58', b'1');
INSERT INTO `platform_menu` VALUES (2156, '查询项目', 'report:go-view-project:query', 3, 0, 2153, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2023-02-07 19:25:53', '1', '2024-01-13 20:49:04', b'1');
INSERT INTO `platform_menu` VALUES (2157, '使用 SQL 查询数据', 'report:go-view-data:get-by-sql', 3, 3, 2153, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2023-02-07 19:26:15', '1', '2024-01-13 20:48:54', b'1');
INSERT INTO `platform_menu` VALUES (2158, '使用 HTTP 查询数据', 'report:go-view-data:get-by-http', 3, 4, 2153, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2023-02-07 19:26:35', '1', '2024-01-13 20:48:51', b'1');
INSERT INTO `platform_menu` VALUES (2159, '开发文档', '', 1, 1, 0, 'http://www.shengyukj.top', 'education', NULL, NULL, 0, b'1', b'1', b'1', '1', '2023-02-10 22:46:28', '1', '2024-08-20 23:29:40', b'0');
INSERT INTO `platform_menu` VALUES (2160, 'Cloud 开发文档', '', 1, 2, 0, 'https://cloud.iocoder.cn', 'documentation', NULL, NULL, 0, b'1', b'1', b'1', '1', '2023-02-10 22:47:07', '1', '2024-08-20 23:29:44', b'1');
INSERT INTO `platform_menu` VALUES (2161, '接入示例', '', 2, 99, 1117, 'demo-order', 'drag', 'pay/demo/index', NULL, 0, b'1', b'1', b'1', '', '2023-02-11 14:21:42', '1', '2024-01-13 18:36:31', b'1');
INSERT INTO `platform_menu` VALUES (2162, '商品导出', 'product:spu:export', 3, 5, 2014, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2022-07-30 14:22:58', '', '2024-01-13 20:37:02', b'1');
INSERT INTO `platform_menu` VALUES (2164, '配送管理', '', 1, 3, 2072, 'delivery', 'ep:shopping-cart', '', '', 0, b'1', b'1', b'1', '1', '2023-05-18 09:18:02', '1', '2024-01-13 20:25:42', b'1');
INSERT INTO `platform_menu` VALUES (2165, '快递发货', '', 1, 0, 2164, 'express', 'ep:bicycle', '', '', 0, b'1', b'1', b'1', '1', '2023-05-18 09:22:06', '1', '2024-01-13 20:25:37', b'1');
INSERT INTO `platform_menu` VALUES (2166, '门店自提', '', 1, 1, 2164, 'pick-up-store', 'ep:add-location', '', '', 0, b'1', b'1', b'1', '1', '2023-05-18 09:23:14', '1', '2024-01-13 20:24:41', b'1');
INSERT INTO `platform_menu` VALUES (2167, '快递公司', '', 2, 0, 2165, 'express', 'ep:compass', 'mall/trade/delivery/express/index', 'Express', 0, b'1', b'1', b'1', '1', '2023-05-18 09:27:21', '1', '2024-01-13 20:25:34', b'1');
INSERT INTO `platform_menu` VALUES (2168, '快递公司查询', 'trade:delivery:express:query', 3, 1, 2167, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-05-18 09:37:53', '', '2024-01-13 20:25:29', b'1');
INSERT INTO `platform_menu` VALUES (2169, '快递公司创建', 'trade:delivery:express:create', 3, 2, 2167, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-05-18 09:37:53', '', '2024-01-13 20:25:25', b'1');
INSERT INTO `platform_menu` VALUES (2170, '快递公司更新', 'trade:delivery:express:update', 3, 3, 2167, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-05-18 09:37:53', '', '2024-01-13 20:25:22', b'1');
INSERT INTO `platform_menu` VALUES (2171, '快递公司删除', 'trade:delivery:express:delete', 3, 4, 2167, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-05-18 09:37:53', '', '2024-01-13 20:25:18', b'1');
INSERT INTO `platform_menu` VALUES (2172, '快递公司导出', 'trade:delivery:express:export', 3, 5, 2167, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-05-18 09:37:53', '', '2024-01-13 20:25:14', b'1');
INSERT INTO `platform_menu` VALUES (2173, '运费模版', 'trade:delivery:express-template:query', 2, 1, 2165, 'express-template', 'ep:coordinate', 'mall/trade/delivery/expressTemplate/index', 'ExpressTemplate', 0, b'1', b'1', b'1', '1', '2023-05-20 06:48:10', '1', '2024-01-13 20:25:08', b'1');
INSERT INTO `platform_menu` VALUES (2174, '快递运费模板查询', 'trade:delivery:express-template:query', 3, 1, 2173, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-05-20 06:49:53', '', '2024-01-13 20:25:05', b'1');
INSERT INTO `platform_menu` VALUES (2175, '快递运费模板创建', 'trade:delivery:express-template:create', 3, 2, 2173, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-05-20 06:49:53', '', '2024-01-13 20:25:02', b'1');
INSERT INTO `platform_menu` VALUES (2176, '快递运费模板更新', 'trade:delivery:express-template:update', 3, 3, 2173, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-05-20 06:49:53', '', '2024-01-13 20:24:59', b'1');
INSERT INTO `platform_menu` VALUES (2177, '快递运费模板删除', 'trade:delivery:express-template:delete', 3, 4, 2173, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-05-20 06:49:53', '', '2024-01-13 20:24:56', b'1');
INSERT INTO `platform_menu` VALUES (2178, '快递运费模板导出', 'trade:delivery:express-template:export', 3, 5, 2173, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-05-20 06:49:53', '', '2024-01-13 20:24:53', b'1');
INSERT INTO `platform_menu` VALUES (2179, '门店管理', '', 2, 1, 2166, 'pick-up-store', 'ep:basketball', 'mall/trade/delivery/pickUpStore/index', 'PickUpStore', 0, b'1', b'1', b'1', '1', '2023-05-25 10:50:00', '1', '2024-01-13 20:24:37', b'1');
INSERT INTO `platform_menu` VALUES (2180, '自提门店查询', 'trade:delivery:pick-up-store:query', 3, 1, 2179, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-05-25 10:53:29', '', '2024-01-13 20:24:33', b'1');
INSERT INTO `platform_menu` VALUES (2181, '自提门店创建', 'trade:delivery:pick-up-store:create', 3, 2, 2179, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-05-25 10:53:29', '', '2024-01-13 20:24:30', b'1');
INSERT INTO `platform_menu` VALUES (2182, '自提门店更新', 'trade:delivery:pick-up-store:update', 3, 3, 2179, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-05-25 10:53:29', '', '2024-01-13 20:24:27', b'1');
INSERT INTO `platform_menu` VALUES (2183, '自提门店删除', 'trade:delivery:pick-up-store:delete', 3, 4, 2179, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-05-25 10:53:29', '', '2024-01-13 20:23:58', b'1');
INSERT INTO `platform_menu` VALUES (2184, '自提门店导出', 'trade:delivery:pick-up-store:export', 3, 5, 2179, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-05-25 10:53:29', '', '2024-01-13 20:23:55', b'1');
INSERT INTO `platform_menu` VALUES (2209, '秒杀活动', '', 2, 3, 2030, 'seckill', 'ep:place', '', '', 0, b'1', b'1', b'1', '1', '2023-06-24 17:39:13', '1', '2024-01-13 20:20:01', b'1');
INSERT INTO `platform_menu` VALUES (2262, '会员中心', '', 1, 55, 0, '/member', 'ep:bicycle', NULL, NULL, 0, b'1', b'1', b'1', '1', '2023-06-10 00:42:03', '1', '2024-01-13 20:43:02', b'1');
INSERT INTO `platform_menu` VALUES (2275, '会员配置', '', 2, 0, 2262, 'config', 'fa:archive', 'member/config/index', 'MemberConfig', 0, b'1', b'1', b'1', '', '2023-06-10 02:07:44', '1', '2024-01-13 20:41:09', b'1');
INSERT INTO `platform_menu` VALUES (2276, '积分设置查询', 'point:config:query', 3, 1, 2275, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-06-10 02:07:44', '', '2024-01-13 20:41:05', b'1');
INSERT INTO `platform_menu` VALUES (2277, '积分设置创建', 'point:config:save', 3, 2, 2275, '', '', '', '', 0, b'1', b'1', b'1', '', '2023-06-10 02:07:44', '1', '2024-01-13 20:41:02', b'1');
INSERT INTO `platform_menu` VALUES (2281, '签到配置', '', 2, 2, 2300, 'config', 'ep:calendar', 'member/signin/config/index', 'SignInConfig', 0, b'1', b'1', b'1', '', '2023-06-10 03:26:12', '1', '2024-01-13 20:38:12', b'1');
INSERT INTO `platform_menu` VALUES (2282, '积分签到规则查询', 'point:sign-in-config:query', 3, 1, 2281, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-06-10 03:26:12', '', '2024-01-13 20:38:09', b'1');
INSERT INTO `platform_menu` VALUES (2283, '积分签到规则创建', 'point:sign-in-config:create', 3, 2, 2281, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-06-10 03:26:12', '', '2024-01-13 20:38:06', b'1');
INSERT INTO `platform_menu` VALUES (2284, '积分签到规则更新', 'point:sign-in-config:update', 3, 3, 2281, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-06-10 03:26:12', '', '2024-01-13 20:38:02', b'1');
INSERT INTO `platform_menu` VALUES (2285, '积分签到规则删除', 'point:sign-in-config:delete', 3, 4, 2281, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-06-10 03:26:12', '', '2024-01-13 20:37:59', b'1');
INSERT INTO `platform_menu` VALUES (2287, '会员积分', '', 2, 10, 2262, 'record', 'fa:asterisk', 'member/point/record/index', 'PointRecord', 0, b'1', b'1', b'1', '', '2023-06-10 04:18:50', '1', '2024-01-13 20:38:28', b'1');
INSERT INTO `platform_menu` VALUES (2288, '用户积分记录查询', 'point:record:query', 3, 1, 2287, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-06-10 04:18:50', '', '2024-01-13 20:38:25', b'1');
INSERT INTO `platform_menu` VALUES (2293, '签到记录', '', 2, 3, 2300, 'record', 'ep:chicken', 'member/signin/record/index', 'SignInRecord', 0, b'1', b'1', b'1', '', '2023-06-10 04:48:22', '1', '2024-01-13 20:37:56', b'1');
INSERT INTO `platform_menu` VALUES (2294, '用户签到积分查询', 'point:sign-in-record:query', 3, 1, 2293, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-06-10 04:48:22', '', '2024-01-13 20:37:52', b'1');
INSERT INTO `platform_menu` VALUES (2297, '用户签到积分删除', 'point:sign-in-record:delete', 3, 4, 2293, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-06-10 04:48:22', '', '2024-01-13 20:37:41', b'1');
INSERT INTO `platform_menu` VALUES (2300, '会员签到', '', 1, 11, 2262, 'signin', 'ep:alarm-clock', '', '', 0, b'1', b'1', b'1', '1', '2023-06-27 22:49:53', '1', '2024-01-13 20:38:15', b'1');
INSERT INTO `platform_menu` VALUES (2301, '回调通知', '', 2, 4, 1117, 'notify', 'example', 'pay/notify/index', 'PayNotify', 0, b'1', b'1', b'1', '', '2023-07-20 04:41:32', '1', '2024-01-13 18:37:24', b'1');
INSERT INTO `platform_menu` VALUES (2302, '支付通知查询', 'pay:notify:query', 3, 1, 2301, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-07-20 04:41:32', '', '2024-01-13 18:36:59', b'1');
INSERT INTO `platform_menu` VALUES (2303, '拼团活动', '', 2, 3, 2030, 'combination', 'fa:group', '', '', 0, b'1', b'1', b'1', '1', '2023-08-12 17:19:54', '1', '2024-01-13 20:18:50', b'1');
INSERT INTO `platform_menu` VALUES (2304, '拼团商品', '', 2, 1, 2303, 'acitivity', 'ep:apple', 'mall/promotion/combination/activity/index', 'PromotionCombinationActivity', 0, b'1', b'1', b'1', '1', '2023-08-12 17:22:03', '1', '2024-01-13 20:18:47', b'1');
INSERT INTO `platform_menu` VALUES (2305, '拼团活动查询', 'promotion:combination-activity:query', 3, 1, 2304, '', '', '', '', 0, b'1', b'1', b'1', '1', '2023-08-12 17:54:32', '1', '2024-01-13 20:18:43', b'1');
INSERT INTO `platform_menu` VALUES (2306, '拼团活动创建', 'promotion:combination-activity:create', 3, 2, 2304, '', '', '', '', 0, b'1', b'1', b'1', '1', '2023-08-12 17:54:49', '1', '2024-01-13 20:18:40', b'1');
INSERT INTO `platform_menu` VALUES (2307, '拼团活动更新', 'promotion:combination-activity:update', 3, 3, 2304, '', '', '', '', 0, b'1', b'1', b'1', '1', '2023-08-12 17:55:04', '1', '2024-01-13 20:18:36', b'1');
INSERT INTO `platform_menu` VALUES (2308, '拼团活动删除', 'promotion:combination-activity:delete', 3, 4, 2304, '', '', '', '', 0, b'1', b'1', b'1', '1', '2023-08-12 17:55:23', '1', '2024-01-13 20:18:12', b'1');
INSERT INTO `platform_menu` VALUES (2309, '拼团活动关闭', 'promotion:combination-activity:close', 3, 5, 2304, '', '', '', '', 0, b'1', b'1', b'1', '1', '2023-08-12 17:55:37', '1', '2024-01-13 20:18:09', b'1');
INSERT INTO `platform_menu` VALUES (2310, '砍价活动', '', 2, 4, 2030, 'bargain', 'ep:box', '', '', 0, b'1', b'1', b'1', '1', '2023-08-13 00:27:25', '1', '2024-01-13 20:17:57', b'1');
INSERT INTO `platform_menu` VALUES (2311, '砍价商品', '', 2, 1, 2310, 'activity', 'ep:burger', 'mall/promotion/bargain/activity/index', 'PromotionBargainActivity', 0, b'1', b'1', b'1', '1', '2023-08-13 00:28:49', '1', '2024-01-13 20:17:52', b'1');
INSERT INTO `platform_menu` VALUES (2312, '砍价活动查询', 'promotion:bargain-activity:query', 3, 1, 2311, '', '', '', '', 0, b'1', b'1', b'1', '1', '2023-08-13 00:32:30', '1', '2024-01-13 20:17:48', b'1');
INSERT INTO `platform_menu` VALUES (2313, '砍价活动创建', 'promotion:bargain-activity:create', 3, 2, 2311, '', '', '', '', 0, b'1', b'1', b'1', '1', '2023-08-13 00:32:44', '1', '2024-01-13 20:17:45', b'1');
INSERT INTO `platform_menu` VALUES (2314, '砍价活动更新', 'promotion:bargain-activity:update', 3, 3, 2311, '', '', '', '', 0, b'1', b'1', b'1', '1', '2023-08-13 00:32:55', '1', '2024-01-13 20:17:41', b'1');
INSERT INTO `platform_menu` VALUES (2315, '砍价活动删除', 'promotion:bargain-activity:delete', 3, 4, 2311, '', '', '', '', 0, b'1', b'1', b'1', '1', '2023-08-13 00:34:50', '1', '2024-01-13 20:17:37', b'1');
INSERT INTO `platform_menu` VALUES (2316, '砍价活动关闭', 'promotion:bargain-activity:close', 3, 5, 2311, '', '', '', '', 0, b'1', b'1', b'1', '1', '2023-08-13 00:35:02', '1', '2024-01-13 20:17:32', b'1');
INSERT INTO `platform_menu` VALUES (2317, '会员管理', '', 2, 0, 2262, 'user', 'ep:avatar', 'member/user/index', 'MemberUser', 0, b'1', b'1', b'1', '', '2023-08-19 04:12:15', '1', '2024-01-13 20:40:51', b'1');
INSERT INTO `platform_menu` VALUES (2318, '会员用户查询', 'member:user:query', 3, 1, 2317, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-08-19 04:12:15', '', '2024-01-13 20:40:48', b'1');
INSERT INTO `platform_menu` VALUES (2319, '会员用户更新', 'member:user:update', 3, 3, 2317, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-08-19 04:12:15', '', '2024-01-13 20:40:45', b'1');
INSERT INTO `platform_menu` VALUES (2320, '会员标签', '', 2, 1, 2262, 'tag', 'ep:collection-tag', 'member/tag/index', 'MemberTag', 0, b'1', b'1', b'1', '', '2023-08-20 01:03:08', '1', '2024-01-13 20:40:24', b'1');
INSERT INTO `platform_menu` VALUES (2321, '会员标签查询', 'member:tag:query', 3, 1, 2320, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-08-20 01:03:08', '', '2024-01-13 20:40:20', b'1');
INSERT INTO `platform_menu` VALUES (2322, '会员标签创建', 'member:tag:create', 3, 2, 2320, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-08-20 01:03:08', '', '2024-01-13 20:40:17', b'1');
INSERT INTO `platform_menu` VALUES (2323, '会员标签更新', 'member:tag:update', 3, 3, 2320, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-08-20 01:03:08', '', '2024-01-13 20:40:13', b'1');
INSERT INTO `platform_menu` VALUES (2324, '会员标签删除', 'member:tag:delete', 3, 4, 2320, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-08-20 01:03:08', '', '2024-01-13 20:40:02', b'1');
INSERT INTO `platform_menu` VALUES (2325, '会员等级', '', 2, 2, 2262, 'level', 'fa:level-up', 'member/level/index', 'MemberLevel', 0, b'1', b'1', b'1', '', '2023-08-22 12:41:01', '1', '2024-01-13 20:39:58', b'1');
INSERT INTO `platform_menu` VALUES (2326, '会员等级查询', 'member:level:query', 3, 1, 2325, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-08-22 12:41:02', '', '2024-01-13 20:39:54', b'1');
INSERT INTO `platform_menu` VALUES (2327, '会员等级创建', 'member:level:create', 3, 2, 2325, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-08-22 12:41:02', '', '2024-01-13 20:39:50', b'1');
INSERT INTO `platform_menu` VALUES (2328, '会员等级更新', 'member:level:update', 3, 3, 2325, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-08-22 12:41:02', '', '2024-01-13 20:38:58', b'1');
INSERT INTO `platform_menu` VALUES (2329, '会员等级删除', 'member:level:delete', 3, 4, 2325, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-08-22 12:41:02', '', '2024-01-13 20:38:55', b'1');
INSERT INTO `platform_menu` VALUES (2330, '会员分组', '', 2, 3, 2262, 'group', 'fa:group', 'member/group/index', 'MemberGroup', 0, b'1', b'1', b'1', '', '2023-08-22 13:50:06', '1', '2024-01-13 20:38:48', b'1');
INSERT INTO `platform_menu` VALUES (2331, '用户分组查询', 'member:group:query', 3, 1, 2330, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-08-22 13:50:06', '', '2024-01-13 20:38:45', b'1');
INSERT INTO `platform_menu` VALUES (2332, '用户分组创建', 'member:group:create', 3, 2, 2330, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-08-22 13:50:06', '', '2024-01-13 20:38:41', b'1');
INSERT INTO `platform_menu` VALUES (2333, '用户分组更新', 'member:group:update', 3, 3, 2330, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-08-22 13:50:06', '', '2024-01-13 20:38:38', b'1');
INSERT INTO `platform_menu` VALUES (2334, '用户分组删除', 'member:group:delete', 3, 4, 2330, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-08-22 13:50:06', '', '2024-01-13 20:38:34', b'1');
INSERT INTO `platform_menu` VALUES (2335, '用户等级修改', 'member:user:update-level', 3, 5, 2317, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-08-23 16:49:05', '', '2024-01-13 20:40:42', b'1');
INSERT INTO `platform_menu` VALUES (2336, '商品评论', '', 2, 5, 2000, 'comment', 'ep:comment', 'mall/product/comment/index', 'ProductComment', 0, b'1', b'1', b'1', '1', '2023-08-26 11:03:00', '1', '2024-01-13 20:26:47', b'1');
INSERT INTO `platform_menu` VALUES (2337, '评论查询', 'product:comment:query', 3, 1, 2336, '', '', '', '', 0, b'1', b'1', b'1', '1', '2023-08-26 11:04:01', '1', '2024-01-13 20:26:44', b'1');
INSERT INTO `platform_menu` VALUES (2338, '添加自评', 'product:comment:create', 3, 2, 2336, '', '', '', '', 0, b'1', b'1', b'1', '1', '2023-08-26 11:04:23', '1', '2024-01-13 20:26:41', b'1');
INSERT INTO `platform_menu` VALUES (2339, '商家回复', 'product:comment:update', 3, 3, 2336, '', '', '', '', 0, b'1', b'1', b'1', '1', '2023-08-26 11:04:37', '1', '2024-01-13 20:26:38', b'1');
INSERT INTO `platform_menu` VALUES (2340, '显隐评论', 'product:comment:update', 3, 4, 2336, '', '', '', '', 0, b'1', b'1', b'1', '1', '2023-08-26 11:04:55', '1', '2024-01-13 20:26:34', b'1');
INSERT INTO `platform_menu` VALUES (2341, '优惠劵发送', 'promotion:coupon:send', 3, 2, 2038, '', '', '', '', 0, b'1', b'1', b'1', '1', '2023-09-02 00:03:14', '1', '2024-01-13 20:20:34', b'1');
INSERT INTO `platform_menu` VALUES (2342, '交易配置', '', 2, 0, 2072, 'config', 'ep:setting', 'trade/config/index', 'TradeConfig', 0, b'1', b'1', b'1', '', '2023-09-28 02:46:22', '1', '2024-01-13 20:26:19', b'1');
INSERT INTO `platform_menu` VALUES (2343, '交易中心配置查询', 'trade:config:query', 3, 1, 2342, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-09-28 02:46:22', '', '2024-01-13 20:26:16', b'1');
INSERT INTO `platform_menu` VALUES (2344, '交易中心配置保存', 'trade:config:save', 3, 2, 2342, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-09-28 02:46:22', '', '2024-01-13 20:26:12', b'1');
INSERT INTO `platform_menu` VALUES (2345, '分销管理', '', 1, 4, 2072, 'brokerage', 'fa-solid:project-diagram', '', '', 0, b'1', b'1', b'1', '', '2023-09-28 02:46:22', '1', '2024-01-13 20:23:16', b'1');
INSERT INTO `platform_menu` VALUES (2346, '分销用户', '', 2, 0, 2345, 'brokerage-user', 'fa-solid:user-tie', 'trade/brokerage/user/index', 'TradeBrokerageUser', 0, b'1', b'1', b'1', '', '2023-09-28 02:46:22', '', '2024-01-13 20:23:12', b'1');
INSERT INTO `platform_menu` VALUES (2347, '分销用户查询', 'trade:brokerage-user:query', 3, 1, 2346, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-09-28 02:46:22', '', '2024-01-13 20:23:09', b'1');
INSERT INTO `platform_menu` VALUES (2348, '分销用户推广人查询', 'trade:brokerage-user:user-query', 3, 2, 2346, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-09-28 02:46:22', '', '2024-01-13 20:23:06', b'1');
INSERT INTO `platform_menu` VALUES (2349, '分销用户推广订单查询', 'trade:brokerage-user:order-query', 3, 3, 2346, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-09-28 02:46:22', '', '2024-01-13 20:23:03', b'1');
INSERT INTO `platform_menu` VALUES (2350, '分销用户修改推广资格', 'trade:brokerage-user:update-brokerage-enable', 3, 4, 2346, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-09-28 02:46:22', '', '2024-01-13 20:23:00', b'1');
INSERT INTO `platform_menu` VALUES (2351, '分销用户修改推广员', 'trade:brokerage-user:update-bind-user', 3, 5, 2346, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-09-28 02:46:22', '', '2024-01-13 20:22:58', b'1');
INSERT INTO `platform_menu` VALUES (2352, '分销用户清除推广员', 'trade:brokerage-user:clear-bind-user', 3, 6, 2346, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-09-28 02:46:22', '', '2024-01-13 20:22:55', b'1');
INSERT INTO `platform_menu` VALUES (2353, '佣金记录', '', 2, 1, 2345, 'brokerage-record', 'fa:money', 'trade/brokerage/record/index', 'TradeBrokerageRecord', 0, b'1', b'1', b'1', '', '2023-09-28 02:46:22', '', '2024-01-13 20:22:50', b'1');
INSERT INTO `platform_menu` VALUES (2354, '佣金记录查询', 'trade:brokerage-record:query', 3, 1, 2353, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-09-28 02:46:22', '', '2024-01-13 20:22:47', b'1');
INSERT INTO `platform_menu` VALUES (2355, '佣金提现', '', 2, 2, 2345, 'brokerage-withdraw', 'fa:credit-card', 'trade/brokerage/withdraw/index', 'TradeBrokerageWithdraw', 0, b'1', b'1', b'1', '', '2023-09-28 02:46:22', '', '2024-01-13 20:22:41', b'1');
INSERT INTO `platform_menu` VALUES (2356, '佣金提现查询', 'trade:brokerage-withdraw:query', 3, 1, 2355, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-09-28 02:46:22', '', '2024-01-13 20:22:38', b'1');
INSERT INTO `platform_menu` VALUES (2357, '佣金提现审核', 'trade:brokerage-withdraw:audit', 3, 2, 2355, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-09-28 02:46:22', '', '2024-01-13 20:22:34', b'1');
INSERT INTO `platform_menu` VALUES (2358, '统计中心', '', 1, 75, 2362, 'statistics', 'ep:data-line', '', '', 0, b'1', b'1', b'1', '', '2023-09-30 03:22:40', '1', '2024-01-13 20:12:59', b'1');
INSERT INTO `platform_menu` VALUES (2359, '交易统计', '', 2, 4, 2358, 'trade', 'fa-solid:credit-card', 'statistics/trade/index', 'TradeStatistics', 0, b'1', b'1', b'1', '', '2023-09-30 03:22:40', '', '2024-01-13 20:12:48', b'1');
INSERT INTO `platform_menu` VALUES (2360, '交易统计查询', 'statistics:trade:query', 3, 1, 2359, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-09-30 03:22:40', '', '2024-01-13 20:12:44', b'1');
INSERT INTO `platform_menu` VALUES (2361, '交易统计导出', 'statistics:trade:export', 3, 2, 2359, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-09-30 03:22:40', '', '2024-01-13 20:12:40', b'1');
INSERT INTO `platform_menu` VALUES (2362, '商城系统', '', 1, 59, 0, '/mall', 'ep:shop', '', '', 0, b'1', b'1', b'1', '1', '2023-09-30 11:52:02', '1', '2024-01-13 20:37:28', b'1');
INSERT INTO `platform_menu` VALUES (2363, '用户积分修改', 'member:user:update-point', 3, 6, 2317, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-01 14:39:43', '', '2024-01-13 20:40:39', b'1');
INSERT INTO `platform_menu` VALUES (2364, '用户余额修改', 'member:user:update-balance', 3, 7, 2317, '', '', '', '', 0, b'1', b'1', b'1', '', '2023-10-01 14:39:43', '1', '2024-01-13 20:40:32', b'1');
INSERT INTO `platform_menu` VALUES (2365, '优惠劵', '', 1, 2, 2030, 'coupon', 'fa-solid:disease', '', '', 0, b'1', b'1', b'1', '1', '2023-10-03 12:39:15', '1', '2024-01-13 20:21:12', b'1');
INSERT INTO `platform_menu` VALUES (2366, '砍价记录', '', 2, 2, 2310, 'record', 'ep:list', 'mall/promotion/bargain/record/index', 'PromotionBargainRecord', 0, b'1', b'1', b'1', '', '2023-10-05 02:49:06', '1', '2024-01-13 20:17:15', b'1');
INSERT INTO `platform_menu` VALUES (2367, '砍价记录查询', 'promotion:bargain-record:query', 3, 1, 2366, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-05 02:49:06', '', '2024-01-13 20:17:11', b'1');
INSERT INTO `platform_menu` VALUES (2368, '助力记录查询', 'promotion:bargain-help:query', 3, 2, 2366, '', '', '', '', 0, b'1', b'1', b'1', '1', '2023-10-05 12:27:49', '1', '2024-01-13 20:17:08', b'1');
INSERT INTO `platform_menu` VALUES (2369, '拼团记录', 'promotion:combination-record:query', 2, 2, 2303, 'record', 'ep:avatar', 'mall/promotion/combination/record/index.vue', 'PromotionCombinationRecord', 0, b'1', b'1', b'1', '1', '2023-10-08 07:10:22', '1', '2024-01-13 20:18:05', b'1');
INSERT INTO `platform_menu` VALUES (2374, '会员统计', '', 2, 2, 2358, 'member', 'ep:avatar', 'statistics/member/index', 'MemberStatistics', 0, b'1', b'1', b'1', '', '2023-10-11 04:39:24', '1', '2024-01-13 20:12:56', b'1');
INSERT INTO `platform_menu` VALUES (2375, '会员统计查询', 'statistics:member:query', 3, 1, 2374, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-11 04:39:24', '', '2024-01-13 20:12:52', b'1');
INSERT INTO `platform_menu` VALUES (2376, '订单核销', 'trade:order:pick-up', 3, 10, 2076, '', '', '', '', 0, b'1', b'1', b'1', '1', '2023-10-14 17:11:58', '1', '2024-01-13 20:26:01', b'1');
INSERT INTO `platform_menu` VALUES (2377, '文章分类', '', 2, 0, 2387, 'article/category', 'fa:certificate', 'mall/promotion/article/category/index', 'ArticleCategory', 0, b'1', b'1', b'1', '', '2023-10-16 01:26:18', '1', '2024-01-13 20:22:11', b'1');
INSERT INTO `platform_menu` VALUES (2378, '分类查询', 'promotion:article-category:query', 3, 1, 2377, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-16 01:26:18', '', '2024-01-13 20:22:07', b'1');
INSERT INTO `platform_menu` VALUES (2379, '分类创建', 'promotion:article-category:create', 3, 2, 2377, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-16 01:26:18', '', '2024-01-13 20:22:04', b'1');
INSERT INTO `platform_menu` VALUES (2380, '分类更新', 'promotion:article-category:update', 3, 3, 2377, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-16 01:26:18', '', '2024-01-13 20:22:01', b'1');
INSERT INTO `platform_menu` VALUES (2381, '分类删除', 'promotion:article-category:delete', 3, 4, 2377, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-16 01:26:18', '', '2024-01-13 20:21:58', b'1');
INSERT INTO `platform_menu` VALUES (2382, '文章列表', '', 2, 2, 2387, 'article', 'ep:connection', 'mall/promotion/article/index', 'Article', 0, b'1', b'1', b'1', '', '2023-10-16 01:26:18', '1', '2024-01-13 20:21:52', b'1');
INSERT INTO `platform_menu` VALUES (2383, '文章管理查询', 'promotion:article:query', 3, 1, 2382, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-16 01:26:18', '', '2024-01-13 20:21:48', b'1');
INSERT INTO `platform_menu` VALUES (2384, '文章管理创建', 'promotion:article:create', 3, 2, 2382, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-16 01:26:18', '', '2024-01-13 20:21:45', b'1');
INSERT INTO `platform_menu` VALUES (2385, '文章管理更新', 'promotion:article:update', 3, 3, 2382, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-16 01:26:18', '', '2024-01-13 20:21:42', b'1');
INSERT INTO `platform_menu` VALUES (2386, '文章管理删除', 'promotion:article:delete', 3, 4, 2382, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-16 01:26:18', '', '2024-01-13 20:21:39', b'1');
INSERT INTO `platform_menu` VALUES (2387, '内容管理', '', 1, 1, 2030, 'content', 'ep:collection', '', '', 0, b'1', b'1', b'1', '1', '2023-10-16 09:37:31', '1', '2024-01-13 20:22:15', b'1');
INSERT INTO `platform_menu` VALUES (2388, '商城首页', '', 2, 1, 2362, 'home', 'ep:home-filled', 'mall/home/index', 'MallHome', 0, b'1', b'1', b'1', '', '2023-10-16 12:10:33', '', '2024-01-13 20:37:24', b'1');
INSERT INTO `platform_menu` VALUES (2389, '核销订单', '', 2, 2, 2166, 'pick-up-order', 'ep:list', 'mall/trade/delivery/pickUpOrder/index', 'PickUpOrder', 0, b'1', b'1', b'1', '', '2023-10-19 16:09:51', '', '2024-01-13 20:23:46', b'1');
INSERT INTO `platform_menu` VALUES (2390, '优惠活动', '', 1, 99, 2030, 'youhui', 'ep:aim', '', '', 0, b'1', b'1', b'1', '1', '2023-10-21 19:23:49', '1', '2024-01-13 20:14:16', b'1');
INSERT INTO `platform_menu` VALUES (2391, '客户管理', '', 2, 0, 2397, 'customer', 'fa:address-book-o', 'crm/customer/index', 'CrmCustomer', 0, b'1', b'1', b'1', '', '2023-10-29 09:04:21', '1', '2024-01-13 18:57:04', b'1');
INSERT INTO `platform_menu` VALUES (2392, '客户查询', 'crm:customer:query', 3, 1, 2391, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-29 09:04:21', '', '2024-01-13 18:56:04', b'1');
INSERT INTO `platform_menu` VALUES (2393, '客户创建', 'crm:customer:create', 3, 2, 2391, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-29 09:04:21', '', '2024-01-13 18:56:02', b'1');
INSERT INTO `platform_menu` VALUES (2394, '客户更新', 'crm:customer:update', 3, 3, 2391, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-29 09:04:21', '', '2024-01-13 18:55:59', b'1');
INSERT INTO `platform_menu` VALUES (2395, '客户删除', 'crm:customer:delete', 3, 4, 2391, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-29 09:04:21', '', '2024-01-13 18:55:55', b'1');
INSERT INTO `platform_menu` VALUES (2396, '客户导出', 'crm:customer:export', 3, 5, 2391, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-29 09:04:21', '', '2024-01-13 18:55:52', b'1');
INSERT INTO `platform_menu` VALUES (2397, '客户管理系统', '', 1, 200, 0, '/crm', 'ep:avatar', '', '', 0, b'1', b'1', b'1', '1', '2023-10-29 17:08:30', '1', '2024-01-13 18:57:08', b'1');
INSERT INTO `platform_menu` VALUES (2398, '合同管理', '', 2, 1, 2397, 'contract', 'ep:notebook', 'crm/contract/index', 'CrmContract', 0, b'1', b'1', b'1', '', '2023-10-29 10:50:41', '1', '2024-01-13 18:52:43', b'1');
INSERT INTO `platform_menu` VALUES (2399, '合同查询', 'crm:contract:query', 3, 1, 2398, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-29 10:50:41', '', '2024-01-13 18:52:39', b'1');
INSERT INTO `platform_menu` VALUES (2400, '合同创建', 'crm:contract:create', 3, 2, 2398, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-29 10:50:41', '', '2024-01-13 18:52:36', b'1');
INSERT INTO `platform_menu` VALUES (2401, '合同更新', 'crm:contract:update', 3, 3, 2398, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-29 10:50:41', '', '2024-01-13 18:52:33', b'1');
INSERT INTO `platform_menu` VALUES (2402, '合同删除', 'crm:contract:delete', 3, 4, 2398, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-29 10:50:41', '', '2024-01-13 18:52:30', b'1');
INSERT INTO `platform_menu` VALUES (2403, '合同导出', 'crm:contract:export', 3, 5, 2398, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-29 10:50:41', '', '2024-01-13 18:52:27', b'1');
INSERT INTO `platform_menu` VALUES (2404, '线索管理', '', 2, 0, 2397, 'clue', 'fa:pagelines', 'crm/clue/index', 'CrmClue', 0, b'1', b'1', b'1', '', '2023-10-29 11:06:29', '1', '2024-01-13 18:55:41', b'1');
INSERT INTO `platform_menu` VALUES (2405, '线索查询', 'crm:clue:query', 3, 1, 2404, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-29 11:06:29', '', '2024-01-13 18:55:36', b'1');
INSERT INTO `platform_menu` VALUES (2406, '线索创建', 'crm:clue:create', 3, 2, 2404, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-29 11:06:29', '', '2024-01-13 18:55:33', b'1');
INSERT INTO `platform_menu` VALUES (2407, '线索更新', 'crm:clue:update', 3, 3, 2404, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-29 11:06:29', '', '2024-01-13 18:55:30', b'1');
INSERT INTO `platform_menu` VALUES (2408, '线索删除', 'crm:clue:delete', 3, 4, 2404, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-29 11:06:29', '', '2024-01-13 18:55:28', b'1');
INSERT INTO `platform_menu` VALUES (2409, '线索导出', 'crm:clue:export', 3, 5, 2404, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-29 11:06:29', '', '2024-01-13 18:55:24', b'1');
INSERT INTO `platform_menu` VALUES (2410, '商机管理', '', 2, 0, 2397, 'business', 'fa:bus', 'crm/business/index', 'CrmBusiness', 0, b'1', b'1', b'1', '', '2023-10-29 11:12:35', '1', '2024-01-13 18:55:18', b'1');
INSERT INTO `platform_menu` VALUES (2411, '商机查询', 'crm:business:query', 3, 1, 2410, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-29 11:12:35', '', '2024-01-13 18:55:15', b'1');
INSERT INTO `platform_menu` VALUES (2412, '商机创建', 'crm:business:create', 3, 2, 2410, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-29 11:12:35', '', '2024-01-13 18:55:10', b'1');
INSERT INTO `platform_menu` VALUES (2413, '商机更新', 'crm:business:update', 3, 3, 2410, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-29 11:12:35', '', '2024-01-13 18:55:07', b'1');
INSERT INTO `platform_menu` VALUES (2414, '商机删除', 'crm:business:delete', 3, 4, 2410, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-29 11:12:35', '', '2024-01-13 18:55:04', b'1');
INSERT INTO `platform_menu` VALUES (2415, '商机导出', 'crm:business:export', 3, 5, 2410, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-29 11:12:35', '', '2024-01-13 18:55:00', b'1');
INSERT INTO `platform_menu` VALUES (2416, '联系人管理', '', 2, 0, 2397, 'contact', 'fa:address-book-o', 'crm/contact/index', 'Contact', 0, b'1', b'1', b'1', '', '2023-10-29 11:14:56', '1', '2024-01-13 18:54:47', b'1');
INSERT INTO `platform_menu` VALUES (2417, '联系人查询', 'crm:contact:query', 3, 1, 2416, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-29 11:14:56', '', '2024-01-13 18:54:44', b'1');
INSERT INTO `platform_menu` VALUES (2418, '联系人创建', 'crm:contact:create', 3, 2, 2416, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-29 11:14:56', '', '2024-01-13 18:54:42', b'1');
INSERT INTO `platform_menu` VALUES (2419, '联系人更新', 'crm:contact:update', 3, 3, 2416, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-29 11:14:56', '', '2024-01-13 18:54:39', b'1');
INSERT INTO `platform_menu` VALUES (2420, '联系人删除', 'crm:contact:delete', 3, 4, 2416, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-29 11:14:56', '', '2024-01-13 18:54:36', b'1');
INSERT INTO `platform_menu` VALUES (2421, '联系人导出', 'crm:contact:export', 3, 5, 2416, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-29 11:14:56', '', '2024-01-13 18:54:33', b'1');
INSERT INTO `platform_menu` VALUES (2422, '回款管理', '', 2, 0, 2397, 'receivable', 'ep:money', 'crm/receivable/index', 'CrmReceivable', 0, b'1', b'1', b'1', '', '2023-10-29 11:18:09', '1', '2024-01-13 18:53:35', b'1');
INSERT INTO `platform_menu` VALUES (2423, '回款管理查询', 'crm:receivable:query', 3, 1, 2422, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-29 11:18:09', '', '2024-01-13 18:53:31', b'1');
INSERT INTO `platform_menu` VALUES (2424, '回款管理创建', 'crm:receivable:create', 3, 2, 2422, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-29 11:18:09', '', '2024-01-13 18:53:28', b'1');
INSERT INTO `platform_menu` VALUES (2425, '回款管理更新', 'crm:receivable:update', 3, 3, 2422, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-29 11:18:09', '', '2024-01-13 18:53:24', b'1');
INSERT INTO `platform_menu` VALUES (2426, '回款管理删除', 'crm:receivable:delete', 3, 4, 2422, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-29 11:18:09', '', '2024-01-13 18:53:20', b'1');
INSERT INTO `platform_menu` VALUES (2427, '回款管理导出', 'crm:receivable:export', 3, 5, 2422, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-29 11:18:09', '', '2024-01-13 18:53:17', b'1');
INSERT INTO `platform_menu` VALUES (2428, '回款计划管理', '', 2, 0, 2397, 'receivable-plan', 'fa:money', 'crm/receivablePlan/index', 'CrmReceivablePlan', 0, b'1', b'1', b'1', '', '2023-10-29 11:18:09', '1', '2024-01-13 18:53:07', b'1');
INSERT INTO `platform_menu` VALUES (2429, '回款计划查询', 'crm:receivable-plan:query', 3, 1, 2428, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-29 11:18:09', '', '2024-01-13 18:53:03', b'1');
INSERT INTO `platform_menu` VALUES (2430, '回款计划创建', 'crm:receivable-plan:create', 3, 2, 2428, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-29 11:18:09', '', '2024-01-13 18:53:00', b'1');
INSERT INTO `platform_menu` VALUES (2431, '回款计划更新', 'crm:receivable-plan:update', 3, 3, 2428, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-29 11:18:09', '', '2024-01-13 18:52:58', b'1');
INSERT INTO `platform_menu` VALUES (2432, '回款计划删除', 'crm:receivable-plan:delete', 3, 4, 2428, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-29 11:18:09', '', '2024-01-13 18:52:54', b'1');
INSERT INTO `platform_menu` VALUES (2433, '回款计划导出', 'crm:receivable-plan:export', 3, 5, 2428, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-29 11:18:09', '', '2024-01-13 18:52:50', b'1');
INSERT INTO `platform_menu` VALUES (2434, '核销订单', '', 2, 2, 2166, 'pick-up-order', 'ep:list', 'mall/trade/delivery/pickUpOrder/index', 'PickUpOrder', 0, b'1', b'1', b'1', '', '2023-10-29 14:19:25', '', '2024-01-13 20:23:43', b'1');
INSERT INTO `platform_menu` VALUES (2435, '商城装修', '', 2, 20, 2030, 'diy-template', 'fa6-solid:brush', 'mall/promotion/diy/template/index', 'DiyTemplate', 0, b'1', b'1', b'1', '', '2023-10-29 14:19:25', '', '2024-01-13 20:16:58', b'1');
INSERT INTO `platform_menu` VALUES (2436, '装修模板', '', 2, 1, 2435, 'diy-template', 'fa6-solid:brush', 'mall/promotion/diy/template/index', 'DiyTemplate', 0, b'1', b'1', b'1', '', '2023-10-29 14:19:25', '', '2024-01-13 20:16:54', b'1');
INSERT INTO `platform_menu` VALUES (2437, '装修模板查询', 'promotion:diy-template:query', 3, 1, 2436, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-29 14:19:25', '', '2024-01-13 20:16:50', b'1');
INSERT INTO `platform_menu` VALUES (2438, '装修模板创建', 'promotion:diy-template:create', 3, 2, 2436, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-29 14:19:25', '', '2024-01-13 20:16:47', b'1');
INSERT INTO `platform_menu` VALUES (2439, '装修模板更新', 'promotion:diy-template:update', 3, 3, 2436, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-29 14:19:25', '', '2024-01-13 20:16:43', b'1');
INSERT INTO `platform_menu` VALUES (2440, '装修模板删除', 'promotion:diy-template:delete', 3, 4, 2436, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-29 14:19:25', '', '2024-01-13 20:16:40', b'1');
INSERT INTO `platform_menu` VALUES (2441, '装修模板使用', 'promotion:diy-template:use', 3, 5, 2436, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-29 14:19:25', '', '2024-01-13 20:16:37', b'1');
INSERT INTO `platform_menu` VALUES (2442, '装修页面', '', 2, 2, 2435, 'diy-page', 'foundation:page-edit', 'mall/promotion/diy/page/index', 'DiyPage', 0, b'1', b'1', b'1', '', '2023-10-29 14:19:25', '', '2024-01-13 20:14:46', b'1');
INSERT INTO `platform_menu` VALUES (2443, '装修页面查询', 'promotion:diy-page:query', 3, 1, 2442, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-29 14:19:25', '', '2024-01-13 20:14:40', b'1');
INSERT INTO `platform_menu` VALUES (2444, '装修页面创建', 'promotion:diy-page:create', 3, 2, 2442, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-29 14:19:26', '', '2024-01-13 20:14:35', b'1');
INSERT INTO `platform_menu` VALUES (2445, '装修页面更新', 'promotion:diy-page:update', 3, 3, 2442, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-29 14:19:26', '', '2024-01-13 20:14:32', b'1');
INSERT INTO `platform_menu` VALUES (2446, '装修页面删除', 'promotion:diy-page:delete', 3, 4, 2442, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-10-29 14:19:26', '', '2024-01-13 20:14:28', b'1');
INSERT INTO `platform_menu` VALUES (2447, '三方登录', '', 1, 10, 1, 'social', 'fa:500px', '', '', 0, b'1', b'1', b'1', '1', '2023-11-04 12:12:01', '1', '2024-05-15 22:21:20', b'0');
INSERT INTO `platform_menu` VALUES (2448, '三方应用', '', 2, 1, 2447, 'client', 'ep:set-up', 'views/system/social/client/index.vue', 'SocialClient', 0, b'1', b'1', b'1', '1', '2023-11-04 12:17:19', '1', '2024-05-15 22:21:20', b'0');
INSERT INTO `platform_menu` VALUES (2449, '三方应用查询', 'system:social-client:query', 3, 1, 2448, '', '', '', '', 0, b'1', b'1', b'1', '1', '2023-11-04 12:43:12', '1', '2024-05-15 22:21:20', b'0');
INSERT INTO `platform_menu` VALUES (2450, '三方应用创建', 'system:social-client:create', 3, 2, 2448, '', '', '', '', 0, b'1', b'1', b'1', '1', '2023-11-04 12:43:58', '1', '2024-05-15 22:21:20', b'0');
INSERT INTO `platform_menu` VALUES (2451, '三方应用更新', 'system:social-client:update', 3, 3, 2448, '', '', '', '', 0, b'1', b'1', b'1', '1', '2023-11-04 12:44:27', '1', '2024-05-15 22:21:20', b'0');
INSERT INTO `platform_menu` VALUES (2452, '三方应用删除', 'system:social-client:delete', 3, 4, 2448, '', '', '', '', 0, b'1', b'1', b'1', '1', '2023-11-04 12:44:43', '1', '2024-05-15 22:21:20', b'0');
INSERT INTO `platform_menu` VALUES (2453, '三方用户', 'system:social-user:query', 2, 2, 2447, 'user', 'ep:avatar', 'system/social/user/index.vue', 'SocialUser', 0, b'1', b'1', b'1', '1', '2023-11-04 14:01:05', '1', '2024-05-15 22:21:20', b'0');
INSERT INTO `platform_menu` VALUES (2516, '客户公海配置', '', 2, 0, 2524, 'customer-pool-config', 'ep:data-analysis', 'crm/config/customerPoolConfig/index', 'CrmCustomerPoolConfig', 0, b'1', b'1', b'1', '', '2023-11-18 13:33:31', '1', '2024-01-13 18:48:43', b'1');
INSERT INTO `platform_menu` VALUES (2517, '客户公海配置保存', 'crm:customer-pool-config:update', 3, 1, 2516, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-11-18 13:33:31', '', '2024-01-13 18:48:38', b'1');
INSERT INTO `platform_menu` VALUES (2518, '客户限制配置', '', 2, 0, 2524, 'customer-limit-config', 'ep:avatar', 'crm/config/customerLimitConfig/index', 'CrmCustomerLimitConfig', 0, b'1', b'1', b'1', '', '2023-11-18 13:33:53', '1', '2024-01-13 18:48:28', b'1');
INSERT INTO `platform_menu` VALUES (2519, '客户限制配置查询', 'crm:customer-limit-config:query', 3, 1, 2518, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-11-18 13:33:53', '', '2024-01-13 18:48:23', b'1');
INSERT INTO `platform_menu` VALUES (2520, '客户限制配置创建', 'crm:customer-limit-config:create', 3, 2, 2518, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-11-18 13:33:53', '', '2024-01-13 18:48:20', b'1');
INSERT INTO `platform_menu` VALUES (2521, '客户限制配置更新', 'crm:customer-limit-config:update', 3, 3, 2518, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-11-18 13:33:53', '', '2024-01-13 18:48:17', b'1');
INSERT INTO `platform_menu` VALUES (2522, '客户限制配置删除', 'crm:customer-limit-config:delete', 3, 4, 2518, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-11-18 13:33:53', '', '2024-01-13 18:48:13', b'1');
INSERT INTO `platform_menu` VALUES (2523, '客户限制配置导出', 'crm:customer-limit-config:export', 3, 5, 2518, '', '', '', NULL, 0, b'1', b'1', b'1', '', '2023-11-18 13:33:53', '', '2024-01-13 18:48:09', b'1');
INSERT INTO `platform_menu` VALUES (2524, '系统配置', '', 1, 99, 2397, 'config', 'ep:connection', '', '', 0, b'1', b'1', b'1', '1', '2023-11-18 21:58:00', '1', '2024-01-13 18:48:46', b'1');
INSERT INTO `platform_menu` VALUES (2525, 'WebSocket 测试', '', 2, 7, 2, 'websocket', 'ep:connection', 'infra/webSocket/index', 'InfraWebSocket', 0, b'1', b'1', b'1', '1', '2023-11-23 19:41:55', '1', '2023-11-24 19:22:30', b'0');
INSERT INTO `platform_menu` VALUES (503880382472261, '租户菜单', '', 2, 0, 1224, 'menu', 'ep:box', 'system/tenantMenu/index', 'SystemTenantMenu', 0, b'1', b'1', b'1', '1', '2024-01-13 21:54:34', '1', '2024-01-13 21:54:34', b'0');
INSERT INTO `platform_menu` VALUES (503880696234053, '租户菜单查询', 'system:tenant-menu:query', 3, 0, 503880382472261, '', '', '', '', 0, b'1', b'1', b'1', '1', '2024-01-13 21:55:50', '1', '2024-01-13 21:55:50', b'0');
INSERT INTO `platform_menu` VALUES (503881088811077, '租户菜单创建', 'system:tenant-menu:create', 3, 0, 503880382472261, '', '', '', '', 0, b'1', b'1', b'1', '1', '2024-01-13 21:57:26', '1', '2024-01-13 21:57:26', b'0');
INSERT INTO `platform_menu` VALUES (503881169776709, '租户菜单更新', 'system:tenant-menu:update', 3, 0, 503880382472261, '', '', '', '', 0, b'1', b'1', b'1', '1', '2024-01-13 21:57:46', '1', '2024-01-13 21:57:46', b'0');
INSERT INTO `platform_menu` VALUES (503881258569797, '租户菜单删除', 'system:tenant-menu:delete', 3, 0, 503880382472261, '', '', '', '', 0, b'1', b'1', b'1', '1', '2024-01-13 21:58:07', '1', '2024-01-13 21:58:07', b'0');
INSERT INTO `platform_menu` VALUES (503881708249157, '应用市场', '', 1, 11, 0, '/plug', 'ep:apple', '', '', 0, b'1', b'1', b'1', '1', '2024-01-13 21:59:57', '1', '2024-01-13 21:59:57', b'0');
INSERT INTO `platform_menu` VALUES (503882569039941, '应用管理', '', 2, 0, 503881708249157, 'plugApp', 'ep:briefcase', 'plug/plugApp/index', 'PlugApp', 0, b'1', b'1', b'1', '1', '2024-01-13 22:03:27', '1', '2024-01-13 22:03:27', b'0');
INSERT INTO `platform_menu` VALUES (503882748592197, '应用管理查询', 'plug:plug-app:query', 3, 0, 503882569039941, '', '', '', '', 0, b'1', b'1', b'1', '1', '2024-01-13 22:04:11', '1', '2024-01-13 22:04:11', b'0');
INSERT INTO `platform_menu` VALUES (503882860208197, '应用管理创建', 'plug:plug-app:create', 3, 0, 503882569039941, '', '', '', '', 0, b'1', b'1', b'1', '1', '2024-01-13 22:04:38', '1', '2024-01-13 22:04:38', b'0');
INSERT INTO `platform_menu` VALUES (503882981924933, '应用管理更新', 'plug:plug-app:update', 3, 0, 503882569039941, '', '', '', '', 0, b'1', b'1', b'1', '1', '2024-01-13 22:05:08', '1', '2024-01-13 22:05:08', b'0');
INSERT INTO `platform_menu` VALUES (503883149041733, '应用管理导出', 'plug:plug-app:export', 3, 0, 503882569039941, '', '', '', '', 0, b'1', b'1', b'1', '1', '2024-01-13 22:05:49', '1', '2024-01-13 22:05:49', b'0');
INSERT INTO `platform_menu` VALUES (503883679580229, '应用订单', '', 2, 0, 503881708249157, 'plugOrder', 'ep:cellphone', 'plug/plugOrder/index', 'PlugOrder', 0, b'1', b'1', b'1', '1', '2024-01-13 22:07:58', '1', '2024-01-13 22:07:58', b'0');
INSERT INTO `platform_menu` VALUES (503883828191301, '应用订单查询', 'plug:plug-order:query', 3, 0, 503883679580229, '', '', '', '', 0, b'1', b'1', b'1', '1', '2024-01-13 22:08:35', '1', '2024-01-13 22:08:35', b'0');
INSERT INTO `platform_menu` VALUES (503883964813381, '应用订单审核', 'plug:plug-order:audit', 3, 0, 503883679580229, '', '', '', '', 0, b'1', b'1', b'1', '1', '2024-01-13 22:09:08', '1', '2024-01-13 22:09:08', b'0');
INSERT INTO `platform_menu` VALUES (505303413260357, '应用管理菜单', 'plug:plug-app:menu', 3, 0, 503882569039941, '', '', '', '', 0, b'1', b'1', b'1', '1', '2024-01-17 22:24:53', '1', '2024-01-17 22:24:53', b'0');
INSERT INTO `platform_menu` VALUES (506900000000001, '应用版本', '', 2, 9, 1, 'app-release', 'ep:cellphone', 'system/appRelease/index', 'SystemAppRelease', 0, b'1', b'1', b'1', '1', '2026-09-07 00:00:00', '1', '2026-09-07 00:00:00', b'0');
INSERT INTO `platform_menu` VALUES (506900000000002, '应用版本查询', 'system:app-release:query', 3, 1, 506900000000001, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2026-09-07 00:00:00', '1', '2026-09-07 00:00:00', b'0');
INSERT INTO `platform_menu` VALUES (506900000000003, '应用版本创建', 'system:app-release:create', 3, 2, 506900000000001, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2026-09-07 00:00:00', '1', '2026-09-07 00:00:00', b'0');
INSERT INTO `platform_menu` VALUES (506900000000004, '应用版本更新', 'system:app-release:update', 3, 3, 506900000000001, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2026-09-07 00:00:00', '1', '2026-09-07 00:00:00', b'0');
INSERT INTO `platform_menu` VALUES (506900000000005, '应用版本删除', 'system:app-release:delete', 3, 4, 506900000000001, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2026-09-07 00:00:00', '1', '2026-09-07 00:00:00', b'0');
INSERT INTO `platform_menu` VALUES (506900000000006, '应用版本发布', 'system:app-release:publish', 3, 5, 506900000000001, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2026-09-07 00:00:00', '1', '2026-09-07 00:00:00', b'0');
INSERT INTO `platform_menu` VALUES (506900000000007, '应用版本暂停', 'system:app-release:pause', 3, 6, 506900000000001, '', '', '', NULL, 0, b'1', b'1', b'1', '1', '2026-09-07 00:00:00', '1', '2026-09-07 00:00:00', b'0');

-- ----------------------------
-- Table structure for platform_notice
-- ----------------------------
DROP TABLE IF EXISTS `platform_notice`;
CREATE TABLE `platform_notice`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '公告ID',
  `title` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '公告标题',
  `content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '公告内容',
  `type` tinyint NOT NULL COMMENT '公告类型（1通知 2公告）',
  `status` tinyint NOT NULL DEFAULT 0 COMMENT '公告状态（0正常 1关闭）',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 5 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '通知公告表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of platform_notice
-- ----------------------------

-- ----------------------------
-- Table structure for platform_app_release
-- ----------------------------
DROP TABLE IF EXISTS `platform_app_release`;
CREATE TABLE `platform_app_release` (
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
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '平台应用版本发布表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of platform_app_release
-- ----------------------------

-- ----------------------------
-- Table structure for platform_oauth2_access_token
-- ----------------------------
DROP TABLE IF EXISTS `platform_oauth2_access_token`;
CREATE TABLE `platform_oauth2_access_token`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `user_id` bigint NOT NULL COMMENT '用户编号',
  `user_type` tinyint NOT NULL COMMENT '用户类型',
  `access_token` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '访问令牌',
  `refresh_token` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '刷新令牌',
  `client_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '客户端编号',
  `scopes` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '授权范围',
  `expires_time` datetime NOT NULL COMMENT '过期时间',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_access_token`(`access_token` ASC) USING BTREE,
  INDEX `idx_refresh_token`(`refresh_token` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1825927743846748162 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'OAuth2 访问令牌' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of platform_oauth2_access_token
-- ----------------------------
INSERT INTO `platform_oauth2_access_token` VALUES (1825926925777113089, 1, 0, 'cbc71d9b87c649f3b604864cda3e0a0a', '4b6bb7628af649878cf2b074904d7806', 'default', NULL, '2024-08-21 00:34:38', NULL, '2024-08-21 00:04:38', NULL, '2024-08-21 00:07:38', b'1');
INSERT INTO `platform_oauth2_access_token` VALUES (1825927743846748161, 1, 0, '55d8c6ef9de24dd6aec4d6f70a106e34', 'aaa371026c98404ba6c0e2823a5857f6', 'default', NULL, '2024-08-21 00:37:53', NULL, '2024-08-21 00:07:53', NULL, '2024-08-21 00:07:53', b'0');

-- ----------------------------
-- Table structure for platform_oauth2_approve
-- ----------------------------
DROP TABLE IF EXISTS `platform_oauth2_approve`;
CREATE TABLE `platform_oauth2_approve`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `user_id` bigint NOT NULL COMMENT '用户编号',
  `user_type` tinyint NOT NULL COMMENT '用户类型',
  `client_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '客户端编号',
  `scope` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '授权范围',
  `approved` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否接受',
  `expires_time` datetime NOT NULL COMMENT '过期时间',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 82 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'OAuth2 批准表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of platform_oauth2_approve
-- ----------------------------

-- ----------------------------
-- Table structure for platform_oauth2_client
-- ----------------------------
DROP TABLE IF EXISTS `platform_oauth2_client`;
CREATE TABLE `platform_oauth2_client`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `client_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '客户端编号',
  `secret` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '客户端密钥',
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '应用名',
  `logo` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '应用图标',
  `description` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '应用描述',
  `status` tinyint NOT NULL COMMENT '状态',
  `access_token_validity_seconds` int NOT NULL COMMENT '访问令牌的有效期',
  `refresh_token_validity_seconds` int NOT NULL COMMENT '刷新令牌的有效期',
  `redirect_uris` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '可重定向的 URI 地址',
  `authorized_grant_types` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '授权类型',
  `scopes` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '授权范围',
  `auto_approve_scopes` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '自动通过的授权范围',
  `authorities` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '权限',
  `resource_ids` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '资源',
  `additional_information` varchar(4096) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '附加信息',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 506659178795078 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'OAuth2 客户端表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of platform_oauth2_client
-- ----------------------------
INSERT INTO `platform_oauth2_client` VALUES (1, 'default', 'admin123', '平台使用', 'http://test.shengyu.iocoder.cn/a5e2e244368878a366b516805a4aabf1.png', '我是描述', 0, 1800, 43200, '[\"http://shengyukj.top/",\"http://shengyukj.top/"]', '[\"password\",\"authorization_code\",\"implicit\",\"refresh_token\"]', '[\"user.read\",\"user.write\"]', '[]', '[\"user.read\",\"user.write\"]', '[]', '{}', '1', '2022-05-11 21:47:12', '1', '2024-01-21 18:16:13', b'0');
INSERT INTO `platform_oauth2_client` VALUES (506659178795077, 'tenant', 'admin123', '租户使用', 'http://127.0.0.1:48080/platform-api/infra/file/4/get/c8ba40f1caf77009434aae5130fa3ad54b25d3a649f67fbe63326933f9b6e40b.png', NULL, 0, 1800, 43200, '[\"http://121.43.32.181\"]', '[\"password\",\"authorization_code\",\"implicit\",\"refresh_token\"]', '[\"user.read\",\"user.write\"]', '[]', '[\"user.read\",\"user.write\"]', '[]', NULL, '1', '2024-01-21 18:21:31', '1', '2024-01-21 18:22:26', b'0');

-- ----------------------------
-- Table structure for platform_oauth2_code
-- ----------------------------
DROP TABLE IF EXISTS `platform_oauth2_code`;
CREATE TABLE `platform_oauth2_code`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `user_id` bigint NOT NULL COMMENT '用户编号',
  `user_type` tinyint NOT NULL COMMENT '用户类型',
  `code` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '授权码',
  `client_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '客户端编号',
  `scopes` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '授权范围',
  `expires_time` datetime NOT NULL COMMENT '过期时间',
  `redirect_uri` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '可重定向的 URI 地址',
  `state` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '状态',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 147 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'OAuth2 授权码表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of platform_oauth2_code
-- ----------------------------

-- ----------------------------
-- Table structure for platform_oauth2_refresh_token
-- ----------------------------
DROP TABLE IF EXISTS `platform_oauth2_refresh_token`;
CREATE TABLE `platform_oauth2_refresh_token`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `user_id` bigint NOT NULL COMMENT '用户编号',
  `refresh_token` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '刷新令牌',
  `user_type` tinyint NOT NULL COMMENT '用户类型',
  `client_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '客户端编号',
  `scopes` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '授权范围',
  `expires_time` datetime NOT NULL COMMENT '过期时间',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1825927743708336131 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'OAuth2 刷新令牌' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of platform_oauth2_refresh_token
-- ----------------------------
INSERT INTO `platform_oauth2_refresh_token` VALUES (1825926925638701057, 1, '4b6bb7628af649878cf2b074904d7806', 0, 'default', NULL, '2024-08-21 12:04:38', NULL, '2024-08-21 00:04:38', NULL, '2024-08-21 00:07:38', b'1');
INSERT INTO `platform_oauth2_refresh_token` VALUES (1825927743708336130, 1, 'aaa371026c98404ba6c0e2823a5857f6', 0, 'default', NULL, '2024-08-21 12:07:53', NULL, '2024-08-21 00:07:53', NULL, '2024-08-21 00:07:53', b'0');

-- ----------------------------
-- Table structure for platform_operate_log
-- ----------------------------
DROP TABLE IF EXISTS `platform_operate_log`;
CREATE TABLE `platform_operate_log`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '日志主键',
  `trace_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '链路追踪编号',
  `user_id` bigint NOT NULL COMMENT '用户编号',
  `user_type` tinyint NOT NULL DEFAULT 0 COMMENT '用户类型',
  `module` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '模块标题',
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '操作名',
  `type` bigint NOT NULL DEFAULT 0 COMMENT '操作分类',
  `content` varchar(2000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '操作内容',
  `exts` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '拓展字段',
  `request_method` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '请求方法名',
  `request_url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '请求地址',
  `user_ip` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '用户 IP',
  `user_agent` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '浏览器 UA',
  `java_method` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT 'Java 方法名',
  `java_method_args` varchar(8000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT 'Java 方法的参数',
  `start_time` datetime NOT NULL COMMENT '操作时间',
  `duration` int NOT NULL COMMENT '执行时长',
  `result_code` int NOT NULL DEFAULT 0 COMMENT '结果码',
  `result_msg` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '结果提示',
  `result_data` varchar(4000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '结果数据',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1825927466334818307 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '操作日志记录' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of platform_operate_log
-- ----------------------------
INSERT INTO `platform_operate_log` VALUES (1825927339280961538, '', 1, 0, '管理后台 - 用户个人中心', '上传用户个人头像', 2, '', '', 'POST', '/platform-api/system/user/profile/update-avatar', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', 'CommonResult com.shengyu.module.platform.controller.platform.user.PlatformUserProfileController.updateUserAvatar(MultipartFile)', '{\"file\":\"[ignore]\"}', '2024-08-21 00:06:16', 620, 0, '', '\"http://127.0.0.1:48080/platform-api/infra/file/4/get/098aab3cb5a9e33ec18ab3bf1ae28f338627f28d92b023d4fd441c098f760f77.png\"', NULL, '2024-08-21 00:06:16', NULL, '2024-08-21 00:06:16', b'0');
INSERT INTO `platform_operate_log` VALUES (1825927466334818306, '', 1, 0, '管理后台 - 用户个人中心', '修改用户个人密码', 3, '', '', 'PUT', '/platform-api/system/user/profile/update-password', '0:0:0:0:0:0:0:1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0', 'CommonResult com.shengyu.module.platform.controller.platform.user.PlatformUserProfileController.updateUserProfilePassword(UserProfileUpdatePasswordReqVO)', '{\"reqVO\":{\"oldPassword\":\"36zhu186\",\"newPassword\":\"123456\"}}', '2024-08-21 00:06:47', 80, 0, '', 'true', NULL, '2024-08-21 00:06:47', NULL, '2024-08-21 00:06:47', b'0');

-- ----------------------------
-- Table structure for platform_plug_app
-- ----------------------------
DROP TABLE IF EXISTS `platform_plug_app`;
CREATE TABLE `platform_plug_app`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT 'id',
  `name` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '应用名称',
  `outline` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '概要描述',
  `app_sn` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '条码',
  `main_pic` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '应用主图地址',
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL COMMENT '描述',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '状态（0上架 1下架）,影响的是租户不能下单购买',
  `enable` tinyint NOT NULL DEFAULT 1 COMMENT '状态（0启用 1停用）平台端操作，停用后租户不能使用该插件',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 505298244644934 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '插件应用' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of platform_plug_app
-- ----------------------------

-- ----------------------------
-- Table structure for platform_post
-- ----------------------------
DROP TABLE IF EXISTS `platform_post`;
CREATE TABLE `platform_post`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '岗位ID',
  `code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '岗位编码',
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '岗位名称',
  `sort` int NOT NULL COMMENT '显示顺序',
  `status` tinyint NOT NULL COMMENT '状态（0正常 1停用）',
  `remark` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '备注',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 5 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '岗位信息表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of platform_post
-- ----------------------------
INSERT INTO `platform_post` VALUES (1, 'ceo', '董事长', 1, 0, '', 'admin', '2021-01-06 17:03:48', '1', '2023-02-11 15:19:04', b'0');
INSERT INTO `platform_post` VALUES (2, 'se', '项目经理', 2, 0, '', 'admin', '2021-01-05 17:03:48', '1', '2023-11-15 09:18:20', b'0');
INSERT INTO `platform_post` VALUES (4, 'user', '普通员工', 4, 0, '111', 'admin', '2021-01-05 17:03:48', '1', '2023-11-15 09:18:18', b'0');

-- ----------------------------
-- Table structure for platform_role
-- ----------------------------
DROP TABLE IF EXISTS `platform_role`;
CREATE TABLE `platform_role`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '角色ID',
  `name` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '角色名称',
  `code` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '角色权限字符串',
  `sort` int NOT NULL COMMENT '显示顺序',
  `data_scope` tinyint NOT NULL DEFAULT 1 COMMENT '数据范围（1：全部数据权限 2：自定数据权限 3：本部门数据权限 4：本部门及以下数据权限）',
  `data_scope_dept_ids` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '数据范围(指定部门数组)',
  `status` tinyint NOT NULL COMMENT '角色状态（0正常 1停用）',
  `type` tinyint NOT NULL COMMENT '角色类型',
  `remark` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '备注',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 140 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '角色信息表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of platform_role
-- ----------------------------
INSERT INTO `platform_role` VALUES (1, '超级管理员', 'super_admin', 1, 1, '', 0, 1, '超级管理员', 'admin', '2021-01-05 17:03:48', '', '2022-02-22 05:08:21', b'0');

-- ----------------------------
-- Table structure for platform_role_menu
-- ----------------------------
DROP TABLE IF EXISTS `platform_role_menu`;
CREATE TABLE `platform_role_menu`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '自增编号',
  `role_id` bigint NOT NULL COMMENT '角色ID',
  `menu_id` bigint NOT NULL COMMENT '菜单ID',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 2901 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '角色和菜单关联表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of platform_role_menu
-- ----------------------------
INSERT INTO `platform_role_menu` VALUES (1489, 1, 1, '1', '2022-02-23 20:03:57', '1', '2022-02-23 20:03:57', b'0');
INSERT INTO `platform_role_menu` VALUES (1490, 1, 2, '1', '2022-02-23 20:03:57', '1', '2022-02-23 20:03:57', b'0');
INSERT INTO `platform_role_menu` VALUES (1494, 1, 1077, '1', '2022-02-23 20:03:57', '1', '2022-02-23 20:03:57', b'0');
INSERT INTO `platform_role_menu` VALUES (1495, 1, 1078, '1', '2022-02-23 20:03:57', '1', '2022-02-23 20:03:57', b'0');
INSERT INTO `platform_role_menu` VALUES (1496, 1, 1083, '1', '2022-02-23 20:03:57', '1', '2022-02-23 20:03:57', b'0');
INSERT INTO `platform_role_menu` VALUES (1497, 1, 1084, '1', '2022-02-23 20:03:57', '1', '2022-02-23 20:03:57', b'0');
INSERT INTO `platform_role_menu` VALUES (1498, 1, 1090, '1', '2022-02-23 20:03:57', '1', '2022-02-23 20:03:57', b'0');
INSERT INTO `platform_role_menu` VALUES (1499, 1, 1093, '1', '2022-02-23 20:03:57', '1', '2024-01-13 18:16:38', b'1');
INSERT INTO `platform_role_menu` VALUES (1500, 1, 1094, '1', '2022-02-23 20:03:57', '1', '2024-01-13 18:05:30', b'1');
INSERT INTO `platform_role_menu` VALUES (1501, 1, 1100, '1', '2022-02-23 20:03:57', '1', '2024-01-13 18:16:17', b'1');
INSERT INTO `platform_role_menu` VALUES (1502, 1, 1107, '1', '2022-02-23 20:03:57', '1', '2024-01-13 18:16:34', b'1');
INSERT INTO `platform_role_menu` VALUES (1503, 1, 1110, '1', '2022-02-23 20:03:57', '1', '2022-02-23 20:03:57', b'0');
INSERT INTO `platform_role_menu` VALUES (1505, 1, 1117, '1', '2022-02-23 20:03:57', '1', '2024-01-13 18:47:30', b'1');
INSERT INTO `platform_role_menu` VALUES (1506, 1, 100, '1', '2022-02-23 20:03:57', '1', '2022-02-23 20:03:57', b'0');
INSERT INTO `platform_role_menu` VALUES (1507, 1, 101, '1', '2022-02-23 20:03:57', '1', '2022-02-23 20:03:57', b'0');
INSERT INTO `platform_role_menu` VALUES (1508, 1, 102, '1', '2022-02-23 20:03:57', '1', '2022-02-23 20:03:57', b'0');
INSERT INTO `platform_role_menu` VALUES (1509, 1, 1126, '1', '2022-02-23 20:03:57', '1', '2024-01-13 18:47:24', b'1');
INSERT INTO `platform_role_menu` VALUES (1510, 1, 103, '1', '2022-02-23 20:03:57', '1', '2022-02-23 20:03:57', b'0');
INSERT INTO `platform_role_menu` VALUES (1511, 1, 104, '1', '2022-02-23 20:03:57', '1', '2022-02-23 20:03:57', b'0');
INSERT INTO `platform_role_menu` VALUES (1512, 1, 105, '1', '2022-02-23 20:03:57', '1', '2022-02-23 20:03:57', b'0');
INSERT INTO `platform_role_menu` VALUES (1513, 1, 106, '1', '2022-02-23 20:03:57', '1', '2022-02-23 20:03:57', b'0');
INSERT INTO `platform_role_menu` VALUES (1514, 1, 107, '1', '2022-02-23 20:03:57', '1', '2022-02-23 20:03:57', b'0');
INSERT INTO `platform_role_menu` VALUES (1515, 1, 108, '1', '2022-02-23 20:03:57', '1', '2022-02-23 20:03:57', b'0');
INSERT INTO `platform_role_menu` VALUES (1516, 1, 109, '1', '2022-02-23 20:03:57', '1', '2022-02-23 20:03:57', b'0');
INSERT INTO `platform_role_menu` VALUES (1517, 1, 110, '1', '2022-02-23 20:03:57', '1', '2022-02-23 20:03:57', b'0');
INSERT INTO `platform_role_menu` VALUES (1518, 1, 111, '1', '2022-02-23 20:03:57', '1', '2022-02-23 20:03:57', b'0');
INSERT INTO `platform_role_menu` VALUES (1519, 1, 112, '1', '2022-02-23 20:03:57', '1', '2022-02-23 20:03:57', b'0');
INSERT INTO `platform_role_menu` VALUES (1520, 1, 113, '1', '2022-02-23 20:03:57', '1', '2022-02-23 20:03:57', b'0');
INSERT INTO `platform_role_menu` VALUES (1522, 1, 1138, '1', '2022-02-23 20:03:57', '1', '2022-02-23 20:03:57', b'0');
INSERT INTO `platform_role_menu` VALUES (1525, 1, 1224, '1', '2022-02-23 20:03:57', '1', '2022-02-23 20:03:57', b'0');
INSERT INTO `platform_role_menu` VALUES (1526, 1, 1225, '1', '2022-02-23 20:03:57', '1', '2022-02-23 20:03:57', b'0');
INSERT INTO `platform_role_menu` VALUES (1527, 1, 500, '1', '2022-02-23 20:03:57', '1', '2022-02-23 20:03:57', b'0');
INSERT INTO `platform_role_menu` VALUES (1528, 1, 501, '1', '2022-02-23 20:03:57', '1', '2022-02-23 20:03:57', b'0');

-- ----------------------------
-- Table structure for platform_user_post
-- ----------------------------
DROP TABLE IF EXISTS `platform_user_post`;
CREATE TABLE `platform_user_post`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT 'id',
  `user_id` bigint NOT NULL DEFAULT 0 COMMENT '用户ID',
  `post_id` bigint NOT NULL DEFAULT 0 COMMENT '岗位ID',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 118 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '用户岗位表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of platform_user_post
-- ----------------------------

-- ----------------------------
-- Table structure for platform_user_role
-- ----------------------------
DROP TABLE IF EXISTS `platform_user_role`;
CREATE TABLE `platform_user_role`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '自增编号',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `role_id` bigint NOT NULL COMMENT '角色ID',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 32 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '用户和角色关联表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of platform_user_role
-- ----------------------------
INSERT INTO `platform_user_role` VALUES (1, 1, 1, '', '2022-01-11 13:19:45', '', '2022-05-12 12:35:17', b'0');

-- ----------------------------
-- Table structure for platform_users
-- ----------------------------
DROP TABLE IF EXISTS `platform_users`;
CREATE TABLE `platform_users`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '用户ID',
  `username` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '用户账号',
  `password` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '密码',
  `nickname` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '用户昵称',
  `remark` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '备注',
  `dept_id` bigint NULL DEFAULT NULL COMMENT '部门ID',
  `email` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '用户邮箱',
  `mobile` varchar(11) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '手机号码',
  `sex` tinyint NULL DEFAULT 0 COMMENT '用户性别',
  `avatar` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '头像地址',
  `theme_mode` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'system' COMMENT '主题模式（light/dark/system）',
  `chat_bubble_color` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '#1677FF' COMMENT '聊天气泡主色',
  `chat_bubble_mode` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'preset' COMMENT '聊天气泡模式（preset/custom）',
  `status` tinyint NOT NULL DEFAULT 0 COMMENT '帐号状态（0正常 1停用）',
  `login_ip` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '最后登录IP',
  `login_date` datetime NULL DEFAULT NULL COMMENT '最后登录时间',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `idx_username`(`username` ASC, `update_time` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 126 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '用户信息表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of platform_users
-- ----------------------------
INSERT INTO `platform_users` (`id`, `username`, `password`, `nickname`, `remark`, `dept_id`, `email`, `mobile`, `sex`, `avatar`, `status`, `login_ip`, `login_date`, `creator`, `create_time`, `updater`, `update_time`, `deleted`) VALUES (1, 'admin', '$2a$04$9GQYoSk1U649RJRSADyFw./ln74SasJ3A84/Qy/FeA9uh8OGYSU7S', '圣钰科技', '管理员', 103, 'jin_zheyicn@qq.com', '15170435653', 1, 'http://127.0.0.1:48080/platform-api/infra/file/4/get/098aab3cb5a9e33ec18ab3bf1ae28f338627f28d92b023d4fd441c098f760f77.png', 0, '0:0:0:0:0:0:0:1', '2024-08-21 00:07:53', 'admin', '2021-01-05 17:03:47', NULL, '2024-08-21 00:07:53', b'0');

-- ----------------------------
-- Table structure for plug_order
-- ----------------------------
DROP TABLE IF EXISTS `plug_order`;
CREATE TABLE `plug_order`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT 'id',
  `order_no` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '订单编号',
  `order_status` tinyint NOT NULL COMMENT '订单状态 0：待审核,1：审核通过,2：审核不通过',
  `user_ip` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '用户 IP',
  `user_id` bigint NOT NULL COMMENT '申请者编号',
  `success_time` datetime NULL DEFAULT CURRENT_TIMESTAMP COMMENT '订单申请成功时间',
  `note` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '订单备注',
  `audit_note` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '审核结果描述',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1760312350952767490 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '插件订单' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of plug_order
-- ----------------------------

-- ----------------------------
-- Table structure for plug_order_item
-- ----------------------------
DROP TABLE IF EXISTS `plug_order_item`;
CREATE TABLE `plug_order_item`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '订单项id',
  `plug_app_id` bigint NOT NULL COMMENT '插件应用id',
  `order_no` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '订单编号',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1760312350889852931 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '订单项' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of plug_order_item
-- ----------------------------

-- ----------------------------
-- Table structure for plug_tenant
-- ----------------------------
DROP TABLE IF EXISTS `plug_tenant`;
CREATE TABLE `plug_tenant`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT 'id',
  `plug_app_id` bigint NOT NULL COMMENT '插件应用id',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '状态（0上架 1下架）',
  `enable` tinyint NOT NULL DEFAULT 0 COMMENT '状态（0启用 1停用）平台端操作，停用后租户不能使用该插件',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1760312550433865730 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '租户应用' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of plug_tenant
-- ----------------------------

-- ----------------------------
-- Table structure for system_dept
-- ----------------------------
DROP TABLE IF EXISTS `system_dept`;
CREATE TABLE `system_dept`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '部门id',
  `name` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '部门名称',
  `parent_id` bigint NOT NULL DEFAULT 0 COMMENT '父部门id',
  `sort` int NOT NULL DEFAULT 0 COMMENT '显示顺序',
  `leader_user_id` bigint NULL DEFAULT NULL COMMENT '负责人',
  `phone` varchar(11) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '联系电话',
  `email` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '邮箱',
  `status` tinyint NOT NULL COMMENT '部门状态（0正常 1停用）',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1802549202420125698 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '部门表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of system_dept
-- ----------------------------

-- ----------------------------
-- Table structure for system_login_log
-- ----------------------------
DROP TABLE IF EXISTS `system_login_log`;
CREATE TABLE `system_login_log`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '访问ID',
  `log_type` bigint NOT NULL COMMENT '日志类型',
  `trace_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '链路追踪编号',
  `user_id` bigint NOT NULL DEFAULT 0 COMMENT '用户编号',
  `user_type` tinyint NOT NULL DEFAULT 0 COMMENT '用户类型',
  `username` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '用户账号',
  `result` tinyint NOT NULL COMMENT '登陆结果',
  `user_ip` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '用户 IP',
  `user_agent` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '浏览器 UA',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1825919181263212547 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '系统访问记录' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of system_login_log
-- ----------------------------

-- ----------------------------
-- Table structure for system_notice
-- ----------------------------
DROP TABLE IF EXISTS `system_notice`;
CREATE TABLE `system_notice`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '公告ID',
  `title` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '公告标题',
  `content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '公告内容',
  `type` tinyint NOT NULL COMMENT '公告类型（1通知 2公告）',
  `status` tinyint NOT NULL DEFAULT 0 COMMENT '公告状态（0正常 1关闭）',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 5 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '通知公告表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of system_notice
-- ----------------------------

-- ----------------------------
-- Table structure for system_notify_message
-- ----------------------------
DROP TABLE IF EXISTS `system_notify_message`;
CREATE TABLE `system_notify_message`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '用户ID',
  `user_id` bigint NOT NULL COMMENT '用户id',
  `user_type` tinyint NOT NULL COMMENT '用户类型',
  `template_id` bigint NOT NULL COMMENT '模版编号',
  `template_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '模板编码',
  `template_nickname` varchar(63) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '模版发送人名称',
  `template_content` varchar(1024) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '模版内容',
  `template_type` int NOT NULL COMMENT '模版类型',
  `template_params` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '模版参数',
  `read_status` bit(1) NOT NULL COMMENT '是否已读',
  `read_time` datetime NULL DEFAULT NULL COMMENT '阅读时间',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 11 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '站内信消息表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of system_notify_message
-- ----------------------------

-- ----------------------------
-- Table structure for system_notify_template
-- ----------------------------
DROP TABLE IF EXISTS `system_notify_template`;
CREATE TABLE `system_notify_template`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `name` varchar(63) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '模板名称',
  `code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '模版编码',
  `nickname` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '发送人名称',
  `content` varchar(1024) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '模版内容',
  `type` tinyint NOT NULL COMMENT '类型',
  `params` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '参数数组',
  `status` tinyint NOT NULL COMMENT '状态',
  `remark` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '备注',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 6 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '站内信模板表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of system_notify_template
-- ----------------------------

-- ----------------------------
-- Table structure for system_oauth2_access_token
-- ----------------------------
DROP TABLE IF EXISTS `system_oauth2_access_token`;
CREATE TABLE `system_oauth2_access_token`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `user_id` bigint NOT NULL COMMENT '用户编号',
  `user_type` tinyint NOT NULL COMMENT '用户类型',
  `access_token` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '访问令牌',
  `refresh_token` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '刷新令牌',
  `client_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '客户端编号',
  `scopes` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '授权范围',
  `expires_time` datetime NOT NULL COMMENT '过期时间',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_access_token`(`access_token` ASC) USING BTREE,
  INDEX `idx_refresh_token`(`refresh_token` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1825919182131433474 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'OAuth2 访问令牌' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of system_oauth2_access_token
-- ----------------------------

-- ----------------------------
-- Table structure for system_oauth2_approve
-- ----------------------------
DROP TABLE IF EXISTS `system_oauth2_approve`;
CREATE TABLE `system_oauth2_approve`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `user_id` bigint NOT NULL COMMENT '用户编号',
  `user_type` tinyint NOT NULL COMMENT '用户类型',
  `client_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '客户端编号',
  `scope` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '授权范围',
  `approved` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否接受',
  `expires_time` datetime NOT NULL COMMENT '过期时间',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 82 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'OAuth2 批准表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of system_oauth2_approve
-- ----------------------------

-- ----------------------------
-- Table structure for system_oauth2_code
-- ----------------------------
DROP TABLE IF EXISTS `system_oauth2_code`;
CREATE TABLE `system_oauth2_code`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `user_id` bigint NOT NULL COMMENT '用户编号',
  `user_type` tinyint NOT NULL COMMENT '用户类型',
  `code` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '授权码',
  `client_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '客户端编号',
  `scopes` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '授权范围',
  `expires_time` datetime NOT NULL COMMENT '过期时间',
  `redirect_uri` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '可重定向的 URI 地址',
  `state` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '状态',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 147 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'OAuth2 授权码表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of system_oauth2_code
-- ----------------------------

-- ----------------------------
-- Table structure for system_oauth2_refresh_token
-- ----------------------------
DROP TABLE IF EXISTS `system_oauth2_refresh_token`;
CREATE TABLE `system_oauth2_refresh_token`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `user_id` bigint NOT NULL COMMENT '用户编号',
  `refresh_token` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '刷新令牌',
  `user_type` tinyint NOT NULL COMMENT '用户类型',
  `client_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '客户端编号',
  `scopes` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '授权范围',
  `expires_time` datetime NOT NULL COMMENT '过期时间',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1825919181934301187 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'OAuth2 刷新令牌' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of system_oauth2_refresh_token
-- ----------------------------

-- ----------------------------
-- Table structure for system_operate_log
-- ----------------------------
DROP TABLE IF EXISTS `system_operate_log`;
CREATE TABLE `system_operate_log`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '日志主键',
  `trace_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '链路追踪编号',
  `user_id` bigint NOT NULL COMMENT '用户编号',
  `user_type` tinyint NOT NULL DEFAULT 0 COMMENT '用户类型',
  `module` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '模块标题',
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '操作名',
  `type` bigint NOT NULL DEFAULT 0 COMMENT '操作分类',
  `content` varchar(2000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '操作内容',
  `exts` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '拓展字段',
  `request_method` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '请求方法名',
  `request_url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '请求地址',
  `user_ip` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '用户 IP',
  `user_agent` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '浏览器 UA',
  `java_method` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT 'Java 方法名',
  `java_method_args` varchar(8000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT 'Java 方法的参数',
  `start_time` datetime NOT NULL COMMENT '操作时间',
  `duration` int NOT NULL COMMENT '执行时长',
  `result_code` int NOT NULL DEFAULT 0 COMMENT '结果码',
  `result_msg` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '结果提示',
  `result_data` varchar(4000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '结果数据',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1802549202717921282 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '操作日志记录' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of system_operate_log
-- ----------------------------

-- ----------------------------
-- Table structure for system_post
-- ----------------------------
DROP TABLE IF EXISTS `system_post`;
CREATE TABLE `system_post`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '岗位ID',
  `code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '岗位编码',
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '岗位名称',
  `sort` int NOT NULL COMMENT '显示顺序',
  `status` tinyint NOT NULL COMMENT '状态（0正常 1停用）',
  `remark` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '备注',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 5 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '岗位信息表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of system_post
-- ----------------------------

-- ----------------------------
-- Table structure for system_role
-- ----------------------------
DROP TABLE IF EXISTS `system_role`;
CREATE TABLE `system_role`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '角色ID',
  `name` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '角色名称',
  `code` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '角色权限字符串',
  `sort` int NOT NULL COMMENT '显示顺序',
  `data_scope` tinyint NOT NULL DEFAULT 1 COMMENT '数据范围（1：全部数据权限 2：自定数据权限 3：本部门数据权限 4：本部门及以下数据权限）',
  `data_scope_dept_ids` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '数据范围(指定部门数组)',
  `status` tinyint NOT NULL COMMENT '角色状态（0正常 1停用）',
  `type` tinyint NOT NULL COMMENT '角色类型',
  `remark` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '备注',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1790399996018049027 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '角色信息表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of system_role
-- ----------------------------

-- ----------------------------
-- Table structure for system_role_menu
-- ----------------------------
DROP TABLE IF EXISTS `system_role_menu`;
CREATE TABLE `system_role_menu`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '自增编号',
  `role_id` bigint NOT NULL COMMENT '角色ID',
  `menu_id` bigint NOT NULL COMMENT '菜单ID',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1790403292510289923 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '角色和菜单关联表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of system_role_menu
-- ----------------------------

-- ----------------------------
-- Table structure for system_saas_user
-- ----------------------------
DROP TABLE IF EXISTS `system_saas_user`;
CREATE TABLE `system_saas_user`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `username` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '邮箱，第一登录方式账号没有用手机号是因为邮箱验证免费',
  `password` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '密码',
  `open_id` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '用户唯一标识值',
  `default_tenant` bigint NULL DEFAULT NULL COMMENT '默认所属租户，这个租户是指每次选定的租户，即记录上次登录的租户',
  `mobile` varchar(11) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '手机号码',
  `sex` tinyint NULL DEFAULT 0 COMMENT '用户性别',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1790399764110786563 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '租户saas单一用户表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of system_saas_user
-- ----------------------------

-- ----------------------------
-- Table structure for system_sensitive_word
-- ----------------------------
DROP TABLE IF EXISTS `system_sensitive_word`;
CREATE TABLE `system_sensitive_word`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '敏感词',
  `description` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '描述',
  `tags` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '标签数组',
  `status` tinyint NOT NULL COMMENT '状态',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 6 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '敏感词' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of system_sensitive_word
-- ----------------------------

-- ----------------------------
-- Table structure for system_user_post
-- ----------------------------
DROP TABLE IF EXISTS `system_user_post`;
CREATE TABLE `system_user_post`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT 'id',
  `user_id` bigint NOT NULL DEFAULT 0 COMMENT '用户ID',
  `post_id` bigint NOT NULL DEFAULT 0 COMMENT '岗位ID',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 118 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '用户岗位表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of system_user_post
-- ----------------------------

-- ----------------------------
-- Table structure for system_user_role
-- ----------------------------
DROP TABLE IF EXISTS `system_user_role`;
CREATE TABLE `system_user_role`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '自增编号',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `role_id` bigint NOT NULL COMMENT '角色ID',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1790403409317462018 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '用户和角色关联表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of system_user_role
-- ----------------------------

-- ----------------------------
-- Table structure for system_users
-- ----------------------------
DROP TABLE IF EXISTS `system_users`;
CREATE TABLE `system_users` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '用户ID',
  `saas_user_id` bigint NOT NULL DEFAULT '0' COMMENT '所属SaaS用户表id',
  `nickname` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '用户昵称',
  `remark` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '备注',
  `dept_id` bigint DEFAULT NULL COMMENT '部门ID',
  `avatar` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '头像地址',
  `status` tinyint NOT NULL DEFAULT '0' COMMENT '帐号状态（0正常 1停用）',
  `login_ip` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '最后登录IP',
  `open_account` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '在当前租户下用户唯一标识值',
  `login_date` datetime DEFAULT NULL COMMENT '最后登录时间',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_tenant_nickname_deleted` (`tenant_id`,`nickname`,`deleted`),
  KEY `idx_saas_user_tenant` (`saas_user_id`,`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='用户信息表';

-- ----------------------------
-- Records of system_users
-- ----------------------------

-- ----------------------------
-- Table structure for tenant
-- ----------------------------
DROP TABLE IF EXISTS `tenant`;
CREATE TABLE `tenant`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '租户编号',
  `name` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '租户名',
  `contact_user_id` bigint NULL DEFAULT NULL COMMENT '联系人的用户编号',
  `contact_name` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '联系人',
  `contact_mobile` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '联系手机',
  `contact_user_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '租户管理员账号',
  `status` tinyint NOT NULL DEFAULT 0 COMMENT '租户状态（0正常 1停用）',
  `website` varchar(256) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '绑定域名',
  `package_id` bigint NOT NULL COMMENT '租户套餐编号',
  `expire_time` datetime NOT NULL COMMENT '过期时间',
  `account_count` int NOT NULL COMMENT '账号数量',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1760311914011148291 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '租户表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of tenant
-- ----------------------------

-- ----------------------------
-- Table structure for tenant_mail_account
-- ----------------------------
DROP TABLE IF EXISTS `tenant_mail_account`;
CREATE TABLE `tenant_mail_account`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `mail` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '邮箱',
  `username` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '用户名',
  `password` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '密码',
  `host` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'SMTP 服务器域名',
  `port` int NOT NULL COMMENT 'SMTP 服务器端口',
  `ssl_enable` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否开启 SSL',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 5 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '邮箱账号表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of tenant_mail_account
-- ----------------------------
INSERT INTO `tenant_mail_account` VALUES (1, '7684413@qq.com', '7684413@qq.com', '123457', '127.0.0.1', 8080, b'0', '1', '2023-01-25 17:39:52', '1', '2024-04-03 23:33:32', b'1', 0);
INSERT INTO `tenant_mail_account` VALUES (2, 'jin_zheyicn@qq.com', 'jin_zheyicn@qq.com', 'bgshmyijdzuucbac', 'smtp.qq.com', 465, b'1', '1', '2023-01-26 01:26:03', '1', '2024-04-03 23:30:21', b'0', 0);
INSERT INTO `tenant_mail_account` VALUES (3, '76854114@qq.com', '3335', '11234', 'yunai1.cn', 466, b'0', '1', '2023-01-27 15:06:38', '1', '2023-01-27 07:08:36', b'1', 0);
INSERT INTO `tenant_mail_account` VALUES (4, '7685413x@qq.com', '2', '3', '4', 5, b'1', '1', '2023-04-12 23:05:06', '1', '2023-04-12 15:05:11', b'1', 0);

-- ----------------------------
-- Table structure for tenant_mail_log
-- ----------------------------
DROP TABLE IF EXISTS `tenant_mail_log`;
CREATE TABLE `tenant_mail_log`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `user_id` bigint NULL DEFAULT NULL COMMENT '用户编号',
  `user_type` tinyint NULL DEFAULT NULL COMMENT '用户类型',
  `to_mail` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '接收邮箱地址',
  `account_id` bigint NOT NULL COMMENT '邮箱账号编号',
  `from_mail` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '发送邮箱地址',
  `template_id` bigint NOT NULL COMMENT '模板编号',
  `template_code` varchar(63) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '模板编码',
  `template_nickname` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '模版发送人名称',
  `template_title` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '邮件标题',
  `template_content` varchar(10240) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '邮件内容',
  `template_params` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '邮件参数',
  `send_status` tinyint NOT NULL DEFAULT 0 COMMENT '发送状态',
  `send_time` datetime NULL DEFAULT NULL COMMENT '发送时间',
  `send_message_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '发送返回的消息 ID',
  `send_exception` varchar(4096) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '发送异常',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1790758092963926019 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '邮件日志表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of tenant_mail_log
-- ----------------------------
INSERT INTO `tenant_mail_log` VALUES (1775168907196571649, 1, 0, 'jin_zheyicn@qq.com', 1, '7684413@qq.com', 13, 'admin-sms-login', '奥特曼', '你猜我猜', '<p>您的验证码是12389，名字是jinzheyi</p>', '{\"code\":\"12389\",\"name\":\"jinzheyi\"}', 20, '2024-04-02 22:30:25', NULL, 'ConnectException: Connection refused: connect', '1', '2024-04-02 22:30:23', NULL, '2024-04-02 22:30:25', b'0', 0);
INSERT INTO `tenant_mail_log` VALUES (1775541111797161985, 1, 0, 'jin_zheyicn@qq.com', 2, 'jin_zheyicn@qq.com', 13, 'admin-sms-login', '奥特曼', '你猜我猜', '<p>您的验证码是12389，名字是jinzheyi</p>', '{\"code\":\"12389\",\"name\":\"jinzheyi\"}', 20, '2024-04-03 23:09:24', NULL, 'AuthenticationFailedException: 535 Login Fail. Please enter your authorization code to login. More information in http://service.mail.qq.com/cgi-bin/help?subtype=1&&id=28&&no=1001256\n', '1', '2024-04-03 23:09:24', NULL, '2024-04-03 23:09:24', b'0', 0);
INSERT INTO `tenant_mail_log` VALUES (1775542056429920258, 1, 0, 'jin_zheyicn@qq.com', 2, 'jin_zheyicn@qq.com', 13, 'admin-sms-login', '奥特曼', '你猜我猜', '<p>您的验证码是12389，名字是jinzheyi</p>', '{\"code\":\"12389\",\"name\":\"jinzheyi\"}', 20, '2024-04-03 23:13:09', NULL, 'AuthenticationFailedException: 535 Login Fail. Please enter your authorization code to login. More information in http://service.mail.qq.com/cgi-bin/help?subtype=1&&id=28&&no=1001256\n', '1', '2024-04-03 23:13:09', NULL, '2024-04-03 23:13:09', b'0', 0);
INSERT INTO `tenant_mail_log` VALUES (1775542648569176066, 1, 0, '136870475@qq.com', 2, 'jin_zheyicn@qq.com', 13, 'admin-sms-login', '奥特曼', '你猜我猜', '<p>您的验证码是123，名字是测试</p>', '{\"code\":\"123\",\"name\":\"测试\"}', 20, '2024-04-03 23:15:30', NULL, 'AuthenticationFailedException: 535 Login Fail. Please enter your authorization code to login. More information in http://service.mail.qq.com/cgi-bin/help?subtype=1&&id=28&&no=1001256\n', '1', '2024-04-03 23:15:30', NULL, '2024-04-03 23:15:30', b'0', 0);
INSERT INTO `tenant_mail_log` VALUES (1775545581373333506, 1, 0, '136870475@qq.com', 2, 'jin_zheyicn@qq.com', 13, 'admin-sms-login', '奥特曼', '你猜我猜', '<p>您的验证码是123，名字是测试</p>', '{\"code\":\"123\",\"name\":\"测试\"}', 20, '2024-04-03 23:27:50', NULL, 'AuthenticationFailedException: 535 Login Fail. Please enter your authorization code to login. More information in http://service.mail.qq.com/cgi-bin/help?subtype=1&&id=28&&no=1001256\n', '1', '2024-04-03 23:27:09', NULL, '2024-04-03 23:27:50', b'0', 0);
INSERT INTO `tenant_mail_log` VALUES (1775545987964968961, 1, 0, '136870475@qq.com', 2, 'jin_zheyicn@qq.com', 13, 'admin-sms-login', '', '你猜我猜', '<p>您的验证码是123，名字是测试</p>', '{\"code\":\"123\",\"name\":\"测试\"}', 20, '2024-04-03 23:28:47', NULL, 'AuthenticationFailedException: 535 Login Fail. Please enter your authorization code to login. More information in http://service.mail.qq.com/cgi-bin/help?subtype=1&&id=28&&no=1001256\n', '1', '2024-04-03 23:28:46', NULL, '2024-04-03 23:28:47', b'0', 0);
INSERT INTO `tenant_mail_log` VALUES (1775546480078462977, 1, 0, '136870475@qq.com', 2, 'jin_zheyicn@qq.com', 13, 'admin-sms-login', '圣钰科技', '你猜我猜', '<p>您的验证码是123，名字是测试</p>', '{\"code\":\"123\",\"name\":\"测试\"}', 10, '2024-04-03 23:30:45', '<1884474595.11.1712158243584@zhusy>', NULL, '1', '2024-04-03 23:30:44', NULL, '2024-04-03 23:30:45', b'0', 0);
INSERT INTO `tenant_mail_log` VALUES (1775546720919592961, 1, 0, 'jin_zheyicn@qq.com', 2, 'jin_zheyicn@qq.com', 13, 'admin-sms-login', '圣钰科技', '你猜我猜', '<p>您的验证码是123456，名字是测试</p>', '{\"code\":\"123456\",\"name\":\"测试\"}', 10, '2024-04-03 23:31:42', '<59875706.13.1712158301005@zhusy>', NULL, '1', '2024-04-03 23:31:41', NULL, '2024-04-03 23:31:42', b'0', 0);
INSERT INTO `tenant_mail_log` VALUES (1790754164901761026, 1, 0, '171828903@qq.com', 2, 'jin_zheyicn@qq.com', 13, 'admin-sms-login', '圣钰科技', '欢迎使用 圣钰SaaS管理系统', '<p><span style=\"font-size: 19px;\"><strong>亲爱的用户您好，欢迎使用 圣钰SaaS管理系统</strong></span></p><p><br></p><p>您的邮箱：<strong>171828903@qq.com</strong></p><p>您的默认密码：<strong>123654 &nbsp;</strong>请勿泄露</p><p>您注册的日期：<strong>2024-05-15 12:00:30</strong></p><p>当您在使用本网站时，遵守当地法律法规</p><p>如果您有什么疑问可以联系管理员，Email: <strong>jin_zheyicn@qq.com</strong></p>', '{\"mail\":\"171828903@qq.com\",\"password\":\"123654\",\"registTime\":\"2024-05-15 12:00:30\"}', 10, '2024-05-15 22:40:39', '<679213157.1.1715784038285@zhusy>', NULL, '1', '2024-05-15 22:40:38', NULL, '2024-05-15 22:40:39', b'0', 0);
INSERT INTO `tenant_mail_log` VALUES (1790755335368429569, 1, 0, '171828903@qq.com', 2, 'jin_zheyicn@qq.com', 13, 'admin-sms-login', '圣钰科技', '欢迎使用 圣钰SaaS管理系统', '<p><img src=\"http://127.0.0.1:48080/platform-api/infra/file/4/get/0dd6ca935a99119bbd0709385781f88d0cea6f3a8268ad348c3b265544fcd698.jpg\" alt=\"image\" data-href=\"http://127.0.0.1:48080/platform-api/infra/file/4/get/0dd6ca935a99119bbd0709385781f88d0cea6f3a8268ad348c3b265544fcd698.jpg\" style=\"\"/><span style=\"font-size: 19px;\"><strong>亲爱的用户您好，欢迎使用 圣钰SaaS管理系统</strong></span></p><p><br></p><p>您的邮箱：<strong>171828903@qq.com</strong></p><p>您的默认密码：<strong>123654 &nbsp;</strong>请勿泄露</p><p>您注册的日期：<strong>2024-05-15 12:00:30</strong></p><p>当您在使用本网站时，遵守当地法律法规</p><p>如果您有什么疑问可以联系管理员，Email: <strong>jin_zheyicn@qq.com</strong></p>', '{\"mail\":\"171828903@qq.com\",\"password\":\"123654\",\"registTime\":\"2024-05-15 12:00:30\"}', 10, '2024-05-15 22:45:18', '<2109745241.3.1715784317265@zhusy>', NULL, '1', '2024-05-15 22:45:17', NULL, '2024-05-15 22:45:18', b'0', 0);
INSERT INTO `tenant_mail_log` VALUES (1790757116332822530, 1, 0, '171828903@qq.com', 2, 'jin_zheyicn@qq.com', 13, 'admin-sms-login', '圣钰科技', '欢迎使用 圣钰SaaS管理系统', '<pre><code class=\"language-html\">&lt;!DOCTYPE html&gt;\r\n&lt;html lang=\"en\" xmlns:th=\"http://www.thymeleaf.org\"&gt;\r\n\r\n    &lt;head&gt;\r\n        &lt;meta charset=\"UTF-8\"&gt;\r\n        &lt;title&gt;激活邮件&lt;/title&gt;\r\n        &lt;style type=\"text/css\"&gt;\r\n            * {\r\n                margin: 0;\r\n                padding: 0;\r\n                box-sizing: border-box;\r\n                font-family: Arial, Helvetica, sans-serif;\r\n            }\r\n\r\n            body {\r\n                background-color: #ECECEC;\r\n            }\r\n\r\n            .container {\r\n                width: 800px;\r\n                margin: 50px auto;\r\n            }\r\n\r\n            .header {\r\n                height: 80px;\r\n                background-color: #49bcff;\r\n                border-top-left-radius: 5px;\r\n                border-top-right-radius: 5px;\r\n                padding-left: 30px;\r\n            }\r\n\r\n            .header h2 {\r\n                padding-top: 25px;\r\n                color: white;\r\n            }\r\n\r\n            .content {\r\n                background-color: #fff;\r\n                padding-left: 30px;\r\n                padding-bottom: 30px;\r\n                border-bottom: 1px solid #ccc;\r\n            }\r\n\r\n            .content h2 {\r\n                padding-top: 20px;\r\n                padding-bottom: 20px;\r\n            }\r\n\r\n            .content p {\r\n                padding-top: 10px;\r\n            }\r\n\r\n            .footer {\r\n                background-color: #fff;\r\n                border-bottom-left-radius: 5px;\r\n                border-bottom-right-radius: 5px;\r\n                padding: 35px;\r\n            }\r\n\r\n            .footer p {\r\n                color: #747474;\r\n                padding-top: 10px;\r\n            }\r\n        &lt;/style&gt;\r\n    &lt;/head&gt;\r\n\r\n    &lt;body&gt;\r\n        &lt;div class=\"container\"&gt;\r\n            &lt;div class=\"header\"&gt;\r\n                &lt;h2&gt;欢迎加入圣钰SaaS管理系统! （最好用的SaaS开源平台）&lt;/h2&gt;\r\n            &lt;/div&gt;\r\n            &lt;div class=\"content\"&gt;\r\n                &lt;h2&gt;亲爱的用户您好&lt;/h2&gt;\r\n                &lt;p&gt;您的邮箱：&lt;b&gt;&lt;span&gt;171828903@qq.com&lt;/span&gt;&lt;/b&gt;&lt;/p&gt;\r\n                &lt;p&gt;您的默认密码：&lt;b&gt;&lt;span&gt;123654&lt;/span&gt;&lt;/b&gt; 请勿泄露&lt;/p&gt;\r\n                &lt;p&gt;您注册的日期：&lt;b&gt;&lt;span&gt;2024-05-15 12:00:30&lt;/span&gt;&lt;/b&gt;&lt;/p&gt;\r\n                &lt;p&gt;当您在使用本网站时，务必要遵守法律法规&lt;/p&gt;\r\n                &lt;p&gt;如果您有什么疑问可以联系管理员，Email: &lt;b&gt;jin_zheyicn@qq.com&lt;/b&gt;&lt;/p&gt;\r\n            &lt;/div&gt;\r\n            &lt;div class=\"footer\"&gt;\r\n                &lt;p&gt;此为系统邮件，请勿回复&lt;/p&gt;\r\n                &lt;p&gt;请保管好您的信息，避免被他人盗用&lt;/p&gt;\r\r\n            &lt;/div&gt;\r\n        &lt;/div&gt;\r\n    &lt;/body&gt;\r\n\r\n&lt;/html&gt;\r</code></pre><p><br></p>', '{\"mail\":\"171828903@qq.com\",\"password\":\"123654\",\"registTime\":\"2024-05-15 12:00:30\"}', 10, '2024-05-15 22:52:23', '<1311858901.5.1715784741883@zhusy>', NULL, '1', '2024-05-15 22:52:22', NULL, '2024-05-15 22:52:23', b'0', 0);
INSERT INTO `tenant_mail_log` VALUES (1790758092963926018, 1, 0, '171828903@qq.com', 2, 'jin_zheyicn@qq.com', 13, 'admin-sms-login', '圣钰科技', '欢迎使用 圣钰SaaS管理系统', '<p><span style=\"font-size: 19px;\"><strong>亲爱的用户您好，欢迎使用 圣钰SaaS管理系统</strong></span></p><p><br></p><p>您的邮箱：<strong>171828903@qq.com</strong></p><p>您的默认密码：<strong>123654</strong> &nbsp;请勿泄露</p><p>您注册的日期：<strong>2024-05-15 12:00:30</strong></p><p>当您在使用本网站时，遵守当地法律法规</p><p>如果您有什么疑问可以联系管理员，Email: jin_zheyicn@qq.com</p>', '{\"mail\":\"171828903@qq.com\",\"password\":\"123654\",\"registTime\":\"2024-05-15 12:00:30\"}', 10, '2024-05-15 22:56:16', '<532646851.7.1715784974733@zhusy>', NULL, '1', '2024-05-15 22:56:15', NULL, '2024-05-15 22:56:16', b'0', 0);

-- ----------------------------
-- Table structure for tenant_mail_template
-- ----------------------------
DROP TABLE IF EXISTS `tenant_mail_template`;
CREATE TABLE `tenant_mail_template`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `name` varchar(63) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '模板名称',
  `code` varchar(63) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '模板编码',
  `account_id` bigint NOT NULL COMMENT '发送的邮箱账号编号',
  `nickname` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '发送人名称',
  `title` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '模板标题',
  `content` varchar(10240) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '模板内容',
  `params` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '参数数组',
  `status` tinyint NOT NULL COMMENT '开启状态',
  `remark` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '备注',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 16 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '邮件模版表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of tenant_mail_template
-- ----------------------------
INSERT INTO `tenant_mail_template` VALUES (13, '添加用户发送用户密码', 'tenant-add-user', 2, '圣钰科技', '欢迎使用 圣钰SaaS管理系统', '<p><span style=\"font-size: 19px;\"><strong>亲爱的用户您好，欢迎使用 圣钰SaaS管理系统</strong></span></p><p><br></p><p>您的登录邮箱账号：<strong>{mail}</strong></p><p>您的默认密码：<strong>{password}</strong> &nbsp;请勿泄露</p><p>您注册的日期：<strong>{registerTime}</strong></p><p>当您在使用本网站时，遵守当地法律法规</p><p>如果您有什么疑问可以联系管理员，Email: jin_zheyicn@qq.com</p>', '[\"mail\",\"password\",\"registerTime\"]', 0, '', '1', '2021-10-11 08:10:00', '1', '2024-05-16 23:47:04', b'0', 0);

-- ----------------------------
-- Table structure for tenant_menu
-- ----------------------------
DROP TABLE IF EXISTS `tenant_menu`;
CREATE TABLE `tenant_menu`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '菜单ID',
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '菜单名称',
  `permission` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '权限标识',
  `type` tinyint NOT NULL COMMENT '菜单类型',
  `sort` int NOT NULL DEFAULT 0 COMMENT '显示顺序',
  `parent_id` bigint NOT NULL DEFAULT 0 COMMENT '父菜单ID',
  `path` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '路由地址',
  `icon` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '#' COMMENT '菜单图标',
  `component` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '组件路径',
  `component_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '组件名',
  `status` tinyint NOT NULL DEFAULT 0 COMMENT '菜单状态',
  `visible` bit(1) NOT NULL DEFAULT b'1' COMMENT '是否可见',
  `keep_alive` bit(1) NOT NULL DEFAULT b'1' COMMENT '是否缓存',
  `always_show` bit(1) NOT NULL DEFAULT b'1' COMMENT '是否总是显示',
  `dimension` tinyint NOT NULL DEFAULT 0 COMMENT '菜单维度 0：普通菜单  1：插件菜单 CommonConstants.MenuDimensionEnum',
  `plug_app_sn` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '应用插件条码，当是插件菜单时，必须有值',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1759936566719213571 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '菜单权限表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of tenant_menu
-- ----------------------------
INSERT INTO `tenant_menu` VALUES (1, '系统管理', '', 1, 10, 0, '/system', 'system', NULL, NULL, 0, b'1', b'1', b'1', 0, NULL, 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `tenant_menu` VALUES (100, '用户管理', 'system:user:list', 2, 1, 1, 'user', 'user', 'system/user/index', 'SystemUser', 0, b'1', b'1', b'1', 0, NULL, 'admin', '2021-01-05 17:03:48', '1', '2023-04-08 08:31:59', b'0');
INSERT INTO `tenant_menu` VALUES (101, '角色管理', '', 2, 2, 1, 'role', 'peoples', 'system/role/index', 'SystemRole', 0, b'1', b'1', b'1', 0, NULL, 'admin', '2021-01-05 17:03:48', '1', '2023-04-08 08:33:59', b'0');
INSERT INTO `tenant_menu` VALUES (103, '部门管理', '', 2, 4, 1, 'dept', 'tree', 'system/dept/index', 'SystemDept', 0, b'1', b'1', b'1', 0, NULL, 'admin', '2021-01-05 17:03:48', '1', '2023-04-08 08:35:32', b'0');
INSERT INTO `tenant_menu` VALUES (104, '岗位管理', '', 2, 5, 1, 'post', 'post', 'system/post/index', 'SystemPost', 0, b'1', b'1', b'1', 0, NULL, 'admin', '2021-01-05 17:03:48', '1', '2023-04-08 08:36:21', b'0');
INSERT INTO `tenant_menu` VALUES (107, '通知公告', '', 2, 8, 1, 'notice', 'message', 'system/notice/index', 'SystemNotice', 0, b'1', b'1', b'1', 0, NULL, 'admin', '2021-01-05 17:03:48', '1', '2023-04-08 08:45:06', b'0');
INSERT INTO `tenant_menu` VALUES (108, '审计日志', '', 1, 9, 1, 'log', 'log', '', NULL, 0, b'1', b'1', b'1', 0, NULL, 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `tenant_menu` VALUES (109, '令牌管理', '', 2, 2, 1261, 'token', 'online', 'system/oauth2/token/index', 'SystemTokenClient', 0, b'1', b'1', b'1', 0, NULL, 'admin', '2021-01-05 17:03:48', '1', '2023-04-08 08:47:41', b'0');
INSERT INTO `tenant_menu` VALUES (500, '操作日志', '', 2, 1, 108, 'operate-log', 'form', 'system/operatelog/index', 'SystemOperateLog', 0, b'1', b'1', b'1', 0, NULL, 'admin', '2021-01-05 17:03:48', '1', '2023-04-08 08:47:00', b'0');
INSERT INTO `tenant_menu` VALUES (501, '登录日志', '', 2, 2, 108, 'login-log', 'logininfor', 'system/loginlog/index', 'SystemLoginLog', 0, b'1', b'1', b'1', 0, NULL, 'admin', '2021-01-05 17:03:48', '1', '2023-04-08 08:46:18', b'0');
INSERT INTO `tenant_menu` VALUES (1001, '用户查询', 'system:user:query', 3, 1, 100, '', '#', '', NULL, 0, b'1', b'1', b'1', 0, NULL, 'admin', '2021-01-05 17:03:48', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `tenant_menu` VALUES (1002, '用户新增', 'system:user:create', 3, 2, 100, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `tenant_menu` VALUES (1003, '用户修改', 'system:user:update', 3, 3, 100, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `tenant_menu` VALUES (1004, '用户删除', 'system:user:delete', 3, 4, 100, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `tenant_menu` VALUES (1005, '用户导出', 'system:user:export', 3, 5, 100, '', '#', '', NULL, 0, b'1', b'1', b'1', 0, NULL, 'admin', '2021-01-05 17:03:48', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `tenant_menu` VALUES (1006, '用户导入', 'system:user:import', 3, 6, 100, '', '#', '', NULL, 0, b'1', b'1', b'1', 0, NULL, 'admin', '2021-01-05 17:03:48', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `tenant_menu` VALUES (1007, '重置密码', 'system:user:update-password', 3, 7, 100, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `tenant_menu` VALUES (1008, '角色查询', 'system:role:query', 3, 1, 101, '', '#', '', NULL, 0, b'1', b'1', b'1', 0, NULL, 'admin', '2021-01-05 17:03:48', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `tenant_menu` VALUES (1009, '角色新增', 'system:role:create', 3, 2, 101, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `tenant_menu` VALUES (1010, '角色修改', 'system:role:update', 3, 3, 101, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `tenant_menu` VALUES (1011, '角色删除', 'system:role:delete', 3, 4, 101, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `tenant_menu` VALUES (1012, '角色导出', 'system:role:export', 3, 5, 101, '', '#', '', NULL, 0, b'1', b'1', b'1', 0, NULL, 'admin', '2021-01-05 17:03:48', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `tenant_menu` VALUES (1017, '部门查询', 'system:dept:query', 3, 1, 103, '', '#', '', NULL, 0, b'1', b'1', b'1', 0, NULL, 'admin', '2021-01-05 17:03:48', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `tenant_menu` VALUES (1018, '部门新增', 'system:dept:create', 3, 2, 103, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `tenant_menu` VALUES (1019, '部门修改', 'system:dept:update', 3, 3, 103, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `tenant_menu` VALUES (1020, '部门删除', 'system:dept:delete', 3, 4, 103, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `tenant_menu` VALUES (1021, '岗位查询', 'system:post:query', 3, 1, 104, '', '#', '', NULL, 0, b'1', b'1', b'1', 0, NULL, 'admin', '2021-01-05 17:03:48', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `tenant_menu` VALUES (1022, '岗位新增', 'system:post:create', 3, 2, 104, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `tenant_menu` VALUES (1023, '岗位修改', 'system:post:update', 3, 3, 104, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `tenant_menu` VALUES (1024, '岗位删除', 'system:post:delete', 3, 4, 104, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `tenant_menu` VALUES (1025, '岗位导出', 'system:post:export', 3, 5, 104, '', '#', '', NULL, 0, b'1', b'1', b'1', 0, NULL, 'admin', '2021-01-05 17:03:48', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `tenant_menu` VALUES (1036, '公告查询', 'system:notice:query', 3, 1, 107, '#', '#', '', NULL, 0, b'1', b'1', b'1', 0, NULL, 'admin', '2021-01-05 17:03:48', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `tenant_menu` VALUES (1037, '公告新增', 'system:notice:create', 3, 2, 107, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `tenant_menu` VALUES (1038, '公告修改', 'system:notice:update', 3, 3, 107, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `tenant_menu` VALUES (1039, '公告删除', 'system:notice:delete', 3, 4, 107, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, 'admin', '2021-01-05 17:03:48', '1', '2022-04-20 17:03:10', b'0');
INSERT INTO `tenant_menu` VALUES (1040, '操作查询', 'system:operate-log:query', 3, 1, 500, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, 'admin', '2021-01-05 17:03:48', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `tenant_menu` VALUES (1042, '日志导出', 'system:operate-log:export', 3, 2, 500, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, 'admin', '2021-01-05 17:03:48', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `tenant_menu` VALUES (1043, '登录查询', 'system:login-log:query', 3, 1, 501, '#', '#', '', NULL, 0, b'1', b'1', b'1', 0, NULL, 'admin', '2021-01-05 17:03:48', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `tenant_menu` VALUES (1045, '日志导出', 'system:login-log:export', 3, 3, 501, '#', '#', '', NULL, 0, b'1', b'1', b'1', 0, NULL, 'admin', '2021-01-05 17:03:48', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `tenant_menu` VALUES (1046, '令牌列表', 'system:oauth2-token:page', 3, 1, 109, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, 'admin', '2021-01-05 17:03:48', '1', '2022-05-09 23:54:42', b'0');
INSERT INTO `tenant_menu` VALUES (1048, '令牌删除', 'system:oauth2-token:delete', 3, 2, 109, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, 'admin', '2021-01-05 17:03:48', '1', '2022-05-09 23:54:53', b'0');
INSERT INTO `tenant_menu` VALUES (1063, '设置角色菜单权限', 'system:permission:assign-role-menu', 3, 6, 101, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '', '2021-01-06 17:53:44', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `tenant_menu` VALUES (1064, '设置角色数据权限', 'system:permission:assign-role-data-scope', 3, 7, 101, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '', '2021-01-06 17:56:31', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `tenant_menu` VALUES (1065, '设置用户角色', 'system:permission:assign-user-role', 3, 8, 101, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '', '2021-01-07 10:23:28', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `tenant_menu` VALUES (1093, '短信管理', '', 1, 11, 1, 'sms', 'validCode', NULL, NULL, 0, b'1', b'1', b'1', 0, NULL, '1', '2021-04-05 01:10:16', '1', '2024-04-02 22:04:15', b'1');
INSERT INTO `tenant_menu` VALUES (1094, '短信渠道', '', 2, 0, 1093, 'sms-channel', 'phone', 'system/sms/channel/index', 'SystemSmsChannel', 0, b'1', b'1', b'1', 0, NULL, '', '2021-04-01 11:07:15', '1', '2024-04-02 22:04:15', b'1');
INSERT INTO `tenant_menu` VALUES (1095, '短信渠道查询', 'system:sms-channel:query', 3, 1, 1094, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '', '2021-04-01 11:07:15', '', '2024-04-02 22:04:15', b'1');
INSERT INTO `tenant_menu` VALUES (1096, '短信渠道创建', 'system:sms-channel:create', 3, 2, 1094, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '', '2021-04-01 11:07:15', '', '2024-04-02 22:04:15', b'1');
INSERT INTO `tenant_menu` VALUES (1097, '短信渠道更新', 'system:sms-channel:update', 3, 3, 1094, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '', '2021-04-01 11:07:15', '', '2024-04-02 22:04:15', b'1');
INSERT INTO `tenant_menu` VALUES (1098, '短信渠道删除', 'system:sms-channel:delete', 3, 4, 1094, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '', '2021-04-01 11:07:15', '', '2024-04-02 22:04:15', b'1');
INSERT INTO `tenant_menu` VALUES (1100, '短信模板', '', 2, 1, 1093, 'sms-template', 'phone', 'system/sms/template/index', 'SystemSmsTemplate', 0, b'1', b'1', b'1', 0, NULL, '', '2021-04-01 17:35:17', '1', '2024-04-02 22:04:15', b'1');
INSERT INTO `tenant_menu` VALUES (1101, '短信模板查询', 'system:sms-template:query', 3, 1, 1100, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '', '2021-04-01 17:35:17', '', '2024-04-02 22:04:15', b'1');
INSERT INTO `tenant_menu` VALUES (1102, '短信模板创建', 'system:sms-template:create', 3, 2, 1100, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '', '2021-04-01 17:35:17', '', '2024-04-02 22:04:15', b'1');
INSERT INTO `tenant_menu` VALUES (1103, '短信模板更新', 'system:sms-template:update', 3, 3, 1100, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '', '2021-04-01 17:35:17', '', '2024-04-02 22:04:15', b'1');
INSERT INTO `tenant_menu` VALUES (1104, '短信模板删除', 'system:sms-template:delete', 3, 4, 1100, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '', '2021-04-01 17:35:17', '', '2024-04-02 22:04:15', b'1');
INSERT INTO `tenant_menu` VALUES (1105, '短信模板导出', 'system:sms-template:export', 3, 5, 1100, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '', '2021-04-01 17:35:17', '', '2024-04-02 22:04:15', b'1');
INSERT INTO `tenant_menu` VALUES (1106, '发送测试短信', 'system:sms-template:send-sms', 3, 6, 1100, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '1', '2021-04-11 00:26:40', '1', '2024-04-02 22:04:15', b'1');
INSERT INTO `tenant_menu` VALUES (1107, '短信日志', '', 2, 2, 1093, 'sms-log', 'phone', 'system/sms/log/index', 'SystemSmsLog', 0, b'1', b'1', b'1', 0, NULL, '', '2021-04-11 08:37:05', '1', '2024-04-02 22:04:15', b'1');
INSERT INTO `tenant_menu` VALUES (1108, '短信日志查询', 'system:sms-log:query', 3, 1, 1107, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '', '2021-04-11 08:37:05', '', '2024-04-02 22:04:15', b'1');
INSERT INTO `tenant_menu` VALUES (1109, '短信日志导出', 'system:sms-log:export', 3, 5, 1107, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '', '2021-04-11 08:37:05', '', '2024-04-02 22:04:15', b'1');
INSERT INTO `tenant_menu` VALUES (1110, '错误码管理', '', 2, 12, 1, 'error-code', 'code', 'system/errorCode/index', 'SystemErrorCode', 0, b'1', b'1', b'1', 0, NULL, '', '2021-04-13 21:46:42', '1', '2024-03-05 22:05:53', b'1');
INSERT INTO `tenant_menu` VALUES (1111, '错误码查询', 'system:error-code:query', 3, 1, 1110, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '', '2021-04-13 21:46:42', '', '2024-03-05 22:05:49', b'1');
INSERT INTO `tenant_menu` VALUES (1112, '错误码创建', 'system:error-code:create', 3, 2, 1110, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '', '2021-04-13 21:46:42', '', '2024-03-05 22:05:46', b'1');
INSERT INTO `tenant_menu` VALUES (1113, '错误码更新', 'system:error-code:update', 3, 3, 1110, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '', '2021-04-13 21:46:42', '', '2024-03-05 22:05:43', b'1');
INSERT INTO `tenant_menu` VALUES (1114, '错误码删除', 'system:error-code:delete', 3, 4, 1110, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '', '2021-04-13 21:46:42', '', '2024-03-05 22:05:40', b'1');
INSERT INTO `tenant_menu` VALUES (1115, '错误码导出', 'system:error-code:export', 3, 5, 1110, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '', '2021-04-13 21:46:42', '', '2024-03-05 22:05:37', b'1');
INSERT INTO `tenant_menu` VALUES (1247, '敏感词管理', '', 2, 13, 1, 'sensitive-word', 'education', 'system/sensitiveWord/index', 'SystemSensitiveWord', 0, b'1', b'1', b'1', 0, NULL, '', '2022-04-07 16:55:03', '1', '2023-04-08 09:00:40', b'0');
INSERT INTO `tenant_menu` VALUES (1248, '敏感词查询', 'system:sensitive-word:query', 3, 1, 1247, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '', '2022-04-07 16:55:03', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `tenant_menu` VALUES (1249, '敏感词创建', 'system:sensitive-word:create', 3, 2, 1247, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '', '2022-04-07 16:55:03', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `tenant_menu` VALUES (1250, '敏感词更新', 'system:sensitive-word:update', 3, 3, 1247, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '', '2022-04-07 16:55:03', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `tenant_menu` VALUES (1251, '敏感词删除', 'system:sensitive-word:delete', 3, 4, 1247, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '', '2022-04-07 16:55:03', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `tenant_menu` VALUES (1252, '敏感词导出', 'system:sensitive-word:export', 3, 5, 1247, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '', '2022-04-07 16:55:03', '', '2022-04-20 17:03:10', b'0');
INSERT INTO `tenant_menu` VALUES (1254, '作者动态', '', 1, 0, 0, 'https://gitee.com/jinzheyi/yubb-saas-pro', 'people', NULL, NULL, 0, b'1', b'1', b'1', 0, NULL, '1', '2022-04-23 01:03:15', '1', '2024-08-20 23:35:47', b'0');
INSERT INTO `tenant_menu` VALUES (1261, 'OAuth 2.0', '', 1, 10, 1, 'oauth2', 'people', NULL, NULL, 0, b'1', b'1', b'1', 0, NULL, '1', '2022-05-09 23:38:17', '1', '2022-05-11 23:51:46', b'0');
INSERT INTO `tenant_menu` VALUES (1263, '应用管理', '', 2, 0, 1261, 'oauth2/application', 'tool', 'system/oauth2/client/index', 'SystemOAuth2Client', 0, b'1', b'1', b'1', 0, NULL, '', '2022-05-10 16:26:33', '1', '2024-03-05 21:52:25', b'1');
INSERT INTO `tenant_menu` VALUES (1264, '客户端查询', 'system:oauth2-client:query', 3, 1, 1263, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '', '2022-05-10 16:26:33', '1', '2024-03-05 21:52:20', b'1');
INSERT INTO `tenant_menu` VALUES (1265, '客户端创建', 'system:oauth2-client:create', 3, 2, 1263, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '', '2022-05-10 16:26:33', '1', '2024-03-05 21:52:16', b'1');
INSERT INTO `tenant_menu` VALUES (1266, '客户端更新', 'system:oauth2-client:update', 3, 3, 1263, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '', '2022-05-10 16:26:33', '1', '2024-03-05 21:52:13', b'1');
INSERT INTO `tenant_menu` VALUES (1267, '客户端删除', 'system:oauth2-client:delete', 3, 4, 1263, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '', '2022-05-10 16:26:33', '1', '2024-03-05 21:52:09', b'1');
INSERT INTO `tenant_menu` VALUES (2083, '地区管理', '', 2, 14, 1, 'area', 'row', 'system/area/index', 'SystemArea', 0, b'1', b'1', b'1', 0, NULL, '1', '2022-12-23 17:35:05', '1', '2023-04-08 09:01:37', b'0');
INSERT INTO `tenant_menu` VALUES (2130, '邮箱管理', '', 2, 11, 1, 'mail', 'email', NULL, NULL, 0, b'1', b'1', b'1', 0, NULL, '1', '2023-01-25 17:27:44', '1', '2024-04-02 22:04:58', b'1');
INSERT INTO `tenant_menu` VALUES (2131, '邮箱账号', '', 2, 0, 2130, 'mail-account', 'user', 'system/mail/account/index', 'SystemMailAccount', 0, b'1', b'1', b'1', 0, NULL, '', '2023-01-25 09:33:48', '1', '2024-04-02 22:04:58', b'1');
INSERT INTO `tenant_menu` VALUES (2132, '账号查询', 'system:mail-account:query', 3, 1, 2131, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '', '2023-01-25 09:33:48', '', '2024-04-02 22:04:58', b'1');
INSERT INTO `tenant_menu` VALUES (2133, '账号创建', 'system:mail-account:create', 3, 2, 2131, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '', '2023-01-25 09:33:48', '', '2024-04-02 22:04:58', b'1');
INSERT INTO `tenant_menu` VALUES (2134, '账号更新', 'system:mail-account:update', 3, 3, 2131, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '', '2023-01-25 09:33:48', '', '2024-04-02 22:04:58', b'1');
INSERT INTO `tenant_menu` VALUES (2135, '账号删除', 'system:mail-account:delete', 3, 4, 2131, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '', '2023-01-25 09:33:48', '', '2024-04-02 22:04:58', b'1');
INSERT INTO `tenant_menu` VALUES (2136, '邮件模版', '', 2, 0, 2130, 'mail-template', 'education', 'system/mail/template/index', 'SystemMailTemplate', 0, b'1', b'1', b'1', 0, NULL, '', '2023-01-25 12:05:31', '1', '2024-04-02 22:04:58', b'1');
INSERT INTO `tenant_menu` VALUES (2137, '模版查询', 'system:mail-template:query', 3, 1, 2136, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '', '2023-01-25 12:05:31', '', '2024-04-02 22:04:58', b'1');
INSERT INTO `tenant_menu` VALUES (2138, '模版创建', 'system:mail-template:create', 3, 2, 2136, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '', '2023-01-25 12:05:31', '', '2024-04-02 22:04:58', b'1');
INSERT INTO `tenant_menu` VALUES (2139, '模版更新', 'system:mail-template:update', 3, 3, 2136, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '', '2023-01-25 12:05:31', '', '2024-04-02 22:04:58', b'1');
INSERT INTO `tenant_menu` VALUES (2140, '模版删除', 'system:mail-template:delete', 3, 4, 2136, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '', '2023-01-25 12:05:31', '', '2024-04-02 22:04:58', b'1');
INSERT INTO `tenant_menu` VALUES (2141, '邮件记录', '', 2, 0, 2130, 'mail-log', 'log', 'system/mail/log/index', 'SystemMailLog', 0, b'1', b'1', b'1', 0, NULL, '', '2023-01-26 02:16:50', '1', '2024-04-02 22:04:58', b'1');
INSERT INTO `tenant_menu` VALUES (2142, '日志查询', 'system:mail-log:query', 3, 1, 2141, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '', '2023-01-26 02:16:50', '', '2024-04-02 22:04:58', b'1');
INSERT INTO `tenant_menu` VALUES (2143, '发送测试邮件', 'system:mail-template:send-mail', 3, 5, 2136, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '1', '2023-01-26 23:29:15', '1', '2024-04-02 22:04:58', b'1');
INSERT INTO `tenant_menu` VALUES (2144, '站内信管理', '', 1, 11, 1, 'notify', 'message', NULL, NULL, 0, b'1', b'1', b'1', 0, NULL, '1', '2023-01-28 10:25:18', '1', '2023-01-28 10:25:46', b'0');
INSERT INTO `tenant_menu` VALUES (2145, '模板管理', '', 2, 0, 2144, 'notify-template', 'education', 'system/notify/template/index', 'SystemNotifyTemplate', 0, b'1', b'1', b'1', 0, NULL, '', '2023-01-28 02:26:42', '1', '2023-04-08 08:54:39', b'0');
INSERT INTO `tenant_menu` VALUES (2146, '站内信模板查询', 'system:notify-template:query', 3, 1, 2145, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '', '2023-01-28 02:26:42', '', '2023-01-28 02:26:42', b'0');
INSERT INTO `tenant_menu` VALUES (2147, '站内信模板创建', 'system:notify-template:create', 3, 2, 2145, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '', '2023-01-28 02:26:42', '', '2023-01-28 02:26:42', b'0');
INSERT INTO `tenant_menu` VALUES (2148, '站内信模板更新', 'system:notify-template:update', 3, 3, 2145, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '', '2023-01-28 02:26:42', '', '2023-01-28 02:26:42', b'0');
INSERT INTO `tenant_menu` VALUES (2149, '站内信模板删除', 'system:notify-template:delete', 3, 4, 2145, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '', '2023-01-28 02:26:42', '', '2023-01-28 02:26:42', b'0');
INSERT INTO `tenant_menu` VALUES (2150, '发送测试站内信', 'system:notify-template:send-notify', 3, 5, 2145, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '1', '2023-01-28 10:54:43', '1', '2023-01-28 10:54:43', b'0');
INSERT INTO `tenant_menu` VALUES (2151, '消息记录', '', 2, 0, 2144, 'notify-message', 'edit', 'system/notify/message/index', 'SystemNotifyMessage', 0, b'1', b'1', b'1', 0, NULL, '', '2023-01-28 04:28:22', '1', '2023-04-08 08:54:11', b'0');
INSERT INTO `tenant_menu` VALUES (2152, '站内信消息查询', 'system:notify-message:query', 3, 1, 2151, '', '', '', NULL, 0, b'1', b'1', b'1', 0, NULL, '', '2023-01-28 04:28:22', '', '2023-01-28 04:28:22', b'0');
INSERT INTO `tenant_menu` VALUES (2159, '开发文档', '', 1, 1, 0, 'http://www.shengyukj.top', 'education', NULL, NULL, 0, b'1', b'1', b'1', 0, NULL, '1', '2023-02-10 22:46:28', '1', '2024-08-20 23:37:23', b'0');
INSERT INTO `tenant_menu` VALUES (2160, 'Cloud 开发文档', '', 1, 2, 0, 'https://cloud.iocoder.cn', 'documentation', NULL, NULL, 0, b'1', b'1', b'1', 0, NULL, '1', '2023-02-10 22:47:07', '1', '2024-08-20 23:37:26', b'1');
INSERT INTO `tenant_menu` VALUES (2447, '三方登录', '', 1, 10, 1, 'social', 'fa:500px', '', '', 0, b'1', b'1', b'1', 0, NULL, '1', '2023-11-04 12:12:01', '1', '2024-05-15 22:16:14', b'1');
INSERT INTO `tenant_menu` VALUES (2448, '三方应用', '', 2, 1, 2447, 'client', 'ep:set-up', 'views/system/social/client/index.vue', 'SocialClient', 0, b'1', b'1', b'1', 0, NULL, '1', '2023-11-04 12:17:19', '1', '2024-05-15 22:16:14', b'1');
INSERT INTO `tenant_menu` VALUES (2449, '三方应用查询', 'system:social-client:query', 3, 1, 2448, '', '', '', '', 0, b'1', b'1', b'1', 0, NULL, '1', '2023-11-04 12:43:12', '1', '2024-05-15 22:16:14', b'1');
INSERT INTO `tenant_menu` VALUES (2450, '三方应用创建', 'system:social-client:create', 3, 2, 2448, '', '', '', '', 0, b'1', b'1', b'1', 0, NULL, '1', '2023-11-04 12:43:58', '1', '2024-05-15 22:16:14', b'1');
INSERT INTO `tenant_menu` VALUES (2451, '三方应用更新', 'system:social-client:update', 3, 3, 2448, '', '', '', '', 0, b'1', b'1', b'1', 0, NULL, '1', '2023-11-04 12:44:27', '1', '2024-05-15 22:16:14', b'1');
INSERT INTO `tenant_menu` VALUES (2452, '三方应用删除', 'system:social-client:delete', 3, 4, 2448, '', '', '', '', 0, b'1', b'1', b'1', 0, NULL, '1', '2023-11-04 12:44:43', '1', '2024-05-15 22:16:14', b'1');
INSERT INTO `tenant_menu` VALUES (2453, '三方用户', 'system:social-user:query', 2, 2, 2447, 'user', 'ep:avatar', 'system/social/user/index.vue', 'SocialUser', 0, b'1', b'1', b'1', 0, NULL, '1', '2023-11-04 14:01:05', '1', '2024-05-15 22:16:14', b'1');

-- ----------------------------
-- Table structure for tenant_package
-- ----------------------------
DROP TABLE IF EXISTS `tenant_package`;
CREATE TABLE `tenant_package`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '套餐编号',
  `name` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '套餐名',
  `status` tinyint NOT NULL DEFAULT 0 COMMENT '租户状态（0正常 1停用）',
  `remark` varchar(256) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '备注',
  `menu_ids` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '关联的菜单编号',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1790399764110786001 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '租户套餐表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of tenant_package
-- ----------------------------
INSERT INTO `tenant_package` VALUES (1790399764110786000, '普通套餐', 0, '通用套餐', '[1024,1,1025,1026,1027,1028,1029,1030,1036,1037,1038,1039,1040,1042,1043,1045,1046,1048,2083,1063,1064,1065,1093,1094,1095,1096,1097,1098,1100,1101,1102,1103,1104,1105,1106,2130,1107,2131,1108,2132,509115459203141,1109,2133,2134,1110,2135,1111,2136,1112,2137,1113,2138,1114,2139,1115,2140,2141,2142,2143,2144,2145,2146,2147,100,2148,101,2149,102,2150,103,2151,104,2152,105,107,108,109,509114757075013,509113910849605,509114900414533,509115017441349,2447,2448,2449,2450,2451,2452,2453,509115790061637,1247,1248,1249,1250,1251,1252,1001,1002,1003,1004,1005,1261,1006,1007,1263,1008,1264,1009,1265,1010,1266,1011,1267,1012,500,1013,501,1014,1015,1016,1017,1018,1019,509115637026885,1020,1021,1022,1023]', '1', '2022-02-22 00:54:00', '1', '2024-08-20 23:54:09', b'0');

-- ----------------------------
-- Table structure for tenant_sms_channel
-- ----------------------------
DROP TABLE IF EXISTS `tenant_sms_channel`;
CREATE TABLE `tenant_sms_channel`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `signature` varchar(12) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '短信签名',
  `code` varchar(63) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '渠道编码',
  `status` tinyint NOT NULL COMMENT '开启状态',
  `remark` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '备注',
  `api_key` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '短信 API 的账号',
  `api_secret` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '短信 API 的秘钥',
  `callback_url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '短信发送回调 URL',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '短信渠道' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of tenant_sms_channel
-- ----------------------------
INSERT INTO `tenant_sms_channel` (`id`, `signature`, `code`, `status`, `remark`, `api_key`, `api_secret`, `callback_url`, `creator`, `create_time`, `updater`, `update_time`, `deleted`) VALUES (2, 'Ballcat', 'ALIYUN', 0, '你要改哦，只有我可以用！！！！', 'LTAI5tCnKso2uG3kJ5gRav88', 'fGJ5SNXL7P1NHNRmJ7DJaMJGPyE55C', NULL, '', '2021-03-31 11:53:10', '1', '2024-08-04 08:53:26', b'0');
INSERT INTO `tenant_sms_channel` (`id`, `signature`, `code`, `status`, `remark`, `api_key`, `api_secret`, `callback_url`, `creator`, `create_time`, `updater`, `update_time`, `deleted`) VALUES (4, '测试渠道', 'DEBUG_DING_TALK', 0, '123', '696b5d8ead48071237e4aa5861ff08dbadb2b4ded1c688a7b7c9afc615579859', 'SEC5c4e5ff888bc8a9923ae47f59e7ccd30af1f14d93c55b4e2c9cb094e35aeed67', NULL, '1', '2021-04-13 00:23:14', '1', '2022-03-27 20:29:49', b'0');
INSERT INTO `tenant_sms_channel` (`id`, `signature`, `code`, `status`, `remark`, `api_key`, `api_secret`, `callback_url`, `creator`, `create_time`, `updater`, `update_time`, `deleted`) VALUES (7, 'mock腾讯云', 'TENCENT', 0, '', '1 2', '2 3', '', '1', '2024-09-30 08:53:45', '1', '2024-09-30 08:55:01', b'0');

-- ----------------------------
-- Table structure for tenant_sms_code
-- ----------------------------
DROP TABLE IF EXISTS `tenant_sms_code`;
CREATE TABLE `tenant_sms_code`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `mobile` varchar(11) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '手机号',
  `code` varchar(6) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '验证码',
  `create_ip` varchar(15) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '创建 IP',
  `scene` tinyint NOT NULL COMMENT '发送场景',
  `today_index` tinyint NOT NULL COMMENT '今日发送的第几条',
  `used` tinyint NOT NULL COMMENT '是否使用',
  `used_time` datetime NULL DEFAULT NULL COMMENT '使用时间',
  `used_ip` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '使用 IP',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_mobile`(`mobile` ASC) USING BTREE COMMENT '手机号'
) ENGINE = InnoDB AUTO_INCREMENT = 536 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '手机验证码' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of tenant_sms_code
-- ----------------------------

-- ----------------------------
-- Table structure for tenant_sms_log
-- ----------------------------
DROP TABLE IF EXISTS `tenant_sms_log`;
CREATE TABLE `tenant_sms_log`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `channel_id` bigint NOT NULL COMMENT '短信渠道编号',
  `channel_code` varchar(63) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '短信渠道编码',
  `template_id` bigint NOT NULL COMMENT '模板编号',
  `template_code` varchar(63) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '模板编码',
  `template_type` tinyint NOT NULL COMMENT '短信类型',
  `template_content` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '短信内容',
  `template_params` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '短信参数',
  `api_template_id` varchar(63) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '短信 API 的模板编号',
  `mobile` varchar(11) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '手机号',
  `user_id` bigint NULL DEFAULT NULL COMMENT '用户编号',
  `user_type` tinyint NULL DEFAULT NULL COMMENT '用户类型',
  `send_status` tinyint NOT NULL DEFAULT 0 COMMENT '发送状态',
  `send_time` datetime NULL DEFAULT NULL COMMENT '发送时间',
  `api_send_code` varchar(63) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '短信 API 发送结果的编码',
  `api_send_msg` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '短信 API 发送失败的提示',
  `api_request_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '短信 API 发送返回的唯一请求 ID',
  `api_serial_no` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '短信 API 发送返回的序号',
  `receive_status` tinyint NOT NULL DEFAULT 0 COMMENT '接收状态',
  `receive_time` datetime NULL DEFAULT NULL COMMENT '接收时间',
  `api_receive_code` varchar(63) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT 'API 接收结果的编码',
  `api_receive_msg` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT 'API 接收结果的说明',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 503 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '短信日志' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of tenant_sms_log
-- ----------------------------

-- ----------------------------
-- Table structure for tenant_sms_template
-- ----------------------------
DROP TABLE IF EXISTS `tenant_sms_template`;
CREATE TABLE `tenant_sms_template`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `type` tinyint NOT NULL COMMENT '短信签名',
  `status` tinyint NOT NULL COMMENT '开启状态',
  `code` varchar(63) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '模板编码',
  `name` varchar(63) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '模板名称',
  `content` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '模板内容',
  `params` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '参数数组',
  `remark` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '备注',
  `api_template_id` varchar(63) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '短信 API 的模板编号',
  `channel_id` bigint NOT NULL COMMENT '短信渠道编号',
  `channel_code` varchar(63) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '短信渠道编码',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 17 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '短信模板' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of tenant_sms_template
-- ----------------------------
INSERT INTO `tenant_sms_template` VALUES (14, 1, 0, 'user-update-mobile', '会员用户 - 修改手机', '您的验证码{code}，该验证码 5 分钟内有效，请勿泄漏于他人！', '[\"code\"]', '', 'null', 4, 'DEBUG_DING_TALK', '1', '2023-08-19 18:58:01', '1', '2023-08-19 11:34:04', b'0', 0);
INSERT INTO `tenant_sms_template` VALUES (15, 1, 0, 'user-update-password', '会员用户 - 修改密码', '您的验证码{code}，该验证码 5 分钟内有效，请勿泄漏于他人！', '[\"code\"]', '', 'null', 4, 'DEBUG_DING_TALK', '1', '2023-08-19 18:58:01', '1', '2023-08-19 11:34:18', b'0', 0);
INSERT INTO `tenant_sms_template` VALUES (16, 1, 0, 'user-reset-password', '会员用户 - 重置密码', '您的验证码{code}，该验证码 5 分钟内有效，请勿泄漏于他人！', '[\"code\"]', '', 'null', 4, 'DEBUG_DING_TALK', '1', '2023-08-19 18:58:01', '1', '2023-08-19 11:34:18', b'0', 0);

-- ----------------------------
-- Table structure for tenant_social_client
-- ----------------------------
DROP TABLE IF EXISTS `tenant_social_client`;
CREATE TABLE `tenant_social_client`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '应用名',
  `social_type` tinyint NOT NULL COMMENT '社交平台的类型',
  `user_type` tinyint NOT NULL COMMENT '用户类型',
  `client_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '客户端编号',
  `client_secret` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '客户端密钥',
  `agent_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '代理编号',
  `status` tinyint NOT NULL COMMENT '状态',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 44 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '社交客户端表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of tenant_social_client
-- ----------------------------

-- ----------------------------
-- Table structure for tenant_social_user
-- ----------------------------
DROP TABLE IF EXISTS `tenant_social_user`;
CREATE TABLE `tenant_social_user`  (
  `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键(自增策略)',
  `type` tinyint NOT NULL COMMENT '社交平台的类型',
  `openid` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '社交 openid',
  `token` varchar(256) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '社交 token',
  `raw_token_info` varchar(1024) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '原始 Token 数据，一般是 JSON 格式',
  `nickname` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '用户昵称',
  `avatar` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '用户头像',
  `raw_user_info` varchar(1024) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '原始用户数据，一般是 JSON 格式',
  `code` varchar(256) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '最后一次的认证 code',
  `state` varchar(256) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '最后一次的认证 state',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 25 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '社交用户表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of tenant_social_user
-- ----------------------------

-- ----------------------------
-- Table structure for tenant_social_user_bind
-- ----------------------------
DROP TABLE IF EXISTS `tenant_social_user_bind`;
CREATE TABLE `tenant_social_user_bind`  (
  `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键(自增策略)',
  `saas_user_id` bigint NOT NULL COMMENT '所属SaaS用户表编号',
  `user_type` tinyint NOT NULL COMMENT '用户类型',
  `social_type` tinyint NOT NULL COMMENT '社交平台的类型',
  `social_user_id` bigint NOT NULL COMMENT '社交用户的编号',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 81 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '社交绑定表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of tenant_social_user_bind
-- ----------------------------

-- ----------------------------
-- Table structure for system_user_dept
-- ----------------------------
DROP TABLE IF EXISTS `system_user_dept`;
CREATE TABLE `system_user_dept`  (
                                     `id` bigint NOT NULL AUTO_INCREMENT COMMENT '自增编号',
                                     `user_id` bigint NOT NULL COMMENT '用户ID',
                                     `dept_id` bigint NOT NULL COMMENT '部门ID',
                                     `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
                                     `create_time` datetime NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
                                     `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
                                     `update_time` datetime NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
                                     `deleted` bit(1) NULL DEFAULT b'0' COMMENT '是否删除',
                                     `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
                                     PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '用户和部门关联表' ROW_FORMAT = DYNAMIC;


-- ----------------------------
-- Table structures synchronized from development schema
-- ----------------------------
-- ----------------------------
-- Table structure for im_audit_log
-- ----------------------------
DROP TABLE IF EXISTS `im_audit_log`;
CREATE TABLE `im_audit_log` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',
  `user_id` bigint NOT NULL COMMENT '用户编号',
  `event_type` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '事件类型(LOGIN/LOGOUT/KICKED/DEVICE_MANAGE/AUTH_FAILURE 等)',
  `event_name` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '事件名称(中文描述)',
  `device_id` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '设备ID',
  `device_type` int DEFAULT NULL COMMENT '设备类型(1-Web 2-Android 3-iOS 4-Desktop)',
  `ip_address` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'IP地址',
  `user_agent` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '客户端信息',
  `details` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '详细信息(JSON格式)',
  `timestamp` bigint DEFAULT NULL COMMENT '事件时间戳(毫秒)',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_tenant_user_time` (`tenant_id`,`user_id`,`timestamp` DESC) USING BTREE COMMENT '租户+用户+时间索引',
  KEY `idx_tenant_event_time` (`tenant_id`,`event_type`,`timestamp` DESC) USING BTREE COMMENT '租户+事件类型+时间索引',
  KEY `idx_tenant` (`tenant_id`) USING BTREE COMMENT '租户索引'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='IM审计日志表(等保三级合规)';

-- ----------------------------
-- Table structure for im_call_event
-- ----------------------------
DROP TABLE IF EXISTS `im_call_event`;
CREATE TABLE `im_call_event` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '事件ID',
  `call_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '通话ID',
  `event_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '事件ID（messageId，用于幂等）',
  `signal_type` tinyint NOT NULL COMMENT '信令类型(1-呼叫 2-接听 3-拒绝 4-挂断 5-忙线 6-切换摄像头)',
  `sender_id` bigint NOT NULL COMMENT '发送者用户ID',
  `device_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '设备ID',
  `payload_json` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '事件载荷（extraData，JSON格式）',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_call_event` (`call_id`,`event_id`) USING BTREE COMMENT '通话+事件唯一索引',
  KEY `idx_call_id` (`call_id`) USING BTREE COMMENT '通话ID索引',
  KEY `idx_tenant` (`tenant_id`) USING BTREE COMMENT '租户索引'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='IM通话事件表';

-- ----------------------------
-- Table structure for im_call_event_outbox
-- ----------------------------
DROP TABLE IF EXISTS `im_call_event_outbox`;
CREATE TABLE `im_call_event_outbox` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint NOT NULL,
  `call_id` varchar(64) NOT NULL,
  `event_type` varchar(64) NOT NULL,
  `event_version` int NOT NULL,
  `recipient_id` bigint DEFAULT NULL,
  `payload` json NOT NULL,
  `status` varchar(16) NOT NULL DEFAULT 'PENDING',
  `retry_count` int NOT NULL DEFAULT '0',
  `next_retry_at` datetime DEFAULT NULL,
  `published_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_im_call_outbox_event` (`call_id`,`event_version`,`event_type`,`recipient_id`),
  KEY `idx_im_call_outbox_pending` (`status`,`next_retry_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='IM 通话事件事务 outbox';

-- ----------------------------
-- Table structure for im_call_participant
-- ----------------------------
DROP TABLE IF EXISTS `im_call_participant`;
CREATE TABLE `im_call_participant` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `call_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '通话ID',
  `user_id` bigint NOT NULL COMMENT '参与者用户ID',
  `device_id` varchar(128) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '实际加入设备',
  `role` tinyint NOT NULL DEFAULT '1' COMMENT '角色：1-主叫 2-被叫',
  `join_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '加入时间',
  `leave_time` datetime DEFAULT NULL COMMENT '离开时间',
  `status` tinyint NOT NULL DEFAULT '1' COMMENT '状态：1-在线 2-离线 3-已离开',
  `invite_state` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDING' COMMENT 'PENDING/ACCEPTED/REJECTED/BUSY/TIMEOUT',
  `join_state` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'NOT_JOINED' COMMENT 'NOT_JOINED/JOINED/LEFT',
  `joined_at` datetime DEFAULT NULL,
  `left_at` datetime DEFAULT NULL,
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_call_user_device` (`call_id`,`user_id`,`device_id`,`deleted`) USING BTREE,
  KEY `idx_call_id` (`call_id`) USING BTREE,
  KEY `idx_user_id` (`user_id`) USING BTREE,
  KEY `idx_tenant` (`tenant_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='IM 通话参与者表（群组通话）';

-- ----------------------------
-- Table structure for im_call_record
-- ----------------------------
DROP TABLE IF EXISTS `im_call_record`;
CREATE TABLE `im_call_record` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '通话记录ID',
  `call_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '通话ID(唯一标识)',
  `call_type` tinyint NOT NULL COMMENT '通话类型(1-语音通话 2-视频通话)',
  `caller_id` bigint NOT NULL COMMENT '呼叫者ID',
  `callee_id` bigint NOT NULL COMMENT '被叫者ID',
  `start_time` datetime NOT NULL COMMENT '通话开始时间',
  `end_time` datetime DEFAULT NULL COMMENT '通话结束时间',
  `connected_at` datetime DEFAULT NULL COMMENT '媒体双方/首个群成员连接时间',
  `duration` int NOT NULL DEFAULT '0' COMMENT '通话时长(秒)',
  `status` tinyint NOT NULL COMMENT '通话状态(1-未接听 2-已接听 3-已拒绝 4-忙线 5-已取消)',
  `state` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'INIT' COMMENT '状态机状态(INIT/RINGING/CONNECTING/CONNECTED/ENDED)',
  `state_version` int NOT NULL DEFAULT '0' COMMENT '通话事件版本，客户端去重与状态对账',
  `end_reason` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '结束原因(HANGUP/REJECT/TIMEOUT/BUSY/CANCEL/CALLEE_OFFLINE/ERROR)',
  `accepted_device_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '接听设备ID（CAS 裁决写入，用于 SDP/ICE 定向转发）',
  `chat_id` bigint DEFAULT NULL COMMENT '关联会话ID（通话结束时填入）',
  `group_id` bigint DEFAULT NULL COMMENT '群组ID（群通话时使用）',
  `record_message_id` bigint DEFAULT NULL COMMENT '通话记录消息ID（CALL_RECORD=209 生成后回填）',
  `caller_name` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '主叫方昵称',
  `caller_avatar` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '主叫方头像',
  `callee_name` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '被叫方昵称',
  `callee_avatar` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '被叫方头像',
  `room_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Janus 房间ID',
  `provider` varchar(24) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'LIVEKIT' COMMENT 'RTC 提供方：LIVEKIT；历史数据仅用于展示',
  `call_mode` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DIRECT' COMMENT 'DIRECT/GROUP',
  `owner_id` bigint DEFAULT NULL COMMENT '通话创建者，群通话拥有结束全体权限',
  `livekit_room` varchar(128) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'LiveKit 房间名',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `idx_tenant_call_id` (`tenant_id`,`call_id`) USING BTREE COMMENT '租户+通话ID唯一索引',
  UNIQUE KEY `uk_im_call_livekit_room` (`livekit_room`),
  KEY `idx_caller` (`caller_id`,`start_time` DESC) USING BTREE COMMENT '呼叫者+时间索引',
  KEY `idx_callee` (`callee_id`,`start_time` DESC) USING BTREE COMMENT '被叫者+时间索引',
  KEY `idx_callee_state` (`callee_id`,`state`) USING BTREE COMMENT '被叫者+状态索引（忙线检测）',
  KEY `idx_chat_started_at` (`chat_id`,`start_time` DESC) USING BTREE COMMENT '会话+时间索引（通话记录查询）',
  KEY `idx_tenant` (`tenant_id`) USING BTREE COMMENT '租户索引',
  KEY `idx_im_call_provider_state` (`tenant_id`,`provider`,`state`),
  KEY `idx_im_call_owner_state` (`tenant_id`,`owner_id`,`state`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='IM通话记录表';

-- ----------------------------
-- Table structure for im_chat
-- ----------------------------
DROP TABLE IF EXISTS `im_chat`;
CREATE TABLE `im_chat` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT 'ChatID',
  `chat_type` tinyint NOT NULL COMMENT '会话类型(1-单聊 2-群聊)',
  `single_user1` bigint DEFAULT NULL COMMENT '单聊用户1(较小ID)',
  `single_user2` bigint DEFAULT NULL COMMENT '单聊用户2(较大ID)',
  `group_id` bigint DEFAULT NULL COMMENT '群ID',
  `last_sequence` bigint NOT NULL DEFAULT '0' COMMENT '会话内消息序列号水位（自增）',
  `status` tinyint NOT NULL DEFAULT '1' COMMENT '状态(1-正常 2-已解散)',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_single_chat` (`tenant_id`,`chat_type`,`single_user1`,`single_user2`,`deleted`) USING BTREE,
  UNIQUE KEY `uk_group_chat` (`tenant_id`,`chat_type`,`group_id`,`deleted`) USING BTREE,
  KEY `idx_tenant` (`tenant_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='IM全局会话表';

-- ----------------------------
-- Table structure for im_chat_clear_watermark
-- ----------------------------
DROP TABLE IF EXISTS `im_chat_clear_watermark`;
CREATE TABLE `im_chat_clear_watermark` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `chat_id` bigint NOT NULL COMMENT 'ChatID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `clear_sequence` bigint NOT NULL DEFAULT '0' COMMENT '清空水位（单调递增）：消息 sequence <= clear_sequence 对该用户不可见',
  `cleared_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '清空时间',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_user_chat` (`tenant_id`,`user_id`,`chat_id`,`deleted`) USING BTREE,
  KEY `idx_user_time` (`tenant_id`,`user_id`,`update_time` DESC) USING BTREE,
  KEY `idx_chat` (`tenant_id`,`chat_id`,`deleted`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='IM会话清空水位表(对我清空，多端一致)';

-- ----------------------------
-- Table structure for im_chat_message
-- ----------------------------
DROP TABLE IF EXISTS `im_chat_message`;
CREATE TABLE `im_chat_message` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '消息ID',
  `chat_id` bigint NOT NULL COMMENT 'ChatID',
  `sequence` bigint NOT NULL DEFAULT '0' COMMENT '会话内序列号（单调递增，用于排序与断线补偿）',
  `sender_id` bigint NOT NULL COMMENT '发送者ID',
  `message_type` tinyint NOT NULL COMMENT '消息类型(1-文本 2-图片 3-语音 4-视频 5-文件 6-位置 7-表情包 8-自定义贴纸 10-系统消息)',
  `content` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '消息内容',
  `extra` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '扩展信息(JSON格式,存储文件URL、时长、大小等)',
  `send_time` datetime NOT NULL COMMENT '发送时间',
  `rev` bigint NOT NULL DEFAULT '1' COMMENT '消息版本号（最终态：撤回/编辑/删除等变更时 rev+1，用于乱序合并）',
  `status` tinyint NOT NULL DEFAULT '2' COMMENT '消息状态(2-已发送 6-已撤回)',
  `recall_time` datetime DEFAULT NULL COMMENT '撤回时间',
  `recall_by` bigint DEFAULT NULL COMMENT '撤回人ID',
  `quote_message_id` bigint DEFAULT NULL COMMENT '引用消息ID',
  `forwarded_from` json DEFAULT NULL COMMENT '转发来源信息(JSON: {originalMessageId, originalChatId, originalSenderId, originalSenderName, forwardTime})',
  `client_message_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '客户端消息ID(幂等键，用于重发)',
  `mentions` json DEFAULT NULL COMMENT '被@提及用户列表(JSON数组: [{userId, nickname}])',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_client_message_id` (`client_message_id`),
  KEY `idx_chat_seq` (`tenant_id`,`chat_id`,`sequence` DESC) USING BTREE,
  KEY `idx_sender_time` (`tenant_id`,`sender_id`,`send_time` DESC) USING BTREE,
  KEY `idx_tenant` (`tenant_id`) USING BTREE,
  KEY `idx_search_scope` (`tenant_id`,`chat_id`,`message_type`,`send_time` DESC,`deleted`),
  KEY `idx_chat_type_sendtime` (`chat_id`,`deleted`,`message_type`,`send_time` DESC),
  KEY `idx_tenant_chat_sendtime` (`tenant_id`,`chat_id`,`send_time` DESC),
  KEY `idx_tenant_type_sendtime` (`tenant_id`,`deleted`,`message_type`,`send_time` DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='IM消息表(全局会话单份存储)';

-- ----------------------------
-- Table structure for im_chat_message_tombstone
-- ----------------------------
DROP TABLE IF EXISTS `im_chat_message_tombstone`;
CREATE TABLE `im_chat_message_tombstone` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `chat_id` bigint NOT NULL COMMENT 'ChatID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `message_id` bigint NOT NULL COMMENT '消息ID',
  `deleted_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '对我删除时间',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_user_message` (`tenant_id`,`user_id`,`message_id`,`deleted`) USING BTREE,
  KEY `idx_user_chat` (`tenant_id`,`user_id`,`chat_id`,`deleted`) USING BTREE,
  KEY `idx_chat_message` (`tenant_id`,`chat_id`,`message_id`,`deleted`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='IM消息对我删除墓碑表(多端一致)';

-- ----------------------------
-- Table structure for im_chat_user
-- ----------------------------
DROP TABLE IF EXISTS `im_chat_user`;
CREATE TABLE `im_chat_user` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '用户会话ID',
  `chat_id` bigint NOT NULL COMMENT 'ChatID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `unread_count` int NOT NULL DEFAULT '0' COMMENT '未读消息数',
  `last_read_message_id` bigint DEFAULT NULL COMMENT '最后已读消息ID',
  `last_read_sequence` bigint NOT NULL DEFAULT '0' COMMENT '最后已读序列号水位（单调递增）',
  `last_message_id` bigint DEFAULT NULL COMMENT '最后一条消息ID',
  `last_message_sequence` bigint NOT NULL DEFAULT '0' COMMENT '最后一条消息序列号水位（单调递增）',
  `last_message_sender_id` bigint DEFAULT NULL COMMENT '最后一条消息发送者ID（冗余字段，避免回表查询 im_chat_message）',
  `last_message_type` tinyint DEFAULT NULL COMMENT '最后一条消息类型(同 im_chat_message.message_type)',
  `last_message_content` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '最后一条消息预览',
  `last_message_has_at_me` bit(1) NOT NULL DEFAULT b'0' COMMENT '最后一条消息是否@了我（用于会话列表[有人@我]标记）',
  `last_message_time` datetime DEFAULT NULL COMMENT '最后一条消息时间',
  `is_pinned` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否置顶',
  `no_disturb` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否免打扰',
  `draft` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '草稿内容',
  `deleted_by_user` bit(1) NOT NULL DEFAULT b'0' COMMENT '用户是否删除会话',
  `group_member_status` tinyint NOT NULL DEFAULT '0' COMMENT '群组成员状态：0=正常(在群内), 1=已退出(主动退群), 2=已被踢(被群主/管理员踢出), 3=群已解散',
  `left_at` datetime DEFAULT NULL COMMENT '离群时间（被踢/退群时间，用于限制只能查询离群前的消息）',
  `snapshot_data` json DEFAULT NULL COMMENT '群组快照数据JSON（被踢/退群/解散时冻结，包含群名称、公告、成员列表关键信息等）',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_user_chat` (`tenant_id`,`user_id`,`chat_id`,`deleted`) USING BTREE,
  KEY `idx_user_time` (`tenant_id`,`user_id`,`last_message_time` DESC) USING BTREE,
  KEY `idx_chat` (`tenant_id`,`chat_id`) USING BTREE,
  KEY `idx_user_group_status` (`tenant_id`,`user_id`,`group_member_status`) USING BTREE,
  KEY `idx_user_pinned_time` (`tenant_id`,`user_id`,`deleted_by_user`,`is_pinned`,`last_message_time` DESC),
  KEY `idx_chat_user_deleted` (`tenant_id`,`chat_id`,`user_id`,`deleted`,`deleted_by_user`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='IM用户会话状态表';

-- ----------------------------
-- Table structure for im_contact_setting
-- ----------------------------
DROP TABLE IF EXISTS `im_contact_setting`;
CREATE TABLE `im_contact_setting` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '设置ID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `contact_id` bigint NOT NULL COMMENT '联系人ID',
  `remark_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '备注名(保留字段,当前版本未使用)',
  `star` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否星标',
  `no_disturb` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否免打扰',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `idx_user_contact_deleted` (`user_id`,`contact_id`,`tenant_id`,`deleted`) USING BTREE COMMENT '用户+联系人+删除状态唯一索引',
  KEY `idx_tenant` (`tenant_id`) USING BTREE COMMENT '租户索引'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='IM联系人设置表';

-- ----------------------------
-- Table structure for im_conversation_user_state
-- ----------------------------
DROP TABLE IF EXISTS `im_conversation_user_state`;
CREATE TABLE `im_conversation_user_state` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `chat_id` bigint NOT NULL COMMENT 'ChatID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `cursor_version` bigint NOT NULL DEFAULT '0' COMMENT '会话同步游标版本号（用户维度）',
  `conversation_version` bigint NOT NULL DEFAULT '0' COMMENT '会话版本号（会话级，用于合并快照）',
  `unread_count` int NOT NULL DEFAULT '0' COMMENT '未读消息数',
  `last_read_sequence` bigint NOT NULL DEFAULT '0' COMMENT '最后已读序列号水位（单调递增）',
  `last_read_time` datetime DEFAULT NULL COMMENT '最后已读时间',
  `last_message_id` bigint DEFAULT NULL COMMENT '最后一条消息ID',
  `last_message_sequence` bigint NOT NULL DEFAULT '0' COMMENT '最后一条消息序列号水位（单调递增）',
  `last_message_sender_id` bigint DEFAULT NULL COMMENT '最后一条消息发送者ID（冗余字段，避免回表查询 im_chat_message）',
  `last_message_type` tinyint DEFAULT NULL COMMENT '最后一条消息类型(同 im_chat_message.message_type)',
  `last_message_content` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '最后一条消息预览',
  `last_message_has_at_me` bit(1) NOT NULL DEFAULT b'0' COMMENT '最后一条消息是否@了我（用于会话列表[有人@我]标记）',
  `last_message_time` datetime DEFAULT NULL COMMENT '最后一条消息时间',
  `is_pinned` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否置顶',
  `no_disturb` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否免打扰',
  `draft` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '草稿内容',
  `deleted_by_user` bit(1) NOT NULL DEFAULT b'0' COMMENT '用户是否删除会话',
  `group_member_status` tinyint DEFAULT NULL COMMENT '群组成员状态：0=正常(在群内), 1=已退出(主动退群), 2=已被踢(被群主/管理员踢出), 3=群已解散',
  `left_at` datetime DEFAULT NULL COMMENT '离群时间（被踢/退群时间，用于会话列表展示）',
  `snapshot_data` json DEFAULT NULL COMMENT '群组快照数据JSON（被踢/退群/解散时冻结，用于会话列表和聊天页展示）',
  `member_snapshot_json` json DEFAULT NULL COMMENT '群成员快照JSON（在踢人/退群/群解散时保存，用于不在群内的用户查看历史成员）',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_user_chat_state` (`tenant_id`,`user_id`,`chat_id`,`deleted`) USING BTREE,
  KEY `idx_user_cursor` (`tenant_id`,`user_id`,`cursor_version`) USING BTREE,
  KEY `idx_chat` (`tenant_id`,`chat_id`) USING BTREE,
  KEY `idx_user_group_status` (`tenant_id`,`user_id`,`group_member_status`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='IM会话-用户态表';

-- ----------------------------
-- Table structure for im_group
-- ----------------------------
DROP TABLE IF EXISTS `im_group`;
CREATE TABLE `im_group` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '群ID',
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '群名称',
  `avatar` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '群头像',
  `owner_id` bigint NOT NULL COMMENT '群主ID',
  `group_type` tinyint NOT NULL DEFAULT '1' COMMENT '群类型(1-普通群 2-工作群)',
  `member_count` int NOT NULL DEFAULT '0' COMMENT '成员数量',
  `max_member_count` int NOT NULL DEFAULT '500' COMMENT '最大成员数量',
  `notice` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '群公告',
  `notice_pinned` bit(1) NOT NULL DEFAULT b'0' COMMENT '群公告是否置顶',
  `introduction` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '群简介',
  `status` tinyint NOT NULL DEFAULT '1' COMMENT '群状态(1-正常 2-已解散)',
  `allow_member_invite` bit(1) NOT NULL DEFAULT b'1' COMMENT '是否允许成员邀请',
  `need_approval` bit(1) NOT NULL DEFAULT b'0' COMMENT '加群是否需要审批',
  `mute_all` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否全员禁言',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_owner` (`owner_id`) USING BTREE COMMENT '群主索引',
  KEY `idx_tenant` (`tenant_id`) USING BTREE COMMENT '租户索引'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='IM群组表';

-- ----------------------------
-- Table structure for im_group_file
-- ----------------------------
DROP TABLE IF EXISTS `im_group_file`;
CREATE TABLE `im_group_file` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `group_id` bigint NOT NULL COMMENT '群组ID',
  `file_id` bigint NOT NULL COMMENT '文件ID(关联 infra_file.id)',
  `uploader_id` bigint NOT NULL COMMENT '上传者ID',
  `folder_id` bigint DEFAULT '0' COMMENT '文件夹ID(0表示根目录)',
  `is_favorite` bit(1) DEFAULT b'0' COMMENT '是否收藏',
  `download_count` int DEFAULT '0' COMMENT '下载次数',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_group_file_deleted` (`group_id`,`file_id`,`tenant_id`,`deleted`) USING BTREE COMMENT '群组文件唯一索引(包含deleted)',
  KEY `idx_group` (`group_id`,`tenant_id`) USING BTREE COMMENT '群组索引',
  KEY `idx_uploader` (`uploader_id`) USING BTREE COMMENT '上传者索引',
  KEY `idx_folder` (`folder_id`) USING BTREE COMMENT '文件夹索引',
  KEY `idx_tenant` (`tenant_id`) USING BTREE COMMENT '租户索引'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='IM群文件关联表';

-- ----------------------------
-- Table structure for im_group_folder
-- ----------------------------
DROP TABLE IF EXISTS `im_group_folder`;
CREATE TABLE `im_group_folder` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `group_id` bigint NOT NULL COMMENT '群组ID',
  `folder_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '文件夹名称',
  `parent_id` bigint DEFAULT '0' COMMENT '父文件夹ID(0表示根目录)',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_group` (`group_id`,`tenant_id`) USING BTREE COMMENT '群组索引',
  KEY `idx_parent` (`parent_id`) USING BTREE COMMENT '父文件夹索引',
  KEY `idx_tenant` (`tenant_id`) USING BTREE COMMENT '租户索引'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='IM群文件夹表';

-- ----------------------------
-- Table structure for im_group_invite
-- ----------------------------
DROP TABLE IF EXISTS `im_group_invite`;
CREATE TABLE `im_group_invite` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '邀请ID',
  `group_id` bigint NOT NULL COMMENT '群ID',
  `invite_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '邀请码(唯一)',
  `creator_id` bigint NOT NULL COMMENT '创建者ID',
  `expire_time` datetime NOT NULL COMMENT '过期时间',
  `max_use_count` int NOT NULL DEFAULT '0' COMMENT '最大使用次数(0表示不限制)',
  `used_count` int NOT NULL DEFAULT '0' COMMENT '已使用次数',
  `status` tinyint NOT NULL DEFAULT '1' COMMENT '状态(1-有效 2-已过期 3-已禁用)',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `idx_tenant_invite_code` (`tenant_id`,`invite_code`) USING BTREE COMMENT '租户+邀请码唯一索引',
  KEY `idx_group` (`group_id`) USING BTREE COMMENT '群组索引',
  KEY `idx_expire` (`expire_time`,`status`) USING BTREE COMMENT '过期时间+状态索引',
  KEY `idx_tenant` (`tenant_id`) USING BTREE COMMENT '租户索引'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='IM群邀请码表';

-- ----------------------------
-- Table structure for im_group_join_request
-- ----------------------------
DROP TABLE IF EXISTS `im_group_join_request`;
CREATE TABLE `im_group_join_request` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '申请单ID',
  `group_id` bigint NOT NULL COMMENT '群ID',
  `applicant_user_id` bigint NOT NULL COMMENT '申请人用户ID',
  `invite_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '触发申请的邀请码',
  `status` tinyint NOT NULL DEFAULT '1' COMMENT '状态(1-待审批 2-已通过 3-已拒绝)',
  `reject_reason` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '拒绝原因',
  `handled_by` bigint DEFAULT NULL COMMENT '处理人用户ID',
  `handled_time` datetime DEFAULT NULL COMMENT '处理时间',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_group_status` (`group_id`,`status`) USING BTREE COMMENT '群组+状态索引',
  KEY `idx_group_applicant_status` (`group_id`,`applicant_user_id`,`status`) USING BTREE COMMENT '群组+申请人+状态索引',
  KEY `idx_tenant` (`tenant_id`) USING BTREE COMMENT '租户索引'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='IM群加群申请表';

-- ----------------------------
-- Table structure for im_group_member
-- ----------------------------
DROP TABLE IF EXISTS `im_group_member`;
CREATE TABLE `im_group_member` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '成员ID',
  `group_id` bigint NOT NULL COMMENT '群ID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `role` tinyint NOT NULL DEFAULT '3' COMMENT '角色(1-群主 2-管理员 3-普通成员)',
  `nickname` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '群昵称',
  `join_time` datetime NOT NULL COMMENT '加入时间',
  `mute_end_time` datetime DEFAULT NULL COMMENT '禁言结束时间',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `idx_group_user_deleted` (`group_id`,`user_id`,`tenant_id`,`deleted`) USING BTREE COMMENT '群+用户+删除状态唯一索引',
  KEY `idx_user` (`user_id`) USING BTREE COMMENT '用户索引',
  KEY `idx_tenant` (`tenant_id`) USING BTREE COMMENT '租户索引',
  KEY `idx_group_deleted` (`group_id`,`deleted`),
  KEY `idx_group_role_deleted` (`group_id`,`role`,`deleted`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='IM群成员表';

-- ----------------------------
-- Table structure for im_message_favorite
-- ----------------------------
DROP TABLE IF EXISTS `im_message_favorite`;
CREATE TABLE `im_message_favorite` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `user_id` bigint NOT NULL COMMENT '收藏用户ID',
  `message_id` bigint NOT NULL COMMENT '消息ID',
  `chat_id` bigint NOT NULL COMMENT '会话ID',
  `anchor_sequence` bigint NOT NULL DEFAULT '0' COMMENT '收藏时锚点序列号',
  `message_type` tinyint DEFAULT NULL COMMENT '收藏时消息类型快照',
  `message_preview` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '收藏时消息预览快照',
  `message_content` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '收藏时消息内容快照',
  `message_extra` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '收藏时消息扩展快照',
  `message_snapshot` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '收藏时完整消息快照(JSON)',
  `source_send_time` datetime DEFAULT NULL COMMENT '收藏时原消息发送时间',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_user_message_deleted` (`tenant_id`,`user_id`,`message_id`,`deleted`) USING BTREE,
  KEY `idx_user_created` (`tenant_id`,`user_id`,`create_time`,`deleted`) USING BTREE,
  KEY `idx_chat_anchor` (`tenant_id`,`chat_id`,`anchor_sequence`,`deleted`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='IM消息收藏表';

-- ----------------------------
-- Table structure for im_message_read
-- ----------------------------
DROP TABLE IF EXISTS `im_message_read`;
CREATE TABLE `im_message_read` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '已读ID',
  `message_id` bigint NOT NULL COMMENT '消息ID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `read_time` datetime NOT NULL COMMENT '已读时间',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `idx_message_user_deleted` (`message_id`,`user_id`,`tenant_id`,`deleted`) USING BTREE COMMENT '消息+用户+删除状态唯一索引',
  KEY `idx_user` (`user_id`) USING BTREE COMMENT '用户索引',
  KEY `idx_tenant` (`tenant_id`) USING BTREE COMMENT '租户索引',
  KEY `idx_message_deleted` (`message_id`,`deleted`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='IM消息已读表(群聊)';

-- ----------------------------
-- Table structure for im_message_voice_play
-- ----------------------------
DROP TABLE IF EXISTS `im_message_voice_play`;
CREATE TABLE `im_message_voice_play` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `message_id` bigint NOT NULL COMMENT '语音消息ID',
  `chat_id` bigint NOT NULL COMMENT '会话ID',
  `user_id` bigint NOT NULL COMMENT '播放用户ID',
  `played_time` datetime NOT NULL COMMENT '首次播放时间',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `idx_message_user_deleted` (`message_id`,`user_id`,`tenant_id`,`deleted`) USING BTREE COMMENT '消息+用户+删除状态唯一索引',
  KEY `idx_user_chat` (`user_id`,`chat_id`,`tenant_id`,`deleted`) USING BTREE COMMENT '用户会话查询索引',
  KEY `idx_played_time` (`played_time`,`tenant_id`,`deleted`) USING BTREE COMMENT '首次播放时间查询索引',
  KEY `idx_tenant` (`tenant_id`) USING BTREE COMMENT '租户索引'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='IM语音消息播放状态表';

-- ----------------------------
-- Table structure for im_notification
-- ----------------------------
DROP TABLE IF EXISTS `im_notification`;
CREATE TABLE `im_notification` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '通知ID',
  `user_id` bigint NOT NULL COMMENT '接收用户ID',
  `notify_type` tinyint NOT NULL COMMENT '通知类型(1-系统公告 2-流程审批 3-待办提醒 4-自定义通知)',
  `title` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '通知标题',
  `content` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '通知内容',
  `icon` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '通知图标URL',
  `extra` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '扩展信息(JSON格式,存储操作按钮、跳转配置、业务数据等)',
  `is_read` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否已读',
  `read_time` datetime DEFAULT NULL COMMENT '已读时间',
  `is_important` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否重要(重要通知需强制阅读)',
  `expire_time` datetime DEFAULT NULL COMMENT '过期时间',
  `status` tinyint NOT NULL DEFAULT '1' COMMENT '通知状态(1-正常 2-已过期 3-已撤回)',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_user_time` (`user_id`,`create_time` DESC) USING BTREE COMMENT '用户+时间索引',
  KEY `idx_user_read` (`user_id`,`is_read`) USING BTREE COMMENT '用户+已读状态索引',
  KEY `idx_type` (`notify_type`) USING BTREE COMMENT '通知类型索引',
  KEY `idx_tenant` (`tenant_id`) USING BTREE COMMENT '租户索引'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='IM通知表';

-- ----------------------------
-- Table structure for im_user_cursor
-- ----------------------------
DROP TABLE IF EXISTS `im_user_cursor`;
CREATE TABLE `im_user_cursor` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `next_cursor_version` bigint NOT NULL DEFAULT '0' COMMENT '下一个会话同步游标版本号',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_user_cursor` (`tenant_id`,`user_id`,`deleted`) USING BTREE,
  KEY `idx_tenant` (`tenant_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='IM用户会话游标分配器';

-- ----------------------------
-- Table structure for im_user_sticker
-- ----------------------------
DROP TABLE IF EXISTS `im_user_sticker`;
CREATE TABLE `im_user_sticker` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `file_id` bigint NOT NULL COMMENT '原图文件ID',
  `thumb_file_id` bigint DEFAULT NULL COMMENT '缩略图文件ID',
  `name` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '表情名称',
  `md5` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '文件MD5或幂等键',
  `width` int DEFAULT NULL COMMENT '宽度',
  `height` int DEFAULT NULL COMMENT '高度',
  `mime_type` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '媒体类型',
  `source_type` tinyint NOT NULL DEFAULT '1' COMMENT '来源(1-上传 2-聊天收藏 3-商店)',
  `source_message_id` bigint DEFAULT NULL COMMENT '来源消息ID',
  `sort_no` int NOT NULL DEFAULT '0' COMMENT '排序号',
  `status` tinyint NOT NULL DEFAULT '1' COMMENT '状态(1-正常 2-已移除)',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_user_md5_deleted` (`tenant_id`,`user_id`,`md5`,`deleted`) USING BTREE,
  KEY `idx_user_sort_deleted` (`tenant_id`,`user_id`,`sort_no`,`deleted`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='IM用户自定义表情表';

-- ----------------------------
-- Table structure for im_user_sticker_recent
-- ----------------------------
DROP TABLE IF EXISTS `im_user_sticker_recent`;
CREATE TABLE `im_user_sticker_recent` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `sticker_id` bigint NOT NULL COMMENT '表情ID',
  `last_used_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '最近使用时间',
  `use_count` int NOT NULL DEFAULT '1' COMMENT '使用次数',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_user_sticker_deleted` (`tenant_id`,`user_id`,`sticker_id`,`deleted`) USING BTREE,
  KEY `idx_user_last_used_deleted` (`tenant_id`,`user_id`,`last_used_at`,`deleted`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='IM用户最近使用表情表';

-- ----------------------------
-- Table structure for infra_demo01_contact
-- ----------------------------
DROP TABLE IF EXISTS `infra_demo01_contact`;
CREATE TABLE `infra_demo01_contact` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '名字',
  `sex` tinyint(1) NOT NULL COMMENT '性别',
  `birthday` datetime NOT NULL COMMENT '出生年',
  `description` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '简介',
  `avatar` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '头像',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='示例联系人表';

-- ----------------------------
-- Table structure for infra_demo02_category
-- ----------------------------
DROP TABLE IF EXISTS `infra_demo02_category`;
CREATE TABLE `infra_demo02_category` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '名字',
  `parent_id` bigint NOT NULL COMMENT '父级编号',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='示例分类表';

-- ----------------------------
-- Table structure for infra_demo03_course
-- ----------------------------
DROP TABLE IF EXISTS `infra_demo03_course`;
CREATE TABLE `infra_demo03_course` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `student_id` bigint NOT NULL COMMENT '学生编号',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '名字',
  `score` tinyint NOT NULL COMMENT '分数',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='学生课程表';

-- ----------------------------
-- Table structure for infra_demo03_grade
-- ----------------------------
DROP TABLE IF EXISTS `infra_demo03_grade`;
CREATE TABLE `infra_demo03_grade` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `student_id` bigint NOT NULL COMMENT '学生编号',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '名字',
  `teacher` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '班主任',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='学生班级表';

-- ----------------------------
-- Table structure for infra_demo03_student
-- ----------------------------
DROP TABLE IF EXISTS `infra_demo03_student`;
CREATE TABLE `infra_demo03_student` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '名字',
  `sex` tinyint NOT NULL COMMENT '性别',
  `birthday` datetime NOT NULL COMMENT '出生日期',
  `description` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '简介',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='学生表';

-- ----------------------------
-- Table structure for infra_file_upload_chunk
-- ----------------------------
DROP TABLE IF EXISTS `infra_file_upload_chunk`;
CREATE TABLE `infra_file_upload_chunk` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '分片编号',
  `upload_id` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '关联的分片上传唯一标识',
  `chunk_number` int NOT NULL COMMENT '分片序号，从 1 开始',
  `chunk_size` bigint NOT NULL COMMENT '分片大小（字节）',
  `etag` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '分片 ETag 或 S3 分片 ID',
  `status` tinyint NOT NULL DEFAULT '0' COMMENT '状态: 0-上传中, 1-已完成',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_upload_id_chunk_number` (`upload_id`,`chunk_number`) USING BTREE,
  KEY `idx_upload_id_status` (`upload_id`,`status`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='分片上传记录表';

-- ----------------------------
-- Table structure for infra_file_upload_task
-- ----------------------------
DROP TABLE IF EXISTS `infra_file_upload_task`;
CREATE TABLE `infra_file_upload_task` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '任务编号',
  `upload_id` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '分片上传唯一标识',
  `config_id` bigint DEFAULT NULL COMMENT '文件配置编号',
  `name` varchar(256) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '原始文件名',
  `path` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '目标文件路径',
  `type` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'MIME 类型',
  `total_size` bigint NOT NULL COMMENT '文件总大小（字节）',
  `chunk_size` int NOT NULL COMMENT '分片大小（字节）',
  `total_chunks` int NOT NULL COMMENT '总分片数',
  `uploaded_chunks` int NOT NULL DEFAULT '0' COMMENT '已上传分片数',
  `status` tinyint NOT NULL DEFAULT '0' COMMENT '状态: 0-初始化, 1-上传中, 2-已完成, 3-已取消, 4-已过期',
  `expire_time` datetime NOT NULL COMMENT '过期时间',
  `s3_upload_id` varchar(256) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'S3 分片上传 ID',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_upload_id` (`upload_id`) USING BTREE,
  KEY `idx_expire_time` (`expire_time`) USING BTREE,
  KEY `idx_status_update_time` (`status`,`update_time`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='分片上传任务表';

-- ----------------------------
-- Table structure for QRTZ_BLOB_TRIGGERS
-- ----------------------------
DROP TABLE IF EXISTS `QRTZ_BLOB_TRIGGERS`;
CREATE TABLE `QRTZ_BLOB_TRIGGERS` (
  `SCHED_NAME` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `TRIGGER_NAME` varchar(190) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `TRIGGER_GROUP` varchar(190) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `BLOB_DATA` blob,
  PRIMARY KEY (`SCHED_NAME`,`TRIGGER_NAME`,`TRIGGER_GROUP`) USING BTREE,
  KEY `SCHED_NAME` (`SCHED_NAME`,`TRIGGER_NAME`,`TRIGGER_GROUP`) USING BTREE,
  CONSTRAINT `qrtz_blob_triggers_ibfk_1` FOREIGN KEY (`SCHED_NAME`, `TRIGGER_NAME`, `TRIGGER_GROUP`) REFERENCES `QRTZ_TRIGGERS` (`SCHED_NAME`, `TRIGGER_NAME`, `TRIGGER_GROUP`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------
-- Table structure for QRTZ_CALENDARS
-- ----------------------------
DROP TABLE IF EXISTS `QRTZ_CALENDARS`;
CREATE TABLE `QRTZ_CALENDARS` (
  `SCHED_NAME` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `CALENDAR_NAME` varchar(190) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `CALENDAR` blob NOT NULL,
  PRIMARY KEY (`SCHED_NAME`,`CALENDAR_NAME`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------
-- Table structure for QRTZ_CRON_TRIGGERS
-- ----------------------------
DROP TABLE IF EXISTS `QRTZ_CRON_TRIGGERS`;
CREATE TABLE `QRTZ_CRON_TRIGGERS` (
  `SCHED_NAME` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `TRIGGER_NAME` varchar(190) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `TRIGGER_GROUP` varchar(190) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `CRON_EXPRESSION` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `TIME_ZONE_ID` varchar(80) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`SCHED_NAME`,`TRIGGER_NAME`,`TRIGGER_GROUP`) USING BTREE,
  CONSTRAINT `qrtz_cron_triggers_ibfk_1` FOREIGN KEY (`SCHED_NAME`, `TRIGGER_NAME`, `TRIGGER_GROUP`) REFERENCES `QRTZ_TRIGGERS` (`SCHED_NAME`, `TRIGGER_NAME`, `TRIGGER_GROUP`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------
-- Table structure for QRTZ_FIRED_TRIGGERS
-- ----------------------------
DROP TABLE IF EXISTS `QRTZ_FIRED_TRIGGERS`;
CREATE TABLE `QRTZ_FIRED_TRIGGERS` (
  `SCHED_NAME` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `ENTRY_ID` varchar(95) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `TRIGGER_NAME` varchar(190) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `TRIGGER_GROUP` varchar(190) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `INSTANCE_NAME` varchar(190) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `FIRED_TIME` bigint NOT NULL,
  `SCHED_TIME` bigint NOT NULL,
  `PRIORITY` int NOT NULL,
  `STATE` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `JOB_NAME` varchar(190) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `JOB_GROUP` varchar(190) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `IS_NONCONCURRENT` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `REQUESTS_RECOVERY` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`SCHED_NAME`,`ENTRY_ID`) USING BTREE,
  KEY `IDX_QRTZ_FT_TRIG_INST_NAME` (`SCHED_NAME`,`INSTANCE_NAME`) USING BTREE,
  KEY `IDX_QRTZ_FT_INST_JOB_REQ_RCVRY` (`SCHED_NAME`,`INSTANCE_NAME`,`REQUESTS_RECOVERY`) USING BTREE,
  KEY `IDX_QRTZ_FT_J_G` (`SCHED_NAME`,`JOB_NAME`,`JOB_GROUP`) USING BTREE,
  KEY `IDX_QRTZ_FT_JG` (`SCHED_NAME`,`JOB_GROUP`) USING BTREE,
  KEY `IDX_QRTZ_FT_T_G` (`SCHED_NAME`,`TRIGGER_NAME`,`TRIGGER_GROUP`) USING BTREE,
  KEY `IDX_QRTZ_FT_TG` (`SCHED_NAME`,`TRIGGER_GROUP`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------
-- Table structure for QRTZ_JOB_DETAILS
-- ----------------------------
DROP TABLE IF EXISTS `QRTZ_JOB_DETAILS`;
CREATE TABLE `QRTZ_JOB_DETAILS` (
  `SCHED_NAME` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `JOB_NAME` varchar(190) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `JOB_GROUP` varchar(190) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `DESCRIPTION` varchar(250) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `JOB_CLASS_NAME` varchar(250) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `IS_DURABLE` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `IS_NONCONCURRENT` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `IS_UPDATE_DATA` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `REQUESTS_RECOVERY` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `JOB_DATA` blob,
  PRIMARY KEY (`SCHED_NAME`,`JOB_NAME`,`JOB_GROUP`) USING BTREE,
  KEY `IDX_QRTZ_J_REQ_RECOVERY` (`SCHED_NAME`,`REQUESTS_RECOVERY`) USING BTREE,
  KEY `IDX_QRTZ_J_GRP` (`SCHED_NAME`,`JOB_GROUP`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------
-- Table structure for QRTZ_LOCKS
-- ----------------------------
DROP TABLE IF EXISTS `QRTZ_LOCKS`;
CREATE TABLE `QRTZ_LOCKS` (
  `SCHED_NAME` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `LOCK_NAME` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`SCHED_NAME`,`LOCK_NAME`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------
-- Table structure for QRTZ_PAUSED_TRIGGER_GRPS
-- ----------------------------
DROP TABLE IF EXISTS `QRTZ_PAUSED_TRIGGER_GRPS`;
CREATE TABLE `QRTZ_PAUSED_TRIGGER_GRPS` (
  `SCHED_NAME` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `TRIGGER_GROUP` varchar(190) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`SCHED_NAME`,`TRIGGER_GROUP`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------
-- Table structure for QRTZ_SCHEDULER_STATE
-- ----------------------------
DROP TABLE IF EXISTS `QRTZ_SCHEDULER_STATE`;
CREATE TABLE `QRTZ_SCHEDULER_STATE` (
  `SCHED_NAME` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `INSTANCE_NAME` varchar(190) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `LAST_CHECKIN_TIME` bigint NOT NULL,
  `CHECKIN_INTERVAL` bigint NOT NULL,
  PRIMARY KEY (`SCHED_NAME`,`INSTANCE_NAME`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------
-- Table structure for QRTZ_SIMPLE_TRIGGERS
-- ----------------------------
DROP TABLE IF EXISTS `QRTZ_SIMPLE_TRIGGERS`;
CREATE TABLE `QRTZ_SIMPLE_TRIGGERS` (
  `SCHED_NAME` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `TRIGGER_NAME` varchar(190) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `TRIGGER_GROUP` varchar(190) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `REPEAT_COUNT` bigint NOT NULL,
  `REPEAT_INTERVAL` bigint NOT NULL,
  `TIMES_TRIGGERED` bigint NOT NULL,
  PRIMARY KEY (`SCHED_NAME`,`TRIGGER_NAME`,`TRIGGER_GROUP`) USING BTREE,
  CONSTRAINT `qrtz_simple_triggers_ibfk_1` FOREIGN KEY (`SCHED_NAME`, `TRIGGER_NAME`, `TRIGGER_GROUP`) REFERENCES `QRTZ_TRIGGERS` (`SCHED_NAME`, `TRIGGER_NAME`, `TRIGGER_GROUP`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------
-- Table structure for QRTZ_SIMPROP_TRIGGERS
-- ----------------------------
DROP TABLE IF EXISTS `QRTZ_SIMPROP_TRIGGERS`;
CREATE TABLE `QRTZ_SIMPROP_TRIGGERS` (
  `SCHED_NAME` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `TRIGGER_NAME` varchar(190) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `TRIGGER_GROUP` varchar(190) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `STR_PROP_1` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `STR_PROP_2` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `STR_PROP_3` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `INT_PROP_1` int DEFAULT NULL,
  `INT_PROP_2` int DEFAULT NULL,
  `LONG_PROP_1` bigint DEFAULT NULL,
  `LONG_PROP_2` bigint DEFAULT NULL,
  `DEC_PROP_1` decimal(13,4) DEFAULT NULL,
  `DEC_PROP_2` decimal(13,4) DEFAULT NULL,
  `BOOL_PROP_1` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `BOOL_PROP_2` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`SCHED_NAME`,`TRIGGER_NAME`,`TRIGGER_GROUP`) USING BTREE,
  CONSTRAINT `qrtz_simprop_triggers_ibfk_1` FOREIGN KEY (`SCHED_NAME`, `TRIGGER_NAME`, `TRIGGER_GROUP`) REFERENCES `QRTZ_TRIGGERS` (`SCHED_NAME`, `TRIGGER_NAME`, `TRIGGER_GROUP`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------
-- Table structure for QRTZ_TRIGGERS
-- ----------------------------
DROP TABLE IF EXISTS `QRTZ_TRIGGERS`;
CREATE TABLE `QRTZ_TRIGGERS` (
  `SCHED_NAME` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `TRIGGER_NAME` varchar(190) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `TRIGGER_GROUP` varchar(190) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `JOB_NAME` varchar(190) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `JOB_GROUP` varchar(190) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `DESCRIPTION` varchar(250) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `NEXT_FIRE_TIME` bigint DEFAULT NULL,
  `PREV_FIRE_TIME` bigint DEFAULT NULL,
  `PRIORITY` int DEFAULT NULL,
  `TRIGGER_STATE` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `TRIGGER_TYPE` varchar(8) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `START_TIME` bigint NOT NULL,
  `END_TIME` bigint DEFAULT NULL,
  `CALENDAR_NAME` varchar(190) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `MISFIRE_INSTR` smallint DEFAULT NULL,
  `JOB_DATA` blob,
  PRIMARY KEY (`SCHED_NAME`,`TRIGGER_NAME`,`TRIGGER_GROUP`) USING BTREE,
  KEY `IDX_QRTZ_T_J` (`SCHED_NAME`,`JOB_NAME`,`JOB_GROUP`) USING BTREE,
  KEY `IDX_QRTZ_T_JG` (`SCHED_NAME`,`JOB_GROUP`) USING BTREE,
  KEY `IDX_QRTZ_T_C` (`SCHED_NAME`,`CALENDAR_NAME`) USING BTREE,
  KEY `IDX_QRTZ_T_G` (`SCHED_NAME`,`TRIGGER_GROUP`) USING BTREE,
  KEY `IDX_QRTZ_T_STATE` (`SCHED_NAME`,`TRIGGER_STATE`) USING BTREE,
  KEY `IDX_QRTZ_T_N_STATE` (`SCHED_NAME`,`TRIGGER_NAME`,`TRIGGER_GROUP`,`TRIGGER_STATE`) USING BTREE,
  KEY `IDX_QRTZ_T_N_G_STATE` (`SCHED_NAME`,`TRIGGER_GROUP`,`TRIGGER_STATE`) USING BTREE,
  KEY `IDX_QRTZ_T_NEXT_FIRE_TIME` (`SCHED_NAME`,`NEXT_FIRE_TIME`) USING BTREE,
  KEY `IDX_QRTZ_T_NFT_ST` (`SCHED_NAME`,`TRIGGER_STATE`,`NEXT_FIRE_TIME`) USING BTREE,
  KEY `IDX_QRTZ_T_NFT_MISFIRE` (`SCHED_NAME`,`MISFIRE_INSTR`,`NEXT_FIRE_TIME`) USING BTREE,
  KEY `IDX_QRTZ_T_NFT_ST_MISFIRE` (`SCHED_NAME`,`MISFIRE_INSTR`,`NEXT_FIRE_TIME`,`TRIGGER_STATE`) USING BTREE,
  KEY `IDX_QRTZ_T_NFT_ST_MISFIRE_GRP` (`SCHED_NAME`,`MISFIRE_INSTR`,`NEXT_FIRE_TIME`,`TRIGGER_GROUP`,`TRIGGER_STATE`) USING BTREE,
  CONSTRAINT `qrtz_triggers_ibfk_1` FOREIGN KEY (`SCHED_NAME`, `JOB_NAME`, `JOB_GROUP`) REFERENCES `QRTZ_JOB_DETAILS` (`SCHED_NAME`, `JOB_NAME`, `JOB_GROUP`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;
