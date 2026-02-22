# IM 群成员逻辑删除设计方案

## 问题背景

### 问题描述
在实现删除群成员功能时，发现以下问题：
1. 删除成员后，该成员被标记为 `deleted=1`（逻辑删除）
2. 重新添加同一成员时，报唯一索引冲突错误
3. 错误信息：`Duplicate entry 'xxx' for key 'im_group_member.idx_group_user'`

### 根本原因
原表设计的唯一索引为：
```sql
UNIQUE INDEX `idx_group_user`(`group_id`, `user_id`, `tenant_id`)
```

该索引**不包含 `deleted` 字段**，导致：
- 逻辑删除的记录（deleted=1）仍然占用唯一索引
- 新插入的记录（deleted=0）与旧记录冲突
- 无法实现"删除后重新加入"的业务需求

## 解决方案对比

### 方案一：修改唯一索引包含 deleted 字段（推荐）✅

**实现方式：**
```sql
UNIQUE INDEX `idx_group_user_deleted`(`group_id`, `user_id`, `tenant_id`, `deleted`)
```

**优点：**
1. ✅ 标准的逻辑删除解决方案
2. ✅ 支持同一用户多次加入/退出群组的历史记录
3. ✅ 保留完整的操作审计日志
4. ✅ 符合数据合规要求（数据不丢失）
5. ✅ 代码改动最小，只需修改索引

**缺点：**
1. ⚠️ 索引占用空间略大（增加一个字段）
2. ⚠️ 需要执行数据库迁移脚本

**适用场景：**
- 需要保留历史记录
- 需要审计追溯
- 数据合规要求高
- **推荐用于生产环境**

---

### 方案二：物理删除（不推荐）❌

**实现方式：**
```java
// 直接删除记录，不使用逻辑删除
groupUserMapper.deleteById(memberToRemove.getId());
```

**优点：**
1. ✅ 不需要修改索引
2. ✅ 数据库空间占用小

**缺点：**
1. ❌ 丢失历史记录，无法追溯
2. ❌ 不符合数据合规要求
3. ❌ 无法统计用户加入/退出次数
4. ❌ 可能影响关联数据（如消息记录）
5. ❌ 违反框架的逻辑删除设计原则

**适用场景：**
- 临时测试环境
- 对历史数据无要求的场景
- **不推荐用于生产环境**

---

### 方案三：先物理删除旧记录再插入（折中方案）⚠️

**实现方式：**
```java
// 添加成员前，先物理删除已逻辑删除的记录
ImGroupUserDO existingMember = groupUserMapper.selectByGroupIdAndUserId(groupId, userId);
if (existingMember != null && existingMember.getDeleted()) {
    groupUserMapper.deleteById(existingMember.getId());
}
// 然后插入新记录
```

**优点：**
1. ✅ 不需要修改索引
2. ✅ 保留当前有效的成员记录

**缺点：**
1. ❌ 丢失历史记录
2. ❌ 代码逻辑复杂，容易出错
3. ❌ 需要在多处添加成员的地方都加上这段逻辑
4. ❌ 可能存在并发问题

**适用场景：**
- 无法修改数据库索引的情况
- 临时过渡方案

---

## 最终选择：方案一（修改唯一索引）

### 实施步骤

#### 1. 修改表结构（DDL）
更新 `sql/mysql/1.0/im/ddl_im_tables.sql`：
```sql
UNIQUE INDEX `idx_group_user_deleted`(`group_id`, `user_id`, `tenant_id`, `deleted`)
```

#### 2. 创建迁移脚本
文件：`sql/mysql/1.0/im/migration_fix_group_member_unique_index.sql`
```sql
-- 删除旧索引
ALTER TABLE `im_group_member` DROP INDEX `idx_group_user`;

-- 创建新索引
ALTER TABLE `im_group_member` 
ADD UNIQUE INDEX `idx_group_user_deleted`(`group_id`, `user_id`, `tenant_id`, `deleted`);
```

#### 3. 执行迁移
```bash
# 在数据库中执行迁移脚本
mysql -u root -p shengyu < sql/mysql/1.0/im/migration_fix_group_member_unique_index.sql
```

#### 4. 验证
```sql
-- 验证索引创建成功
SHOW INDEX FROM `im_group_member` WHERE Key_name = 'idx_group_user_deleted';

-- 测试场景
-- 1. 添加成员
-- 2. 删除成员（逻辑删除）
-- 3. 重新添加同一成员（应该成功）
```

### 业务逻辑说明

#### 删除成员
```java
// 逻辑删除，保留历史记录
groupUserMapper.deleteById(memberToRemove.getId());
// deleted 字段自动设置为 1
```

#### 添加成员
```java
// 直接插入新记录
ImGroupUserDO groupUser = new ImGroupUserDO();
groupUser.setGroupId(groupId);
groupUser.setUserId(userId);
groupUser.setRole(role);
groupUser.setJoinTime(LocalDateTime.now());
groupUserMapper.insert(groupUser);
// deleted 字段默认为 0

// 由于唯一索引包含 deleted 字段：
// - deleted=0 的记录只能有一条（当前成员）
// - deleted=1 的记录可以有多条（历史记录）
```

#### 查询成员
```java
// 查询时必须过滤 deleted=0
List<ImGroupUserDO> members = groupUserMapper.selectList(
    new LambdaQueryWrapper<ImGroupUserDO>()
        .eq(ImGroupUserDO::getGroupId, groupId)
        .eq(ImGroupUserDO::getDeleted, false)  // 重要：过滤已删除
);
```

## 架构设计原则

### 1. 逻辑删除的标准实践
- 唯一索引必须包含 `deleted` 字段
- 查询时必须过滤 `deleted=0`
- 统计时必须考虑 `deleted` 状态

### 2. 其他表的检查清单
需要检查以下表是否存在相同问题：

| 表名 | 唯一索引 | 是否包含 deleted | 状态 |
|------|---------|-----------------|------|
| im_conversation | idx_user_target | ❌ 需要修复 | 待处理 |
| im_contact_setting | idx_user_contact | ❌ 需要修复 | 待处理 |
| im_message_read | idx_message_user | ❌ 需要修复 | 待处理 |
| im_group_member | idx_group_user_deleted | ✅ 已修复 | 完成 |

### 3. 代码规范
```java
// ❌ 错误：直接查询，未过滤 deleted
ImGroupUserDO member = groupUserMapper.selectByGroupIdAndUserId(groupId, userId);

// ✅ 正确：查询时过滤 deleted
ImGroupUserDO member = groupUserMapper.selectOne(
    new LambdaQueryWrapper<ImGroupUserDO>()
        .eq(ImGroupUserDO::getGroupId, groupId)
        .eq(ImGroupUserDO::getUserId, userId)
        .eq(ImGroupUserDO::getDeleted, false)
);
```

## 总结

1. **问题根源**：唯一索引未包含 `deleted` 字段
2. **最佳方案**：修改索引包含 `deleted` 字段
3. **核心原则**：逻辑删除的唯一索引必须包含删除标记字段
4. **后续工作**：检查并修复其他表的相同问题

## 参考资料

- [MySQL 逻辑删除最佳实践](https://dev.mysql.com/doc/)
- [MyBatis-Plus 逻辑删除](https://baomidou.com/pages/6b03c5/)
- [数据库索引设计规范](https://www.mysql.com/cn/)
