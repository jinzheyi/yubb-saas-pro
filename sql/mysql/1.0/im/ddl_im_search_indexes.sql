-- IM 搜索索引增强（按需执行）
-- 说明：
-- 1) 本脚本用于 IM 搜索性能优化，建议先在预发环境执行并观察慢 SQL。
-- 2) 若索引已存在，请先确认后再执行，避免重复创建报错。

-- 消息搜索：优先按 tenant/chat/type/time 收敛范围
ALTER TABLE `im_chat_message`
  ADD INDEX `idx_search_scope` (`tenant_id`, `chat_id`, `message_type`, `send_time` DESC, `deleted`);

-- 联系人搜索：按租户 + 昵称检索（并保留 deleted 过滤）
ALTER TABLE `system_users`
  ADD INDEX `idx_tenant_nickname_deleted` (`tenant_id`, `nickname`, `deleted`);

