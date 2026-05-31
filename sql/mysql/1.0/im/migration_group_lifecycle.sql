-- ========================================
-- 群组生命周期与会话状态一致性改造
-- 参考微信方案：保留历史消息，标记群组状态
-- 执行时间：2026-05-30
-- ========================================

-- 1. im_chat_user 表新增群组状态字段
ALTER TABLE `im_chat_user` 
ADD COLUMN `group_member_status` tinyint NOT NULL DEFAULT 0 COMMENT '群组成员状态：0=正常(在群内), 1=已退出(主动退群), 2=已被踢(被群主/管理员踢出), 3=群已解散' AFTER `deleted_by_user`;

-- 2. 添加索引优化查询
ALTER TABLE `im_chat_user` 
ADD INDEX `idx_user_group_status`(`tenant_id` ASC, `user_id` ASC, `group_member_status` ASC) USING BTREE;

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

-- ========================================
-- 回滚脚本（如需回滚请执行以下SQL）
-- ========================================
-- ALTER TABLE `im_chat_user` DROP COLUMN `group_member_status`;
-- ALTER TABLE `im_chat_user` DROP INDEX `idx_user_group_status`;
