/*
 IM 表唯一索引修复脚本
 
 问题描述: 
 - 多个表的唯一索引不包含 deleted 字段
 - 导致逻辑删除后无法重新创建相同记录
 
 解决方案:
 - 删除旧的唯一索引
 - 创建包含 deleted 字段的新唯一索引
 
 执行时间: 2026-02-22
 影响范围: im_group_member, im_conversation, im_contact_setting, im_message_read
*/

USE `shengyu`;

-- ============================================
-- 1. 修复 im_group_member 表
-- ============================================
-- 删除旧的唯一索引
ALTER TABLE `im_group_member` DROP INDEX `idx_group_user`;

-- 创建新的唯一索引（包含 deleted 字段）
ALTER TABLE `im_group_member` 
ADD UNIQUE INDEX `idx_group_user_deleted`(`group_id` ASC, `user_id` ASC, `tenant_id` ASC, `deleted` ASC) 
COMMENT '群+用户+删除状态唯一索引';

-- 验证索引创建成功
SHOW INDEX FROM `im_group_member` WHERE Key_name = 'idx_group_user_deleted';

-- ============================================
-- 2. 修复 im_conversation 表
-- ============================================
-- 删除旧的唯一索引
ALTER TABLE `im_conversation` DROP INDEX `idx_user_target`;

-- 创建新的唯一索引（包含 deleted 字段）
ALTER TABLE `im_conversation` 
ADD UNIQUE INDEX `idx_user_target_deleted`(`user_id` ASC, `target_id` ASC, `conversation_type` ASC, `tenant_id` ASC, `deleted` ASC) 
COMMENT '用户+目标+类型+删除状态唯一索引';

-- 验证索引创建成功
SHOW INDEX FROM `im_conversation` WHERE Key_name = 'idx_user_target_deleted';

-- ============================================
-- 3. 修复 im_contact_setting 表
-- ============================================
-- 删除旧的唯一索引
ALTER TABLE `im_contact_setting` DROP INDEX `idx_user_contact`;

-- 创建新的唯一索引（包含 deleted 字段）
ALTER TABLE `im_contact_setting` 
ADD UNIQUE INDEX `idx_user_contact_deleted`(`user_id` ASC, `contact_id` ASC, `tenant_id` ASC, `deleted` ASC) 
COMMENT '用户+联系人+删除状态唯一索引';

-- 验证索引创建成功
SHOW INDEX FROM `im_contact_setting` WHERE Key_name = 'idx_user_contact_deleted';

-- ============================================
-- 4. 修复 im_message_read 表
-- ============================================
-- 检查表是否存在 deleted 字段，如果不存在则添加
ALTER TABLE `im_message_read` 
ADD COLUMN `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除' AFTER `create_time`;

-- 删除旧的唯一索引
ALTER TABLE `im_message_read` DROP INDEX `idx_message_user`;

-- 创建新的唯一索引（包含 deleted 字段）
ALTER TABLE `im_message_read` 
ADD UNIQUE INDEX `idx_message_user_deleted`(`message_id` ASC, `user_id` ASC, `tenant_id` ASC, `deleted` ASC) 
COMMENT '消息+用户+删除状态唯一索引';

-- 验证索引创建成功
SHOW INDEX FROM `im_message_read` WHERE Key_name = 'idx_message_user_deleted';

-- ============================================
-- 验证所有修改
-- ============================================
SELECT 
    TABLE_NAME,
    INDEX_NAME,
    GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) AS INDEX_COLUMNS
FROM 
    INFORMATION_SCHEMA.STATISTICS
WHERE 
    TABLE_SCHEMA = 'shengyu'
    AND TABLE_NAME IN ('im_group_member', 'im_conversation', 'im_contact_setting', 'im_message_read')
    AND INDEX_NAME LIKE '%deleted%'
GROUP BY 
    TABLE_NAME, INDEX_NAME
ORDER BY 
    TABLE_NAME, INDEX_NAME;

