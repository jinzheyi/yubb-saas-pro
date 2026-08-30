-- 修复 system_users 错误唯一索引。
--
-- 历史建表脚本把 (update_time, tenant_id) 错误命名为 idx_username 并设为唯一，
-- 同一租户两个用户在同一秒登录时会因 update_time 相同而随机失败。
-- 用户租户关系的查询键是 (saas_user_id, tenant_id)，这里只创建普通索引；
-- 业务唯一性继续由租户上下文和用户服务校验，避免软删除记录阻止重新加入租户。

ALTER TABLE `system_users`
    DROP INDEX `idx_username`,
    ADD INDEX `idx_saas_user_tenant` (`saas_user_id`, `tenant_id`);
