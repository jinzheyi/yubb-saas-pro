/*
 IM 即时通讯模块 - 初始化数据
 
 功能说明: IM 模块初始化数据(字典、配置等)
 创建日期: 2026-02-11
 版本: v1.0
 
 注意事项: 
 1. 使用 UUID_SHORT() 函数生成唯一 ID
 2. 后续数据变更直接在本文件中修改
 3. 正式执行前需要经过代码审查
*/

SET NAMES utf8mb4;

BEGIN;

-- ----------------------------
-- 消息类型字典
-- ----------------------------
-- 字典类型
INSERT INTO `platform_dict_type` (`id`, `name`, `type`, `status`, `remark`, `creator`, `create_time`, `updater`, `update_time`, `deleted`, `deleted_time`) 
VALUES (UUID_SHORT(), 'IM消息类型', 'im_message_type', 0, 'IM消息类型', 'system', NOW(), 'system', NOW(), b'0', NULL);

-- 字典数据
INSERT INTO `platform_dict_data` (`id`, `sort`, `label`, `value`, `dict_type`, `status`, `color_type`, `css_class`, `remark`, `creator`, `create_time`, `updater`, `update_time`, `deleted`) 
VALUES 
(UUID_SHORT(), 1, '文本', '1', 'im_message_type', 0, 'default', '', '文本消息', 'system', NOW(), 'system', NOW(), b'0'),
(UUID_SHORT(), 2, '图片', '2', 'im_message_type', 0, 'default', '', '图片消息', 'system', NOW(), 'system', NOW(), b'0'),
(UUID_SHORT(), 3, '语音', '3', 'im_message_type', 0, 'default', '', '语音消息', 'system', NOW(), 'system', NOW(), b'0'),
(UUID_SHORT(), 4, '视频', '4', 'im_message_type', 0, 'default', '', '视频消息', 'system', NOW(), 'system', NOW(), b'0'),
(UUID_SHORT(), 5, '文件', '5', 'im_message_type', 0, 'default', '', '文件消息', 'system', NOW(), 'system', NOW(), b'0'),
(UUID_SHORT(), 6, '位置', '6', 'im_message_type', 0, 'default', '', '位置消息', 'system', NOW(), 'system', NOW(), b'0'),
(UUID_SHORT(), 7, '表情包', '7', 'im_message_type', 0, 'default', '', '表情包消息', 'system', NOW(), 'system', NOW(), b'0'),
(UUID_SHORT(), 8, '自定义贴纸', '8', 'im_message_type', 0, 'default', '', '自定义贴纸消息', 'system', NOW(), 'system', NOW(), b'0'),
(UUID_SHORT(), 10, '系统消息', '10', 'im_message_type', 0, 'default', '', '系统消息', 'system', NOW(), 'system', NOW(), b'0');

-- ----------------------------
-- 会话类型字典
-- ----------------------------
-- 字典类型
INSERT INTO `platform_dict_type` (`id`, `name`, `type`, `status`, `remark`, `creator`, `create_time`, `updater`, `update_time`, `deleted`, `deleted_time`) 
VALUES (UUID_SHORT(), 'IM会话类型', 'im_conversation_type', 0, 'IM会话类型', 'system', NOW(), 'system', NOW(), b'0', NULL);

-- 字典数据
INSERT INTO `platform_dict_data` (`id`, `sort`, `label`, `value`, `dict_type`, `status`, `color_type`, `css_class`, `remark`, `creator`, `create_time`, `updater`, `update_time`, `deleted`) 
VALUES 
(UUID_SHORT(), 1, '单聊', '1', 'im_conversation_type', 0, 'default', '', '单聊会话', 'system', NOW(), 'system', NOW(), b'0'),
(UUID_SHORT(), 2, '群聊', '2', 'im_conversation_type', 0, 'default', '', '群聊会话', 'system', NOW(), 'system', NOW(), b'0');

-- ----------------------------
-- 群组类型字典
-- ----------------------------
-- 字典类型
INSERT INTO `platform_dict_type` (`id`, `name`, `type`, `status`, `remark`, `creator`, `create_time`, `updater`, `update_time`, `deleted`, `deleted_time`) 
VALUES (UUID_SHORT(), 'IM群组类型', 'im_group_type', 0, 'IM群组类型', 'system', NOW(), 'system', NOW(), b'0', NULL);

-- 字典数据
INSERT INTO `platform_dict_data` (`id`, `sort`, `label`, `value`, `dict_type`, `status`, `color_type`, `css_class`, `remark`, `creator`, `create_time`, `updater`, `update_time`, `deleted`) 
VALUES 
(UUID_SHORT(), 1, '普通群', '1', 'im_group_type', 0, 'default', '', '普通群聊', 'system', NOW(), 'system', NOW(), b'0'),
(UUID_SHORT(), 2, '工作群', '2', 'im_group_type', 0, 'default', '', '工作群聊', 'system', NOW(), 'system', NOW(), b'0');

-- ----------------------------
-- 群成员角色字典
-- ----------------------------
-- 字典类型
INSERT INTO `platform_dict_type` (`id`, `name`, `type`, `status`, `remark`, `creator`, `create_time`, `updater`, `update_time`, `deleted`, `deleted_time`) 
VALUES (UUID_SHORT(), 'IM群成员角色', 'im_group_member_role', 0, 'IM群成员角色', 'system', NOW(), 'system', NOW(), b'0', NULL);

-- 字典数据
INSERT INTO `platform_dict_data` (`id`, `sort`, `label`, `value`, `dict_type`, `status`, `color_type`, `css_class`, `remark`, `creator`, `create_time`, `updater`, `update_time`, `deleted`) 
VALUES 
(UUID_SHORT(), 1, '群主', '1', 'im_group_member_role', 0, 'danger', '', '群主', 'system', NOW(), 'system', NOW(), b'0'),
(UUID_SHORT(), 2, '管理员', '2', 'im_group_member_role', 0, 'warning', '', '管理员', 'system', NOW(), 'system', NOW(), b'0'),
(UUID_SHORT(), 3, '普通成员', '3', 'im_group_member_role', 0, 'default', '', '普通成员', 'system', NOW(), 'system', NOW(), b'0');

COMMIT;