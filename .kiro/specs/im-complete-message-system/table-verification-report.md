# IM 消息系统 - 数据库表结构验证报告

## 验证日期
2026-02-11

## 验证范围
验证 `sql/mysql/1.0/im/ddl_im_tables.sql` 中的所有表结构是否满足需求文档和设计文档的要求。

## 验证结果

### 1. 现有表验证 ✅

#### 1.1 im_message (消息表) ✅
**状态**: 已存在，结构完整

**核心字段**:
- `id`: 消息ID (主键)
- `conversation_id`: 会话ID
- `sender_id`: 发送者ID
- `receiver_id`: 接收者ID (单聊)
- `group_id`: 群ID (群聊)
- `message_type`: 消息类型 (1-文本 2-图片 3-语音 4-视频 5-文件 6-位置 7-表情包 8-自定义贴纸 10-系统消息)
- `content`: 消息内容
- `extra`: 扩展信息 (JSON格式)
- `send_time`: 发送时间
- `status`: 消息状态 (1-发送中 2-已发送 3-已送达 4-已读 5-发送失败 6-已撤回)
- `recall_time`: 撤回时间
- `recall_by`: 撤回人ID
- `quote_message_id`: 引用消息ID
- `tenant_id`: 租户编号

**索引**:
- PRIMARY KEY: `id`
- `idx_conversation`: (conversation_id, send_time DESC) - 会话消息查询
- `idx_sender`: (sender_id, send_time DESC) - 发送者消息查询
- `idx_receiver`: (receiver_id, send_time DESC) - 接收者消息查询
- `idx_group`: (group_id, send_time DESC) - 群组消息查询
- `idx_tenant`: (tenant_id) - 租户隔离

**满足需求**: 1.2, 2.2, 3.1-3.7, 4.1-4.6, 6.4, 8.3, 58.1

#### 1.2 im_conversation (会话表) ✅
**状态**: 已存在，结构完整

**核心字段**:
- `id`: 会话ID (主键)
- `user_id`: 用户ID
- `target_id`: 目标ID (单聊为对方用户ID，群聊为群ID)
- `conversation_type`: 会话类型 (1-单聊 2-群聊)
- `unread_count`: 未读消息数
- `last_message_id`: 最后一条消息ID
- `last_message_content`: 最后一条消息内容
- `last_message_time`: 最后一条消息时间
- `is_pinned`: 是否置顶
- `no_disturb`: 是否免打扰
- `deleted_by_user`: 用户是否删除会话
- `tenant_id`: 租户编号

**索引**:
- PRIMARY KEY: `id`
- UNIQUE `idx_user_target_deleted`: (user_id, target_id, conversation_type, tenant_id, deleted) - 唯一会话
- `idx_user_time`: (user_id, last_message_time DESC) - 会话列表查询
- `idx_tenant`: (tenant_id) - 租户隔离

**满足需求**: 12.1-12.6, 28.1, 46.1-46.4, 75.1, 76.1

#### 1.3 im_group (群组表) ✅
**状态**: 已存在，结构完整

**核心字段**:
- `id`: 群ID (主键)
- `name`: 群名称
- `avatar`: 群头像
- `owner_id`: 群主ID
- `group_type`: 群类型 (1-普通群 2-工作群)
- `member_count`: 成员数量
- `max_member_count`: 最大成员数量
- `notice`: 群公告
- `notice_pinned`: 群公告是否置顶
- `introduction`: 群简介
- `status`: 群状态 (1-正常 2-已解散)
- `allow_member_invite`: 是否允许成员邀请
- `need_approval`: 加群是否需要审批
- `mute_all`: 是否全员禁言
- `tenant_id`: 租户编号

**索引**:
- PRIMARY KEY: `id`
- `idx_owner`: (owner_id) - 群主查询
- `idx_tenant`: (tenant_id) - 租户隔离

**满足需求**: 13.1-13.6, 14.1-14.5, 52.5-52.6

#### 1.4 im_group_member (群成员表) ✅
**状态**: 已存在，结构完整

**核心字段**:
- `id`: 成员ID (主键)
- `group_id`: 群ID
- `user_id`: 用户ID
- `role`: 角色 (1-群主 2-管理员 3-普通成员)
- `nickname`: 群昵称
- `join_time`: 加入时间
- `mute_end_time`: 禁言结束时间
- `tenant_id`: 租户编号

**索引**:
- PRIMARY KEY: `id`
- UNIQUE `idx_group_user_deleted`: (group_id, user_id, tenant_id, deleted) - 唯一成员
- `idx_user`: (user_id) - 用户查询
- `idx_tenant`: (tenant_id) - 租户隔离

**满足需求**: 13.3-13.5, 51.1-51.6, 52.1-52.4, 53.1-53.3

#### 1.5 im_message_read (消息已读表) ✅
**状态**: 已存在，结构完整

**核心字段**:
- `id`: 已读ID (主键)
- `message_id`: 消息ID
- `user_id`: 用户ID
- `read_time`: 已读时间
- `tenant_id`: 租户编号

**索引**:
- PRIMARY KEY: `id`
- UNIQUE `idx_message_user_deleted`: (message_id, user_id, tenant_id, deleted) - 唯一已读记录
- `idx_user`: (user_id) - 用户查询
- `idx_tenant`: (tenant_id) - 租户隔离

**满足需求**: 5.1-5.6, 80.1-80.6

#### 1.6 im_group_file (群文件关联表) ✅
**状态**: 已存在，结构完整

**核心字段**:
- `id`: 主键ID
- `group_id`: 群组ID
- `file_id`: 文件ID (关联 infra_file.id)
- `uploader_id`: 上传者ID
- `folder_id`: 文件夹ID (0表示根目录)
- `is_favorite`: 是否收藏
- `download_count`: 下载次数
- `tenant_id`: 租户编号

**索引**:
- PRIMARY KEY: `id`
- UNIQUE `uk_group_file_deleted`: (group_id, file_id, tenant_id, deleted) - 唯一文件
- `idx_group`: (group_id, tenant_id) - 群组查询
- `idx_uploader`: (uploader_id) - 上传者查询
- `idx_folder`: (folder_id) - 文件夹查询
- `idx_tenant`: (tenant_id) - 租户隔离

**满足需求**: 41.1-41.6 (集成现有文件上传服务)

#### 1.7 im_group_folder (群文件夹表) ✅
**状态**: 已存在，结构完整

**核心字段**:
- `id`: 主键ID
- `group_id`: 群组ID
- `folder_name`: 文件夹名称
- `parent_id`: 父文件夹ID (0表示根目录)
- `tenant_id`: 租户编号

**索引**:
- PRIMARY KEY: `id`
- `idx_group`: (group_id, tenant_id) - 群组查询
- `idx_parent`: (parent_id) - 父文件夹查询
- `idx_tenant`: (tenant_id) - 租户隔离

**满足需求**: 41.1-41.6 (群文件夹管理)

### 2. 新增表验证 ✅

#### 2.1 im_call_record (通话记录表) ✅
**状态**: 新创建，结构完整

**核心字段**:
- `id`: 通话记录ID (主键)
- `call_id`: 通话ID (唯一标识)
- `call_type`: 通话类型 (1-语音通话 2-视频通话)
- `caller_id`: 呼叫者ID
- `callee_id`: 被叫者ID
- `start_time`: 通话开始时间
- `end_time`: 通话结束时间
- `duration`: 通话时长 (秒)
- `status`: 通话状态 (1-未接听 2-已接听 3-已拒绝 4-忙线 5-已取消)
- `tenant_id`: 租户编号

**索引**:
- PRIMARY KEY: `id`
- UNIQUE `idx_call_id`: (call_id) - 通话ID唯一索引
- `idx_caller`: (caller_id, start_time DESC) - 呼叫者查询
- `idx_callee`: (callee_id, start_time DESC) - 被叫者查询
- `idx_tenant`: (tenant_id) - 租户隔离

**满足需求**: 23.1-23.6 (通话记录管理)

**设计要点**:
- 支持语音和视频通话记录
- 记录通话时长和状态
- 支持未接听、已接听、已拒绝等多种状态
- 通过 call_id 唯一标识每次通话
- 支持按呼叫者和被叫者查询通话记录

#### 2.2 im_notification (通知表) ✅
**状态**: 新创建，结构完整

**核心字段**:
- `id`: 通知ID (主键)
- `user_id`: 接收用户ID
- `notify_type`: 通知类型 (1-系统公告 4-自定义通知)
- `title`: 通知标题
- `content`: 通知内容
- `icon`: 通知图标URL
- `extra`: 扩展信息 (JSON格式，存储操作按钮、跳转配置、业务数据等)
- `is_read`: 是否已读
- `read_time`: 已读时间
- `is_important`: 是否重要 (重要通知需强制阅读)
- `expire_time`: 过期时间
- `status`: 通知状态 (1-正常 2-已过期 3-已撤回)
- `tenant_id`: 租户编号

**索引**:
- PRIMARY KEY: `id`
- `idx_user_time`: (user_id, create_time DESC) - 用户通知列表查询
- `idx_user_read`: (user_id, is_read) - 未读通知查询
- `idx_type`: (notify_type) - 按类型查询
- `idx_tenant`: (tenant_id) - 租户隔离

**满足需求**: 26.1-26.6, 27.1-27.6 (系统通知、自定义通知)

**设计要点**:
- 支持多种通知类型：系统公告、自定义通知
- 通过 extra 字段存储操作按钮、跳转配置等扩展信息
- 支持重要通知标记，强制用户阅读
- 支持通知过期时间和状态管理
- 支持通知撤回功能

### 3. 索引优化验证 ✅

#### 3.1 查询性能索引
所有表都包含必要的索引以支持高效查询：

1. **会话消息查询**: `im_message.idx_conversation` (conversation_id, send_time DESC)
   - 支持按会话分页查询历史消息
   - 满足需求 15.1-15.6 (消息历史加载)

2. **会话列表查询**: `im_conversation.idx_user_time` (user_id, last_message_time DESC)
   - 支持按用户查询会话列表并按时间排序
   - 满足需求 12.1, 46.1-46.4 (会话管理和排序)

3. **群成员查询**: `im_group_member.idx_group_user_deleted` (group_id, user_id, tenant_id, deleted)
   - 支持快速查询群成员关系
   - 满足需求 13.3-13.5, 51.1-51.6 (群成员管理)

4. **消息已读查询**: `im_message_read.idx_message_user_deleted` (message_id, user_id, tenant_id, deleted)
   - 支持快速查询消息已读状态
   - 满足需求 5.1-5.6, 80.1-80.6 (已读回执)

5. **通话记录查询**: `im_call_record.idx_caller`, `im_call_record.idx_callee`
   - 支持按呼叫者和被叫者查询通话记录
   - 满足需求 23.1-23.6 (通话记录管理)

6. **通知查询**: `im_notification.idx_user_time`, `im_notification.idx_user_read`
   - 支持按用户查询通知列表和未读通知
   - 满足需求 24.1-27.6 (各类通知)

#### 3.2 租户隔离索引
所有表都包含 `tenant_id` 字段和 `idx_tenant` 索引：
- 支持多租户数据隔离
- 满足需求 90.1-90.6 (租户隔离)

#### 3.3 唯一约束索引
关键表包含唯一约束索引，防止重复数据：
- `im_conversation.idx_user_target_deleted`: 防止重复会话
- `im_group_member.idx_group_user_deleted`: 防止重复群成员
- `im_message_read.idx_message_user_deleted`: 防止重复已读记录
- `im_group_file.uk_group_file_deleted`: 防止重复群文件
- `im_call_record.idx_call_id`: 防止重复通话记录

### 4. 数据类型验证 ✅

#### 4.1 字符集和排序规则
- 所有文本字段使用 `utf8mb4` 字符集
- 使用 `utf8mb4_unicode_ci` 排序规则
- 支持 emoji 表情符号存储
- 满足需求 3.1 (表情符号支持)

#### 4.2 JSON 字段
- `im_message.extra`: 存储消息扩展信息 (文件URL、时长、大小等)
- `im_notification.extra`: 存储通知扩展信息 (操作按钮、跳转配置等)
- 支持灵活的扩展数据存储
- 满足需求 3.2-3.7, 27.2-27.4 (多种消息类型和自定义通知)

#### 4.3 时间字段
- 所有时间字段使用 `datetime` 类型
- 支持精确到秒的时间记录
- 满足需求 16.1-16.6 (消息时间显示)

#### 4.4 布尔字段
- 使用 `bit(1)` 类型存储布尔值
- 包括: is_pinned, no_disturb, deleted, is_read, is_important 等
- 节省存储空间，提高查询效率

### 5. 逻辑删除支持 ✅

所有表都支持逻辑删除：
- 包含 `deleted` 字段 (bit(1))
- 唯一索引包含 `deleted` 字段，支持删除后重新创建
- 满足需求 12.4, 13.5, 49.3 (会话删除、退出群组、消息删除)

### 6. 审计字段 ✅

所有表都包含完整的审计字段：
- `creator`: 创建者
- `create_time`: 创建时间 (DEFAULT CURRENT_TIMESTAMP)
- `updater`: 更新者
- `update_time`: 更新时间 (ON UPDATE CURRENT_TIMESTAMP)
- 满足需求 93.1-93.6 (日志记录和审计)

## 验证结论

### ✅ 所有表结构验证通过

1. **现有表 (7个)**: 全部验证通过，结构完整，索引合理
   - im_message ✅
   - im_conversation ✅
   - im_group ✅
   - im_group_member ✅
   - im_message_read ✅
   - im_group_file ✅
   - im_group_folder ✅

2. **新增表 (2个)**: 已创建，结构完整，索引合理
   - im_call_record ✅
   - im_notification ✅

3. **索引优化**: 所有表都包含必要的索引，支持高效查询 ✅

4. **租户隔离**: 所有表都支持多租户数据隔离 ✅

5. **数据类型**: 字符集、JSON、时间、布尔字段都符合设计要求 ✅

6. **逻辑删除**: 所有表都支持逻辑删除 ✅

7. **审计字段**: 所有表都包含完整的审计字段 ✅

### 满足的需求

- **消息功能**: 1.2, 2.2, 3.1-3.7, 4.1-4.6, 5.1-5.6, 6.4, 8.3, 15.1-15.6, 16.1-16.6, 58.1
- **会话管理**: 12.1-12.6, 28.1, 46.1-46.4, 75.1, 76.1
- **群组管理**: 13.1-13.6, 14.1-14.5, 51.1-51.6, 52.1-52.6, 53.1-53.3
- **通话功能**: 23.1-23.6
- **通知功能**: 24.1-27.6
- **文件管理**: 41.1-41.6
- **已读回执**: 80.1-80.6
- **租户隔离**: 90.1-90.6
- **日志审计**: 93.1-93.6

## 下一步建议

1. ✅ 表结构已完成，可以执行 DDL 创建表
2. ⏭️ 继续实施计划的阶段2：后端核心服务实现
3. ⏭️ 实现 ImMessageService, ImConversationService, ImGroupService 等核心服务
4. ⏭️ 实现 WebSocket 中间件 SPI 集成

## 附录：表关系图

```
im_conversation (会话表)
    ├─ user_id → system_users.id
    ├─ target_id → system_users.id (单聊) / im_group.id (群聊)
    └─ last_message_id → im_message.id

im_message (消息表)
    ├─ conversation_id → im_conversation.id
    ├─ sender_id → system_users.id
    ├─ receiver_id → system_users.id (单聊)
    ├─ group_id → im_group.id (群聊)
    └─ quote_message_id → im_message.id (引用回复)

im_group (群组表)
    └─ owner_id → system_users.id

im_group_member (群成员表)
    ├─ group_id → im_group.id
    └─ user_id → system_users.id

im_message_read (消息已读表)
    ├─ message_id → im_message.id
    └─ user_id → system_users.id

im_group_file (群文件关联表)
    ├─ group_id → im_group.id
    ├─ file_id → infra_file.id
    ├─ uploader_id → system_users.id
    └─ folder_id → im_group_folder.id

im_group_folder (群文件夹表)
    ├─ group_id → im_group.id
    └─ parent_id → im_group_folder.id (自关联)

im_call_record (通话记录表)
    ├─ caller_id → system_users.id
    └─ callee_id → system_users.id

im_notification (通知表)
    └─ user_id → system_users.id
```
