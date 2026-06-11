-- IM 模块核心索引优化脚本
-- 版本：v1.1
-- 日期：2026-06-11
-- 说明：基于 ddl_im_tables.sql 实际表结构，为高频查询路径补充索引
-- 注意：MySQL 不支持 IF NOT EXISTS，本脚本使用存储过程实现幂等
--       执行前请备份数据库，建议先在测试环境验证

DELIMITER $$

-- 1. im_chat_message: 客户端幂等唯一约束（当前 DDL 缺失）
DROP PROCEDURE IF EXISTS AddIndex1 $$
CREATE PROCEDURE AddIndex1()
BEGIN
    DECLARE idx_cnt INT;
    SELECT COUNT(*) INTO idx_cnt FROM information_schema.statistics
    WHERE table_schema = DATABASE() AND table_name = 'im_chat_message' AND index_name = 'uk_client_message_id';
    IF idx_cnt = 0 THEN
        ALTER TABLE im_chat_message ADD UNIQUE INDEX uk_client_message_id (client_message_id);
    END IF;
END $$
CALL AddIndex1() $$
DROP PROCEDURE IF EXISTS AddIndex1 $$

-- 2. im_chat_user: 会话列表查询优化（置顶 + 删除过滤 + 时间排序）
DROP PROCEDURE IF EXISTS AddIndex2 $$
CREATE PROCEDURE AddIndex2()
BEGIN
    DECLARE idx_cnt INT;
    SELECT COUNT(*) INTO idx_cnt FROM information_schema.statistics
    WHERE table_schema = DATABASE() AND table_name = 'im_chat_user' AND index_name = 'idx_user_pinned_time';
    IF idx_cnt = 0 THEN
        ALTER TABLE im_chat_user ADD INDEX idx_user_pinned_time (tenant_id, user_id, deleted_by_user, is_pinned, last_message_time DESC);
    END IF;
END $$
CALL AddIndex2() $$
DROP PROCEDURE IF EXISTS AddIndex2 $$

-- 3. im_group_member: 按群查询成员优化（群列表构建、群成员拉取）
DROP PROCEDURE IF EXISTS AddIndex3 $$
CREATE PROCEDURE AddIndex3()
BEGIN
    DECLARE idx_cnt INT;
    SELECT COUNT(*) INTO idx_cnt FROM information_schema.statistics
    WHERE table_schema = DATABASE() AND table_name = 'im_group_member' AND index_name = 'idx_group_deleted';
    IF idx_cnt = 0 THEN
        ALTER TABLE im_group_member ADD INDEX idx_group_deleted (group_id, deleted);
    END IF;
END $$
CALL AddIndex3() $$
DROP PROCEDURE IF EXISTS AddIndex3 $$

-- 4. im_group_member: 群成员角色变更批量推送场景
DROP PROCEDURE IF EXISTS AddIndex4 $$
CREATE PROCEDURE AddIndex4()
BEGIN
    DECLARE idx_cnt INT;
    SELECT COUNT(*) INTO idx_cnt FROM information_schema.statistics
    WHERE table_schema = DATABASE() AND table_name = 'im_group_member' AND index_name = 'idx_group_role_deleted';
    IF idx_cnt = 0 THEN
        ALTER TABLE im_group_member ADD INDEX idx_group_role_deleted (group_id, role, deleted);
    END IF;
END $$
CALL AddIndex4() $$
DROP PROCEDURE IF EXISTS AddIndex4 $$

-- 5. im_chat_message: 消息搜索优化（按会话 + 类型 + 时间范围）
DROP PROCEDURE IF EXISTS AddIndex5 $$
CREATE PROCEDURE AddIndex5()
BEGIN
    DECLARE idx_cnt INT;
    SELECT COUNT(*) INTO idx_cnt FROM information_schema.statistics
    WHERE table_schema = DATABASE() AND table_name = 'im_chat_message' AND index_name = 'idx_chat_type_sendtime';
    IF idx_cnt = 0 THEN
        ALTER TABLE im_chat_message ADD INDEX idx_chat_type_sendtime (chat_id, deleted, message_type, send_time DESC);
    END IF;
END $$
CALL AddIndex5() $$
DROP PROCEDURE IF EXISTS AddIndex5 $$

-- 6. im_message_read: 已读回执批量查询优化
DROP PROCEDURE IF EXISTS AddIndex6 $$
CREATE PROCEDURE AddIndex6()
BEGIN
    DECLARE idx_cnt INT;
    SELECT COUNT(*) INTO idx_cnt FROM information_schema.statistics
    WHERE table_schema = DATABASE() AND table_name = 'im_message_read' AND index_name = 'idx_message_deleted';
    IF idx_cnt = 0 THEN
        ALTER TABLE im_message_read ADD INDEX idx_message_deleted (message_id, deleted);
    END IF;
END $$
CALL AddIndex6() $$
DROP PROCEDURE IF EXISTS AddIndex6 $$

DELIMITER ;

-- ========================================
-- 索引验证查询
-- ========================================

-- 执行后可用以下语句验证索引是否创建成功：
-- SHOW INDEX FROM im_chat_message WHERE Key_name LIKE 'idx_%' OR Key_name LIKE 'uk_%';
-- SHOW INDEX FROM im_chat_user WHERE Key_name LIKE 'idx_%' OR Key_name LIKE 'uk_%';
-- SHOW INDEX FROM im_conversation_user_state WHERE Key_name LIKE 'idx_%' OR Key_name LIKE 'uk_%';
-- SHOW INDEX FROM im_group_member WHERE Key_name LIKE 'idx_%' OR Key_name LIKE 'uk_%';
-- SHOW INDEX FROM im_message_read WHERE Key_name LIKE 'idx_%' OR Key_name LIKE 'uk_%';
-- SHOW INDEX FROM im_message_favorite WHERE Key_name LIKE 'idx_%' OR Key_name LIKE 'uk_%';
