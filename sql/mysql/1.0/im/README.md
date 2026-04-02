# IM 即时通讯模块 - 数据库表结构

## 概述

本目录包含 IM 即时通讯模块的数据库设计文件。

**创建日期**: 2026-02-11  
**更新日期**: 2026-02-24  
**版本**: v1.0  
**数据库**: MySQL 8.0+  
**字符集**: utf8mb4  
**排序规则**: utf8mb4_unicode_ci

## 文件清单

| 文件名 | 说明 | 状态 |
|--------|------|------|
| ddl_im_tables.sql | IM 模块所有表结构定义(8张表) | ✅已完成 |
| dml_im_init_data.sql | IM 模块初始化数据(字典等) | 📝设计中 |
| README.md | 本文件(设计说明) | ✅已完成 |

## 表结构清单

### 核心表(8张)

| 序号 | 表名 | 说明 | 状态 |
|------|------|------|------|
| 1 | im_conversation | 会话表(单聊/群聊) | ✅已完成 |
| 2 | im_message | 消息表(所有聊天消息) | ✅已完成 |
| 3 | im_group | 群组表(群组基本信息) | ✅已完成 |
| 4 | im_group_member | 群成员表(群组成员关系) | ✅已完成 |
| 5 | im_contact_setting | 联系人设置表(个性化设置) | ✅已完成 |
| 6 | im_message_read | 消息已读表(群聊已读回执) | ✅已完成 |
| 7 | im_group_file | 群文件关联表(群文件管理) | ✅已完成 |
| 8 | im_group_folder | 群文件夹表(文件夹管理) | ✅已完成 |

## 执行说明

**开发阶段**: 直接执行 `ddl_im_tables.sql` 即可创建所有表，无需考虑版本兼容性。

```bash
# 一次性创建所有表
mysql -u root -p shengyu-saas < ddl_im_tables.sql
```

**说明**:
- 开发阶段以最优性能和最优方案实现
- 不需要考虑版本兼容性和数据迁移
- 表结构变更直接修改 `ddl_im_tables.sql` 文件
- 重新执行脚本会先删除旧表再创建新表（DROP TABLE IF EXISTS）

## 设计说明

### 1. im_conversation (会话表)

**功能**: 存储用户的会话列表(单聊/群聊)

**核心字段**:
- `user_id`: 用户ID
- `target_id`: 目标ID(单聊为对方用户ID,群聊为群ID)
- `conversation_type`: 会话类型(1-单聊 2-群聊)
- `unread_count`: 未读消息数
- `is_pinned`: 是否置顶
- `no_disturb`: 是否免打扰

### 2. im_message (消息表)

**功能**: 存储所有聊天消息(单聊/群聊)

**核心字段**:
- `message_type`: 消息类型(1-文本 2-图片 3-语音 4-视频 5-文件 6-位置 7-表情包 8-自定义贴纸 10-系统消息)
- `content`: 消息内容(TEXT类型)
- `extra`: 扩展信息(JSON格式)
- `status`: 消息状态(1-发送中 2-已发送 3-已送达 4-已读 5-发送失败 6-已撤回)
- `quote_message_id`: 引用消息ID

**注意**: 消息表数据量大,后续可能需要按月分表

### 3. im_group (群组表)

**功能**: 存储群组基本信息

**核心字段**:
- `name`: 群名称
- `owner_id`: 群主ID
- `group_type`: 群类型(1-普通群 2-工作群)
- `member_count`: 成员数量
- `max_member_count`: 最大成员数量(默认500)
- `allow_member_invite`: 是否允许成员邀请
- `need_approval`: 加群是否需要审批
- `mute_all`: 是否全员禁言

### 4. im_group_member (群成员表)

**功能**: 存储群组成员关系

**核心字段**:
- `group_id`: 群ID
- `user_id`: 用户ID
- `role`: 角色(1-群主 2-管理员 3-普通成员)
- `nickname`: 群昵称
- `mute_end_time`: 禁言结束时间

### 5. im_contact_setting (联系人设置表)

**功能**: 存储用户对联系人的个性化设置

**核心字段**:
- `user_id`: 用户ID
- `contact_id`: 联系人ID(对应 system_users.id)
- `remark_name`: 备注名
- `star`: 是否星标
- `no_disturb`: 是否免打扰

**说明**: 企业内部IM,联系人直接来源于 `system_users` 表,本表仅存储个性化设置

### 6. im_message_read (消息已读表)

**功能**: 存储群聊消息的已读状态

**核心字段**:
- `message_id`: 消息ID
- `user_id`: 用户ID
- `read_time`: 已读时间

**说明**: 仅用于群聊消息已读回执,单聊消息已读状态存储在 `im_message.status` 字段

## 表关系图

```
im_message ───┬──> im_conversation (更新会话)
             │
             ├──> im_group (群聊消息)
             │
             └──> system_users (单聊消息,联系人来源)

im_group ────────> im_group_member (群成员)

im_contact_setting ──> system_users (联系人个性化设置)

im_message_read ──> im_message (群聊已读回执)

system_users ──> system_dept (用户所属部门)
```

## 设计原则

1. **租户隔离**: 每个表都包含 `tenant_id` 字段和索引
2. **软删除**: 使用 `deleted` 字段,不物理删除数据
3. **审计字段**: 包含 `creator`, `create_time`, `updater`, `update_time`
4. **字符集**: 统一使用 `utf8mb4` 和 `utf8mb4_unicode_ci`
5. **索引规范**: 合理的索引设计,包含唯一索引、普通索引、租户索引
6. **注释完整**: 每个表、字段、索引都有详细的 COMMENT

## 后续计划

- [ ] 完善设计文档
- [ ] 代码审查
- [ ] 正式执行 DDL
- [ ] 执行初始化数据
- [ ] 开发后端 API
- [ ] 对接移动端

## 相关文档

- [IM即时通讯架构设计文档-v2.0](../../../doc/IM即时通讯架构设计文档-v2.0.md)
- [IM即时通讯开发任务清单-v2.0](../../../doc/IM即时通讯开发任务清单-v2.0.md)
- [数据库变更管理规范](../README.md)
## 版本历史

| 版本 | 日期 | 说明 | 作者 |
|------|------|------|------|
| v1.0 | 2026-02-11 | 初始设计版本,定义6张核心表 | AI |


### 1. im_conversation (会话表)

**功能**: 存储用户的会话列表(单聊/群聊)

**核心字段**:
- `user_id`: 用户ID
- `target_id`: 目标ID(单聊为对方用户ID,群聊为群ID)
- `conversation_type`: 会话类型(1-单聊 2-群聊)
- `unread_count`: 未读消息数
- `last_message_id`: 最后一条消息ID
- `last_message_content`: 最后一条消息内容
- `last_message_time`: 最后一条消息时间
- `is_pinned`: 是否置顶
- `no_disturb`: 是否免打扰

**索引**:
- 唯一索引: `idx_user_target` (user_id, target_id, conversation_type, tenant_id)
- 普通索引: `idx_user_time` (user_id, last_message_time DESC)
- 租户索引: `idx_tenant` (tenant_id)

### 2. im_message (消息表)

**功能**: 存储所有聊天消息(单聊/群聊)

**核心字段**:
- `conversation_id`: 会话ID
- `sender_id`: 发送者ID
- `receiver_id`: 接收者ID(单聊有值,群聊为NULL)
- `group_id`: 群ID(群聊有值,单聊为NULL)
- `message_type`: 消息类型(1-文本 2-图片 3-语音 4-视频 5-文件 6-位置 7-表情包 8-自定义贴纸 10-系统消息)
- `content`: 消息内容(TEXT类型)
- `extra`: 扩展信息(JSON格式,存储文件URL、时长、大小等)
- `send_time`: 发送时间
- `status`: 消息状态(1-发送中 2-已发送 3-已送达 4-已读 5-发送失败 6-已撤回)
- `recall_time`: 撤回时间
- `recall_by`: 撤回人ID
- `quote_message_id`: 引用消息ID

**索引**:
- 会话索引: `idx_conversation` (conversation_id, send_time DESC)
- 发送者索引: `idx_sender` (sender_id, send_time DESC)
- 接收者索引: `idx_receiver` (receiver_id, send_time DESC)
- 群组索引: `idx_group` (group_id, send_time DESC)
- 租户索引: `idx_tenant` (tenant_id)

**注意**: 消息表数据量大,建议按月分表

### 3. im_group (群组表)

**功能**: 存储群组基本信息

**核心字段**:
- `name`: 群名称
- `avatar`: 群头像
- `owner_id`: 群主ID
- `group_type`: 群类型(1-普通群 2-工作群)
- `member_count`: 成员数量
- `max_member_count`: 最大成员数量(默认500)
- `notice`: 群公告
- `introduction`: 群简介
- `status`: 群状态(1-正常 2-已解散)
- `allow_member_invite`: 是否允许成员邀请
- `need_approval`: 加群是否需要审批
- `mute_all`: 是否全员禁言

**索引**:
- 群主索引: `idx_owner` (owner_id)
- 租户索引: `idx_tenant` (tenant_id)

### 4. im_group_member (群成员表)

**功能**: 存储群组成员关系

**核心字段**:
- `group_id`: 群ID
- `user_id`: 用户ID
- `role`: 角色(1-群主 2-管理员 3-普通成员)
- `nickname`: 群昵称
- `join_time`: 加入时间
- `mute_end_time`: 禁言结束时间

**索引**:
- 唯一索引: `idx_group_user` (group_id, user_id, tenant_id)
- 用户索引: `idx_user` (user_id)
- 租户索引: `idx_tenant` (tenant_id)

### 5. im_contact_setting (联系人设置表)

**功能**: 存储用户对联系人的个性化设置(备注名、星标、免打扰)

**核心字段**:
- `user_id`: 用户ID
- `contact_id`: 联系人ID(对应 system_users.id)
- `remark_name`: 备注名
- `star`: 是否星标
- `no_disturb`: 是否免打扰

**索引**:
- 唯一索引: `idx_user_contact` (user_id, contact_id, tenant_id)
- 租户索引: `idx_tenant` (tenant_id)

**说明**:
- 企业内部IM,联系人直接来源于 `system_users` 表(同租户)
- 本表仅存储用户的个性化设置
- 无需好友申请、拉黑等社交功能

### 6. im_message_read (消息已读表)

**功能**: 存储群聊消息的已读状态

**核心字段**:
- `message_id`: 消息ID
- `user_id`: 用户ID
- `read_time`: 已读时间

**索引**:
- 唯一索引: `idx_message_user` (message_id, user_id, tenant_id)
- 用户索引: `idx_user` (user_id)
- 租户索引: `idx_tenant` (tenant_id)

**说明**:
- 仅用于群聊消息已读回执
- 单聊消息已读状态存储在 `im_message` 表的 `status` 字段

### 7. im_message_voice_play (语音播放状态表)

**功能**: 存储用户对语音消息的播放状态（首次播放）

**核心字段**:
- `message_id`: 语音消息ID
- `chat_id`: 会话ID
- `user_id`: 播放用户ID
- `played_time`: 首次播放时间

**索引**:
- 唯一索引: `idx_message_user_deleted` (message_id, user_id, tenant_id, deleted)
- 用户会话索引: `idx_user_chat` (user_id, chat_id, tenant_id, deleted)
- 租户索引: `idx_tenant` (tenant_id)

**说明**:
- 仅用于“语音未听点”多端同步
- 与消息“已读/未读”统计口径解耦

## 表关系图

```
im_message ───┬──> im_conversation (更新会话)
             │
             ├──> im_group (群聊消息)
             │
             └──> system_users (单聊消息,联系人来源)

im_group ────────> im_group_member (群成员)

im_contact_setting ──> system_users (联系人个性化设置)

im_message_read ──> im_message (群聊已读回执)

system_users ──> system_dept (用户所属部门)
```

## 执行顺序

```bash
# 1. 创建会话表
mysql -u root -p shengyu-saas < ddl_im_conversation.sql

# 2. 创建消息表
mysql -u root -p shengyu-saas < ddl_im_message.sql

# 3. 创建群组表
mysql -u root -p shengyu-saas < ddl_im_group.sql

# 4. 创建群成员表
mysql -u root -p shengyu-saas < ddl_im_group_member.sql

# 5. 创建联系人设置表
mysql -u root -p shengyu-saas < ddl_im_contact_setting.sql

# 6. 创建消息已读表
mysql -u root -p shengyu-saas < ddl_im_message_read.sql
```

或者一次性执行:

```bash
# 按顺序执行所有 DDL 文件
for file in ddl_*.sql; do
  echo "Executing $file..."
  mysql -u root -p shengyu-saas < "$file"
done
```

## 数据量预估

| 表名 | 预估数据量 | 增长速度 | 分表建议 |
|------|-----------|---------|---------|
| im_conversation | 10万/租户 | 慢 | 不需要 |
| im_message | 1000万/月 | 快 | 建议按月分表 |
| im_group | 1万/租户 | 慢 | 不需要 |
| im_group_member | 50万/租户 | 中 | 不需要 |
| im_contact_setting | 10万/租户 | 慢 | 不需要 |
| im_message_read | 500万/月 | 快 | 建议按月分表 |

## 性能优化建议

### 1. 索引优化
- 所有查询字段都已添加索引
- 租户隔离索引必须包含 `tenant_id`
- 时间字段使用降序索引(DESC)

### 2. 分表策略
- `im_message` 表建议按月分表(数据量大)
- `im_message_read` 表建议按月分表(数据量大)
- 分表命名: `im_message_202602`, `im_message_202603`

### 3. 数据归档
- 消息表定期归档(如保留最近6个月)
- 已读表定期清理(如保留最近3个月)
- 归档数据可迁移到冷存储

### 4. 缓存策略
- 会话列表缓存(Redis)
- 最近消息缓存(Redis)
- 群成员列表缓存(Redis)
- 联系人设置缓存(Redis)

## 注意事项

1. **租户隔离**: 所有表都包含 `tenant_id` 字段,必须在查询时添加租户条件
2. **软删除**: 所有表都使用 `deleted` 字段实现软删除,不物理删除数据
3. **字符集**: 统一使用 `utf8mb4` 字符集,支持 Emoji 表情
4. **时间字段**: 使用 `datetime` 类型,不使用 `timestamp`(避免2038年问题)
5. **JSON字段**: `im_message.extra` 使用 JSON 类型存储扩展信息
6. **大字段**: `im_message.content` 使用 TEXT 类型,支持长文本消息

## 相关文档

- [IM即时通讯架构设计文档-v2.0](../../../doc/IM即时通讯架构设计文档-v2.0.md)
- [IM即时通讯开发任务清单-v2.0](../../../doc/IM即时通讯开发任务清单-v2.0.md)
- [数据库变更管理规范](../README.md)

## 版本历史

| 版本 | 日期 | 说明 | 作者 |
|------|------|------|------|
| v1.0 | 2026-02-11 | 初始版本,创建6张核心表 | AI |
