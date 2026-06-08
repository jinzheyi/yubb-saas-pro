-- 主题模式已改为设备本地存储（SharedPreferences），不再持久化到数据库
-- 原 theme_mode 字段已在 migration_group_lifecycle.sql 中通过 DROP COLUMN 清理

ALTER TABLE `system_users`
    ADD COLUMN IF NOT EXISTS `chat_bubble_color` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '#D2E3FC' COMMENT '聊天气泡颜色' AFTER `avatar`,
    ADD COLUMN IF NOT EXISTS `chat_bubble_mode` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT 'preset' COMMENT '聊天气泡模式' AFTER `chat_bubble_color`;

ALTER TABLE `platform_users`
    DROP COLUMN IF EXISTS `language_mode`;

ALTER TABLE `system_users`
    DROP COLUMN IF EXISTS `language_mode`;
