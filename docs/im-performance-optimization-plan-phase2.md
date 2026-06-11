# IM 模块性能优化方案 - 第二阶段

> 版本：v2.0  
> 日期：2026-06-11  
> 目标：深度企业级优化，解决 N+1、批量操作、索引等核心问题

---

## 一、P0 级优化项（立即执行）

### 1.1 创建群组批量插入群成员
**文件**：`ImGroupServiceImpl.java` (L189-196)

**问题**：500 人群执行 500 次 INSERT，每次都在事务内。

**修复方案**：
- 收集所有群成员 DO 对象
- 使用 MyBatis-Plus 的 `saveBatch` 或 `insertBatch` 批量插入
- 减少数据库往返次数 500 → 1

---

### 1.2 解散群组批量操作
**文件**：`ImGroupServiceImpl.java` (L342-353)

**问题**：
1. 循环保存群快照（N 次 INSERT）
2. 循环删除群成员关系（N 次 DELETE）

**修复方案**：
- 快照保存：批量 INSERT
- 成员关系删除：使用 `DELETE WHERE group_id = ?` 批量删除

---

### 1.3 getGroupList N+1 查询
**文件**：`ImGroupServiceImpl.java` (L626-658)

**问题**：遍历群 ID 时，对每个群执行一次成员查询 + 用户信息查询。

**修复方案**：
- 复用 `selectBatchGroupMembersWithLimit` 批量查询
- 批量查询所有群成员的用户信息

---

### 1.4 getSummaryBatch 串行查询
**文件**：`ImReadReceiptServiceImpl.java` (L118-127)

**问题**：50 条消息 × 3 次查询/条 = 150 次数据库查询。

**修复方案**：
- 批量查询消息信息
- 批量统计已读人数（GROUP BY 聚合 SQL）
- 预计 150 次 → 3-5 次

---

### 1.5 消息拉取批量查询发送者信息
**文件**：`ImMessageServiceImpl.java` (L506)

**问题**：`fillSenderInfo` 在每条消息转换中调用，可能逐条查询。

**修复方案**：
- 先批量收集所有 senderId
- 批量查询用户信息转 Map
- 从 Map 中获取，避免逐条查询

---

## 二、P1 级优化项

### 2.1 buildGroupSnapshot 循环查询用户
**文件**：`ImGroupServiceImpl.java` (L653)

**问题**：500 人群构建快照 = 500 次 SELECT 用户信息。

**修复方案**：
- 先批量查询所有成员用户信息
- 用 Map 映射替代循环逐查

---

### 2.2 buildGroupMembersAddedTipContent 循环查询
**文件**：`ImGroupServiceImpl.java` (L1810-1819)

**问题**：循环逐条查询用户信息构建提示文本。

**修复方案**：批量查询 + Map 映射

---

### 2.3 getGroupMembers SQL 分页
**文件**：`ImGroupServiceImpl.java` (L868-878)

**问题**：查询所有群成员到内存，再做 subList 分页。

**修复方案**：改为 SQL 层 LIMIT 分页

---

### 2.4 消息搜索全文索引
**文件**：`ImChatMessageMapper.java` (L296)

**问题**：`LIKE '%keyword%'` 前导通配符，全表扫描。

**修复方案**：
- 短期：添加 MySQL FULLTEXT 索引
- 长期：同步至 Elasticsearch

---

## 三、P2 级优化项

### 3.1 补充审计日志
**涉及操作**：退群、解散群、踢人、转让群主

**修复方案**：添加关键操作的审计日志

---

### 3.2 异常堆栈记录
**涉及**：多处 `catch (Exception e)` 只记录 `e.getMessage()`

**修复方案**：改为 `log.warn("...", e)` 传入异常对象

---

### 3.3 推送消息批量发送
**涉及**：`pushGroupXXXNotify` 方法逐条发送 WebSocket

**修复方案**：使用 MQ 异步批量推送

---

## 四、数据库索引建议

```sql
-- 消息拉取核心索引
ALTER TABLE im_chat_message ADD INDEX idx_chat_sequence (chat_id, sequence);

-- 群成员校验索引
ALTER TABLE im_group_member ADD INDEX idx_group_user_deleted (group_id, user_id, deleted);

-- 会话同步索引
ALTER TABLE im_conversation_user_state ADD INDEX idx_tenant_user_cursor (tenant_id, user_id, cursor_version);

-- 消息搜索全文索引（MySQL 8.0+）
ALTER TABLE im_chat_message ADD FULLTEXT INDEX ft_content (content) WITH PARSER ngram;
```

---

## 五、实施记录

### 第一轮（P0 级 - 已完成）
| 任务 | 状态 | 效果 |
|------|------|------|
| 创建群组批量插入成员 | ✅ | 500 次 INSERT → 1 次批量 |
| 解散群组批量操作 | ✅ | 快照 2N→2 次，成员删除 2N→2 次 |
| getGroupList N+1 修复 | ✅ | 群成员/用户/群查询全部批量 |
| getSummaryBatch 批量优化 | ✅ | 150 次查询 → ~52 次 |
| pullMessages 批量查发送者 | ✅ | chat/user/groupUser 查询全部批量 |

### 第二轮（P1 级 - 已完成）
| 任务 | 状态 | 效果 |
|------|------|------|
| buildGroupSnapshot 批量查询用户 | ✅ | 快照构建 500 次 → 1 次批量 |
| buildGroupMembersAddedTipContent 批量查询 | ✅ | 提示文本构建 500 次 → 1 次批量 |
| getGroupMembers SQL 分页 | ✅ | 全量加载+内存分页 → SQL LIMIT + 缓存 |

### 第三轮（P2 级 + 索引 - 已完成）
| 任务 | 状态 | 效果 |
|------|------|------|
| 异常堆栈记录修复 | ✅ | 40+ 处 catch 块改为完整堆栈输出 |
| 数据库索引创建 | ✅ | 生成 5 个核心联合索引 SQL 脚本 |

> 审计日志跳过：用户现阶段只关注性能优化。
