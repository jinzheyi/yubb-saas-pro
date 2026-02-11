# IM 即时通讯逻辑设计文档 v1.0

> **文档版本**: v1.0.3  
> **创建日期**: 2026年2月11日  
> **更新日期**: 2026年2月11日  
> **项目**: 圣钰 SaaS Pro - IM 即时通讯系统  
> **定位**: 企业内部IM(无需添加好友、拉黑等社交功能)  
> **目标**: AI 可执行的详细设计文档  
> **中间件**: shengyu-spring-boot-starter-websocket (基于 Netty + Protobuf)

---

## 📋 文档说明

本文档基于以下现有资料编写:
1. **IM 中间件**: `shengyu-framework/shengyu-spring-boot-starter-websocket` (基于 Netty + Protobuf)
2. **租户后台**: `shengyu-module-system`
3. **移动端**: `shengyu-ui/shengyu-ui-admin-uniappx`
4. **数据库表**: `sql/mysql/1.0/shengyu-saas.sql` (im_* 表)

**重要说明**:
- 本系统定位为企业内部IM,联系人直接来源于租户的 `system_users` 表
- 无需添加好友、好友申请、拉黑等社交功能
- 无需"是否能看我"、"是否能看他"等隐私设置
- 部门信息直接从 `system_dept` 表查询
- 仅提供联系人个性化设置(备注名、星标、免打扰)
- 支持单用户多设备登录
- 支持租户隔离和平台端/租户端双端认证
- 支持分布式部署(Redis/RocketMQ/Kafka/RabbitMQ 消息总线)

文档包含:
- 完整的前后端交互接口定义
- 数据库表结构与字段说明
- Protobuf 通信协议(基于中间件实现)
- 业务逻辑流程图
- System 模块与中间件的 SPI 接口实现
- 可执行的任务拆解清单

---

## 目录

1. [系统架构概览](#1-系统架构概览)
2. [数据库设计](#2-数据库设计)
3. [Protobuf 协议定义](#3-protobuf-协议定义)
4. [WebSocket 连接流程](#4-websocket-连接流程)
5. [消息收发流程](#5-消息收发流程)
6. [移动端页面交互逻辑](#6-移动端页面交互逻辑)
7. [后端 API 接口设计](#7-后端-api-接口设计)
8. [System 模块与中间件交互](#8-system-模块与中间件交互)
9. [缓存设计](#9-缓存设计)
10. [性能优化](#10-性能优化)
11. [任务拆解清单](#11-任务拆解清单)
12. [开发注意事项](#12-开发注意事项)
13. [附录](#13-附录)
14. [后端实现详细指南](#14-后端实现详细指南)
15. [WebSocket 中间件集成指南](#15-websocket-中间件集成指南)

---

## 1. 系统架构概览

### 1.1 三层架构

```
┌──────────────────────────────────────────────────────────┐
│                 移动端 (uni-app x)                       │
│ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐   │
│ │消息列表│ │聊天页面│ │通讯录  │ │个人中心│   │
│ └──────────┘ └──────────┘ └──────────┘ └──────────┘   │
└──────────────────┬───────────────────────────────────────┘
                   ↓HTTP REST API + WebSocket(Protobuf)
┌──────────────────┴───────────────────────────────────────┐
│             shengyu-module-system (业务层)               │
│ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ │
│ │Controller   │ │  Service    │ │   Mapper    │ │
│ │(REST API)   │ │ (业务逻辑)   │ │ (数据访问)   │ │
│ └──────────────┘ └──────────────┘ └──────────────┘ │
│        ↓                 ↓                 ↓         │
│        └─────────────────┴─────────────────┘         │
│                         ↓                              │
│ ┌────────────────────────────────────────────────────┐│
│ │ 实现 SPI 接口                                      ││
│ │ - MessageStorageService (消息存储)                ││
│ │ - AuthService (认证服务)                          ││
│ │ - MessageCacheService (消息缓存,可选)             ││
│ │ - OfflinePushService (离线推送,可选)              ││
│ └────────────────────────────────────────────────────┘│
└──────────────────┬───────────────────────────────────────┘
                   ↓SPI 调用
┌──────────────────┴───────────────────────────────────────┐
│   shengyu-spring-boot-starter-websocket (中间件层)       │
│ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ │
│ │Netty Server │ │  Session    │ │  Message    │ │
│ │ (连接管理)   │ │  Manager    │ │  Processor  │ │
│ │ - Epoll优化  │ │ - 多设备支持 │ │ - 消息路由   │ │
│ │ - 50w+连接   │ │ - 租户隔离   │ │ - Protobuf  │ │
│ └──────────────┘ └──────────────┘ └──────────────┘ │
│                                                         │
│ ┌────────────────────────────────────────────────────┐│
│ │ 消息总线 (分布式部署支持)                          ││
│ │ - Local (单机模式)                                 ││
│ │ - Redis (推荐)                                     ││
│ │ - RocketMQ / Kafka / RabbitMQ                     ││
│ └────────────────────────────────────────────────────┘│
└──────────────────────────────────────────────────────────┘
```

### 1.2 核心模块职责

| 模块 | 职责 | 关键组件 |
|------|------|---------|
| **移动端** | 用户交互、消息展示、WebSocket 连接 | message.uvue, chat.uvue, contacts.uvue |
| **System 模块** | 业务逻辑、数据存储、API 接口、SPI 实现 | ImMessageController, ImMessageService, SPI 实现类 |
| **WebSocket 中间件** | 连接管理、协议处理、消息路由、认证鉴权 | NettyServer, NettySessionManager, MessageProcessor |

### 1.3 中间件核心特性

#### 1.3.1 高性能设计
- **Netty 框架**: 基于 NIO 的异步事件驱动架构
- **Epoll 优化**: Linux 环境下自动启用 Epoll,性能提升 30%+
- **连接能力**: 单机支持 50w+ TCP 长连接
- **消息吞吐**: 10w+ msg/s (单机)
- **低延迟**: < 100ms (局域网)

#### 1.3.2 协议支持
- **Protobuf**: 高性能二进制序列化,体积小 3-10 倍,速度快 20-100 倍
- **WebSocket**: 兼容 Web/小程序客户端
- **双协议**: 同时支持 Protobuf 和 WebSocket

#### 1.3.3 多租户支持
- **租户隔离**: 会话管理支持按租户分组
- **双端认证**: 支持租户端(LoginUser)和平台端(PlatformLoginUser)
- **租户级推送**: 支持向指定租户的所有用户推送消息

#### 1.3.4 多设备支持
- **单用户多设备**: 支持同一用户在多个设备同时在线
- **设备级推送**: 支持向指定用户的指定设备推送消息
- **设备管理**: 自动管理设备连接和断开

#### 1.3.5 分布式部署
- **消息总线**: 支持 Redis/RocketMQ/Kafka/RabbitMQ
- **水平扩展**: 多台服务器共享会话状态
- **负载均衡**: 支持 Nginx/LVS 负载均衡

#### 1.3.6 SPI 接口设计
- **MessageStorageService**: 消息存储(必须实现)
- **AuthService**: 认证服务(必须实现)
- **MessageCacheService**: 消息缓存(可选实现)
- **OfflinePushService**: 离线推送(可选实现)

---

## 2. 数据库设计

### 2.1 核心表结构


#### 2.1.1 im_message (消息表)

```sql
CREATE TABLE `im_message` (
  `id` bigint NOT NULL COMMENT '消息ID(雪花算法)',
  `message_type` int NOT NULL COMMENT '消息类型(100-文本 101-图片 102-语音 103-视频 104-文件 105-位置)',
  `sender_id` bigint NOT NULL COMMENT '发送者ID',
  `receiver_id` bigint COMMENT '接收者ID(单聊)',
  `group_id` bigint COMMENT '群组ID(群聊)',
  `content` text COMMENT '消息内容(JSON或Protobuf Base64)',
  `extra` varchar(500) COMMENT '扩展字段(JSON)',
  `status` int DEFAULT 0 COMMENT '状态(0-未读 1-已读 2-已撤回)',
  `sequence` bigint NOT NULL COMMENT '序列号(用于排序和去重)',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `tenant_id` bigint NOT NULL COMMENT '租户ID',
  PRIMARY KEY (`id`),
  KEY `idx_receiver_status` (`receiver_id`, `status`),
  KEY `idx_group` (`group_id`),
  KEY `idx_tenant` (`tenant_id`),
  KEY `idx_sequence` (`sequence`)
) COMMENT='IM消息表';
```

**字段说明**:
- `message_type`: 100-文本, 101-图片, 102-语音, 103-视频, 104-文件, 105-位置
- `content`: 根据消息类型存储不同格式的内容(JSON或Protobuf序列化后的Base64)
- `sequence`: 全局递增序列号,用于消息排序和去重
- `status`: 0-未读, 1-已读, 2-已撤回

#### 2.1.2 im_conversation (会话表)

```sql
CREATE TABLE `im_conversation` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `target_id` bigint NOT NULL COMMENT '对方ID(单聊用户ID或群组ID)',
  `conversation_type` int NOT NULL COMMENT '会话类型(1-单聊 2-群聊)',
  `unread_count` int DEFAULT 0 COMMENT '未读数',
  `last_message_id` bigint COMMENT '最后一条消息ID',
  `last_message_content` varchar(500) COMMENT '最后消息内容摘要',
  `last_message_time` datetime COMMENT '最后消息时间',
  `is_pinned` bit(1) DEFAULT b'0' COMMENT '是否置顶',
  `pinned_time` datetime COMMENT '置顶时间',
  `no_disturb` bit(1) DEFAULT b'0' COMMENT '免打扰',
  `creator` varchar(64) DEFAULT '',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updater` varchar(64) DEFAULT '',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted` bit(1) NOT NULL DEFAULT b'0',
  `tenant_id` bigint NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_target_type` (`user_id`, `target_id`, `conversation_type`, `tenant_id`),
  KEY `idx_user` (`user_id`, `tenant_id`),
  KEY `idx_last_time` (`last_message_time`)
) COMMENT='IM会话表';
```

**字段说明**:
- `conversation_type`: 1-单聊, 2-群聊
- `unread_count`: 未读消息数量
- `is_pinned`: 是否置顶会话
- `no_disturb`: 免打扰模式(不显示未读数,只显示红点)

#### 2.1.3 im_group (群组表)

```sql
CREATE TABLE `im_group` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '群ID',
  `user_id` bigint NOT NULL COMMENT '群主ID',
  `name` varchar(64) NOT NULL COMMENT '群名',
  `avatar` varchar(255) COMMENT '群头像地址',
  `status` int NOT NULL COMMENT '状态(0正常 1停用)',
  `remark` varchar(500) COMMENT '群公告',
  `invite_confirm` int COMMENT '邀请确认(0-无需确认 1-需要确认)',
  `creator` varchar(64) DEFAULT '',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updater` varchar(64) DEFAULT '',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted` bit(1) NOT NULL DEFAULT b'0',
  `tenant_id` bigint NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_tenant` (`tenant_id`)
) COMMENT='聊天群组表';
```

#### 2.1.4 im_group_user (群成员表)

```sql
CREATE TABLE `im_group_user` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `group_id` bigint NOT NULL COMMENT '群组ID',
  `nickname` varchar(64) COMMENT '在群里的昵称',
  `role` int DEFAULT 0 COMMENT '角色(0-普通成员 1-管理员 2-群主)',
  `creator` varchar(64) DEFAULT '',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updater` varchar(64) DEFAULT '',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted` bit(1) NOT NULL DEFAULT b'0',
  `tenant_id` bigint NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_group` (`user_id`, `group_id`, `tenant_id`),
  KEY `idx_group` (`group_id`)
) COMMENT='聊天群用户表';
```

#### 2.1.5 im_contact_setting (联系人设置表)

> **说明**: 企业内部IM,联系人直接来源于租户的用户表(system_users),无需添加好友。本表仅用于存储用户对联系人的个性化设置。

```sql
CREATE TABLE `im_contact_setting` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `contact_id` bigint NOT NULL COMMENT '联系人ID(对应 system_users.id)',
  `nickname` varchar(64) COMMENT '备注名',
  `star` bit(1) DEFAULT b'0' COMMENT '是否星标联系人',
  `no_disturb` bit(1) DEFAULT b'0' COMMENT '是否免打扰',
  `creator` varchar(64) DEFAULT '',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updater` varchar(64) DEFAULT '',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted` bit(1) NOT NULL DEFAULT b'0',
  `tenant_id` bigint NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_contact` (`user_id`, `contact_id`, `tenant_id`),
  KEY `idx_contact` (`contact_id`),
  KEY `idx_tenant` (`tenant_id`)
) COMMENT='IM联系人设置表';
```

**字段说明**:
- `user_id`: 当前用户ID
- `contact_id`: 联系人ID,对应 `system_users.id`
- `nickname`: 备注名(可选)
- `star`: 是否星标联系人
- `no_disturb`: 是否免打扰(单独对某个联系人设置)

**数据来源**:
- 联系人列表直接从 `system_users` 表查询(同租户下的所有用户)
- 部门信息直接从 `system_dept` 表查询
- 本表仅存储用户的个性化设置(备注名、星标、免打扰)

#### 2.1.6 删除的表

以下表在企业内部IM场景下不需要:
- ~~`im_friend` (好友表)~~ - 联系人直接来源于 `system_users`
- ~~`im_apply` (好友申请表)~~ - 无需添加好友流程

### 2.2 表关系图

```
im_message ───┬──> im_conversation (更新会话)
             │
             ├──> im_group (群聊消息)
             │
             └──> system_users (单聊消息,联系人来源)

im_group ────────> im_group_user (群成员)

im_contact_setting ──> system_users (联系人个性化设置)

system_users ──> system_dept (用户所属部门)
```

**说明**:
- 联系人数据直接来源于 `system_users` 表(同租户下的所有用户)
- 部门数据直接来源于 `system_dept` 表
- `im_contact_setting` 仅存储用户对联系人的个性化设置(备注名、星标、免打扰)
- 无需好友申请、拉黑等社交功能

---

## 3. Protobuf 协议定义

### 3.1 协议文件位置

```
shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/proto/im_message.proto
```

### 3.2 消息类型枚举

```protobuf
syntax = "proto3";

option java_package = "com.shengyu.framework.websocket.core.protocol";
option java_outer_classname = "ImMessageProto";
option java_multiple_files = true;

// 消息类型枚举
enum MessageType {
  // 未知类型
  UNKNOWN = 0;
  
  // ========== 系统消息 ==========
  HEARTBEAT_REQ = 1;      // 心跳请求
  HEARTBEAT_RESP = 2;     // 心跳响应
  AUTH_REQ = 3;           // 认证请求
  AUTH_RESP = 4;          // 认证响应
  CLOSE = 5;              // 连接关闭
  
  // ========== 业务消息 ==========
  TEXT = 100;             // 文本消息
  IMAGE = 101;            // 图片消息
  VOICE = 102;            // 语音消息
  VIDEO = 103;            // 视频消息
  FILE = 104;             // 文件消息
  LOCATION = 105;         // 位置消息
  CUSTOM = 106;           // 自定义消息
  
  // ========== 通知消息 ==========
  SYSTEM_NOTIFY = 200;    // 系统通知
  READ_RECEIPT = 201;     // 消息已读回执
  RECALL = 202;           // 消息撤回
  TYPING = 203;           // 正在输入
}
```

### 3.3 消息体定义

```protobuf
// IM 消息协议定义
message ImMessage {
  // 消息头
  MessageHeader header = 1;
  // 消息体(具体消息类型的序列化数据)
  bytes body = 2;
}

// 消息头
message MessageHeader {
  int64 messageId = 1;        // 消息ID(雪花算法生成)
  MessageType messageType = 2; // 消息类型
  int64 senderId = 3;         // 发送者ID
  int64 receiverId = 4;       // 接收者ID(单聊时使用)
  int64 groupId = 5;          // 群组ID(群聊时使用)
  int64 tenantId = 6;         // 租户ID
  int64 timestamp = 7;        // 时间戳(毫秒)
  int64 sequence = 8;         // 序列号(用于消息去重和排序)
  string extra = 9;           // 扩展字段(JSON格式)
}

// 认证请求
message AuthRequest {
  string accessToken = 1;     // 访问令牌
  int32 deviceType = 2;       // 设备类型(1-Web 2-iOS 3-Android 4-小程序)
  string deviceId = 3;        // 设备ID
  string clientVersion = 4;   // 客户端版本
}

// 认证响应
message AuthResponse {
  bool success = 1;           // 是否成功
  int32 code = 2;             // 错误码
  string message = 3;         // 错误消息
  int64 userId = 4;           // 用户ID
  int64 tenantId = 5;         // 租户ID
}

// 文本消息
message TextMessage {
  string content = 1;         // 文本内容
  repeated int64 atUserIds = 2; // @用户列表
}

// 图片消息
message ImageMessage {
  string url = 1;             // 图片URL
  string thumbnailUrl = 2;    // 缩略图URL
  int32 width = 3;            // 宽度
  int32 height = 4;           // 高度
  int64 size = 5;             // 文件大小(字节)
}

// 语音消息
message VoiceMessage {
  string url = 1;             // 语音URL
  int32 duration = 2;         // 时长(秒)
  int64 size = 3;             // 文件大小(字节)
}

// 视频消息
message VideoMessage {
  string url = 1;             // 视频URL
  string coverUrl = 2;        // 封面URL
  int32 duration = 3;         // 时长(秒)
  int32 width = 4;            // 宽度
  int32 height = 5;           // 高度
  int64 size = 6;             // 文件大小(字节)
}

// 文件消息
message FileMessage {
  string url = 1;             // 文件URL
  string fileName = 2;        // 文件名
  int64 size = 3;             // 文件大小(字节)
  string fileType = 4;        // 文件类型
}

// 位置消息
message LocationMessage {
  double latitude = 1;        // 纬度
  double longitude = 2;       // 经度
  string address = 3;         // 地址描述
}

// 消息已读回执
message ReadReceiptMessage {
  repeated int64 messageIds = 1; // 已读的消息ID列表
}

// 消息撤回
message RecallMessage {
  int64 messageId = 1;        // 撤回的消息ID
}
```

### 3.4 编解码流程

#### 3.4.1 编码流程 (发送消息)

```java
// 1. 构建具体消息类型
TextMessage textMessage = TextMessage.newBuilder()
    .setContent("你好")
    .build();

// 2. 构建消息头
MessageHeader header = MessageHeader.newBuilder()
    .setMessageId(generateMessageId())
    .setMessageType(MessageType.TEXT)
    .setSenderId(senderId)
    .setReceiverId(receiverId)
    .setTenantId(tenantId)
    .setTimestamp(System.currentTimeMillis())
    .build();

// 3. 构建 IM 消息
ImMessage message = ImMessage.newBuilder()
    .setHeader(header)
    .setBody(ByteString.copyFrom(textMessage.toByteArray()))
    .build();

// 4. 序列化为字节数组
byte[] bytes = message.toByteArray();

// 5. 通过 WebSocket 发送
channel.writeAndFlush(new BinaryWebSocketFrame(Unpooled.wrappedBuffer(bytes)));
```

#### 3.4.2 解码流程 (接收消息)

```java
// 1. 从 WebSocket 接收字节数组
byte[] bytes = frame.content().array();

// 2. 解析 IM 消息
ImMessage message = ImMessage.parseFrom(bytes);

// 3. 获取消息头
MessageHeader header = message.getHeader();
MessageType messageType = header.getMessageType();

// 4. 根据消息类型解析消息体
if (messageType == MessageType.TEXT) {
    TextMessage textMessage = TextMessage.parseFrom(message.getBody());
    String content = textMessage.getContent();
}
```

### 3.5 Protobuf 优势

| 对比项 | JSON | Protobuf | 优势 |
|-------|------|----------|------|
| 体积 | 100% | 10-30% | 体积小 3-10 倍 |
| 速度 | 100% | 500-10000% | 速度快 20-100 倍 |
| 类型安全 | ❌ | ✅ | 编译时类型检查 |
| 向后兼容 | ❌ | ✅ | 字段可选,易扩展 |
| 可读性 | ✅ | ❌ | 二进制格式 |

**适用场景**:
- ✅ 移动端 APP (节省流量,提升性能)
- ✅ 高并发场景 (降低 CPU 和带宽消耗)
- ✅ 微服务间通信 (RPC 调用)
- ❌ Web 浏览器 (可使用 WebSocket + JSON)

---

## 4. WebSocket 连接流程

### 4.1 连接建立流程

```
移动端                    Netty Server              System Module
  │                            │                          │
  │ 1. 建立 WebSocket 连接     │                          │
  │──────────────────────────>│                          │
  │                            │                          │
  │ 2. 发送认证请求(Protobuf)  │                          │
  │    AuthRequest             │                          │
  │──────────────────────────>│                          │
  │                            │ 3. 调用 AuthService      │
  │                            │    validateToken()       │
  │                            │────────────────────────>│
  │                            │                          │
  │                            │ 4. 验证 token,返回       │
  │                            │    LoginBase 对象        │
  │                            │<────────────────────────│
  │                            │                          │
  │                            │ 5. 创建 NettySession     │
  │                            │    - userId              │
  │                            │    - tenantId            │
  │                            │    - deviceId            │
  │                            │    - deviceType          │
  │                            │    保存到 SessionManager │
  │                            │                          │
  │ 6. 返回认证成功(Protobuf)  │                          │
  │    AuthResponse            │                          │
  │<──────────────────────────│                          │
  │                            │                          │
  │ 7. 开始心跳(30秒一次)      │                          │
  │<─────────────────────────>│                          │
```

### 4.2 认证流程详解

**步骤 1: 移动端发起连接**
```typescript
// uni-app x 代码示例
const ws = uni.connectSocket({
  url: 'wss://api.example.com:9000/ws',
  protocols: ['protobuf']  // 使用 Protobuf 协议
});
```

**步骤 2: 发送认证请求**
```typescript
ws.onOpen(() => {
  // 构建 AuthRequest (Protobuf)
  const authRequest = AuthRequest.encode({
    accessToken: getAccessToken(),
    deviceType: 3,  // Android
    deviceId: getDeviceId(),
    clientVersion: '1.0.0'
  }).finish();
  
  // 构建 ImMessage
  const message = ImMessage.encode({
    header: {
      messageId: Date.now(),
      messageType: MessageType.AUTH_REQ,
      timestamp: Date.now()
    },
    body: authRequest
  }).finish();
  
  ws.send({ data: message.buffer });
});
```

**步骤 3-4: 服务端验证**
```java
// AuthService 实现 (System 模块)
@Service
public class SystemAuthServiceImpl implements AuthService {
    
    @Autowired
    private OAuth2TokenApi oauth2TokenApi;
    
    @Override
    public LoginBase validateToken(String accessToken) {
        // 验证 token 有效性
        OAuth2AccessTokenCheckRespDTO tokenInfo = 
            oauth2TokenApi.checkAccessToken(accessToken);
        
        if (tokenInfo == null || tokenInfo.getExpiresTime().isBefore(LocalDateTime.now())) {
            return null;  // 认证失败
        }
        
        // 返回登录用户信息
        return buildLoginUser(tokenInfo);
    }
    
    @Override
    public Long getTenantId(LoginBase loginUser) {
        if (loginUser instanceof LoginUser) {
            return ((LoginUser) loginUser).getTenantId();
        }
        return null;  // 平台端用户无租户ID
    }
}
```

**步骤 5: 创建并保存 Session**
```java
// NettySession 对象
public class NettySession {
    private Channel channel;           // Netty Channel
    private Long userId;               // 用户ID
    private Long tenantId;             // 租户ID
    private String deviceId;           // 设备ID
    private Integer deviceType;        // 设备类型
    private LocalDateTime loginTime;   // 登录时间
    private LocalDateTime lastActiveTime; // 最后活跃时间
}

// SessionManager 保存会话
sessionManager.addSession(session);
```

**步骤 6: 返回认证成功**
```java
// 构建 AuthResponse
AuthResponse authResponse = AuthResponse.newBuilder()
    .setSuccess(true)
    .setCode(0)
    .setMessage("认证成功")
    .setUserId(userId)
    .setTenantId(tenantId)
    .build();

// 构建 ImMessage
ImMessage message = ImMessage.newBuilder()
    .setHeader(MessageHeader.newBuilder()
        .setMessageId(generateMessageId())
        .setMessageType(MessageType.AUTH_RESP)
        .setTimestamp(System.currentTimeMillis())
        .build())
    .setBody(ByteString.copyFrom(authResponse.toByteArray()))
    .build();

// 发送给客户端
channel.writeAndFlush(message);
```

### 4.3 心跳机制

#### 4.3.1 配置参数

```yaml
shengyu:
  netty:
    reader-idle-time: 60      # 读空闲时间(秒),超时关闭连接
    writer-idle-time: 0       # 写空闲时间(秒),0表示不检测
    all-idle-time: 0          # 读写空闲时间(秒),0表示不检测
```

#### 4.3.2 客户端心跳

```typescript
// 每 30 秒发送一次心跳
setInterval(() => {
  if (ws.readyState === 1) {
    const heartbeat = ImMessage.encode({
      header: {
        messageId: Date.now(),
        messageType: MessageType.HEARTBEAT_REQ,
        timestamp: Date.now()
      }
    }).finish();
    
    ws.send({ data: heartbeat.buffer });
  }
}, 30000);
```

#### 4.3.3 服务端心跳检测

```java
// HeartbeatHandler (中间件实现)
@Component
public class HeartbeatHandler extends ChannelInboundHandlerAdapter {
    
    @Override
    public void userEventTriggered(ChannelHandlerContext ctx, Object evt) {
        if (evt instanceof IdleStateEvent) {
            IdleStateEvent event = (IdleStateEvent) evt;
            if (event.state() == IdleState.READER_IDLE) {
                // 读空闲超时,关闭连接
                log.warn("[Heartbeat] 心跳超时,关闭连接: {}", 
                    ctx.channel().id().asShortText());
                ctx.close();
            }
        }
    }
}
```

### 4.4 断线重连

#### 4.4.1 重连策略

- **指数退避**: 1s, 2s, 4s, 8s, 16s, 30s (最大)
- **最大重连次数**: 5 次
- **重连触发**: 连接关闭、连接错误

#### 4.4.2 客户端实现

```typescript
let reconnectCount = 0;
const maxReconnect = 5;

function reconnect() {
  if (reconnectCount >= maxReconnect) {
    console.error('重连失败,已达最大重连次数');
    uni.showToast({ title: '连接失败,请检查网络', icon: 'none' });
    return;
  }
  
  reconnectCount++;
  const delay = Math.min(1000 * Math.pow(2, reconnectCount), 30000);
  
  console.log(`${delay}ms 后进行第 ${reconnectCount} 次重连...`);
  
  setTimeout(() => {
    connectWebSocket();
  }, delay);
}

ws.onClose(() => {
  console.log('WebSocket 连接关闭');
  reconnect();
});

ws.onError((err) => {
  console.error('WebSocket 连接错误', err);
  reconnect();
});
```

### 4.5 多设备支持

#### 4.5.1 会话管理

```java
// NettySessionManager 支持单用户多设备
public class NettySessionManager {
    
    // User ID -> Channel IDs (支持多设备)
    private final Map<Long, Set<String>> userChannelMap = new ConcurrentHashMap<>();
    
    /**
     * 获取用户的所有会话(所有设备)
     */
    public List<NettySession> getSessionsByUserId(Long userId) {
        Set<String> channelIds = userChannelMap.get(userId);
        if (channelIds == null || channelIds.isEmpty()) {
            return Collections.emptyList();
        }
        
        return channelIds.stream()
            .map(channelSessionMap::get)
            .filter(Objects::nonNull)
            .filter(NettySession::isActive)
            .collect(Collectors.toList());
    }
}
```

#### 4.5.2 消息推送

```java
// 推送消息给用户的所有设备
public void sendToUser(Long userId, MessageType messageType, MessageLite body) {
    List<NettySession> sessions = sessionManager.getSessionsByUserId(userId);
    
    ImMessage message = buildMessage(messageType, body, null, userId, null, null);
    
    for (NettySession session : sessions) {
        if (session.isActive()) {
            session.getChannel().writeAndFlush(message);
        }
    }
}

// 推送消息给指定设备
public void sendToDevice(Long userId, String deviceId, 
                        MessageType messageType, MessageLite body) {
    List<NettySession> sessions = sessionManager.getSessionsByUserId(userId);
    
    for (NettySession session : sessions) {
        if (deviceId.equals(session.getDeviceId()) && session.isActive()) {
            ImMessage message = buildMessage(messageType, body, null, userId, null, null);
            session.getChannel().writeAndFlush(message);
            return;
        }
    }
}
```

---

## 5. 消息收发流程

### 5.1 发送消息流程

```
移动端                    Netty Server              System Module
  │                            │                          │
  │ 1. 用户输入消息并点击发送  │                          │
  │                            │                          │
  │ 2. 通过 WebSocket 发送消息 │                          │
  │──────────────────────────>│                          │
  │                            │                          │
  │                            │ 3. 调用 MessageStorageService.saveMessage()
  │                            │────────────────────────>│
  │                            │                          │
  │                            │                          │ 4. 保存到数据库
  │                            │                          │    (im_message)
  │                            │                          │
  │                            │                          │ 5. 更新会话
  │                            │                          │    (im_conversation)
  │                            │                          │
  │                            │ 6. 返回消息ID和sequence  │
  │                            │<────────────────────────│
  │                            │                          │
  │ 7. 返回 ACK 确认           │                          │
  │<──────────────────────────│                          │
  │                            │                          │
  │                            │ 8. 查找接收者 Session    │
  │                            │                          │
  │                            │ 9. 推送消息给接收者      │
  │                            │──────────────────────────> 接收者
  │                            │                          │
```

### 5.2 接收消息流程

```
发送者                    Netty Server              接收者
  │                            │                          │
  │                            │ 1. 推送消息              │
  │                            │────────────────────────>│
  │                            │                          │
  │                            │ 2. 返回 ACK 确认         │
  │                            │<────────────────────────│
  │                            │                          │
  │                            │                          │ 3. 显示消息
  │                            │                          │
  │                            │                          │ 4. 用户查看消息
  │                            │                          │
  │                            │ 5. 发送已读回执          │
  │                            │<────────────────────────│
  │                            │                          │
  │                            │ 6. 更新消息状态为已读    │
  │                            │────────────────────────> System Module
  │                            │                          │
  │ 7. 推送已读回执给发送者    │                          │
  │<──────────────────────────│                          │
```

### 5.3 消息发送代码示例

**移动端发送消息**:
```typescript
// 发送文本消息
function sendTextMessage(text: string, receiverId: number) {
  const message = {
    type: 'MESSAGE',
    payload: {
      messageType: 100,  // 文本消息
      senderId: getUserId(),
      receiverId: receiverId,
      content: {
        text: text
      },
      timestamp: Date.now(),
      tenantId: getTenantId()
    }
  };
  
  ws.send(JSON.stringify(message));
}
```

**服务端处理消息**:
```java
// MessageProcessor
@Override
public void processMessage(Channel channel, Message message) {
    // 1. 保存消息到数据库
    Long messageId = messageStorageService.saveMessage(message);
    
    // 2. 发送 ACK 给发送者
    MessageAck ack = MessageAck.newBuilder()
        .setMessageId(messageId)
        .setSuccess(true)
        .build();
    channel.writeAndFlush(ack);
    
    // 3. 推送消息给接收者
    if (message.getReceiverId() > 0) {
        // 单聊
        Channel receiverChannel = sessionManager.getChannel(message.getReceiverId());
        if (receiverChannel != null && receiverChannel.isActive()) {
            receiverChannel.writeAndFlush(message);
        }
    } else if (message.getGroupId() > 0) {
        // 群聊
        List<Long> memberIds = groupService.getGroupMemberIds(message.getGroupId());
        for (Long memberId : memberIds) {
            if (!memberId.equals(message.getSenderId())) {
                Channel memberChannel = sessionManager.getChannel(memberId);
                if (memberChannel != null && memberChannel.isActive()) {
                    memberChannel.writeAndFlush(message);
                }
            }
        }
    }
}
```

### 5.4 离线消息处理

**场景**: 接收者不在线时,消息如何处理?

**方案**:
1. 消息已保存到数据库(`im_message`)
2. 会话表(`im_conversation`)的 `unread_count` 已更新
3. 接收者上线后,通过 REST API 拉取离线消息

**拉取离线消息**:
```typescript
// 移动端上线后拉取离线消息
async function fetchOfflineMessages() {
  const response = await request({
    url: '/system/im/conversation/list',
    method: 'GET'
  });
  
  // 遍历会话,拉取未读消息
  for (const conversation of response.data) {
    if (conversation.unreadCount > 0) {
      await fetchConversationMessages(conversation.id);
    }
  }
}
```

---

## 6. 移动端页面交互逻辑

### 6.0 移动端技术栈与目录结构

**技术栈**:
- uni-app x (跨平台框架)
- UTS (TypeScript 语法)
- uvue (类 Vue 3 语法)

**核心目录结构**:
```
shengyu-ui-admin-uniappx/
├── pages/
│   ├── message/          # 消息模块
│   │   ├── index.uvue    # 消息列表页
│   │   └── chat.uvue     # 聊天页面
│   ├── contacts/         # 通讯录模块
│   │   ├── index.uvue    # 通讯录首页
│   │   ├── list.uvue     # 联系人列表
│   │   └── detail.uvue   # 联系人详情
│   └── profile/          # 个人中心
├── components/           # 公共组件
├── store/                # 状态管理
│   ├── user.uts          # 用户状态
│   └── locale.uts        # 国际化
├── utils/                # 工具函数
│   ├── request.uts       # HTTP 请求
│   ├── emojiParser.uts   # 表情解析
│   └── upload.uts        # 文件上传
└── api/                  # API 接口
    └── login.uts         # 登录接口
```

### 6.1 消息列表页 (message/index.uvue)

**功能**:
- 显示所有会话列表
- 置顶会话显示在最上方
- 显示未读消息数量
- 支持左滑删除会话
- 支持下拉刷新

**交互流程**:
```
1. 页面加载
   ├─> 调用 GET /system/im/conversation/list
   ├─> 渲染会话列表
   └─> 建立 WebSocket 连接

2. 接收新消息(WebSocket)
   ├─> 更新对应会话的最后消息
   ├─> 未读数 +1
   └─> 会话移到列表顶部(如果未置顶)

3. 点击会话
   └─> 跳转到聊天页面 chat.uvue

4. 左滑会话
   ├─> 显示"删除"按钮
   └─> 点击删除 -> 调用 DELETE /system/im/conversation/{id}
```

**数据结构**:
```typescript
interface Conversation {
  id: number;
  targetId: number;
  conversationType: number;  // 1-单聊 2-群聊
  unreadCount: number;
  lastMessageContent: string;
  lastMessageTime: string;
  isPinned: boolean;
  noDisturb: boolean;
  // 扩展字段
  targetName: string;        // 对方名称或群名
  targetAvatar: string;      // 对方头像或群头像
}
```

### 6.2 聊天页面 (message/chat.uvue)

**功能**:
- 显示聊天消息列表
- 支持多种消息类型(文本、图片、语音、视频、文件)
- 支持表情输入(109个微信表情)
- 支持语音输入
- 支持图片/视频/文件发送
- 消息长按菜单(复制、删除、撤回、转发)
- 多选模式(批量删除、转发)
- 全屏输入模式

**交互流程**:
```
1. 页面加载
   ├─> 调用 GET /system/im/message/list?conversationId={id}&pageSize=20
   ├─> 渲染消息列表
   └─> 滚动到最底部

2. 发送文本消息
   ├─> 用户输入文本
   ├─> 点击发送按钮
   ├─> 通过 WebSocket 发送消息
   ├─> 收到 ACK 确认
   └─> 消息显示为"已发送"

3. 发送图片消息
   ├─> 点击图片按钮
   ├─> 选择图片
   ├─> 调用 POST /infra/file/upload 上传图片
   ├─> 获取图片 URL
   ├─> 通过 WebSocket 发送图片消息
   └─> 显示图片消息

4. 接收消息(WebSocket)
   ├─> 收到新消息
   ├─> 插入到消息列表
   ├─> 滚动到最底部
   └─> 发送已读回执

5. 消息长按
   ├─> 显示操作菜单
   ├─> 复制: 复制文本到剪贴板
   ├─> 删除: 调用 DELETE /system/im/message/{id}
   ├─> 撤回: 调用 POST /system/im/message/recall/{id}
   └─> 转发: 进入联系人选择页面
```

**表情系统**:
- 109个微信表情
- 表情面板显示
- 表情解析与渲染
- 表情代码: `[微笑]`, `[撇嘴]` 等

### 6.3 通讯录页面 (contacts/index.uvue)

**功能**:
- 显示企业内所有联系人(来自 system_users)
- 按部门分组显示
- 字母索引快速定位
- 搜索联系人
- 星标联系人置顶

**交互流程**:
```
1. 页面加载
   ├─> 调用 GET /system/im/contact/list
   ├─> 获取联系人列表(包含部门信息)
   ├─> 按部门分组
   └─> 渲染列表

2. 搜索联系人
   ├─> 输入关键词
   ├─> 调用 GET /system/im/contact/search?keyword={keyword}
   └─> 显示搜索结果

3. 点击联系人
   └─> 跳转到联系人详情页 contacts/detail.uvue

4. 点击部门
   └─> 展开/收起部门成员列表
```

**数据结构**:
```typescript
interface Contact {
  id: number;
  username: string;
  nickname: string;
  avatar: string;
  deptId: number;
  deptName: string;
  // 个性化设置
  remarkName: string;    // 备注名
  star: boolean;         // 是否星标
  noDisturb: boolean;    // 是否免打扰
}

interface Department {
  id: number;
  name: string;
  parentId: number;
  contacts: Contact[];
}
```

**说明**:
- 联系人数据直接来源于 `system_users` 表(同租户)
- 部门数据直接来源于 `system_dept` 表
- 无需添加好友流程
- 个性化设置(备注名、星标)存储在 `im_contact_setting` 表

### 6.4 联系人详情页 (contacts/detail.uvue)

**功能**:
- 显示联系人基本信息
- 设置备注名
- 设置星标联系人
- 设置免打扰
- 发起单聊

**交互流程**:
```
1. 页面加载
   ├─> 调用 GET /system/im/contact/{id}
   └─> 显示联系人信息

2. 设置备注名
   ├─> 点击"设置备注名"
   ├─> 输入备注名
   ├─> 调用 PUT /system/im/contact/setting
   └─> 更新成功

3. 设置星标
   ├─> 点击"星标联系人"开关
   ├─> 调用 PUT /system/im/contact/setting
   └─> 更新成功

4. 发起单聊
   ├─> 点击"发消息"按钮
   ├─> 调用 POST /system/im/conversation/create
   └─> 跳转到聊天页面
```

### 6.5 发起群聊页面 (message/create-group.uvue)

**功能**:
- 选择群成员(多选)
- 设置群名称
- 创建群聊

**交互流程**:
```
1. 页面加载
   ├─> 调用 GET /system/im/contact/list
   └─> 显示联系人列表(支持多选)

2. 选择成员
   ├─> 勾选联系人
   └─> 显示已选成员数量

3. 创建群聊
   ├─> 点击"完成"按钮
   ├─> 输入群名称(可选)
   ├─> 调用 POST /system/im/group/create
   │   {
   │     "name": "群名称",
   │     "memberIds": [1, 2, 3]
   │   }
   ├─> 创建成功,返回群ID
   └─> 跳转到群聊页面
```

### 6.6 群聊详情页 (message/group-detail.uvue)

**功能**:
- 显示群信息(群名、群公告)
- 显示群成员列表
- 添加/移除群成员
- 设置群名称
- 设置群公告
- 退出群聊
- 解散群聊(群主)

**交互流程**:
```
1. 页面加载
   ├─> 调用 GET /system/im/group/{id}
   └─> 显示群信息和成员列表

2. 添加群成员
   ├─> 点击"添加成员"
   ├─> 选择联系人
   ├─> 调用 POST /system/im/group/member/add
   └─> 刷新成员列表

3. 移除群成员(群主/管理员)
   ├─> 点击成员头像
   ├─> 点击"移除"
   ├─> 调用 DELETE /system/im/group/member/{userId}
   └─> 刷新成员列表

4. 设置群名称
   ├─> 点击"群名称"
   ├─> 输入新群名
   ├─> 调用 PUT /system/im/group/{id}
   └─> 更新成功

5. 退出群聊
   ├─> 点击"退出群聊"
   ├─> 确认对话框
   ├─> 调用 POST /system/im/group/quit/{id}
   └─> 返回消息列表

6. 解散群聊(群主)
   ├─> 点击"解散群聊"
   ├─> 确认对话框
   ├─> 调用 DELETE /system/im/group/{id}
   └─> 返回消息列表
```

---

## 7. 后端 API 接口设计

### 7.1 会话管理接口

#### 7.1.1 获取会话列表

```
GET /system/im/conversation/list

请求参数: 无

响应:
{
  "code": 0,
  "data": [
    {
      "id": 1,
      "targetId": 100,
      "conversationType": 1,
      "unreadCount": 5,
      "lastMessageContent": "你好",
      "lastMessageTime": "2026-02-11 10:30:00",
      "isPinned": false,
      "noDisturb": false,
      "targetName": "张三",
      "targetAvatar": "https://..."
    }
  ]
}
```

#### 7.1.2 创建会话

```
POST /system/im/conversation/create

请求体:
{
  "targetId": 100,
  "conversationType": 1  // 1-单聊 2-群聊
}

响应:
{
  "code": 0,
  "data": {
    "id": 1,
    "targetId": 100,
    "conversationType": 1
  }
}
```

#### 7.1.3 删除会话

```
DELETE /system/im/conversation/{id}

响应:
{
  "code": 0,
  "msg": "删除成功"
}
```

#### 7.1.4 置顶会话

```
PUT /system/im/conversation/pin/{id}

请求体:
{
  "pinned": true
}

响应:
{
  "code": 0,
  "msg": "操作成功"
}
```

#### 7.1.5 设置免打扰

```
PUT /system/im/conversation/no-disturb/{id}

请求体:
{
  "noDisturb": true
}

响应:
{
  "code": 0,
  "msg": "操作成功"
}
```

### 7.2 消息管理接口

#### 7.2.1 获取消息列表

```
GET /system/im/message/list

请求参数:
- conversationId: 会话ID
- lastMessageId: 最后一条消息ID(用于分页)
- pageSize: 每页数量(默认20)

响应:
{
  "code": 0,
  "data": {
    "list": [
      {
        "id": 1,
        "messageType": 100,
        "senderId": 1,
        "receiverId": 2,
        "content": "{\"text\":\"你好\"}",
        "status": 1,
        "createTime": "2026-02-11 10:30:00"
      }
    ],
    "hasMore": true
  }
}
```

#### 7.2.2 撤回消息

```
POST /system/im/message/recall/{id}

响应:
{
  "code": 0,
  "msg": "撤回成功"
}

说明: 只能撤回2分钟内的消息
```

#### 7.2.3 删除消息

```
DELETE /system/im/message/{id}

响应:
{
  "code": 0,
  "msg": "删除成功"
}

说明: 仅删除本地记录,不影响对方
```

#### 7.2.4 标记消息已读

```
POST /system/im/message/read

请求体:
{
  "conversationId": 1,
  "lastReadMessageId": 100
}

响应:
{
  "code": 0,
  "msg": "操作成功"
}
```

### 7.3 联系人管理接口

#### 7.3.1 获取联系人列表

```
GET /system/im/contact/list

请求参数: 无

响应:
{
  "code": 0,
  "data": [
    {
      "id": 1,
      "username": "zhangsan",
      "nickname": "张三",
      "avatar": "https://...",
      "deptId": 10,
      "deptName": "技术部",
      "remarkName": "老张",
      "star": true,
      "noDisturb": false
    }
  ]
}

说明: 
- 联系人数据来源于 system_users 表(同租户)
- 部门信息来源于 system_dept 表
- remarkName/star/noDisturb 来源于 im_contact_setting 表
```

#### 7.3.2 搜索联系人

```
GET /system/im/contact/search

请求参数:
- keyword: 搜索关键词(姓名/用户名)

响应:
{
  "code": 0,
  "data": [
    {
      "id": 1,
      "username": "zhangsan",
      "nickname": "张三",
      "avatar": "https://...",
      "deptName": "技术部"
    }
  ]
}
```

#### 7.3.3 获取联系人详情

```
GET /system/im/contact/{id}

响应:
{
  "code": 0,
  "data": {
    "id": 1,
    "username": "zhangsan",
    "nickname": "张三",
    "avatar": "https://...",
    "mobile": "13800138000",
    "email": "zhangsan@example.com",
    "deptName": "技术部",
    "remarkName": "老张",
    "star": true,
    "noDisturb": false
  }
}
```

#### 7.3.4 更新联系人设置

```
PUT /system/im/contact/setting

请求体:
{
  "contactId": 1,
  "remarkName": "老张",
  "star": true,
  "noDisturb": false
}

响应:
{
  "code": 0,
  "msg": "操作成功"
}

说明: 更新 im_contact_setting 表
```

### 7.4 群组管理接口

#### 7.4.1 创建群组

```
POST /system/im/group/create

请求体:
{
  "name": "技术交流群",
  "memberIds": [1, 2, 3, 4]
}

响应:
{
  "code": 0,
  "data": {
    "id": 1,
    "name": "技术交流群",
    "avatar": "https://...",
    "memberCount": 4
  }
}
```

#### 7.4.2 获取群组详情

```
GET /system/im/group/{id}

响应:
{
  "code": 0,
  "data": {
    "id": 1,
    "name": "技术交流群",
    "avatar": "https://...",
    "ownerId": 1,
    "remark": "群公告内容",
    "memberCount": 10,
    "members": [
      {
        "userId": 1,
        "nickname": "张三",
        "avatar": "https://...",
        "role": 2  // 0-普通成员 1-管理员 2-群主
      }
    ]
  }
}
```

#### 7.4.3 更新群组信息

```
PUT /system/im/group/{id}

请求体:
{
  "name": "新群名",
  "remark": "新公告"
}

响应:
{
  "code": 0,
  "msg": "更新成功"
}
```

#### 7.4.4 添加群成员

```
POST /system/im/group/member/add

请求体:
{
  "groupId": 1,
  "memberIds": [5, 6]
}

响应:
{
  "code": 0,
  "msg": "添加成功"
}
```

#### 7.4.5 移除群成员

```
DELETE /system/im/group/member/{userId}

请求参数:
- groupId: 群组ID

响应:
{
  "code": 0,
  "msg": "移除成功"
}
```

#### 7.4.6 退出群组

```
POST /system/im/group/quit/{id}

响应:
{
  "code": 0,
  "msg": "退出成功"
}
```

#### 7.4.7 解散群组

```
DELETE /system/im/group/{id}

响应:
{
  "code": 0,
  "msg": "解散成功"
}

说明: 仅群主可操作
```

---

## 8. System 模块与中间件交互

### 8.1 SPI 接口实现

WebSocket 中间件定义了 SPI 接口,System 模块需要实现这些接口。

#### 8.1.1 MessageStorageService 实现 (必须)

```java
package com.shengyu.module.system.service.im;

import com.shengyu.framework.websocket.core.protocol.ImMessage;
import com.shengyu.framework.websocket.core.protocol.MessageHeader;
import com.shengyu.framework.websocket.core.service.MessageStorageService;
import com.shengyu.module.system.dal.dataobject.im.ImMessageDO;
import com.shengyu.module.system.dal.mysql.im.ImMessageMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 消息存储服务实现
 * 
 * 说明:
 * 1. 中间件在接收到消息后会调用 saveMessage 方法
 * 2. 业务模块负责将消息持久化到数据库
 * 3. 可以在此方法中实现额外的业务逻辑(如更新会话、推送通知等)
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class SystemMessageStorageServiceImpl implements MessageStorageService {

    private final ImMessageMapper messageMapper;
    private final ImConversationService conversationService;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void saveMessage(ImMessage message) {
        log.info("[MessageStorage] 保存消息: messageId={}, type={}", 
            message.getHeader().getMessageId(), 
            message.getHeader().getMessageType());

        // 1. 转换为 DO 对象
        ImMessageDO messageDO = convertToDO(message);
        
        // 2. 保存到数据库
        messageMapper.insert(messageDO);
        
        // 3. 更新会话
        conversationService.updateConversationByMessage(messageDO);
        
        log.info("[MessageStorage] 消息保存成功: id={}", messageDO.getId());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long saveMessageWithId(ImMessage message) {
        saveMessage(message);
        
        // 返回数据库生成的消息ID
        MessageHeader header = message.getHeader();
        ImMessageDO messageDO = messageMapper.selectByMessageId(header.getMessageId());
        return messageDO != null ? messageDO.getId() : null;
    }

    /**
     * 转换为 DO 对象
     */
    private ImMessageDO convertToDO(ImMessage message) {
        MessageHeader header = message.getHeader();
        
        return ImMessageDO.builder()
            .messageId(header.getMessageId())
            .messageType(header.getMessageType().getNumber())
            .senderId(header.getSenderId())
            .receiverId(header.getReceiverId())
            .groupId(header.getGroupId())
            .content(message.getBody().toByteArray())  // Protobuf 字节数组
            .extra(header.getExtra())
            .status(0)  // 未读
            .sequence(header.getSequence())
            .build();
    }
}
```

#### 8.1.2 AuthService 实现 (必须)

```java
package com.shengyu.module.system.service.im;

import com.shengyu.framework.security.core.LoginUser;
import com.shengyu.framework.security.core.PlatformLoginUser;
import com.shengyu.framework.security.core.util.LoginBase;
import com.shengyu.framework.websocket.core.service.AuthService;
import com.shengyu.module.system.api.oauth2.OAuth2TokenApi;
import com.shengyu.module.system.api.oauth2.dto.OAuth2AccessTokenCheckRespDTO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

/**
 * 认证服务实现
 * 
 * 说明:
 * 1. 支持租户端(LoginUser)和平台端(PlatformLoginUser)双端认证
 * 2. 验证 Token 有效性和过期时间
 * 3. 返回登录用户信息
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class SystemAuthServiceImpl implements AuthService {

    private final OAuth2TokenApi oauth2TokenApi;

    @Override
    public LoginBase validateToken(String accessToken) {
        log.info("[Auth] 验证 Token: {}", accessToken);

        try {
            // 1. 验证 token
            OAuth2AccessTokenCheckRespDTO tokenInfo = 
                oauth2TokenApi.checkAccessToken(accessToken);
            
            if (tokenInfo == null) {
                log.warn("[Auth] Token 无效");
                return null;
            }

            // 2. 检查 token 是否过期
            if (tokenInfo.getExpiresTime().isBefore(LocalDateTime.now())) {
                log.warn("[Auth] Token 已过期");
                return null;
            }

            // 3. 构建登录用户信息
            LoginBase loginUser = buildLoginUser(tokenInfo);
            
            log.info("[Auth] 认证成功: userId={}, tenantId={}", 
                tokenInfo.getUserId(), getTenantId(loginUser));
            
            return loginUser;

        } catch (Exception e) {
            log.error("[Auth] 认证异常", e);
            return null;
        }
    }

    @Override
    public Long getTenantId(LoginBase loginUser) {
        if (loginUser instanceof LoginUser) {
            return ((LoginUser) loginUser).getTenantId();
        }
        return null;  // 平台端用户无租户ID
    }

    /**
     * 构建登录用户信息
     */
    private LoginBase buildLoginUser(OAuth2AccessTokenCheckRespDTO tokenInfo) {
        // 根据用户类型构建不同的登录对象
        if (tokenInfo.getUserType() == 1) {
            // 租户端用户
            LoginUser loginUser = new LoginUser();
            loginUser.setId(tokenInfo.getUserId());
            loginUser.setTenantId(tokenInfo.getTenantId());
            loginUser.setUserType(tokenInfo.getUserType());
            return loginUser;
        } else {
            // 平台端用户
            PlatformLoginUser loginUser = new PlatformLoginUser();
            loginUser.setId(tokenInfo.getUserId());
            loginUser.setUserType(tokenInfo.getUserType());
            return loginUser;
        }
    }
}
```

#### 8.1.3 MessageCacheService 实现 (可选)

```java
package com.shengyu.module.system.service.im;

import com.shengyu.framework.redis.core.RedisKeyConstants;
import com.shengyu.framework.websocket.core.service.MessageCacheService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.util.concurrent.TimeUnit;

/**
 * 消息缓存服务实现
 * 
 * 说明:
 * 1. 使用 Redis 缓存未读消息数
 * 2. 提高查询性能,减少数据库压力
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class SystemMessageCacheServiceImpl implements MessageCacheService {

    private final RedisTemplate<String, Object> redisTemplate;

    @Override
    public void cacheUnreadCount(Long userId, long count) {
        String key = RedisKeyConstants.IM_UNREAD_COUNT + userId;
        redisTemplate.opsForValue().set(key, count, 24, TimeUnit.HOURS);
    }

    @Override
    public Long getCachedUnreadCount(Long userId) {
        String key = RedisKeyConstants.IM_UNREAD_COUNT + userId;
        Object value = redisTemplate.opsForValue().get(key);
        return value != null ? Long.parseLong(value.toString()) : null;
    }

    @Override
    public long incrementUnreadCount(Long userId, long delta) {
        String key = RedisKeyConstants.IM_UNREAD_COUNT + userId;
        Long result = redisTemplate.opsForValue().increment(key, delta);
        redisTemplate.expire(key, 24, TimeUnit.HOURS);
        return result != null ? result : 0;
    }
}
```

#### 8.1.4 OfflinePushService 实现 (可选)

```java
package com.shengyu.module.system.service.im;

import com.shengyu.framework.websocket.core.service.OfflinePushService;
import com.shengyu.module.system.dal.dataobject.im.ImMessageDO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

/**
 * 离线推送服务实现
 * 
 * 说明:
 * 1. 用户离线时推送消息通知
 * 2. 可集成第三方推送服务(极光推送、个推等)
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class SystemOfflinePushServiceImpl implements OfflinePushService {

    @Override
    public boolean pushOfflineMessage(Long userId, ImMessageDO message) {
        log.info("[OfflinePush] 推送离线消息: userId={}, messageId={}", 
            userId, message.getId());
        
        // TODO: 集成第三方推送服务
        // 1. 构建推送内容
        // 2. 调用推送 API
        // 3. 返回推送结果
        
        return true;
    }

    @Override
    public boolean pushUnreadCount(Long userId, long count) {
        log.info("[OfflinePush] 推送未读数: userId={}, count={}", userId, count);
        
        // TODO: 推送未读消息数角标
        
        return true;
    }
}
```

### 8.2 Spring Bean 配置

```java
package com.shengyu.module.system.config;

import com.shengyu.framework.websocket.core.service.AuthService;
import com.shengyu.framework.websocket.core.service.MessageCacheService;
import com.shengyu.framework.websocket.core.service.MessageStorageService;
import com.shengyu.framework.websocket.core.service.OfflinePushService;
import com.shengyu.module.system.service.im.*;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * IM WebSocket 配置
 * 
 * 说明:
 * 1. 注册 SPI 接口实现类为 Spring Bean
 * 2. 中间件会自动注入这些 Bean
 */
@Configuration
public class ImWebSocketConfig {

    /**
     * 消息存储服务 (必须)
     */
    @Bean
    public MessageStorageService messageStorageService(
            ImMessageMapper messageMapper,
            ImConversationService conversationService) {
        return new SystemMessageStorageServiceImpl(messageMapper, conversationService);
    }

    /**
     * 认证服务 (必须)
     */
    @Bean
    public AuthService authService(OAuth2TokenApi oauth2TokenApi) {
        return new SystemAuthServiceImpl(oauth2TokenApi);
    }

    /**
     * 消息缓存服务 (可选)
     */
    @Bean
    @ConditionalOnMissingBean
    public MessageCacheService messageCacheService(RedisTemplate<String, Object> redisTemplate) {
        return new SystemMessageCacheServiceImpl(redisTemplate);
    }

    /**
     * 离线推送服务 (可选)
     */
    @Bean
    @ConditionalOnMissingBean
    public OfflinePushService offlinePushService() {
        return new SystemOfflinePushServiceImpl();
    }
}
```

### 8.3 消息流转流程

```
1. 客户端发送消息 (Protobuf)
   ↓
2. Netty Server 接收消息
   ↓
3. ProtobufMessageHandler 解码消息
   ↓
4. MessageProcessorFactory 获取对应的处理器
   ↓
5. MessageProcessor 处理消息
   ├─> 5.1 调用 MessageStorageService.saveMessage()
   │        ↓
   │        SystemMessageStorageServiceImpl 实现
   │        ├─> 保存到 im_message 表
   │        ├─> 更新 im_conversation 表
   │        └─> 返回
   │
   ├─> 5.2 查找接收者 Session
   │        ↓
   │        NettySessionManager.getSessionsByUserId()
   │
   └─> 5.3 推送消息给接收者
            ↓
            单聊: 推送给 receiverId 的所有设备
            群聊: 推送给所有群成员(排除发送者)
            ↓
            Channel.writeAndFlush(message)
```

### 8.4 会话更新逻辑

```java
@Service
@RequiredArgsConstructor
public class ImConversationServiceImpl implements ImConversationService {

    private final ImConversationMapper conversationMapper;
    private final ImGroupUserMapper groupUserMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateConversationByMessage(ImMessageDO message) {
        // 1. 更新发送者的会话
        updateUserConversation(
            message.getSenderId(),
            message.getReceiverId() > 0 ? message.getReceiverId() : message.getGroupId(),
            message.getReceiverId() > 0 ? 1 : 2,
            message,
            false  // 发送者不增加未读数
        );
        
        // 2. 更新接收者的会话
        if (message.getReceiverId() > 0) {
            // 单聊
            updateUserConversation(
                message.getReceiverId(),
                message.getSenderId(),
                1,
                message,
                true  // 接收者增加未读数
            );
        } else if (message.getGroupId() > 0) {
            // 群聊: 更新所有群成员的会话
            List<Long> memberIds = groupUserMapper.selectUserIdsByGroupId(message.getGroupId());
            for (Long memberId : memberIds) {
                if (!memberId.equals(message.getSenderId())) {
                    updateUserConversation(
                        memberId,
                        message.getGroupId(),
                        2,
                        message,
                        true  // 群成员增加未读数
                    );
                }
            }
        }
    }

    private void updateUserConversation(Long userId, Long targetId, 
                                       int type, ImMessageDO message, 
                                       boolean incrementUnread) {
        ImConversationDO conversation = conversationMapper.selectOne(userId, targetId, type);
        
        if (conversation == null) {
            // 创建新会话
            conversation = ImConversationDO.builder()
                .userId(userId)
                .targetId(targetId)
                .conversationType(type)
                .unreadCount(incrementUnread ? 1 : 0)
                .lastMessageId(message.getId())
                .lastMessageContent(getMessageSummary(message))
                .lastMessageTime(message.getCreateTime())
                .build();
            conversationMapper.insert(conversation);
        } else {
            // 更新会话
            ImConversationDO updateObj = new ImConversationDO();
            updateObj.setId(conversation.getId());
            if (incrementUnread) {
                updateObj.setUnreadCount(conversation.getUnreadCount() + 1);
            }
            updateObj.setLastMessageId(message.getId());
            updateObj.setLastMessageContent(getMessageSummary(message));
            updateObj.setLastMessageTime(message.getCreateTime());
            conversationMapper.updateById(updateObj);
        }
    }

    private String getMessageSummary(ImMessageDO message) {
        // 根据消息类型返回摘要
        switch (message.getMessageType()) {
            case 100: return "[文本]";
            case 101: return "[图片]";
            case 102: return "[语音]";
            case 103: return "[视频]";
            case 104: return "[文件]";
            case 105: return "[位置]";
            default: return "[消息]";
        }
    }
}
```

---

## 9. 缓存设计

### 9.1 缓存策略

| 数据类型 | 缓存Key | 过期时间 | 说明 |
|---------|---------|---------|------|
| 用户Session | 内存(ConcurrentHashMap) | 永久 | 用户在线状态,断开连接时删除 |
| 会话列表 | `im:conversation:list:{userId}` | 5分钟 | 用户的会话列表 |
| 群成员列表 | `im:group:members:{groupId}` | 10分钟 | 群组成员ID列表 |
| 用户信息 | `im:user:{userId}` | 30分钟 | 用户基本信息 |
| 未读消息数 | `im:unread:{userId}` | 24小时 | 用户总未读数 |

### 9.2 会话管理缓存 (内存)

```java
/**
 * NettySessionManager 使用内存缓存
 * 优势: 高性能,无网络开销
 * 劣势: 单机模式,不支持分布式
 */
@Component
public class NettySessionManager {

    // Channel ID -> Session (快速查找会话)
    private final Map<String, NettySession> channelSessionMap = new ConcurrentHashMap<>();

    // User ID -> Channel IDs (支持多设备)
    private final Map<Long, Set<String>> userChannelMap = new ConcurrentHashMap<>();

    // Tenant ID -> Channel IDs (租户隔离)
    private final Map<Long, Set<String>> tenantChannelMap = new ConcurrentHashMap<>();
}
```

### 9.3 分布式会话管理 (Redis)

```yaml
# 配置消息总线为 Redis
shengyu:
  websocket:
    sender-type: redis
    sender-redis:
      channel: im-message-channel
```

```java
/**
 * Redis 消息总线
 * 优势: 支持分布式部署,多台服务器共享会话状态
 * 实现: 通过 Redis Pub/Sub 实现跨服务器消息推送
 */
@Service
public class RedisWebSocketMessageSender extends AbstractWebSocketMessageSender {

    private final RedisMQTemplate redisMQTemplate;

    @Override
    public void send(String sessionId, Object message) {
        // 1. 尝试本地推送
        if (sendToLocalSession(sessionId, message)) {
            return;
        }

        // 2. 本地没有会话,通过 Redis 广播给其他服务器
        redisMQTemplate.send(
            "im-message-channel",
            new WebSocketMessage(sessionId, message)
        );
    }

    @Override
    public void broadcast(Object message) {
        // 1. 推送给本地所有会话
        broadcastToLocalSessions(message);

        // 2. 通过 Redis 广播给其他服务器
        redisMQTemplate.send(
            "im-message-channel",
            new WebSocketMessage(null, message)
        );
    }
}
```

### 9.4 业务数据缓存 (Redis)

```java
@Service
@RequiredArgsConstructor
public class ImCacheService {

    private final RedisTemplate<String, Object> redisTemplate;

    /**
     * 缓存会话列表
     */
    public void cacheConversationList(Long userId, List<ConversationVO> list) {
        String key = "im:conversation:list:" + userId;
        redisTemplate.opsForValue().set(key, list, 5, TimeUnit.MINUTES);
    }

    /**
     * 获取会话列表
     */
    public List<ConversationVO> getConversationList(Long userId) {
        String key = "im:conversation:list:" + userId;
        return (List<ConversationVO>) redisTemplate.opsForValue().get(key);
    }

    /**
     * 缓存群成员列表
     */
    public void cacheGroupMembers(Long groupId, List<Long> memberIds) {
        String key = "im:group:members:" + groupId;
        redisTemplate.opsForValue().set(key, memberIds, 10, TimeUnit.MINUTES);
    }

    /**
     * 获取群成员列表
     */
    public List<Long> getGroupMembers(Long groupId) {
        String key = "im:group:members:" + groupId;
        return (List<Long>) redisTemplate.opsForValue().get(key);
    }

    /**
     * 增加未读消息数
     */
    public void incrUnreadCount(Long userId) {
        String key = "im:unread:" + userId;
        redisTemplate.opsForValue().increment(key);
        redisTemplate.expire(key, 24, TimeUnit.HOURS);
    }

    /**
     * 清空未读消息数
     */
    public void clearUnreadCount(Long userId) {
        String key = "im:unread:" + userId;
        redisTemplate.delete(key);
    }
}
```

### 9.5 缓存更新策略

#### 9.5.1 会话列表缓存

```java
// 新消息到达时,删除缓存
public void onNewMessage(ImMessageDO message) {
    // 1. 保存消息
    messageMapper.insert(message);
    
    // 2. 更新会话
    conversationService.updateConversation(message);
    
    // 3. 删除缓存
    String key = "im:conversation:list:" + message.getReceiverId();
    redisTemplate.delete(key);
}

// 下次查询时重新加载
public List<ConversationVO> getConversationList(Long userId) {
    // 1. 尝试从缓存获取
    List<ConversationVO> list = cacheService.getConversationList(userId);
    if (list != null) {
        return list;
    }
    
    // 2. 从数据库查询
    list = conversationMapper.selectListByUserId(userId);
    
    // 3. 写入缓存
    cacheService.cacheConversationList(userId, list);
    
    return list;
}
```

#### 9.5.2 群成员列表缓存

```java
// 添加/移除成员时,删除缓存
public void addGroupMember(Long groupId, Long userId) {
    // 1. 添加成员
    groupUserMapper.insert(new ImGroupUserDO(groupId, userId));
    
    // 2. 删除缓存
    String key = "im:group:members:" + groupId;
    redisTemplate.delete(key);
}

// 下次查询时重新加载
public List<Long> getGroupMemberIds(Long groupId) {
    // 1. 尝试从缓存获取
    List<Long> memberIds = cacheService.getGroupMembers(groupId);
    if (memberIds != null) {
        return memberIds;
    }
    
    // 2. 从数据库查询
    memberIds = groupUserMapper.selectUserIdsByGroupId(groupId);
    
    // 3. 写入缓存
    cacheService.cacheGroupMembers(groupId, memberIds);
    
    return memberIds;
}
```

---

## 10. 性能优化

### 10.1 Netty 性能优化

#### 10.1.1 Epoll 优化 (Linux 环境)

```yaml
shengyu:
  netty:
    use-epoll: true  # Linux 环境下自动启用 Epoll
```

```java
// NettyServer 自动检测并启用 Epoll
boolean useEpoll = nettyProperties.getUseEpoll() && Epoll.isAvailable();

if (useEpoll) {
    log.info("[Netty Server] 使用 Epoll 模式");
    bossGroup = new EpollEventLoopGroup(bossThreads);
    workerGroup = new EpollEventLoopGroup(workerThreads);
    channelClass = EpollServerSocketChannel.class;
} else {
    log.info("[Netty Server] 使用 NIO 模式");
    bossGroup = new NioEventLoopGroup(bossThreads);
    workerGroup = new NioEventLoopGroup(workerThreads);
    channelClass = NioServerSocketChannel.class;
}
```

**性能提升**:
- Epoll 比 NIO 性能提升 30%+
- 更低的 CPU 占用
- 更高的并发连接数

#### 10.1.2 TCP 参数优化

```yaml
shengyu:
  netty:
    so-backlog: 2048              # TCP 连接队列大小
    so-rcvbuf: 131072             # TCP 接收缓冲区 (128KB)
    so-sndbuf: 131072             # TCP 发送缓冲区 (128KB)
    write-buffer-low-water-mark: 32768   # 写缓冲区低水位线 (32KB)
    write-buffer-high-water-mark: 65536  # 写缓冲区高水位线 (64KB)
```

```java
ServerBootstrap bootstrap = new ServerBootstrap();
bootstrap.group(bossGroup, workerGroup)
    .channel(channelClass)
    // TCP 参数优化
    .option(ChannelOption.SO_BACKLOG, nettyProperties.getSoBacklog())
    .option(ChannelOption.SO_REUSEADDR, true)
    .childOption(ChannelOption.TCP_NODELAY, true)  // 禁用 Nagle 算法
    .childOption(ChannelOption.SO_KEEPALIVE, true) // 启用 TCP KeepAlive
    .childOption(ChannelOption.SO_RCVBUF, nettyProperties.getSoRcvbuf())
    .childOption(ChannelOption.SO_SNDBUF, nettyProperties.getSoSndbuf())
    // 写缓冲区水位线设置 (防止内存溢出)
    .childOption(ChannelOption.WRITE_BUFFER_WATER_MARK, 
        new WriteBufferWaterMark(
            nettyProperties.getWriteBufferLowWaterMark(),
            nettyProperties.getWriteBufferHighWaterMark()
        ));
```

#### 10.1.3 线程池优化

```yaml
shengyu:
  netty:
    boss-threads: 1               # Boss 线程数 (接收连接)
    worker-threads: 32            # Worker 线程数 (建议 CPU 核心数 * 2)
```

```java
// 使用自定义线程工厂,便于监控和调试
bossGroup = new NioEventLoopGroup(
    nettyProperties.getBossThreads(),
    new DefaultThreadFactory("netty-boss")
);

workerGroup = new NioEventLoopGroup(
    nettyProperties.getWorkerThreads(),
    new DefaultThreadFactory("netty-worker")
);
```

**线程数配置建议**:
- Boss 线程: 1 个即可 (只负责接收连接)
- Worker 线程: CPU 核心数 * 2 (处理 I/O 事件)
- 生产环境: 16-32 个 Worker 线程

### 10.2 数据库优化

#### 10.2.1 索引设计

```sql
-- im_message 表
CREATE INDEX idx_receiver_status ON im_message(receiver_id, status);
CREATE INDEX idx_group ON im_message(group_id);
CREATE INDEX idx_sequence ON im_message(sequence);
CREATE INDEX idx_tenant ON im_message(tenant_id);

-- im_conversation 表
CREATE INDEX idx_user ON im_conversation(user_id, tenant_id);
CREATE INDEX idx_last_time ON im_conversation(last_message_time);

-- im_group_user 表
CREATE INDEX idx_group ON im_group_user(group_id);
CREATE INDEX idx_user ON im_group_user(user_id);
```

#### 10.2.2 分页查询优化

```java
/**
 * 使用游标分页,避免深分页问题
 * 
 * 传统分页: SELECT * FROM im_message LIMIT 10000, 20
 * 游标分页: SELECT * FROM im_message WHERE id < 10000 ORDER BY id DESC LIMIT 20
 */
public List<ImMessageDO> getMessages(Long conversationId, Long lastMessageId, int limit) {
    return messageMapper.selectList(
        new LambdaQueryWrapper<ImMessageDO>()
            .eq(ImMessageDO::getConversationId, conversationId)
            .lt(lastMessageId != null, ImMessageDO::getId, lastMessageId)
            .orderByDesc(ImMessageDO::getId)
            .last("LIMIT " + limit)
    );
}
```

**性能对比**:
- 传统分页: 查询 10000 条数据,耗时 500ms
- 游标分页: 查询 20 条数据,耗时 10ms

#### 10.2.3 批量操作优化

```java
/**
 * 批量插入消息
 */
public void batchSaveMessages(List<ImMessageDO> messages) {
    if (messages.size() > 100) {
        // 分批插入,每批 100 条
        List<List<ImMessageDO>> batches = Lists.partition(messages, 100);
        for (List<ImMessageDO> batch : batches) {
            messageMapper.insertBatch(batch);
        }
    } else {
        messageMapper.insertBatch(messages);
    }
}
```

### 10.3 消息推送优化

#### 10.3.1 异步推送

```java
/**
 * 异步推送消息,不阻塞主线程
 */
@Service
public class AsyncMessageSender {
    
    private final ExecutorService executor = Executors.newFixedThreadPool(10);
    
    public CompletableFuture<Boolean> sendToUserAsync(Long userId, ImMessage message) {
        return CompletableFuture.supplyAsync(() -> {
            List<NettySession> sessions = sessionManager.getSessionsByUserId(userId);
            for (NettySession session : sessions) {
                if (session.isActive()) {
                    session.getChannel().writeAndFlush(message);
                }
            }
            return true;
        }, executor);
    }
}
```

#### 10.3.2 批量推送

```java
/**
 * 批量推送消息给多个用户
 */
public void batchSendToUsers(List<Long> userIds, ImMessage message) {
    List<CompletableFuture<Boolean>> futures = userIds.stream()
        .map(userId -> sendToUserAsync(userId, message))
        .collect(Collectors.toList());
    
    // 等待所有推送完成
    CompletableFuture.allOf(futures.toArray(new CompletableFuture[0])).join();
}
```

#### 10.3.3 群聊消息优化

```java
/**
 * 群聊消息推送优化
 * 1. 从缓存获取群成员列表
 * 2. 并行推送给所有成员
 */
public void sendToGroup(Long groupId, ImMessage message, Long excludeUserId) {
    // 1. 从缓存获取群成员
    List<Long> memberIds = cacheService.getGroupMembers(groupId);
    if (memberIds == null) {
        memberIds = groupUserMapper.selectUserIdsByGroupId(groupId);
        cacheService.cacheGroupMembers(groupId, memberIds);
    }
    
    // 2. 过滤发送者
    List<Long> targetUserIds = memberIds.stream()
        .filter(memberId -> !memberId.equals(excludeUserId))
        .collect(Collectors.toList());
    
    // 3. 并行推送
    batchSendToUsers(targetUserIds, message);
}
```

### 10.4 Protobuf 优化

#### 10.4.1 性能对比

| 对比项 | JSON | Protobuf | 优势 |
|-------|------|----------|------|
| 序列化速度 | 100% | 500-1000% | 快 5-10 倍 |
| 反序列化速度 | 100% | 2000-10000% | 快 20-100 倍 |
| 数据体积 | 100% | 10-30% | 小 3-10 倍 |
| CPU 占用 | 100% | 20-50% | 低 50-80% |

#### 10.4.2 使用建议

```java
// ✅ 推荐: 使用 Protobuf (移动端)
ImMessage message = ImMessage.newBuilder()
    .setHeader(header)
    .setBody(ByteString.copyFrom(textMessage.toByteArray()))
    .build();

// ❌ 不推荐: 使用 JSON (Web 端可用)
String json = JsonUtils.toJsonString(message);
```

### 10.5 连接管理优化

#### 10.5.1 定期清理无效连接

```java
/**
 * 定期清理无效连接
 * 每分钟执行一次
 */
@Scheduled(fixedRate = 60000)
public void cleanInactiveSessions() {
    int beforeCount = sessionManager.getOnlineConnectionCount();
    
    sessionManager.getAllSessions().forEach(session -> {
        if (!session.isActive()) {
            sessionManager.removeSession(session.getChannel());
        }
    });
    
    int afterCount = sessionManager.getOnlineConnectionCount();
    log.info("[SessionManager] 清理无效连接: {} -> {}", beforeCount, afterCount);
}
```

#### 10.5.2 心跳超时优化

```yaml
shengyu:
  netty:
    reader-idle-time: 60  # 生产环境: 60 秒
    # reader-idle-time: 120  # 开发环境: 120 秒 (延长超时时间)
```

### 10.6 内存优化

#### 10.6.1 对象池

```java
/**
 * 使用对象池减少 GC
 */
private final ObjectPool<ImMessage> messagePool = new GenericObjectPool<>(
    new MessagePooledObjectFactory());

// 从对象池获取对象
ImMessage message = messagePool.borrowObject();
try {
    // 使用对象
    channel.writeAndFlush(message);
} finally {
    // 归还对象
    messagePool.returnObject(message);
}
```

#### 10.6.2 ByteBuf 池化

```java
/**
 * 使用 Netty 的 ByteBuf 池
 */
PooledByteBufAllocator allocator = PooledByteBufAllocator.DEFAULT;

// 分配 ByteBuf
ByteBuf buffer = allocator.buffer(1024);
try {
    // 使用 buffer
    buffer.writeBytes(data);
} finally {
    // 释放 buffer
    buffer.release();
}
```

### 10.7 性能监控

#### 10.7.1 关键指标

| 指标 | 目标值 | 监控方式 |
|------|--------|---------|
| 在线连接数 | 50w+ | `sessionManager.getOnlineConnectionCount()` |
| 消息吞吐量 | 10w+ msg/s | Micrometer Counter |
| 消息延迟 | < 100ms | Micrometer Timer |
| CPU 占用 | < 70% | JVM Metrics |
| 内存占用 | < 80% | JVM Metrics |
| GC 频率 | < 10次/分钟 | JVM Metrics |

#### 10.7.2 监控实现

```java
@Component
public class WebSocketMetrics {

    private final MeterRegistry meterRegistry;

    // 在线用户数
    public void recordOnlineUsers(int count) {
        meterRegistry.gauge("websocket.online.users", count);
    }

    // 消息发送量
    public void recordMessageSent() {
        meterRegistry.counter("websocket.message.sent").increment();
    }

    // 消息接收量
    public void recordMessageReceived() {
        meterRegistry.counter("websocket.message.received").increment();
    }

    // 消息延迟
    public void recordMessageLatency(long latency) {
        meterRegistry.timer("websocket.message.latency")
            .record(latency, TimeUnit.MILLISECONDS);
    }
}
```

---

## 11. 任务拆解清单

### 阶段 1: 数据库设计与初始化 (2天)

- [ ] 1.1 创建 `im_message` 表
- [ ] 1.2 创建 `im_conversation` 表
- [ ] 1.3 创建 `im_group` 表
- [ ] 1.4 创建 `im_group_user` 表
- [ ] 1.5 创建 `im_contact_setting` 表
- [ ] 1.6 创建索引
- [ ] 1.7 初始化测试数据

### 阶段 2: 后端基础框架搭建 (3天)

#### 2.1 DO 实体类 (0.5天)
- [ ] 2.1.1 创建 `ImMessageDO.java`
- [ ] 2.1.2 创建 `ImConversationDO.java`
- [ ] 2.1.3 创建 `ImGroupDO.java`
- [ ] 2.1.4 创建 `ImGroupUserDO.java`
- [ ] 2.1.5 创建 `ImContactSettingDO.java`

#### 2.2 Mapper 接口 (0.5天)
- [ ] 2.2.1 创建 `ImMessageMapper.java`
- [ ] 2.2.2 创建 `ImConversationMapper.java`
- [ ] 2.2.3 创建 `ImGroupMapper.java`
- [ ] 2.2.4 创建 `ImGroupUserMapper.java`
- [ ] 2.2.5 创建 `ImContactSettingMapper.java`

#### 2.3 VO 类 (0.5天)
- [ ] 2.3.1 创建 `MessageRespVO.java`
- [ ] 2.3.2 创建 `ConversationRespVO.java`
- [ ] 2.3.3 创建 `GroupRespVO.java`
- [ ] 2.3.4 创建 `ContactRespVO.java`
- [ ] 2.3.5 创建请求 VO 类

#### 2.4 Service 层 (1天)
- [ ] 2.4.1 创建 `ImMessageService` 接口和实现
- [ ] 2.4.2 创建 `ImConversationService` 接口和实现
- [ ] 2.4.3 创建 `ImGroupService` 接口和实现
- [ ] 2.4.4 创建 `ImContactService` 接口和实现

#### 2.5 Controller 层 (0.5天)
- [ ] 2.5.1 创建 `ImMessageController.java`
- [ ] 2.5.2 创建 `ImConversationController.java`
- [ ] 2.5.3 创建 `ImGroupController.java`
- [ ] 2.5.4 创建 `ImContactController.java`

### 阶段 3: WebSocket 中间件集成 (3天)

#### 3.1 SPI 接口实现 (1天)
- [ ] 3.1.1 实现 `MessageStorageService` 接口
- [ ] 3.1.2 实现 `AuthService` 接口
- [ ] 3.1.3 配置 Spring Bean

#### 3.2 消息处理逻辑 (1天)
- [ ] 3.2.1 实现消息保存逻辑
- [ ] 3.2.2 实现会话更新逻辑
- [ ] 3.2.3 实现消息推送逻辑
- [ ] 3.2.4 实现已读回执处理

#### 3.3 连接管理 (1天)
- [ ] 3.3.1 实现认证逻辑
- [ ] 3.3.2 实现心跳检测
- [ ] 3.3.3 实现断线重连
- [ ] 3.3.4 实现Session管理

### 阶段 4: REST API 接口开发 (4天)

#### 4.1 会话管理接口 (1天)
- [ ] 4.1.1 获取会话列表
- [ ] 4.1.2 创建会话
- [ ] 4.1.3 删除会话
- [ ] 4.1.4 置顶会话
- [ ] 4.1.5 设置免打扰

#### 4.2 消息管理接口 (1天)
- [ ] 4.2.1 获取消息列表
- [ ] 4.2.2 撤回消息
- [ ] 4.2.3 删除消息
- [ ] 4.2.4 标记已读

#### 4.3 联系人管理接口 (1天)
- [ ] 4.3.1 获取联系人列表(从 system_users 查询)
- [ ] 4.3.2 搜索联系人
- [ ] 4.3.3 获取联系人详情
- [ ] 4.3.4 更新联系人设置(备注名、星标、免打扰)

#### 4.4 群组管理接口 (1天)
- [ ] 4.4.1 创建群组
- [ ] 4.4.2 获取群组详情
- [ ] 4.4.3 更新群组信息
- [ ] 4.4.4 添加群成员
- [ ] 4.4.5 移除群成员
- [ ] 4.4.6 退出群组
- [ ] 4.4.7 解散群组

### 阶段 5: 移动端开发 (10天)

#### 5.1 基础框架搭建 (1天)
- [ ] 5.1.1 配置 WebSocket 连接
- [ ] 5.1.2 配置 HTTP 请求
- [ ] 5.1.3 配置状态管理
- [ ] 5.1.4 配置路由

#### 5.2 消息列表页 (2天)
- [ ] 5.2.1 页面布局
- [ ] 5.2.2 会话列表渲染
- [ ] 5.2.3 未读消息显示
- [ ] 5.2.4 置顶会话
- [ ] 5.2.5 左滑删除
- [ ] 5.2.6 下拉刷新
- [ ] 5.2.7 WebSocket 消息接收

#### 5.3 聊天页面 (3天)
- [ ] 5.3.1 页面布局
- [ ] 5.3.2 消息列表渲染
- [ ] 5.3.3 文本消息发送
- [ ] 5.3.4 图片消息发送
- [ ] 5.3.5 语音消息发送
- [ ] 5.3.6 视频消息发送
- [ ] 5.3.7 文件消息发送
- [ ] 5.3.8 表情输入(109个微信表情)
- [ ] 5.3.9 语音输入
- [ ] 5.3.10 消息长按菜单(复制、删除、撤回、转发)
- [ ] 5.3.11 多选模式
- [ ] 5.3.12 全屏输入
- [ ] 5.3.13 消息已读回执
- [ ] 5.3.14 正在输入提示

#### 5.4 通讯录页面 (2天)
- [ ] 5.4.1 页面布局
- [ ] 5.4.2 联系人列表渲染(从 system_users 加载)
- [ ] 5.4.3 按部门分组显示
- [ ] 5.4.4 字母索引
- [ ] 5.4.5 搜索联系人
- [ ] 5.4.6 星标联系人置顶

#### 5.5 联系人详情页 (1天)
- [ ] 5.5.1 页面布局
- [ ] 5.5.2 显示联系人信息
- [ ] 5.5.3 设置备注名
- [ ] 5.5.4 设置星标
- [ ] 5.5.5 设置免打扰
- [ ] 5.5.6 发起单聊

#### 5.6 群聊功能 (1天)
- [ ] 5.6.1 发起群聊页面
- [ ] 5.6.2 选择群成员
- [ ] 5.6.3 创建群聊
- [ ] 5.6.4 群聊详情页
- [ ] 5.6.5 添加/移除群成员
- [ ] 5.6.6 设置群名称
- [ ] 5.6.7 设置群公告
- [ ] 5.6.8 退出/解散群聊

### 阶段 6: 测试与优化 (3天)

#### 6.1 单元测试 (1天)
- [ ] 6.1.1 Service 层单元测试
- [ ] 6.1.2 Controller 层单元测试
- [ ] 6.1.3 Mapper 层单元测试

#### 6.2 集成测试 (1天)
- [ ] 6.2.1 消息收发测试
- [ ] 6.2.2 群聊功能测试
- [ ] 6.2.3 离线消息测试
- [ ] 6.2.4 断线重连测试

#### 6.3 性能测试 (0.5天)
- [ ] 6.3.1 并发连接测试
- [ ] 6.3.2 消息吞吐量测试
- [ ] 6.3.3 数据库性能测试

#### 6.4 优化 (0.5天)
- [ ] 6.4.1 代码优化
- [ ] 6.4.2 SQL 优化
- [ ] 6.4.3 缓存优化

---

## 12. 开发注意事项

### 12.1 租户隔离

所有 IM 相关表都包含 `tenant_id` 字段,必须确保:
- 所有查询都带上 `tenant_id` 条件
- 使用框架提供的 `@TenantIgnore` 注解控制租户过滤
- WebSocket 认证时验证租户ID

### 12.2 消息序列号

- 使用全局递增的序列号(`sequence`)
- 用于消息排序和去重
- 可使用 Redis 的 INCR 命令生成

```java
public Long generateSequence() {
    return redisTemplate.opsForValue().increment("im:sequence");
}
```

### 12.3 消息可靠性

- 发送消息后等待 ACK 确认
- 超时未收到 ACK 则重发
- 使用 `sequence` 去重

### 12.4 安全性

- WebSocket 连接必须认证
- 验证用户权限(是否可以发送消息给对方)
- 敏感信息加密存储

### 12.5 性能考虑

- 消息列表使用游标分页
- 群成员列表使用缓存
- 离线消息批量拉取
- 图片/视频使用 CDN

### 12.6 中间件配置

#### 12.6.1 基础配置

```yaml
shengyu:
  netty:
    # 是否启用 Netty 服务器
    enable: true
    
    # 服务器配置
    host: 0.0.0.0
    port: 9000
    
    # 性能优化配置
    use-epoll: true                           # Linux 环境下启用 Epoll
    boss-threads: 1                           # Boss 线程数
    worker-threads: 32                        # Worker 线程数 (生产环境)
    
    # TCP 参数配置
    so-backlog: 2048                          # TCP 连接队列大小
    so-rcvbuf: 131072                         # TCP 接收缓冲区 (128KB)
    so-sndbuf: 131072                         # TCP 发送缓冲区 (128KB)
    write-buffer-low-water-mark: 32768        # 写缓冲区低水位线 (32KB)
    write-buffer-high-water-mark: 65536       # 写缓冲区高水位线 (64KB)
    
    # 心跳配置
    reader-idle-time: 60                      # 读空闲时间 (秒)
    writer-idle-time: 0                       # 写空闲时间 (秒)
    all-idle-time: 0                          # 读写空闲时间 (秒)
    
    # 协议配置
    enable-websocket: true                    # 是否启用 WebSocket 协议
    websocket-path: /ws                       # WebSocket 路径
    max-content-length: 65536                 # HTTP 最大内容长度 (64KB)
    enable-protobuf: true                     # 是否启用 Protobuf 协议
```

#### 12.6.2 分布式部署配置

```yaml
shengyu:
  websocket:
    # 消息发送类型: local/redis/rocketmq/kafka/rabbitmq
    sender-type: redis
    
    # Redis 消息总线配置 (推荐)
    sender-redis:
      channel: im-message-channel
    
    # RocketMQ 消息总线配置
    sender-rocketmq:
      topic: im-message-topic
      consumer-group: im-message-consumer-group
    
    # Kafka 消息总线配置
    sender-kafka:
      topic: im-message-topic
      consumer-group: im-message-consumer-group
    
    # RabbitMQ 消息总线配置
    sender-rabbitmq:
      exchange: im-message-exchange
      queue: im-message-queue
```

#### 12.6.3 环境配置

```yaml
---
# 开发环境
spring:
  profiles: dev

shengyu:
  netty:
    port: 9000
    worker-threads: 8
    reader-idle-time: 120                     # 开发环境延长超时时间

---
# 生产环境
spring:
  profiles: prod

shengyu:
  netty:
    port: 9000
    use-epoll: true
    worker-threads: 32                        # 生产环境增加线程数
    so-backlog: 2048
    so-rcvbuf: 131072                         # 128KB
    so-sndbuf: 131072                         # 128KB
    reader-idle-time: 60
```

---

## 13. 附录

### 13.1 消息类型定义

| 类型值 | 类型名称 | 说明 |
|-------|---------|------|
| 100 | TEXT | 文本消息 |
| 101 | IMAGE | 图片消息 |
| 102 | VOICE | 语音消息 |
| 103 | VIDEO | 视频消息 |
| 104 | FILE | 文件消息 |
| 105 | LOCATION | 位置消息 |

### 13.2 会话类型定义

| 类型值 | 类型名称 | 说明 |
|-------|---------|------|
| 1 | SINGLE | 单聊 |
| 2 | GROUP | 群聊 |

### 13.3 消息状态定义

| 状态值 | 状态名称 | 说明 |
|-------|---------|------|
| 0 | UNREAD | 未读 |
| 1 | READ | 已读 |
| 2 | RECALLED | 已撤回 |

### 13.4 群成员角色定义

| 角色值 | 角色名称 | 说明 |
|-------|---------|------|
| 0 | MEMBER | 普通成员 |
| 1 | ADMIN | 管理员 |
| 2 | OWNER | 群主 |

### 13.5 错误码定义

| 错误码 | 错误信息 | 说明 |
|-------|---------|------|
| 10001 | 认证失败 | Token 无效或过期 |
| 10002 | 权限不足 | 无权限执行操作 |
| 10003 | 消息发送失败 | 消息发送异常 |
| 10004 | 会话不存在 | 会话ID无效 |
| 10005 | 群组不存在 | 群组ID无效 |
| 10006 | 非群成员 | 不是群组成员 |
| 10007 | 撤回超时 | 超过2分钟无法撤回 |

---

## 14. 后端实现详细指南

本章节基于 `shengyu-module-system` 现有代码模式,提供详细的实现指南。

### 14.1 项目结构

```
shengyu-module-system-biz/
└── src/main/java/com/shengyu/module/system/
    ├── controller/admin/im/      # Controller 层
    │   ├── ImMessageController.java
    │   ├── ImConversationController.java
    │   ├── ImGroupController.java
    │   └── ImContactController.java
    ├── service/im/               # Service 层
    │   ├── ImMessageService.java
    │   ├── ImMessageServiceImpl.java
    │   ├── ImConversationService.java
    │   ├── ImConversationServiceImpl.java
    │   ├── ImGroupService.java
    │   ├── ImGroupServiceImpl.java
    │   ├── ImContactService.java
    │   └── ImContactServiceImpl.java
    ├── dal/                      # 数据访问层
    │   ├── dataobject/im/        # DO 实体类
    │   │   ├── ImMessageDO.java
    │   │   ├── ImConversationDO.java
    │   │   ├── ImGroupDO.java
    │   │   ├── ImGroupUserDO.java
    │   │   └── ImContactSettingDO.java
    │   └── mysql/im/             # Mapper 接口
    │       ├── ImMessageMapper.java
    │       ├── ImConversationMapper.java
    │       ├── ImGroupMapper.java
    │       ├── ImGroupUserMapper.java
    │       └── ImContactSettingMapper.java
    └── controller/admin/im/vo/   # VO 类
        ├── message/
        │   ├── MessageRespVO.java
        │   ├── MessageSendReqVO.java
        │   └── MessagePageReqVO.java
        ├── conversation/
        │   ├── ConversationRespVO.java
        │   └── ConversationCreateReqVO.java
        ├── group/
        │   ├── GroupRespVO.java
        │   ├── GroupCreateReqVO.java
        │   └── GroupUpdateReqVO.java
        └── contact/
            ├── ContactRespVO.java
            └── ContactSettingUpdateReqVO.java
```

### 14.2 DO 实体类示例

参考 `AdminUserDO.java` 的模式:

```java
package com.shengyu.module.system.dal.dataobject.im;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.framework.mybatis.core.dataobject.BaseDO;
import lombok.*;

/**
 * IM 消息 DO
 *
 * @author shengyu
 */
@TableName("im_message")
@Data
@EqualsAndHashCode(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ImMessageDO extends BaseDO {

    /**
     * 消息ID
     */
    @TableId
    private Long id;

    /**
     * 消息类型
     * 
     * 枚举 {@link MessageTypeEnum}
     */
    private Integer messageType;

    /**
     * 发送者ID
     */
    private Long senderId;

    /**
     * 接收者ID(单聊)
     */
    private Long receiverId;

    /**
     * 群组ID(群聊)
     */
    private Long groupId;

    /**
     * 消息内容
     */
    private String content;

    /**
     * 扩展字段
     */
    private String extra;

    /**
     * 状态
     * 
     * 枚举 {@link MessageStatusEnum}
     */
    private Integer status;

    /**
     * 序列号
     */
    private Long sequence;

}
```

```java
package com.shengyu.module.system.dal.dataobject.im;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.framework.mybatis.core.dataobject.BaseDO;
import lombok.*;

/**
 * IM 会话 DO
 *
 * @author shengyu
 */
@TableName("im_conversation")
@Data
@EqualsAndHashCode(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ImConversationDO extends BaseDO {

    /**
     * 会话ID
     */
    @TableId
    private Long id;

    /**
     * 用户ID
     */
    private Long userId;

    /**
     * 对方ID(单聊用户ID或群组ID)
     */
    private Long targetId;

    /**
     * 会话类型
     * 
     * 枚举 {@link ConversationTypeEnum}
     */
    private Integer conversationType;

    /**
     * 未读数
     */
    private Integer unreadCount;

    /**
     * 最后一条消息ID
     */
    private Long lastMessageId;

    /**
     * 最后消息内容摘要
     */
    private String lastMessageContent;

    /**
     * 最后消息时间
     */
    private LocalDateTime lastMessageTime;

    /**
     * 是否置顶
     */
    private Boolean isPinned;

    /**
     * 置顶时间
     */
    private LocalDateTime pinnedTime;

    /**
     * 免打扰
     */
    private Boolean noDisturb;

}
```

### 14.3 Mapper 接口示例

参考 `UserMapper.java` 的模式:

```java
package com.shengyu.module.system.dal.mysql.im;

import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.module.system.controller.admin.im.vo.message.MessagePageReqVO;
import com.shengyu.module.system.dal.dataobject.im.ImMessageDO;
import org.apache.ibatis.annotations.Mapper;

/**
 * IM 消息 Mapper
 *
 * @author shengyu
 */
@Mapper
public interface ImMessageMapper extends BaseMapperX<ImMessageDO> {

    default PageResult<ImMessageDO> selectPage(MessagePageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<ImMessageDO>()
                .eqIfPresent(ImMessageDO::getSenderId, reqVO.getSenderId())
                .eqIfPresent(ImMessageDO::getReceiverId, reqVO.getReceiverId())
                .eqIfPresent(ImMessageDO::getGroupId, reqVO.getGroupId())
                .eqIfPresent(ImMessageDO::getMessageType, reqVO.getMessageType())
                .betweenIfPresent(ImMessageDO::getCreateTime, reqVO.getCreateTime())
                .orderByDesc(ImMessageDO::getId));
    }

}
```

```java
package com.shengyu.module.system.dal.mysql.im;

import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.module.system.dal.dataobject.im.ImConversationDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * IM 会话 Mapper
 *
 * @author shengyu
 */
@Mapper
public interface ImConversationMapper extends BaseMapperX<ImConversationDO> {

    default List<ImConversationDO> selectListByUserId(Long userId) {
        return selectList(new LambdaQueryWrapperX<ImConversationDO>()
                .eq(ImConversationDO::getUserId, userId)
                .orderByDesc(ImConversationDO::getIsPinned)
                .orderByDesc(ImConversationDO::getLastMessageTime));
    }

    default ImConversationDO selectOne(Long userId, Long targetId, Integer conversationType) {
        return selectOne(new LambdaQueryWrapperX<ImConversationDO>()
                .eq(ImConversationDO::getUserId, userId)
                .eq(ImConversationDO::getTargetId, targetId)
                .eq(ImConversationDO::getConversationType, conversationType));
    }

}
```

### 14.4 VO 类示例

参考 `UserRespVO.java` 的模式:

```java
package com.shengyu.module.system.controller.admin.im.vo.message;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Schema(description = "管理后台 - IM 消息 Response VO")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class MessageRespVO {

    @Schema(description = "消息ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    private Long id;

    @Schema(description = "消息类型", requiredMode = Schema.RequiredMode.REQUIRED, example = "100")
    private Integer messageType;

    @Schema(description = "发送者ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    private Long senderId;

    @Schema(description = "接收者ID", example = "2")
    private Long receiverId;

    @Schema(description = "群组ID", example = "10")
    private Long groupId;

    @Schema(description = "消息内容", requiredMode = Schema.RequiredMode.REQUIRED)
    private String content;

    @Schema(description = "扩展字段")
    private String extra;

    @Schema(description = "状态", requiredMode = Schema.RequiredMode.REQUIRED, example = "0")
    private Integer status;

    @Schema(description = "序列号", requiredMode = Schema.RequiredMode.REQUIRED, example = "1000")
    private Long sequence;

    @Schema(description = "创建时间", requiredMode = Schema.RequiredMode.REQUIRED)
    private LocalDateTime createTime;

}
```

```java
package com.shengyu.module.system.controller.admin.im.vo.conversation;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Schema(description = "管理后台 - IM 会话 Response VO")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ConversationRespVO {

    @Schema(description = "会话ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    private Long id;

    @Schema(description = "用户ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    private Long userId;

    @Schema(description = "对方ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "2")
    private Long targetId;

    @Schema(description = "会话类型", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    private Integer conversationType;

    @Schema(description = "未读数", requiredMode = Schema.RequiredMode.REQUIRED, example = "5")
    private Integer unreadCount;

    @Schema(description = "最后消息内容")
    private String lastMessageContent;

    @Schema(description = "最后消息时间")
    private LocalDateTime lastMessageTime;

    @Schema(description = "是否置顶", requiredMode = Schema.RequiredMode.REQUIRED, example = "false")
    private Boolean isPinned;

    @Schema(description = "免打扰", requiredMode = Schema.RequiredMode.REQUIRED, example = "false")
    private Boolean noDisturb;

    // 扩展字段
    @Schema(description = "对方名称", example = "张三")
    private String targetName;

    @Schema(description = "对方头像", example = "https://...")
    private String targetAvatar;

}
```

### 14.5 Service 层实现示例

参考 `UserServiceImpl.java` 的模式:

```java
package com.shengyu.module.system.service.im;

import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.module.system.controller.admin.im.vo.message.MessagePageReqVO;
import com.shengyu.module.system.controller.admin.im.vo.message.MessageSendReqVO;
import com.shengyu.module.system.dal.dataobject.im.ImMessageDO;

/**
 * IM 消息 Service 接口
 *
 * @author shengyu
 */
public interface ImMessageService {

    /**
     * 发送消息
     *
     * @param reqVO 消息信息
     * @return 消息ID
     */
    Long sendMessage(MessageSendReqVO reqVO);

    /**
     * 获取消息分页
     *
     * @param reqVO 分页查询
     * @return 消息分页
     */
    PageResult<ImMessageDO> getMessagePage(MessagePageReqVO reqVO);

    /**
     * 撤回消息
     *
     * @param id 消息ID
     */
    void recallMessage(Long id);

    /**
     * 删除消息
     *
     * @param id 消息ID
     */
    void deleteMessage(Long id);

}
```

```java
package com.shengyu.module.system.service.im;

import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.module.system.controller.admin.im.vo.message.MessagePageReqVO;
import com.shengyu.module.system.controller.admin.im.vo.message.MessageSendReqVO;
import com.shengyu.module.system.dal.dataobject.im.ImMessageDO;
import com.shengyu.module.system.dal.mysql.im.ImMessageMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import static com.shengyu.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.shengyu.module.system.enums.ErrorCodeConstants.*;

/**
 * IM 消息 Service 实现类
 *
 * @author shengyu
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ImMessageServiceImpl implements ImMessageService {

    private final ImMessageMapper messageMapper;
    private final ImConversationService conversationService;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long sendMessage(MessageSendReqVO reqVO) {
        // 1. 构建消息 DO
        ImMessageDO message = ImMessageDO.builder()
                .messageType(reqVO.getMessageType())
                .senderId(reqVO.getSenderId())
                .receiverId(reqVO.getReceiverId())
                .groupId(reqVO.getGroupId())
                .content(reqVO.getContent())
                .extra(reqVO.getExtra())
                .status(0) // 未读
                .sequence(generateSequence())
                .build();

        // 2. 保存消息
        messageMapper.insert(message);

        // 3. 更新会话
        conversationService.updateConversationByMessage(message);

        return message.getId();
    }

    @Override
    public PageResult<ImMessageDO> getMessagePage(MessagePageReqVO reqVO) {
        return messageMapper.selectPage(reqVO);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void recallMessage(Long id) {
        // 1. 校验消息存在
        ImMessageDO message = messageMapper.selectById(id);
        if (message == null) {
            throw exception(MESSAGE_NOT_EXISTS);
        }

        // 2. 校验是否超过2分钟
        long diff = System.currentTimeMillis() - message.getCreateTime().getTime();
        if (diff > 2 * 60 * 1000) {
            throw exception(MESSAGE_RECALL_TIMEOUT);
        }

        // 3. 更新状态为已撤回
        ImMessageDO updateObj = new ImMessageDO();
        updateObj.setId(id);
        updateObj.setStatus(2); // 已撤回
        messageMapper.updateById(updateObj);
    }

    @Override
    public void deleteMessage(Long id) {
        // 校验消息存在
        ImMessageDO message = messageMapper.selectById(id);
        if (message == null) {
            throw exception(MESSAGE_NOT_EXISTS);
        }

        // 删除消息
        messageMapper.deleteById(id);
    }

    private Long generateSequence() {
        // 使用 Redis 生成全局递增序列号
        // 这里简化处理,实际应使用 RedisTemplate
        return System.currentTimeMillis();
    }

}
```

### 14.6 Controller 层实现示例

参考 `UserController.java` 的模式:

```java
package com.shengyu.module.system.controller.admin.im;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.module.system.controller.admin.im.vo.message.MessagePageReqVO;
import com.shengyu.module.system.controller.admin.im.vo.message.MessageRespVO;
import com.shengyu.module.system.controller.admin.im.vo.message.MessageSendReqVO;
import com.shengyu.module.system.convert.im.ImMessageConvert;
import com.shengyu.module.system.dal.dataobject.im.ImMessageDO;
import com.shengyu.module.system.service.im.ImMessageService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;

import static com.shengyu.framework.common.pojo.CommonResult.success;

/**
 * IM 消息 Controller
 *
 * @author shengyu
 */
@Tag(name = "管理后台 - IM 消息")
@RestController
@RequestMapping("/system/im/message")
@RequiredArgsConstructor
@Validated
public class ImMessageController {

    private final ImMessageService messageService;

    @PostMapping("/send")
    @Operation(summary = "发送消息")
    @PreAuthorize("@ss.hasPermission('system:im:message:send')")
    public CommonResult<Long> sendMessage(@Valid @RequestBody MessageSendReqVO reqVO) {
        return success(messageService.sendMessage(reqVO));
    }

    @GetMapping("/page")
    @Operation(summary = "获取消息分页")
    @PreAuthorize("@ss.hasPermission('system:im:message:query')")
    public CommonResult<PageResult<MessageRespVO>> getMessagePage(@Valid MessagePageReqVO reqVO) {
        PageResult<ImMessageDO> pageResult = messageService.getMessagePage(reqVO);
        return success(ImMessageConvert.INSTANCE.convertPage(pageResult));
    }

    @PostMapping("/recall/{id}")
    @Operation(summary = "撤回消息")
    @Parameter(name = "id", description = "消息ID", required = true, example = "1")
    @PreAuthorize("@ss.hasPermission('system:im:message:recall')")
    public CommonResult<Boolean> recallMessage(@PathVariable("id") Long id) {
        messageService.recallMessage(id);
        return success(true);
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "删除消息")
    @Parameter(name = "id", description = "消息ID", required = true, example = "1")
    @PreAuthorize("@ss.hasPermission('system:im:message:delete')")
    public CommonResult<Boolean> deleteMessage(@PathVariable("id") Long id) {
        messageService.deleteMessage(id);
        return success(true);
    }

}
```

```java
package com.shengyu.module.system.controller.admin.im;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.module.system.controller.admin.im.vo.conversation.ConversationRespVO;
import com.shengyu.module.system.service.im.ImConversationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

import static com.shengyu.framework.common.pojo.CommonResult.success;

/**
 * IM 会话 Controller
 *
 * @author shengyu
 */
@Tag(name = "管理后台 - IM 会话")
@RestController
@RequestMapping("/system/im/conversation")
@RequiredArgsConstructor
@Validated
public class ImConversationController {

    private final ImConversationService conversationService;

    @GetMapping("/list")
    @Operation(summary = "获取会话列表")
    @PreAuthorize("@ss.hasPermission('system:im:conversation:query')")
    public CommonResult<List<ConversationRespVO>> getConversationList() {
        return success(conversationService.getConversationList());
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "删除会话")
    @Parameter(name = "id", description = "会话ID", required = true, example = "1")
    @PreAuthorize("@ss.hasPermission('system:im:conversation:delete')")
    public CommonResult<Boolean> deleteConversation(@PathVariable("id") Long id) {
        conversationService.deleteConversation(id);
        return success(true);
    }

    @PutMapping("/pin/{id}")
    @Operation(summary = "置顶会话")
    @Parameter(name = "id", description = "会话ID", required = true, example = "1")
    @PreAuthorize("@ss.hasPermission('system:im:conversation:update')")
    public CommonResult<Boolean> pinConversation(@PathVariable("id") Long id,
                                                  @RequestParam("pinned") Boolean pinned) {
        conversationService.pinConversation(id, pinned);
        return success(true);
    }

    @PutMapping("/no-disturb/{id}")
    @Operation(summary = "设置免打扰")
    @Parameter(name = "id", description = "会话ID", required = true, example = "1")
    @PreAuthorize("@ss.hasPermission('system:im:conversation:update')")
    public CommonResult<Boolean> setNoDisturb(@PathVariable("id") Long id,
                                               @RequestParam("noDisturb") Boolean noDisturb) {
        conversationService.setNoDisturb(id, noDisturb);
        return success(true);
    }

}
```

### 14.7 联系人 Controller 实现(企业内部IM)

```java
package com.shengyu.module.system.controller.admin.im;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.module.system.controller.admin.im.vo.contact.ContactRespVO;
import com.shengyu.module.system.controller.admin.im.vo.contact.ContactSettingUpdateReqVO;
import com.shengyu.module.system.service.im.ImContactService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.util.List;

import static com.shengyu.framework.common.pojo.CommonResult.success;

/**
 * IM 联系人 Controller
 * 
 * 说明: 企业内部IM,联系人直接来源于 system_users 表(同租户)
 *
 * @author shengyu
 */
@Tag(name = "管理后台 - IM 联系人")
@RestController
@RequestMapping("/system/im/contact")
@RequiredArgsConstructor
@Validated
public class ImContactController {

    private final ImContactService contactService;

    @GetMapping("/list")
    @Operation(summary = "获取联系人列表", description = "从 system_users 表查询同租户下的所有用户")
    @PreAuthorize("@ss.hasPermission('system:im:contact:query')")
    public CommonResult<List<ContactRespVO>> getContactList() {
        return success(contactService.getContactList());
    }

    @GetMapping("/search")
    @Operation(summary = "搜索联系人")
    @Parameter(name = "keyword", description = "搜索关键词", required = true, example = "张三")
    @PreAuthorize("@ss.hasPermission('system:im:contact:query')")
    public CommonResult<List<ContactRespVO>> searchContact(@RequestParam("keyword") String keyword) {
        return success(contactService.searchContact(keyword));
    }

    @GetMapping("/{id}")
    @Operation(summary = "获取联系人详情")
    @Parameter(name = "id", description = "联系人ID", required = true, example = "1")
    @PreAuthorize("@ss.hasPermission('system:im:contact:query')")
    public CommonResult<ContactRespVO> getContact(@PathVariable("id") Long id) {
        return success(contactService.getContact(id));
    }

    @PutMapping("/setting")
    @Operation(summary = "更新联系人设置", description = "设置备注名、星标、免打扰")
    @PreAuthorize("@ss.hasPermission('system:im:contact:update')")
    public CommonResult<Boolean> updateContactSetting(@Valid @RequestBody ContactSettingUpdateReqVO reqVO) {
        contactService.updateContactSetting(reqVO);
        return success(true);
    }

}
```

### 14.8 联系人 Service 实现(企业内部IM)

```java
package com.shengyu.module.system.service.im;

import com.shengyu.module.system.controller.admin.im.vo.contact.ContactRespVO;
import com.shengyu.module.system.controller.admin.im.vo.contact.ContactSettingUpdateReqVO;

import java.util.List;

/**
 * IM 联系人 Service 接口
 *
 * @author shengyu
 */
public interface ImContactService {

    /**
     * 获取联系人列表
     * 
     * 说明: 从 system_users 表查询同租户下的所有用户
     *
     * @return 联系人列表
     */
    List<ContactRespVO> getContactList();

    /**
     * 搜索联系人
     *
     * @param keyword 搜索关键词
     * @return 联系人列表
     */
    List<ContactRespVO> searchContact(String keyword);

    /**
     * 获取联系人详情
     *
     * @param id 联系人ID
     * @return 联系人详情
     */
    ContactRespVO getContact(Long id);

    /**
     * 更新联系人设置
     * 
     * 说明: 更新 im_contact_setting 表(备注名、星标、免打扰)
     *
     * @param reqVO 设置信息
     */
    void updateContactSetting(ContactSettingUpdateReqVO reqVO);

}
```

```java
package com.shengyu.module.system.service.im;

import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.module.system.controller.admin.im.vo.contact.ContactRespVO;
import com.shengyu.module.system.controller.admin.im.vo.contact.ContactSettingUpdateReqVO;
import com.shengyu.module.system.dal.dataobject.dept.DeptDO;
import com.shengyu.module.system.dal.dataobject.im.ImContactSettingDO;
import com.shengyu.module.system.dal.dataobject.user.AdminUserDO;
import com.shengyu.module.system.dal.mysql.dept.DeptMapper;
import com.shengyu.module.system.dal.mysql.im.ImContactSettingMapper;
import com.shengyu.module.system.dal.mysql.user.AdminUserMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * IM 联系人 Service 实现类
 * 
 * 说明: 企业内部IM,联系人直接来源于 system_users 表
 *
 * @author shengyu
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ImContactServiceImpl implements ImContactService {

    private final AdminUserMapper userMapper;
    private final DeptMapper deptMapper;
    private final ImContactSettingMapper contactSettingMapper;

    @Override
    public List<ContactRespVO> getContactList() {
        // 1. 获取当前用户ID
        Long currentUserId = SecurityFrameworkUtils.getLoginUserId();

        // 2. 查询同租户下的所有用户(排除自己)
        List<AdminUserDO> users = userMapper.selectList();
        users = users.stream()
                .filter(user -> !user.getId().equals(currentUserId))
                .collect(Collectors.toList());

        // 3. 查询部门信息
        List<Long> deptIds = users.stream()
                .map(AdminUserDO::getDeptId)
                .distinct()
                .collect(Collectors.toList());
        Map<Long, DeptDO> deptMap = deptMapper.selectBatchIds(deptIds).stream()
                .collect(Collectors.toMap(DeptDO::getId, dept -> dept));

        // 4. 查询联系人设置
        List<ImContactSettingDO> settings = contactSettingMapper.selectListByUserId(currentUserId);
        Map<Long, ImContactSettingDO> settingMap = settings.stream()
                .collect(Collectors.toMap(ImContactSettingDO::getContactId, setting -> setting));

        // 5. 组装返回数据
        return users.stream().map(user -> {
            ContactRespVO vo = BeanUtils.toBean(user, ContactRespVO.class);
            
            // 设置部门信息
            DeptDO dept = deptMap.get(user.getDeptId());
            if (dept != null) {
                vo.setDeptName(dept.getName());
            }
            
            // 设置个性化配置
            ImContactSettingDO setting = settingMap.get(user.getId());
            if (setting != null) {
                vo.setRemarkName(setting.getNickname());
                vo.setStar(setting.getStar());
                vo.setNoDisturb(setting.getNoDisturb());
            }
            
            return vo;
        }).collect(Collectors.toList());
    }

    @Override
    public List<ContactRespVO> searchContact(String keyword) {
        // 1. 获取当前用户ID
        Long currentUserId = SecurityFrameworkUtils.getLoginUserId();

        // 2. 搜索用户(按用户名或昵称)
        List<AdminUserDO> users = userMapper.selectListByKeyword(keyword);
        users = users.stream()
                .filter(user -> !user.getId().equals(currentUserId))
                .collect(Collectors.toList());

        // 3. 组装返回数据(简化版,不包含设置信息)
        return users.stream().map(user -> {
            ContactRespVO vo = BeanUtils.toBean(user, ContactRespVO.class);
            DeptDO dept = deptMapper.selectById(user.getDeptId());
            if (dept != null) {
                vo.setDeptName(dept.getName());
            }
            return vo;
        }).collect(Collectors.toList());
    }

    @Override
    public ContactRespVO getContact(Long id) {
        // 1. 查询用户信息
        AdminUserDO user = userMapper.selectById(id);
        if (user == null) {
            throw exception(USER_NOT_EXISTS);
        }

        // 2. 查询部门信息
        DeptDO dept = deptMapper.selectById(user.getDeptId());

        // 3. 查询联系人设置
        Long currentUserId = SecurityFrameworkUtils.getLoginUserId();
        ImContactSettingDO setting = contactSettingMapper.selectOne(currentUserId, id);

        // 4. 组装返回数据
        ContactRespVO vo = BeanUtils.toBean(user, ContactRespVO.class);
        if (dept != null) {
            vo.setDeptName(dept.getName());
        }
        if (setting != null) {
            vo.setRemarkName(setting.getNickname());
            vo.setStar(setting.getStar());
            vo.setNoDisturb(setting.getNoDisturb());
        }

        return vo;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateContactSetting(ContactSettingUpdateReqVO reqVO) {
        // 1. 获取当前用户ID
        Long currentUserId = SecurityFrameworkUtils.getLoginUserId();

        // 2. 查询或创建设置记录
        ImContactSettingDO setting = contactSettingMapper.selectOne(currentUserId, reqVO.getContactId());
        if (setting == null) {
            // 创建新记录
            setting = ImContactSettingDO.builder()
                    .userId(currentUserId)
                    .contactId(reqVO.getContactId())
                    .nickname(reqVO.getRemarkName())
                    .star(reqVO.getStar())
                    .noDisturb(reqVO.getNoDisturb())
                    .build();
            contactSettingMapper.insert(setting);
        } else {
            // 更新记录
            setting.setNickname(reqVO.getRemarkName());
            setting.setStar(reqVO.getStar());
            setting.setNoDisturb(reqVO.getNoDisturb());
            contactSettingMapper.updateById(setting);
        }
    }

}
```

### 14.9 Convert 转换器

```java
package com.shengyu.module.system.convert.im;

import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.module.system.controller.admin.im.vo.message.MessageRespVO;
import com.shengyu.module.system.dal.dataobject.im.ImMessageDO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

/**
 * IM 消息 Convert
 *
 * @author shengyu
 */
@Mapper
public interface ImMessageConvert {

    ImMessageConvert INSTANCE = Mappers.getMapper(ImMessageConvert.class);

    MessageRespVO convert(ImMessageDO bean);

    PageResult<MessageRespVO> convertPage(PageResult<ImMessageDO> page);

}
```

---

## 15. WebSocket 中间件集成指南

本章节基于 `shengyu-spring-boot-starter-websocket` 中间件,提供详细的集成指南。

### 15.1 中间件架构概览

```
┌─────────────────────────────────────────────────────────┐
│         shengyu-spring-boot-starter-websocket           │
│                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │ Netty Server │  │   Session    │  │   Message    │ │
│  │              │  │   Manager    │  │  Processor   │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
│         │                  │                  │         │
│         └──────────────────┴──────────────────┘         │
│                         │                                │
│                         ↓                                │
│              ┌──────────────────────┐                   │
│              │    SPI 接口定义      │                   │
│              ├──────────────────────┤                   │
│              │ MessageStorageService│                   │
│              │ AuthService          │                   │
│              └──────────────────────┘                   │
└─────────────────────────────────────────────────────────┘
                         ↑
                         │ 实现 SPI 接口
                         │
┌─────────────────────────────────────────────────────────┐
│              shengyu-module-system                      │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │ SystemMessageStorageServiceImpl                  │  │
│  │ SystemAuthServiceImpl                            │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### 15.2 核心 SPI 接口

#### 15.2.1 MessageStorageService 接口

```java
package com.shengyu.framework.websocket.core.service;

import com.shengyu.framework.websocket.core.message.Message;
import com.shengyu.framework.websocket.core.enums.ConversationType;

import java.util.List;

/**
 * 消息存储服务接口
 * 
 * 由业务模块实现,提供消息的持久化存储能力
 *
 * @author shengyu
 */
public interface MessageStorageService {

    /**
     * 保存消息
     *
     * @param message 消息对象
     * @return 消息ID
     */
    Long saveMessage(Message message);

    /**
     * 获取消息
     *
     * @param messageId 消息ID
     * @return 消息对象
     */
    Message getMessage(Long messageId);

    /**
     * 获取消息列表
     *
     * @param userId 用户ID
     * @param targetId 目标ID(单聊用户ID或群组ID)
     * @param type 会话类型
     * @param limit 数量限制
     * @return 消息列表
     */
    List<Message> getMessages(Long userId, Long targetId, ConversationType type, int limit);

    /**
     * 标记消息为已读
     *
     * @param userId 用户ID
     * @param conversationId 会话ID
     * @param messageId 消息ID
     */
    void markAsRead(Long userId, Long conversationId, Long messageId);

    /**
     * 获取群组成员ID列表
     *
     * @param groupId 群组ID
     * @return 成员ID列表
     */
    List<Long> getGroupMemberIds(Long groupId);

}
```

#### 15.2.2 AuthService 接口

```java
package com.shengyu.framework.websocket.core.service;

/**
 * 认证服务接口
 * 
 * 由业务模块实现,提供 WebSocket 连接的认证能力
 *
 * @author shengyu
 */
public interface AuthService {

    /**
     * 认证
     *
     * @param token 访问令牌
     * @return 用户ID,认证失败返回 null
     */
    Long authenticate(String token);

    /**
     * 检查权限
     *
     * @param userId 用户ID
     * @param permission 权限标识
     * @return 是否有权限
     */
    boolean hasPermission(Long userId, String permission);

}
```

### 15.3 完整的 SPI 实现示例

#### 15.3.1 MessageStorageService 完整实现

```java
package com.shengyu.module.system.service.im;

import com.shengyu.framework.websocket.core.enums.ConversationType;
import com.shengyu.framework.websocket.core.message.Message;
import com.shengyu.framework.websocket.core.service.MessageStorageService;
import com.shengyu.module.system.dal.dataobject.im.ImGroupUserDO;
import com.shengyu.module.system.dal.dataobject.im.ImMessageDO;
import com.shengyu.module.system.dal.mysql.im.ImGroupUserMapper;
import com.shengyu.module.system.dal.mysql.im.ImMessageMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

/**
 * 消息存储服务实现
 *
 * @author shengyu
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class SystemMessageStorageServiceImpl implements MessageStorageService {

    private final ImMessageMapper messageMapper;
    private final ImConversationService conversationService;
    private final ImGroupUserMapper groupUserMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long saveMessage(Message message) {
        log.info("[saveMessage] 保存消息: {}", message);

        // 1. 转换为 DO 对象
        ImMessageDO messageDO = ImMessageDO.builder()
                .id(message.getId())
                .messageType(message.getType().getValue())
                .senderId(message.getSenderId())
                .receiverId(message.getReceiverId())
                .groupId(message.getGroupId())
                .content(message.getContent())
                .extra(convertExtraToJson(message.getExtra()))
                .status(0) // 未读
                .sequence(message.getSequence())
                .build();

        // 2. 保存到数据库
        messageMapper.insert(messageDO);

        // 3. 更新会话
        conversationService.updateConversationByMessage(messageDO);

        log.info("[saveMessage] 消息保存成功, messageId: {}", messageDO.getId());
        return messageDO.getId();
    }

    @Override
    public Message getMessage(Long messageId) {
        ImMessageDO messageDO = messageMapper.selectById(messageId);
        if (messageDO == null) {
            return null;
        }
        return convertToMessage(messageDO);
    }

    @Override
    public List<Message> getMessages(Long userId, Long targetId, 
                                     ConversationType type, int limit) {
        // 查询消息列表
        List<ImMessageDO> list;
        if (type == ConversationType.SINGLE) {
            // 单聊: 查询双方的消息
            list = messageMapper.selectListBySingleChat(userId, targetId, limit);
        } else {
            // 群聊: 查询群组消息
            list = messageMapper.selectListByGroupChat(targetId, limit);
        }

        return list.stream()
                .map(this::convertToMessage)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void markAsRead(Long userId, Long conversationId, Long messageId) {
        log.info("[markAsRead] 标记已读: userId={}, conversationId={}, messageId={}", 
                 userId, conversationId, messageId);

        // 1. 更新消息状态
        messageMapper.updateStatusByConversation(userId, conversationId, messageId, 1);

        // 2. 清空会话未读数
        conversationService.clearUnreadCount(userId, conversationId);
    }

    @Override
    public List<Long> getGroupMemberIds(Long groupId) {
        List<ImGroupUserDO> members = groupUserMapper.selectListByGroupId(groupId);
        return members.stream()
                .map(ImGroupUserDO::getUserId)
                .collect(Collectors.toList());
    }

    // 转换方法
    private Message convertToMessage(ImMessageDO messageDO) {
        return Message.builder()
                .id(messageDO.getId())
                .type(MessageType.valueOf(messageDO.getMessageType()))
                .senderId(messageDO.getSenderId())
                .receiverId(messageDO.getReceiverId())
                .groupId(messageDO.getGroupId())
                .content(messageDO.getContent())
                .extra(convertJsonToExtra(messageDO.getExtra()))
                .sequence(messageDO.getSequence())
                .timestamp(messageDO.getCreateTime().getTime())
                .build();
    }

    private String convertExtraToJson(Map<String, String> extra) {
        if (extra == null || extra.isEmpty()) {
            return null;
        }
        // 使用 JSON 工具类转换
        return JsonUtils.toJsonString(extra);
    }

    private Map<String, String> convertJsonToExtra(String json) {
        if (json == null || json.isEmpty()) {
            return Collections.emptyMap();
        }
        // 使用 JSON 工具类转换
        return JsonUtils.parseObject(json, new TypeReference<Map<String, String>>() {});
    }

}
```

#### 15.3.2 AuthService 完整实现

```java
package com.shengyu.module.system.service.im;

import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.framework.websocket.core.service.AuthService;
import com.shengyu.module.system.api.oauth2.OAuth2TokenApi;
import com.shengyu.module.system.api.oauth2.dto.OAuth2AccessTokenCheckRespDTO;
import com.shengyu.module.system.api.permission.PermissionApi;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

/**
 * 认证服务实现
 *
 * @author shengyu
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class SystemAuthServiceImpl implements AuthService {

    private final OAuth2TokenApi oauth2TokenApi;
    private final PermissionApi permissionApi;

    @Override
    public Long authenticate(String token) {
        log.info("[authenticate] 认证 token: {}", token);

        try {
            // 1. 验证 token
            OAuth2AccessTokenCheckRespDTO tokenInfo = oauth2TokenApi.checkAccessToken(token);
            if (tokenInfo == null) {
                log.warn("[authenticate] token 无效");
                return null;
            }

            // 2. 检查 token 是否过期
            if (tokenInfo.getExpiresTime().isBefore(LocalDateTime.now())) {
                log.warn("[authenticate] token 已过期");
                return null;
            }

            log.info("[authenticate] 认证成功, userId: {}", tokenInfo.getUserId());
            return tokenInfo.getUserId();

        } catch (Exception e) {
            log.error("[authenticate] 认证异常", e);
            return null;
        }
    }

    @Override
    public boolean hasPermission(Long userId, String permission) {
        return permissionApi.hasAnyPermissions(userId, permission);
    }

}
```

### 15.4 核心服务使用指南

#### 15.4.1 NettyMessageSender (消息发送器)

```java
package com.shengyu.framework.websocket.core.sender;

import com.shengyu.framework.websocket.core.message.Message;

/**
 * Netty 消息发送器
 *
 * @author shengyu
 */
public interface NettyMessageSender {

    /**
     * 发送消息给指定用户
     *
     * @param userId 用户ID
     * @param message 消息
     * @return 是否发送成功
     */
    boolean sendToUser(Long userId, Message message);

    /**
     * 发送消息给群组
     *
     * @param groupId 群组ID
     * @param message 消息
     * @param excludeUserId 排除的用户ID(通常是发送者)
     */
    void sendToGroup(Long groupId, Message message, Long excludeUserId);

    /**
     * 广播消息给所有在线用户
     *
     * @param message 消息
     */
    void broadcast(Message message);

}
```

**使用示例**:

```java
@Service
@RequiredArgsConstructor
public class ImMessageServiceImpl implements ImMessageService {

    private final NettyMessageSender messageSender;
    private final MessageStorageService storageService;

    @Override
    public Long sendMessage(MessageSendReqVO reqVO) {
        // 1. 构建消息对象
        Message message = Message.builder()
                .type(MessageType.valueOf(reqVO.getMessageType()))
                .senderId(reqVO.getSenderId())
                .receiverId(reqVO.getReceiverId())
                .groupId(reqVO.getGroupId())
                .content(reqVO.getContent())
                .sequence(generateSequence())
                .timestamp(System.currentTimeMillis())
                .build();

        // 2. 保存消息(通过 SPI 调用)
        Long messageId = storageService.saveMessage(message);
        message.setId(messageId);

        // 3. 推送消息
        if (message.getReceiverId() != null && message.getReceiverId() > 0) {
            // 单聊
            messageSender.sendToUser(message.getReceiverId(), message);
        } else if (message.getGroupId() != null && message.getGroupId() > 0) {
            // 群聊
            messageSender.sendToGroup(message.getGroupId(), message, message.getSenderId());
        }

        return messageId;
    }

}
```

#### 15.4.2 NettySessionManager (会话管理器)

```java
package com.shengyu.framework.websocket.core.session;

import io.netty.channel.Channel;

import java.util.List;

/**
 * Netty 会话管理器
 *
 * @author shengyu
 */
public interface NettySessionManager {

    /**
     * 添加会话
     *
     * @param userId 用户ID
     * @param channel 通道
     */
    void addSession(Long userId, Channel channel);

    /**
     * 移除会话
     *
     * @param userId 用户ID
     */
    void removeSession(Long userId);

    /**
     * 获取通道
     *
     * @param userId 用户ID
     * @return 通道
     */
    Channel getChannel(Long userId);

    /**
     * 获取所有在线用户ID
     *
     * @return 用户ID列表
     */
    List<Long> getOnlineUserIds();

    /**
     * 检查用户是否在线
     *
     * @param userId 用户ID
     * @return 是否在线
     */
    boolean isOnline(Long userId);

}
```

**使用示例**:

```java
@Service
@RequiredArgsConstructor
public class ImUserServiceImpl implements ImUserService {

    private final NettySessionManager sessionManager;

    @Override
    public boolean isUserOnline(Long userId) {
        return sessionManager.isOnline(userId);
    }

    @Override
    public List<Long> getOnlineUsers() {
        return sessionManager.getOnlineUserIds();
    }

    @Override
    public int getOnlineUserCount() {
        return sessionManager.getOnlineUserIds().size();
    }

}
```

### 15.5 消息流转详细流程

```
1. 客户端发送消息
   ↓
2. Netty Server 接收 WebSocket 消息
   ↓
3. MessageDecoder 解码消息(Protobuf -> Message 对象)
   ↓
4. MessageProcessor 处理消息
   ├─> 4.1 验证消息合法性
   ├─> 4.2 调用 MessageStorageService.saveMessage()
   │        ↓
   │        System 模块实现
   │        ├─> 保存到 im_message 表
   │        ├─> 更新 im_conversation 表
   │        └─> 返回消息ID
   │
   ├─> 4.3 发送 ACK 给发送者
   │        ↓
   │        MessageAck { messageId, success }
   │
   └─> 4.4 推送消息给接收者
            ↓
            单聊: NettyMessageSender.sendToUser(receiverId, message)
            群聊: NettyMessageSender.sendToGroup(groupId, message, senderId)
            ↓
            NettySessionManager.getChannel(userId)
            ↓
            Channel.writeAndFlush(message)
```

### 15.6 Protobuf 协议详解

中间件使用 Protobuf 作为通信协议,提供高效的序列化/反序列化。

**消息包结构**:

```protobuf
message WebSocketPacket {
  PacketType type = 1;      // 包类型
  bytes payload = 2;        // 负载数据(具体消息的序列化结果)
  int64 sequence = 3;       // 序列号
  int64 timestamp = 4;      // 时间戳
}
```

**包类型**:
- `HEARTBEAT (0)`: 心跳包
- `AUTH (1)`: 认证包
- `MESSAGE (2)`: 消息包
- `ACK (3)`: 确认包
- `READ_RECEIPT (4)`: 已读回执
- `TYPING (5)`: 正在输入
- `ERROR (6)`: 错误包

**编解码流程**:

```java
// 编码: Message -> Protobuf bytes
public byte[] encode(Message message) {
    // 1. 构建 Protobuf 消息
    MessageProto proto = MessageProto.newBuilder()
            .setId(message.getId())
            .setType(message.getType().getValue())
            .setSenderId(message.getSenderId())
            .setReceiverId(message.getReceiverId())
            .setGroupId(message.getGroupId())
            .setContent(message.getContent())
            .setSequence(message.getSequence())
            .setTimestamp(message.getTimestamp())
            .build();

    // 2. 构建 WebSocket 包
    WebSocketPacket packet = WebSocketPacket.newBuilder()
            .setType(PacketType.MESSAGE)
            .setPayload(proto.toByteString())
            .setSequence(message.getSequence())
            .setTimestamp(System.currentTimeMillis())
            .build();

    // 3. 序列化为字节数组
    return packet.toByteArray();
}

// 解码: Protobuf bytes -> Message
public Message decode(byte[] bytes) {
    // 1. 解析 WebSocket 包
    WebSocketPacket packet = WebSocketPacket.parseFrom(bytes);

    // 2. 解析消息
    MessageProto proto = MessageProto.parseFrom(packet.getPayload());

    // 3. 转换为 Message 对象
    return Message.builder()
            .id(proto.getId())
            .type(MessageType.valueOf(proto.getType()))
            .senderId(proto.getSenderId())
            .receiverId(proto.getReceiverId())
            .groupId(proto.getGroupId())
            .content(proto.getContent())
            .sequence(proto.getSequence())
            .timestamp(proto.getTimestamp())
            .build();
}
```

### 15.7 配置指南

#### 15.7.1 application.yml 配置

```yaml
shengyu:
  websocket:
    # WebSocket 服务端口
    port: 9090
    # 路径
    path: /ws
    # 最大连接数
    max-connections: 10000
    # 心跳超时时间(秒)
    heartbeat-timeout: 90
    # 是否启用 SSL
    ssl-enabled: false
    # Boss 线程数
    boss-threads: 1
    # Worker 线程数(默认为 CPU 核心数 * 2)
    worker-threads: 0
    # 消息最大长度(字节)
    max-frame-size: 65536
```

#### 15.7.2 Spring Bean 配置

```java
package com.shengyu.module.system.config;

import com.shengyu.framework.websocket.core.service.AuthService;
import com.shengyu.framework.websocket.core.service.MessageStorageService;
import com.shengyu.module.system.service.im.SystemAuthServiceImpl;
import com.shengyu.module.system.service.im.SystemMessageStorageServiceImpl;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * IM WebSocket 配置
 *
 * @author shengyu
 */
@Configuration
public class ImWebSocketConfig {

    @Bean
    public MessageStorageService messageStorageService(
            ImMessageMapper messageMapper,
            ImConversationService conversationService,
            ImGroupUserMapper groupUserMapper) {
        return new SystemMessageStorageServiceImpl(
                messageMapper, conversationService, groupUserMapper);
    }

    @Bean
    public AuthService authService(
            OAuth2TokenApi oauth2TokenApi,
            PermissionApi permissionApi) {
        return new SystemAuthServiceImpl(oauth2TokenApi, permissionApi);
    }

}
```

### 15.8 客户端连接示例 (uni-app x)

```typescript
// WebSocket 连接管理
class WebSocketManager {
  private ws: WebSocket | null = null;
  private heartbeatTimer: number | null = null;
  private reconnectTimer: number | null = null;
  private reconnectCount: number = 0;
  private maxReconnect: number = 5;

  // 连接 WebSocket
  connect(token: string) {
    const url = `wss://api.example.com/ws`;
    
    this.ws = uni.connectSocket({
      url: url,
      header: {
        'Authorization': `Bearer ${token}`
      },
      success: () => {
        console.log('WebSocket 连接成功');
      },
      fail: (err) => {
        console.error('WebSocket 连接失败', err);
      }
    });

    // 监听连接打开
    this.ws.onOpen(() => {
      console.log('WebSocket 已打开');
      this.reconnectCount = 0;
      
      // 发送认证请求
      this.sendAuth(token);
      
      // 启动心跳
      this.startHeartbeat();
    });

    // 监听消息
    this.ws.onMessage((res) => {
      this.handleMessage(res.data);
    });

    // 监听关闭
    this.ws.onClose(() => {
      console.log('WebSocket 已关闭');
      this.stopHeartbeat();
      this.reconnect(token);
    });

    // 监听错误
    this.ws.onError((err) => {
      console.error('WebSocket 错误', err);
    });
  }

  // 发送认证请求
  private sendAuth(token: string) {
    const authPacket = {
      type: 'AUTH',
      payload: {
        token: token,
        userId: getUserId(),
        tenantId: getTenantId()
      },
      sequence: Date.now(),
      timestamp: Date.now()
    };
    
    this.send(authPacket);
  }

  // 发送消息
  send(data: any) {
    if (this.ws && this.ws.readyState === 1) {
      this.ws.send({
        data: JSON.stringify(data)
      });
    }
  }

  // 处理接收到的消息
  private handleMessage(data: string) {
    try {
      const packet = JSON.parse(data);
      
      switch (packet.type) {
        case 'AUTH_RESPONSE':
          this.handleAuthResponse(packet.payload);
          break;
        case 'MESSAGE':
          this.handleNewMessage(packet.payload);
          break;
        case 'ACK':
          this.handleAck(packet.payload);
          break;
        case 'READ_RECEIPT':
          this.handleReadReceipt(packet.payload);
          break;
        case 'HEARTBEAT':
          // 心跳响应,无需处理
          break;
        default:
          console.warn('未知消息类型', packet.type);
      }
    } catch (e) {
      console.error('消息解析失败', e);
    }
  }

  // 处理认证响应
  private handleAuthResponse(payload: any) {
    if (payload.success) {
      console.log('认证成功', payload);
      // 触发认证成功事件
      uni.$emit('ws:auth:success', payload);
    } else {
      console.error('认证失败', payload.message);
      // 触发认证失败事件
      uni.$emit('ws:auth:fail', payload);
    }
  }

  // 处理新消息
  private handleNewMessage(message: any) {
    console.log('收到新消息', message);
    // 触发新消息事件
    uni.$emit('ws:message:new', message);
  }

  // 处理 ACK 确认
  private handleAck(ack: any) {
    console.log('收到 ACK', ack);
    // 触发 ACK 事件
    uni.$emit('ws:message:ack', ack);
  }

  // 处理已读回执
  private handleReadReceipt(receipt: any) {
    console.log('收到已读回执', receipt);
    // 触发已读回执事件
    uni.$emit('ws:message:read', receipt);
  }

  // 启动心跳
  private startHeartbeat() {
    this.heartbeatTimer = setInterval(() => {
      this.send({
        type: 'HEARTBEAT',
        timestamp: Date.now()
      });
    }, 30000); // 30秒一次
  }

  // 停止心跳
  private stopHeartbeat() {
    if (this.heartbeatTimer) {
      clearInterval(this.heartbeatTimer);
      this.heartbeatTimer = null;
    }
  }

  // 重连
  private reconnect(token: string) {
    if (this.reconnectCount >= this.maxReconnect) {
      console.error('重连失败,已达最大重连次数');
      return;
    }

    this.reconnectCount++;
    const delay = Math.min(1000 * Math.pow(2, this.reconnectCount), 30000);

    console.log(`${delay}ms 后进行第 ${this.reconnectCount} 次重连...`);

    this.reconnectTimer = setTimeout(() => {
      this.connect(token);
    }, delay);
  }

  // 关闭连接
  close() {
    this.stopHeartbeat();
    
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = null;
    }

    if (this.ws) {
      this.ws.close();
      this.ws = null;
    }
  }
}

// 导出单例
export const wsManager = new WebSocketManager();
```

### 15.9 性能指标与优化

#### 15.9.1 性能指标

| 指标 | 目标值 | 说明 |
|------|--------|------|
| 并发连接数 | 10,000+ | 单机支持的最大连接数 |
| 消息吞吐量 | 10,000 msg/s | 每秒处理的消息数 |
| 消息延迟 | < 100ms | 消息从发送到接收的延迟 |
| 心跳间隔 | 30s | 客户端心跳发送间隔 |
| 心跳超时 | 90s | 服务端心跳超时时间 |
| 重连延迟 | 指数退避 | 1s, 2s, 4s, 8s, 16s, 30s |

#### 15.9.2 优化建议

**1. 连接管理优化**

```java
// 使用 ConcurrentHashMap 管理 Session
private final ConcurrentHashMap<Long, Channel> sessions = new ConcurrentHashMap<>();

// 定期清理无效连接
@Scheduled(fixedRate = 60000) // 每分钟执行一次
public void cleanInactiveSessions() {
    sessions.entrySet().removeIf(entry -> {
        Channel channel = entry.getValue();
        return !channel.isActive();
    });
}
```

**2. 消息推送优化**

```java
// 使用异步推送
public CompletableFuture<Boolean> sendToUserAsync(Long userId, Message message) {
    return CompletableFuture.supplyAsync(() -> {
        Channel channel = sessions.get(userId);
        if (channel != null && channel.isActive()) {
            channel.writeAndFlush(message);
            return true;
        }
        return false;
    }, executor);
}

// 批量推送
public void batchSendToUsers(List<Long> userIds, Message message) {
    List<CompletableFuture<Boolean>> futures = userIds.stream()
            .map(userId -> sendToUserAsync(userId, message))
            .collect(Collectors.toList());
    
    CompletableFuture.allOf(futures.toArray(new CompletableFuture[0])).join();
}
```

**3. 内存优化**

```java
// 使用对象池减少 GC
private final ObjectPool<Message> messagePool = new GenericObjectPool<>(
    new MessagePooledObjectFactory());

// 使用 Netty 的 ByteBuf 池
PooledByteBufAllocator allocator = PooledByteBufAllocator.DEFAULT;
```

### 15.10 监控与运维

#### 15.10.1 监控指标

```java
@Component
public class WebSocketMetrics {

    private final MeterRegistry meterRegistry;

    // 在线用户数
    public void recordOnlineUsers(int count) {
        meterRegistry.gauge("websocket.online.users", count);
    }

    // 消息发送量
    public void recordMessageSent() {
        meterRegistry.counter("websocket.message.sent").increment();
    }

    // 消息接收量
    public void recordMessageReceived() {
        meterRegistry.counter("websocket.message.received").increment();
    }

    // 消息延迟
    public void recordMessageLatency(long latency) {
        meterRegistry.timer("websocket.message.latency")
                .record(latency, TimeUnit.MILLISECONDS);
    }

    // 连接建立
    public void recordConnectionEstablished() {
        meterRegistry.counter("websocket.connection.established").increment();
    }

    // 连接断开
    public void recordConnectionClosed() {
        meterRegistry.counter("websocket.connection.closed").increment();
    }

}
```

#### 15.10.2 日志记录

```java
@Slf4j
public class WebSocketLogger {

    // 连接日志
    public void logConnection(Long userId, String channelId) {
        log.info("[WebSocket] 用户连接: userId={}, channelId={}", userId, channelId);
    }

    // 断开日志
    public void logDisconnection(Long userId, String reason) {
        log.info("[WebSocket] 用户断开: userId={}, reason={}", userId, reason);
    }

    // 消息日志
    public void logMessage(Message message) {
        log.debug("[WebSocket] 消息: id={}, type={}, senderId={}, receiverId={}", 
                 message.getId(), message.getType(), 
                 message.getSenderId(), message.getReceiverId());
    }

    // 错误日志
    public void logError(String operation, Throwable e) {
        log.error("[WebSocket] 操作失败: operation={}", operation, e);
    }

}
```

### 15.11 常见问题与解决方案

#### 问题 1: 消息丢失

**原因**:
- 网络不稳定导致连接断开
- 服务端重启导致内存中的消息丢失

**解决方案**:
- 使用消息序列号(`sequence`)进行去重和补偿
- 客户端记录最后接收的消息ID,重连后拉取离线消息
- 服务端使用消息队列(如 RabbitMQ)进行消息持久化

#### 问题 2: 消息重复

**原因**:
- 网络抖动导致重发
- 客户端重连后重复发送

**解决方案**:
- 使用全局唯一的消息序列号(`sequence`)
- 服务端根据序列号去重

```java
// 使用 Redis 记录已处理的消息序列号
public boolean isDuplicateMessage(Long sequence) {
    String key = "im:message:sequence:" + sequence;
    Boolean exists = redisTemplate.hasKey(key);
    if (Boolean.TRUE.equals(exists)) {
        return true;
    }
    // 记录序列号,过期时间 5 分钟
    redisTemplate.opsForValue().set(key, "1", 5, TimeUnit.MINUTES);
    return false;
}
```

#### 问题 3: 连接数过多

**原因**:
- 单机连接数达到上限
- 资源不足

**解决方案**:
- 使用负载均衡,多台服务器分担连接
- 使用 Redis 存储 Session,实现跨服务器消息推送
- 优化 Netty 配置,提高单机连接数

```yaml
shengyu:
  websocket:
    max-connections: 50000
    worker-threads: 16
```

---

## 文档结束

本文档提供了完整的 IM 即时通讯系统设计方案,包括:
- 数据库设计(5张核心表)
- Protobuf 协议定义
- WebSocket 连接与消息流程
- 移动端页面交互逻辑
- 后端 API 接口设计(会话、消息、联系人、群组)
- System 模块与中间件集成
- 缓存设计与性能优化
- 详细的任务拆解清单(60+ 任务项)
- 后端实现详细指南(基于现有代码模式)
- WebSocket 中间件集成指南(SPI 接口实现)

**企业内部IM特性**:
- 联系人直接来源于 `system_users` 表(同租户)
- 部门信息直接来源于 `system_dept` 表
- 无需添加好友、好友申请、拉黑等社交功能
- 仅提供个性化设置(备注名、星标、免打扰)

**预计开发周期**: 25 天
- 阶段 1: 数据库设计 (2天)
- 阶段 2: 后端基础框架 (3天)
- 阶段 3: WebSocket 中间件集成 (3天)
- 阶段 4: REST API 接口开发 (4天)
- 阶段 5: 移动端开发 (10天)
- 阶段 6: 测试与优化 (3天)

---

**版本历史**:
- v1.0.0 (2026-02-11): 初始版本
- v1.0.1 (2026-02-11): 优化为企业内部IM,移除社交功能
- v1.0.2 (2026-02-11): 添加后端实现指南和中间件集成指南
- v1.0.3 (2026-02-11): 
  - 更新为基于 Netty + Protobuf 的高性能架构
  - 调整 SPI 接口定义,与中间件实际实现完全匹配
  - 补充多设备支持、租户隔离、分布式部署说明
  - 优化性能指标和监控方案
  - 统一使用 Protobuf 协议定义

**文档维护**: shengyu 开发团队

**中间件版本**: shengyu-spring-boot-starter-websocket v1.0.0
