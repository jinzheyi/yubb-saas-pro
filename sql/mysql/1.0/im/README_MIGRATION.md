# IM 模块数据库迁移指南

## 迁移背景

修复逻辑删除与唯一索引冲突的问题，确保删除后可以重新创建相同记录。

## 影响范围

| 表名 | 修改内容 | 影响 |
|------|---------|------|
| im_group_member | 修改唯一索引 | 支持删除成员后重新加入 |
| im_conversation | 修改唯一索引 | 支持删除会话后重新创建 |
| im_contact_setting | 修改唯一索引 | 支持删除设置后重新创建 |
| im_message_read | 添加字段+修改索引 | 支持逻辑删除 |

## 执行步骤

### 1. 备份数据库（重要！）

```bash
# 备份整个数据库
mysqldump -u root -p shengyu > backup_shengyu_$(date +%Y%m%d_%H%M%S).sql

# 或只备份 IM 相关表
mysqldump -u root -p shengyu \
  im_group_member \
  im_conversation \
  im_contact_setting \
  im_message_read \
  > backup_im_tables_$(date +%Y%m%d_%H%M%S).sql
```

### 2. 检查当前索引状态

```sql
-- 查看当前唯一索引
SELECT 
    TABLE_NAME,
    INDEX_NAME,
    GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) AS INDEX_COLUMNS
FROM 
    INFORMATION_SCHEMA.STATISTICS
WHERE 
    TABLE_SCHEMA = 'shengyu'
    AND TABLE_NAME IN ('im_group_member', 'im_conversation', 'im_contact_setting', 'im_message_read')
    AND NON_UNIQUE = 0
GROUP BY 
    TABLE_NAME, INDEX_NAME
ORDER BY 
    TABLE_NAME, INDEX_NAME;
```

### 3. 执行迁移脚本

```bash
# 方式一：直接执行 SQL 文件
mysql -u root -p shengyu < migration_fix_group_member_unique_index.sql

# 方式二：在 MySQL 客户端中执行
mysql -u root -p
USE shengyu;
SOURCE /path/to/migration_fix_group_member_unique_index.sql;
```

### 4. 验证迁移结果

```sql
-- 验证新索引已创建
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

-- 预期结果：
-- im_group_member | idx_group_user_deleted | group_id,user_id,tenant_id,deleted
-- im_conversation | idx_user_target_deleted | user_id,target_id,conversation_type,tenant_id,deleted
-- im_contact_setting | idx_user_contact_deleted | user_id,contact_id,tenant_id,deleted
-- im_message_read | idx_message_user_deleted | message_id,user_id,tenant_id,deleted
```

### 5. 功能测试

#### 测试场景 1：删除并重新添加群成员

```sql
-- 1. 添加成员
INSERT INTO im_group_member (id, group_id, user_id, role, join_time, tenant_id) 
VALUES (1, 100, 200, 3, NOW(), 1);

-- 2. 逻辑删除成员
UPDATE im_group_member SET deleted = 1 WHERE id = 1;

-- 3. 重新添加同一成员（应该成功）
INSERT INTO im_group_member (id, group_id, user_id, role, join_time, tenant_id) 
VALUES (2, 100, 200, 3, NOW(), 1);

-- 4. 验证：应该有两条记录，一条 deleted=1，一条 deleted=0
SELECT * FROM im_group_member WHERE group_id = 100 AND user_id = 200;
```

#### 测试场景 2：删除并重新创建会话

```sql
-- 1. 创建会话
INSERT INTO im_conversation (id, user_id, target_id, conversation_type, tenant_id) 
VALUES (1, 100, 200, 1, 1);

-- 2. 逻辑删除会话
UPDATE im_conversation SET deleted = 1 WHERE id = 1;

-- 3. 重新创建同一会话（应该成功）
INSERT INTO im_conversation (id, user_id, target_id, conversation_type, tenant_id) 
VALUES (2, 100, 200, 1, 1);

-- 4. 验证
SELECT * FROM im_conversation WHERE user_id = 100 AND target_id = 200;
```

## 回滚方案

如果迁移出现问题，可以回滚：

```sql
-- 1. 恢复 im_group_member
ALTER TABLE `im_group_member` DROP INDEX `idx_group_user_deleted`;
ALTER TABLE `im_group_member` 
ADD UNIQUE INDEX `idx_group_user`(`group_id`, `user_id`, `tenant_id`);

-- 2. 恢复 im_conversation
ALTER TABLE `im_conversation` DROP INDEX `idx_user_target_deleted`;
ALTER TABLE `im_conversation` 
ADD UNIQUE INDEX `idx_user_target`(`user_id`, `target_id`, `conversation_type`, `tenant_id`);

-- 3. 恢复 im_contact_setting
ALTER TABLE `im_contact_setting` DROP INDEX `idx_user_contact_deleted`;
ALTER TABLE `im_contact_setting` 
ADD UNIQUE INDEX `idx_user_contact`(`user_id`, `contact_id`, `tenant_id`);

-- 4. 恢复 im_message_read
ALTER TABLE `im_message_read` DROP INDEX `idx_message_user_deleted`;
ALTER TABLE `im_message_read` DROP COLUMN `deleted`;
ALTER TABLE `im_message_read` 
ADD UNIQUE INDEX `idx_message_user`(`message_id`, `user_id`, `tenant_id`);
```

## 注意事项

1. **执行时间**：建议在业务低峰期执行，预计耗时 < 1 分钟（取决于数据量）
2. **锁表影响**：ALTER TABLE 会锁表，期间相关表无法写入
3. **数据一致性**：迁移前确保没有正在进行的事务
4. **测试环境**：建议先在测试环境验证
5. **监控告警**：执行期间关注数据库性能监控

## 常见问题

### Q1: 执行时报错 "Duplicate entry"

**原因**：存在多条 deleted=0 的重复记录

**解决**：
```sql
-- 查找重复记录
SELECT group_id, user_id, tenant_id, COUNT(*) 
FROM im_group_member 
WHERE deleted = 0 
GROUP BY group_id, user_id, tenant_id 
HAVING COUNT(*) > 1;

-- 手动处理重复记录（保留最新的）
-- 根据实际情况调整
```

### Q2: 索引创建失败

**原因**：旧索引未删除或表结构异常

**解决**：
```sql
-- 查看当前索引
SHOW INDEX FROM im_group_member;

-- 手动删除旧索引
ALTER TABLE im_group_member DROP INDEX idx_group_user;
```

### Q3: 性能影响

**原因**：索引增加了一个字段，略微增加存储空间

**影响**：可忽略不计，查询性能基本无影响

## 联系方式

如有问题，请联系：
- 技术负责人：[姓名]
- 邮箱：[email]
- 钉钉群：[群号]
