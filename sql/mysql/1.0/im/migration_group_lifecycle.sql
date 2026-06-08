-- ========================================
-- 群组生命周期与会话状态一致性改造
-- 参考微信方案：保留历史消息，标记群组状态
-- 执行时间：2026-05-30
-- ========================================

-- 1. im_chat_user 表新增群组状态字段
ALTER TABLE `im_chat_user` 
ADD COLUMN `group_member_status` tinyint NOT NULL DEFAULT 0 COMMENT '群组成员状态：0=正常(在群内), 1=已退出(主动退群), 2=已被踢(被群主/管理员踢出), 3=群已解散' AFTER `deleted_by_user`;

-- 2. im_chat_user 表新增离群时间字段（用于限制聊天记录查询范围）
ALTER TABLE `im_chat_user` 
ADD COLUMN `left_at` datetime NULL DEFAULT NULL COMMENT '离群时间（被踢/退群时间，用于限制只能查询离群前的消息）' AFTER `group_member_status`;

-- 3. 添加索引优化查询
ALTER TABLE `im_chat_user` 
ADD INDEX `idx_user_group_status`(`tenant_id` ASC, `user_id` ASC, `group_member_status` ASC) USING BTREE;

-- 4. im_conversation_user_state 表新增群组状态字段
ALTER TABLE `im_conversation_user_state` 
ADD COLUMN `group_member_status` tinyint NULL DEFAULT NULL COMMENT '群组成员状态：0=正常(在群内), 1=已退出(主动退群), 2=已被踢(被群主/管理员踢出), 3=群已解散' AFTER `deleted_by_user`;

-- 5. im_conversation_user_state 表新增离群时间字段
ALTER TABLE `im_conversation_user_state` 
ADD COLUMN `left_at` datetime NULL DEFAULT NULL COMMENT '离群时间（被踢/退群时间，用于会话列表展示）' AFTER `group_member_status`;

-- 6. 添加索引优化查询
ALTER TABLE `im_conversation_user_state` 
ADD INDEX `idx_user_group_status`(`tenant_id` ASC, `user_id` ASC, `group_member_status` ASC) USING BTREE;

-- 7. im_chat_user 表新增快照数据字段（JSON格式，冻结离群时的群信息）
ALTER TABLE `im_chat_user` 
ADD COLUMN `snapshot_data` json NULL DEFAULT NULL COMMENT '群组快照数据JSON（被踢/退群/解散时冻结，包含群名称、公告、成员列表关键信息等）' AFTER `left_at`;

-- 8. im_conversation_user_state 表新增快照数据字段
ALTER TABLE `im_conversation_user_state` 
ADD COLUMN `snapshot_data` json NULL DEFAULT NULL COMMENT '群组快照数据JSON（被踢/退群/解散时冻结，用于会话列表和聊天页展示）' AFTER `left_at`;

-- 添加 lastMessageSenderId 字段到 im_chat_user 表
ALTER TABLE `im_chat_user` ADD COLUMN `last_message_sender_id` BIGINT NULL COMMENT '最后一条消息发送者ID（冗余字段，避免回表查询 im_chat_message）' AFTER `last_message_sequence`;

-- 添加 lastMessageSenderId 字段到 im_conversation_user_state 表
ALTER TABLE `im_conversation_user_state` ADD COLUMN `last_message_sender_id` BIGINT NULL COMMENT '最后一条消息发送者ID（冗余字段，避免回表查询 im_chat_message）' AFTER `last_message_sequence`;

-- 7. 更新 im_conversation_user_state 的群组成员状态（从 im_chat_user 同步）
UPDATE `im_conversation_user_state` cus
INNER JOIN `im_chat_user` cu ON cus.chat_id = cu.chat_id AND cus.user_id = cu.user_id AND cus.tenant_id = cu.tenant_id
INNER JOIN `im_chat` c ON cus.chat_id = c.id AND c.chat_type = 2
SET cus.group_member_status = cu.group_member_status,
    cus.left_at = cu.left_at
WHERE cus.deleted = 0 AND cus.deleted_by_user = 0;

-- 3. 更新已存在的群聊会话状态（根据 im_group_user 表关联）
-- 对于已在群内的用户，group_member_status 默认为 0（正常）
-- 对于已不在群内的用户，需要根据实际情况标记
UPDATE `im_chat_user` cu
INNER JOIN `im_chat` c ON cu.chat_id = c.id
INNER JOIN `im_group` g ON c.group_id = g.id AND c.chat_type = 2
SET cu.group_member_status = CASE
    WHEN g.status = 3 THEN 3  -- 群已解散
    ELSE 0  -- 默认正常
END
WHERE c.chat_type = 2 AND cu.deleted_by_user = 0;

-- 4. 为被踢出群的用户标记状态
UPDATE `im_chat_user` cu
INNER JOIN `im_chat` c ON cu.chat_id = c.id
LEFT JOIN `im_group_member` gm ON c.group_id = gm.group_id AND cu.user_id = gm.user_id AND gm.deleted = 0
SET cu.group_member_status = 2  -- 已被踢
WHERE c.chat_type = 2 
  AND cu.deleted_by_user = 0 
  AND gm.id IS NULL  -- 不在群成员表中
  AND cu.group_member_status = 0;

-- 5. 为已退出群的用户标记状态（历史数据处理）
-- 注意：这里假设已退出但未被踢的用户，left_at 设为当前时间
UPDATE `im_chat_user` cu
INNER JOIN `im_chat` c ON cu.chat_id = c.id
SET cu.left_at = NOW()
WHERE c.chat_type = 2 
  AND cu.group_member_status IN (1, 2, 3)  -- 已离群状态
  AND cu.left_at IS NULL;

-- ========================================
-- 回滚脚本（如需回滚请执行以下SQL）
-- ========================================
-- ALTER TABLE `im_chat_user` DROP COLUMN `group_member_status`;
-- ALTER TABLE `im_chat_user` DROP COLUMN `left_at`;
-- ALTER TABLE `im_chat_user` DROP COLUMN `snapshot_data`;
-- ALTER TABLE `im_chat_user` DROP INDEX `idx_user_group_status`;
-- ALTER TABLE `im_conversation_user_state` DROP COLUMN `group_member_status`;
-- ALTER TABLE `im_conversation_user_state` DROP COLUMN `left_at`;
-- ALTER TABLE `im_conversation_user_state` DROP COLUMN `snapshot_data`;
-- ALTER TABLE `im_conversation_user_state` DROP INDEX `idx_user_group_status`;

-- ========================================
-- 主题模式改为设备本地存储，不再持久化到数据库
-- 说明：主题模式与国际化作用域一致，存储在 SharedPreferences，不跟随账号
-- ========================================
ALTER TABLE `system_users` DROP COLUMN `theme_mode`;
