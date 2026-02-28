# 设计文档: 完整的企业级 IM 消息系统

## 概述

本设计实现一个完整的、高效的、规范的企业级 IM 即时通讯系统，基于现有的 WebSocket 中间件 (shengyu-spring-boot-starter-websocket) 构建。该中间件已提供底层的连接管理、协议处理、消息路由等核心能力，支持 50w+ 并发连接。

### 现有基础设施

**重要**: 以下基础设施已经存在，本设计将集成和扩展这些功能:

1. **数据库表** (已存在于 `sql/mysql/1.0/im/ddl_im_tables.sql`):
   - im_message (消息表)
   - im_conversation (会话表)
   - im_group (群组表)
   - im_group_member (群成员表)
   - im_message_read (消息已读表)
   - im_contact_setting (联系人设置表)
   - im_group_invite (群邀请码表)
   - im_group_file (群文件关联表)
   - im_group_folder (群文件夹表)

2. **文件上传服务** (已实现):
   - 后端 API: `AppFileController` - `/app-api/infra/file/upload`
   - 前端工具: `utils/upload.uts` (支持图片、视频、文件上传)
   - 群文件管理: `AppImGroupFileController` (支持群文件上传、列表、删除、下载统计)

3. **角标通知服务** (已实现 - 参见 im-badge-notifications spec):
   - 后端: ImBadgeService (角标数据计算和推送)
   - 前端: BadgeService (services/badge-service.uts)
   - WebSocket: BADGE_UPDATE 消息处理 (messageType = 204)
   - UI 集成: message.uvue, index.uvue, workbench.uvue
   - 功能: 消息角标、菜单角标、多端同步、本地缓存

4. **需要新增的功能**:
   - im_call_record 表 (通话记录)
   - im_notification 表 (系统通知)
   - 消息服务实现 (ImMessageService)
   - 会话服务实现 (ImConversationService)
   - 群组服务实现 (ImGroupService)
   - WebSocket 中间件 SPI 实现
   - 移动端 IM 服务和界面

### 核心特性

1. **完整的消息功能**: 单聊、群聊、7种消息类型、消息状态管理
2. **高级交互功能**: 已读回执、消息撤回、转发、引用回复、@提醒、正在输入
3. **实时通话支持**: 语音/视频通话信令处理、通话记录管理
4. **业务通知集成**: 系统公告、自定义通知
5. **性能优化**: 虚拟滚动、智能缓存、懒加载、消息预加载
6. **多端同步**: 消息同步、已读同步、会话同步、设置同步
7. **离线处理**: 离线消息拉取、离线推送、消息队列管理
8. **高可用架构**: 分布式部署、负载均衡、故障转移、租户隔离

### 技术栈

- **后端**: Spring Boot 2.7.18 + Netty 4.1.x + Protobuf 3.x
- **前端**: uni-app x (UTS 语言)
- **中间件**: shengyu-spring-boot-starter-websocket
- **数据库**: MySQL 8.0+ (消息存储、会话管理)
- **缓存**: Redis 5.0+ (会话共享、消息缓存、未读数缓存)
- **消息总线**: Redis Pub/Sub (推荐) / RocketMQ / Kafka
- **对象存储**: 阿里云 OSS / 腾讯云 COS (文件、图片、语音、视频)
- **推送服务**: 极光推送 / 个推 (离线推送)

### 设计原则

1. **职责分离**: 中间件负责通信，业务层负责逻辑
2. **高性能**: 支持海量并发，低延迟，高吞吐
3. **高可用**: 分布式部署，故障转移，数据冗余
4. **可扩展**: SPI 接口，插件化设计，支持自定义扩展
5. **易维护**: 清晰的分层架构，完整的文档和测试

## 架构

### 整体架构图

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          移动端 (uni-app x)                              │
│                                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────┐  │
│  │ 会话列表页   │  │ 聊天页面     │  │ 联系人页面   │  │ 工作台   │  │
│  │ (message)    │  │ (chat)       │  │ (contacts)   │  │ (work)   │  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └────┬─────┘  │
│         │                  │                  │               │         │
│         └──────────────────┴──────────────────┴───────────────┘         │
│                            ↓                                             │
│         ┌──────────────────────────────────────────────────┐           │
│         │              服务层 (Services)                    │           │
│         │  ┌──────────────┐  ┌──────────────┐            │           │
│         │  │MessageService│  │ConversationSvc│            │           │
│         │  └──────┬───────┘  └──────┬───────┘            │           │
│         │  ┌──────────────┐  ┌──────────────┐            │           │
│         │  │ BadgeService │  │ CallService  │            │           │
│         │  └──────┬───────┘  └──────┬───────┘            │           │
│         └─────────┼──────────────────┼─────────────────────┘           │
│                   │                  │                                  │
│         ┌─────────┴──────────────────┴─────────────────────┐           │
│         │           工具层 (Utils)                          │           │
│         │  - avatar.uts: 头像生成                          │           │
│         │  - storage.uts: 本地存储                         │           │
│         │  - cache.uts: 缓存管理                           │           │
│         │  - emoji.uts: 表情解析                           │           │
│         └─────────┬──────────────────────────────────────────┘           │
│                   │                                                      │
│         ┌─────────┴──────────────────────────────────────────┐           │
│         │           传输层 (Transport)                       │           │
│         │  - websocket.uts: WebSocket 连接管理              │           │
│         │  - request.uts: HTTP 请求封装                     │           │
│         └─────────┬──────────────────────────────────────────┘           │
└───────────────────┼──────────────────────────────────────────────────────┘
                    ↓
    ┌───────────────┴───────────────────────────────────────────────────┐
    │          WebSocket 中间件 (Netty + Protobuf)                      │
    │                                                                    │
    │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
    │  │ NettyServer  │  │SessionManager│  │MessageSender │          │
    │  │ (连接管理)   │  │ (会话管理)   │  │ (消息发送)   │          │
    │  └──────────────┘  └──────────────┘  └──────────────┘          │
    │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
    │  │ AuthHandler  │  │HeartbeatHdlr │  │MessageRouter │          │
    │  │ (认证处理)   │  │ (心跳保活)   │  │ (消息路由)   │          │
    │  └──────────────┘  └──────────────┘  └──────────────┘          │
    └───────────────────────┬────────────────────────────────────────────┘
                            ↓ 消息总线 (Redis Pub/Sub)
    ┌───────────────────────┴────────────────────────────────────────────┐
    │                  后端业务层 (Spring Boot)                          │
    │                                                                    │
    │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
    │  │ImMessageSvc  │  │ImConversation│  │ ImGroupSvc   │          │
    │  │ (消息服务)   │  │Svc (会话服务)│  │ (群组服务)   │          │
    │  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
    │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
    │  │ImNotifySvc   │  │ ImCallSvc    │  │ ImBadgeSvc   │          │
    │  │ (通知服务)   │  │ (通话服务)   │  │ (角标服务)   │          │
    │  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
    │         │                  │                  │                   │
    │         └──────────────────┴──────────────────┘                   │
    │                            ↓                                       │
    │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
    │  │ MySQL        │  │ Redis        │  │ OSS          │          │
    │  │ (消息存储)   │  │ (缓存/会话)  │  │ (文件存储)   │          │
    │  └──────────────┘  └──────────────┘  └──────────────┘          │
    └────────────────────────────────────────────────────────────────────┘
```

### 分层职责

#### 移动端 (uni-app x)

**UI 层**:
- 会话列表页: 显示所有会话、未读数、最后消息
- 聊天页面: 显示消息列表、输入框、消息操作
- 联系人页面: 显示好友列表、群组列表
- 工作台: 显示菜单角标

**服务层**:
- MessageService: 消息发送、接收、存储、状态管理
- ConversationService: 会话管理、排序、置顶、免打扰
- BadgeService: 角标管理、实时更新、多端同步 (已实现 - 参见 im-badge-notifications spec)
- CallService: 通话信令处理、通话状态管理

**工具层**:
- avatar.uts: 头像文本生成、颜色生成
- storage.uts: 本地数据库、本地存储
- cache.uts: 内存缓存、LRU 淘汰
- emoji.uts: 表情符号解析

**传输层**:
- websocket.uts: WebSocket 连接、断线重连、心跳保活
- request.uts: HTTP 请求、错误处理、重试机制

#### WebSocket 中间件

**核心组件**:
- NettyServer: Netty 服务器启动和管理
- NettySessionManager: 会话管理、多端登录互踢
- NettyMessageSender: 消息发送、单播/多播/广播
- AuthHandler: 认证处理、Token 验证
- HeartbeatHandler: 心跳检测、空闲超时
- MessageRouter: 消息路由、处理器分发

**协议支持**:
- WebSocket + JSON: Web 浏览器、小程序
- WebSocket + Protobuf: 移动端 (体积小3-10倍，速度快20-100倍)

#### 后端业务层 (Spring Boot)

**核心服务**:
- ImMessageService: 消息存储、查询、状态更新
- ImConversationService: 会话管理、未读数计算
- ImGroupService: 群组管理、成员管理、权限控制
- ImNotifyService: 通知管理、推送调度
- ImCallService: 通话记录、信令转发
- ImBadgeService: 角标计算、实时推送 (已实现 - 参见 im-badge-notifications spec)

**数据存储**:
- MySQL: 消息表、会话表、群组表、用户表 (已存在: im_message, im_conversation, im_group, im_group_member, im_message_read, im_group_file, im_group_folder)
- Redis: 会话缓存、未读数缓存、在线状态
- OSS: 图片、语音、视频、文件存储 (通过 AppFileController 统一管理)


### 消息流转流程

#### 单聊消息流程

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          发送方客户端                                    │
│  1. 用户输入消息并点击发送                                              │
│  2. MessageService.sendTextMessage()                                   │
│  3. 生成消息 ID (雪花算法)                                              │
│  4. 构建 ImMessage (Protobuf)                                          │
│  5. 通过 WebSocket 发送 (messageType=100)                              │
│  6. 乐观更新 UI (显示"发送中")                                          │
└──────────────────────────┬──────────────────────────────────────────────┘
                           ↓ WebSocket (Protobuf)
┌──────────────────────────┴──────────────────────────────────────────────┐
│                    WebSocket 中间件 (Netty)                             │
│  1. MessageHandler 接收消息                                             │
│  2. 解析 Protobuf 消息                                                  │
│  3. 调用 MessageProcessor.process()                                    │
│  4. 调用 MessageStorageService.saveMessage() (SPI)                     │
│  5. 查找接收者的在线会话                                                │
│  6. 通过 NettyMessageSender 推送到接收者                               │
│  7. 返回发送确认到发送方                                                │
└──────────────────────────┬──────────────────────────────────────────────┘
                           ↓ SPI 调用
┌──────────────────────────┴──────────────────────────────────────────────┐
│                      后端业务层 (Spring Boot)                           │
│  1. ImMessageServiceImpl.saveMessage()                                 │
│  2. 保存消息到数据库 (im_message 表)                                   │
│  3. 更新会话最后消息 (im_conversation 表)                              │
│  4. 增加接收者未读数                                                    │
│  5. 如果接收者离线，调用 OfflinePushService 推送通知                   │
│  6. 推送角标更新到接收者的所有设备                                      │
└──────────────────────────┬──────────────────────────────────────────────┘
                           ↓ WebSocket (Protobuf)
┌──────────────────────────┴──────────────────────────────────────────────┐
│                          接收方客户端                                    │
│  1. WebSocket 接收消息 (messageType=100)                               │
│  2. MessageService.handleReceivedMessage()                             │
│  3. 解析消息内容                                                        │
│  4. 保存到本地数据库                                                    │
│  5. 通知消息监听器                                                      │
│  6. 更新 UI 显示新消息                                                  │
│  7. 增加会话未读数                                                      │
│  8. 更新角标显示                                                        │
└─────────────────────────────────────────────────────────────────────────┘
```

#### 群聊消息流程

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          发送方客户端                                    │
│  1. 用户在群聊输入消息并发送                                            │
│  2. MessageService.sendGroupMessage()                                  │
│  3. 构建 ImMessage (包含 groupId)                                      │
│  4. 通过 WebSocket 发送                                                │
└──────────────────────────┬──────────────────────────────────────────────┘
                           ↓
┌──────────────────────────┴──────────────────────────────────────────────┐
│                    WebSocket 中间件 (Netty)                             │
│  1. 接收群聊消息                                                        │
│  2. 调用 MessageStorageService 保存消息                                │
│  3. 查询群成员列表 (调用业务层接口)                                    │
│  4. 遍历群成员，推送消息到所有在线成员                                  │
│  5. 使用消息总线广播到其他服务器节点                                    │
└──────────────────────────┬──────────────────────────────────────────────┘
                           ↓
┌──────────────────────────┴──────────────────────────────────────────────┐
│                      后端业务层 (Spring Boot)                           │
│  1. 保存群聊消息到数据库                                                │
│  2. 更新所有群成员的会话                                                │
│  3. 增加所有群成员的未读数 (除发送者外)                                │
│  4. 如果消息包含@提醒，标记被@的成员                                    │
│  5. 推送角标更新到所有群成员                                            │
└──────────────────────────┬──────────────────────────────────────────────┘
                           ↓
┌──────────────────────────┴──────────────────────────────────────────────┐
│                          接收方客户端 (所有群成员)                       │
│  1. 接收群聊消息                                                        │
│  2. 保存到本地数据库                                                    │
│  3. 如果当前在该群聊页面，显示消息                                      │
│  4. 如果不在该群聊页面，增加未读数和角标                                │
│  5. 如果被@，显示特殊通知                                               │
└─────────────────────────────────────────────────────────────────────────┘
```

### 多端登录和互踢策略

```
设备类型定义:
- 1: Web 浏览器
- 2: iPhone
- 3: Android 手机
- 4: 小程序
- 5: iPad
- 6: Mac 电脑
- 7: Windows 电脑

互踢规则:
- 同类型设备只允许一个在线 (如只能一个手机在线)
- 不同类型设备可以同时在线 (如手机+电脑+平板)

示例场景:
用户 A 当前在线设备:
- iPhone (设备类型2) ✅
- iPad (设备类型5) ✅
- Mac (设备类型6) ✅

用户 A 在另一台 iPhone 登录:
- iPhone 1 (设备类型2) ❌ 被踢下线 (收到 CLOSE 消息)
- iPhone 2 (设备类型2) ✅ 新设备上线
- iPad (设备类型5) ✅ 保持在线
- Mac (设备类型6) ✅ 保持在线
```

### 消息类型映射

根据 WebSocket 中间件的 Protobuf 协议定义，系统使用两套消息类型编号:

**REST API (历史消息查询)**:
- 1: 文本消息
- 2: 图片消息
- 3: 语音消息
- 4: 视频消息
- 5: 文件消息
- 6: 位置消息

**WebSocket/Protobuf (实时消息)**:
- 100: TEXT (文本消息)
- 101: IMAGE (图片消息)
- 102: VOICE (语音消息)
- 103: VIDEO (视频消息)
- 104: FILE (文件消息)
- 105: LOCATION (位置消息)
- 106: CUSTOM (自定义消息)
- 200: SYSTEM_NOTIFY (系统通知)
- 201: READ_RECEIPT (已读回执)
- 202: RECALL (消息撤回)
- 203: TYPING (正在输入)
- 204: BADGE_UPDATE (角标更新)

**前端统一处理**: 创建类型转换函数，将两种格式统一转换为字符串类型 ('text', 'image', 'voice', 'video', 'file', 'location')

## 与现有系统的集成

### 集成 im-badge-notifications spec

本系统将集成 im-badge-notifications spec 中已实现的完整角标通知功能，而不是重新实现。

**已实现的组件** (im-badge-notifications spec):

1. **后端 ImBadgeService**:
   - 位置: `shengyu-module-system/.../service/im/ImBadgeService.java`
   - 功能: 角标数据计算、WebSocket 推送、菜单角标管理
   - 方法: getUserBadgeData, pushBadgeUpdate, calculateTotalUnread, getConversationBadges, getMenuBadges

2. **前端 BadgeService**:
   - 位置: `services/badge-service.uts`
   - 功能: 角标数据管理、BADGE_UPDATE 消息处理、本地缓存、监听器机制
   - 方法: getTotalUnread, getConversationBadge, incrementConversationBadge, clearConversationBadge, handleBadgeUpdate, syncFromServer

3. **UI 组件集成**:
   - message.uvue: 会话列表角标显示
   - index.uvue: 底部导航栏角标 (uni.setTabBarBadge)
   - workbench.uvue: 工作台菜单角标

4. **WebSocket 消息处理**:
   - message-service.uts: BADGE_UPDATE (messageType = 204) 消息路由到 BadgeService

**集成要点**:

1. **MessageStorageService 集成**:
   ```java
   @Resource
   private ImBadgeService badgeService;
   
   @Override
   public void saveMessage(ImMessage message) {
       // ... 保存消息逻辑
       
       // 推送角标更新 (调用已实现的服务)
       badgeService.pushBadgeUpdate(receiverId);
   }
   ```

2. **MessageService 集成**:
   ```typescript
   import { badgeService } from '@/services/badge-service'
   
   private handleReceivedMessage(message: MessageItem): void {
       // ... 保存消息
       
       // 更新角标 (调用已实现的服务)
       badgeService.incrementConversationBadge(message.conversationId)
   }
   ```

3. **ConversationService 集成**:
   ```typescript
   public clearUnread(conversationId: number): void {
       // ... 清空未读数
       
       // 清空角标 (调用已实现的服务)
       badgeService.clearConversationBadge(conversationId)
   }
   ```

**验证要点**:
- 确保新消息功能不破坏现有角标通知
- 确保 MessageStorageService 正确调用 ImBadgeService
- 确保 MessageService 正确调用 BadgeService
- 确保角标在所有场景下正确更新 (新消息、已读、多端同步)

## 组件和接口

### 1. 移动端核心组件

#### 1.1 MessageService (消息服务)

**位置**: `shengyu-ui/shengyu-ui-admin-uniappx/services/message-service.uts`

**职责**:
- 消息发送和接收
- 消息状态管理
- 消息本地存储
- WebSocket 消息处理
- 消息监听器管理

**核心接口**:

```typescript
class MessageService {
  // WebSocket 连接
  private websocket: WebSocketClient
  
  // 消息监听器
  private listeners: Array<MessageListener>
  
  // 发送队列
  private sendQueue: Array<ImMessage>
  
  // 当前用户 ID
  private currentUserId: number
  
  /**
   * 初始化消息服务
   */
  public init(userId: number, token: string): void
  
  /**
   * 发送文本消息
   */
  public sendTextMessage(
    receiverId: number | null,
    groupId: number | null,
    content: string
  ): Promise<MessageItem>
  
  /**
   * 发送图片消息
   */
  public sendImageMessage(
    receiverId: number | null,
    groupId: number | null,
    imageUrl: string,
    width: number,
    height: number,
    size: number
  ): Promise<MessageItem>
  
  /**
   * 发送语音消息
   */
  public sendVoiceMessage(
    receiverId: number | null,
    groupId: number | null,
    voiceUrl: string,
    duration: number
  ): Promise<MessageItem>
  
  /**
   * 发送视频消息
   */
  public sendVideoMessage(
    receiverId: number | null,
    groupId: number | null,
    videoUrl: string,
    coverUrl: string,
    duration: number,
    width: number,
    height: number
  ): Promise<MessageItem>
  
  /**
   * 发送文件消息
   */
  public sendFileMessage(
    receiverId: number | null,
    groupId: number | null,
    fileUrl: string,
    fileName: string,
    fileSize: number,
    fileType: string
  ): Promise<MessageItem>
  
  /**
   * 发送位置消息
   */
  public sendLocationMessage(
    receiverId: number | null,
    groupId: number | null,
    latitude: number,
    longitude: number,
    address: string
  ): Promise<MessageItem>
  
  /**
   * 撤回消息
   */
  public recallMessage(messageId: number): Promise<boolean>
  
  /**
   * 发送已读回执
   */
  public sendReadReceipt(messageIds: Array<number>): void
  
  /**
   * 发送正在输入状态
   */
  public sendTypingStatus(targetId: number, isTyping: boolean): void
  
  /**
   * 添加消息监听器
   */
  public addListener(listener: MessageListener): void
  
  /**
   * 移除消息监听器
   */
  public removeListener(listener: MessageListener): void
  
  /**
   * 处理接收到的消息
   */
  private handleReceivedMessage(message: ImMessage): void
  
  /**
   * 处理消息发送确认
   */
  private handleMessageAck(messageId: number): void
  
  /**
   * 处理消息撤回通知
   */
  private handleRecallNotify(messageId: number): void
  
  /**
   * 处理已读回执
   */
  private handleReadReceipt(messageIds: Array<number>): void
  
  /**
   * 处理正在输入状态
   */
  private handleTypingStatus(userId: number, isTyping: boolean): void
}

/**
 * 消息监听器接口
 */
interface MessageListener {
  onMessageReceived(message: MessageItem): void
  onMessageStatusChanged(messageId: number, status: string): void
  onMessageRecalled(messageId: number): void
  onTypingStatusChanged(userId: number, isTyping: boolean): void
}
```

#### 1.2 ConversationService (会话服务)

**位置**: `shengyu-ui/shengyu-ui-admin-uniappx/services/conversation-service.uts`

**职责**:
- 会话列表管理
- 会话排序和置顶
- 未读数管理
- 会话设置 (免打扰、标签)

**核心接口**:

```typescript
class ConversationService {
  // 会话列表
  private conversations: Array<ConversationItem>
  
  // 会话监听器
  private listeners: Array<ConversationListener>
  
  /**
   * 获取会话列表
   */
  public getConversations(): Promise<Array<ConversationItem>>
  
  /**
   * 获取单个会话
   */
  public getConversation(conversationId: number): Promise<ConversationItem | null>
  
  /**
   * 创建或更新会话
   */
  public upsertConversation(conversation: ConversationItem): Promise<void>
  
  /**
   * 删除会话
   */
  public deleteConversation(conversationId: number): Promise<void>
  
  /**
   * 置顶会话
   */
  public pinConversation(conversationId: number, isPinned: boolean): Promise<void>
  
  /**
   * 设置免打扰
   */
  public setMute(conversationId: number, isMuted: boolean): Promise<void>
  
  /**
   * 清空未读数
   */
  public clearUnread(conversationId: number): Promise<void>
  
  /**
   * 更新最后消息
   */
  public updateLastMessage(conversationId: number, message: MessageItem): void
  
  /**
   * 增加未读数
   */
  public incrementUnread(conversationId: number, delta: number = 1): void
  
  /**
   * 排序会话列表
   */
  private sortConversations(): void
  
  /**
   * 添加监听器
   */
  public addListener(listener: ConversationListener): void
}

/**
 * 会话监听器接口
 */
interface ConversationListener {
  onConversationUpdated(conversation: ConversationItem): void
  onConversationDeleted(conversationId: number): void
  onUnreadCountChanged(conversationId: number, count: number): void
}
```

#### 1.3 BadgeService (角标服务)

**已实现 - 参见 im-badge-notifications spec**

**位置**: `shengyu-ui/shengyu-ui-admin-uniappx/services/badge-service.uts`

**实现状态**: BadgeService 已在 im-badge-notifications spec 中完整实现，提供以下功能:

**核心功能**:
- 角标数据管理 (totalUnread, conversationBadges, menuBadges)
- WebSocket BADGE_UPDATE 消息处理 (messageType = 204)
- 本地存储和缓存 (localStorage)
- 监听器机制 (BadgeListener)
- 服务器同步 (syncFromServer)

**集成点**:
- MessageService 在接收新消息时调用 BadgeService 更新角标
- ConversationService 在清空未读数时调用 BadgeService
- UI 组件 (message.uvue, index.uvue, workbench.uvue) 监听 BadgeService 更新

**核心接口** (已实现):

```typescript
class BadgeService {
  // 角标数据
  private badgeData: BadgeData
  
  // 监听器
  private listeners: Array<BadgeListener>
  
  /**
   * 初始化角标服务
   */
  public init(): void
  
  /**
   * 获取总未读数
   */
  public getTotalUnread(): number
  
  /**
   * 获取会话未读数
   */
  public getConversationBadge(conversationId: number): number
  
  /**
   * 获取菜单角标
   */
  public getMenuBadge(menuId: string): number
  
  /**
   * 增加会话未读数
   */
  public incrementConversationBadge(conversationId: number, delta: number = 1): void
  
  /**
   * 清空会话未读数
   */
  public clearConversationBadge(conversationId: number): void
  
  /**
   * 更新菜单角标
   */
  public updateMenuBadge(menuId: string, count: number): void
  
  /**
   * 处理 WebSocket BADGE_UPDATE 消息
   */
  public handleBadgeUpdate(message: BadgeUpdateMessage): void
  
  /**
   * 从服务器同步角标数据
   */
  public syncFromServer(): Promise<void>
  
  /**
   * 添加监听器
   */
  public addListener(listener: BadgeListener): void
}

/**
 * 角标数据结构
 */
type BadgeData = {
  totalUnread: number
  conversationBadges: Map<number, number>
  menuBadges: Map<string, number>
  lastUpdateTime: number
}

/**
 * 角标监听器接口
 */
interface BadgeListener {
  onBadgeUpdate(badgeData: BadgeData): void
}
```

**使用示例**:

```typescript
// 在 MessageService 中集成
import { badgeService } from '@/services/badge-service'

// 接收新消息时更新角标
private handleReceivedMessage(message: MessageItem): void {
  // ... 保存消息到本地
  
  // 更新角标
  if (message.conversationId) {
    badgeService.incrementConversationBadge(message.conversationId)
  }
}

// 在 UI 组件中监听角标更新
onMounted(() => {
  badgeService.addListener({
    onBadgeUpdate: (badgeData) => {
      // 更新 UI
      totalUnread.value = badgeData.totalUnread
    }
  })
})
```

#### 1.4 CallService (通话服务)

**位置**: `shengyu-ui/shengyu-ui-admin-uniappx/services/call-service.uts`

**职责**:
- 通话信令处理
- 通话状态管理
- 通话记录保存

**核心接口**:

```typescript
class CallService {
  // 当前通话状态
  private callState: CallState | null
  
  // 通话监听器
  private listeners: Array<CallListener>
  
  /**
   * 发起语音通话
   */
  public initiateVoiceCall(targetUserId: number): Promise<void>
  
  /**
   * 发起视频通话
   */
  public initiateVideoCall(targetUserId: number): Promise<void>
  
  /**
   * 接听通话
   */
  public acceptCall(): Promise<void>
  
  /**
   * 拒绝通话
   */
  public rejectCall(reason: string): Promise<void>
  
  /**
   * 挂断通话
   */
  public hangupCall(): Promise<void>
  
  /**
   * 切换摄像头
   */
  public switchCamera(): Promise<void>
  
  /**
   * 静音/取消静音
   */
  public toggleMute(): void
  
  /**
   * 处理通话信令
   */
  public handleCallSignal(signal: CallSignalMessage): void
  
  /**
   * 保存通话记录
   */
  private saveCallRecord(record: CallRecord): Promise<void>
}

/**
 * 通话状态
 */
type CallState = {
  callId: string
  callType: 'voice' | 'video'
  callerId: number
  calleeId: number
  status: 'calling' | 'connected' | 'ended'
  startTime: number
  endTime: number | null
  duration: number
}

/**
 * 通话监听器接口
 */
interface CallListener {
  onIncomingCall(callerId: number, callType: string): void
  onCallAccepted(): void
  onCallRejected(reason: string): void
  onCallEnded(duration: number): void
}
```


### 2. 后端核心服务

#### 2.1 ImMessageService (消息服务)

**位置**: `shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/service/im/ImMessageService.java`

**职责**:
- 消息存储和查询
- 消息状态更新
- 消息撤回处理
- 消息转发处理

**核心接口**:

```java
public interface ImMessageService {
    
    /**
     * 保存消息
     */
    Long saveMessage(ImMessageSaveReqVO reqVO);
    
    /**
     * 分页查询消息列表
     */
    PageResult<ImMessageRespVO> getMessagePage(ImMessagePageReqVO reqVO);
    
    /**
     * 查询会话的消息列表
     */
    List<ImMessageRespVO> getConversationMessages(Long conversationId, Long lastMessageId, Integer pageSize);
    
    /**
     * 更新消息状态
     */
    void updateMessageStatus(Long messageId, Integer status);
    
    /**
     * 批量更新消息状态
     */
    void batchUpdateMessageStatus(List<Long> messageIds, Integer status);
    
    /**
     * 撤回消息
     */
    void recallMessage(Long userId, Long messageId);
    
    /**
     * 删除消息
     */
    void deleteMessage(Long userId, Long messageId);
    
    /**
     * 转发消息
     */
    Long forwardMessage(Long userId, Long messageId, Long targetConversationId);
    
    /**
     * 搜索消息
     */
    List<ImMessageRespVO> searchMessages(String keyword, Long conversationId, Integer messageType);
    
    /**
     * 获取消息详情
     */
    ImMessageRespVO getMessageDetail(Long messageId);
    
    /**
     * 填充发送者信息
     */
    void fillSenderInfo(ImMessageRespVO message);
}
```

#### 2.2 ImConversationService (会话服务)

**位置**: `shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/service/im/ImConversationService.java`

**职责**:
- 会话创建和管理
- 未读数计算和更新
- 会话设置管理
- 会话列表查询

**核心接口**:

```java
public interface ImConversationService {
    
    /**
     * 获取用户的会话列表
     */
    List<ImConversationRespVO> getUserConversations(Long userId);
    
    /**
     * 获取或创建单聊会话
     */
    ImConversationRespVO getOrCreateSingleConversation(Long userId, Long targetUserId);
    
    /**
     * 获取或创建群聊会话
     */
    ImConversationRespVO getOrCreateGroupConversation(Long userId, Long groupId);
    
    /**
     * 更新会话最后消息
     */
    void updateLastMessage(Long conversationId, ImMessageDO message);
    
    /**
     * 增加未读数
     */
    void incrementUnreadCount(Long conversationId, Long userId);
    
    /**
     * 清空未读数
     */
    void clearUnreadCount(Long conversationId, Long userId);
    
    /**
     * 获取总未读数
     */
    Integer getTotalUnreadCount(Long userId);
    
    /**
     * 置顶会话
     */
    void pinConversation(Long conversationId, Long userId, Boolean isPinned);
    
    /**
     * 设置免打扰
     */
    void setMute(Long conversationId, Long userId, Boolean isMuted);
    
    /**
     * 删除会话
     */
    void deleteConversation(Long conversationId, Long userId);
    
    /**
     * 获取会话角标列表
     */
    List<ConversationBadge> getConversationBadges(Long userId);
}
```

#### 2.3 ImGroupService (群组服务)

**位置**: `shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/service/im/ImGroupService.java`

**职责**:
- 群组创建和管理
- 群成员管理
- 群权限控制
- 群公告管理

**核心接口**:

```java
public interface ImGroupService {
    
    /**
     * 创建群组
     */
    Long createGroup(ImGroupCreateReqVO reqVO);
    
    /**
     * 获取群组信息
     */
    ImGroupRespVO getGroup(Long groupId);
    
    /**
     * 更新群组信息
     */
    void updateGroup(ImGroupUpdateReqVO reqVO);
    
    /**
     * 解散群组
     */
    void dismissGroup(Long groupId, Long operatorId);
    
    /**
     * 添加群成员
     */
    void addMembers(Long groupId, List<Long> userIds, Long operatorId);
    
    /**
     * 移除群成员
     */
    void removeMembers(Long groupId, List<Long> userIds, Long operatorId);
    
    /**
     * 退出群组
     */
    void quitGroup(Long groupId, Long userId);
    
    /**
     * 转让群组
     */
    void transferGroup(Long groupId, Long newOwnerId, Long operatorId);
    
    /**
     * 设置管理员
     */
    void setAdmin(Long groupId, Long userId, Boolean isAdmin, Long operatorId);
    
    /**
     * 禁言成员
     */
    void muteMember(Long groupId, Long userId, Long duration, Long operatorId);
    
    /**
     * 解除禁言
     */
    void unmuteMember(Long groupId, Long userId, Long operatorId);
    
    /**
     * 全员禁言
     */
    void muteAll(Long groupId, Boolean isMuted, Long operatorId);
    
    /**
     * 获取群成员列表
     */
    List<ImGroupMemberRespVO> getGroupMembers(Long groupId);
    
    /**
     * 获取群成员 ID 列表
     */
    List<Long> getGroupMemberIds(Long groupId);
    
    /**
     * 设置群名片
     */
    void setMemberNickname(Long groupId, Long userId, String nickname);
    
    /**
     * 发布群公告
     */
    void publishAnnouncement(Long groupId, String content, Long operatorId);
    
    /**
     * 获取群公告列表
     */
    List<ImGroupAnnouncementRespVO> getAnnouncements(Long groupId);
}
```

#### 2.4 ImNotifyService (通知服务)

**位置**: `shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/service/im/ImNotifyService.java`

**职责**:
- 系统通知发送
- 自定义通知处理

**核心接口**:

```java
public interface ImNotifyService {
    
    /**
     * 发送系统通知
     */
    void sendSystemNotify(Long userId, String title, String content, String type);
    

    /**
     * 发送自定义通知
     */
    void sendCustomNotify(Long userId, CustomNotifyDTO notifyDTO);
    
    /**
     * 广播系统公告
     */
    void broadcastAnnouncement(String title, String content, List<Long> targetUserIds);
    
    /**
     * 获取用户的通知列表
     */
    List<ImNotifyRespVO> getUserNotifications(Long userId, Integer pageSize);
    
    /**
     * 标记通知已读
     */
    void markNotifyAsRead(Long notifyId, Long userId);
    
    /**
     * 删除通知
     */
    void deleteNotify(Long notifyId, Long userId);
}
```

#### 2.5 ImCallService (通话服务)

**位置**: `shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/service/im/ImCallService.java`

**职责**:
- 通话信令转发
- 通话记录保存
- 通话状态管理

**核心接口**:

```java
public interface ImCallService {
    
    /**
     * 发起通话
     */
    String initiateCall(Long callerId, Long calleeId, String callType);
    
    /**
     * 接听通话
     */
    void acceptCall(String callId, Long userId);
    
    /**
     * 拒绝通话
     */
    void rejectCall(String callId, Long userId, String reason);
    
    /**
     * 挂断通话
     */
    void hangupCall(String callId, Long userId);
    
    /**
     * 保存通话记录
     */
    void saveCallRecord(ImCallRecordSaveReqVO reqVO);
    
    /**
     * 获取通话记录列表
     */
    List<ImCallRecordRespVO> getCallRecords(Long userId, Integer pageSize);
    
    /**
     * 转发通话信令
     */
    void forwardCallSignal(CallSignalMessage signal);
}
```

#### 2.6 ImBadgeService (角标服务)

**已实现 - 参见 im-badge-notifications spec**

**位置**: `shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/service/im/ImBadgeService.java`

**实现状态**: ImBadgeService 已在 im-badge-notifications spec 中完整实现，提供以下功能:

**核心功能**:
- 角标数据计算 (calculateTotalUnread, getConversationBadges, getMenuBadges)
- 角标实时推送 (pushBadgeUpdate, pushBadgeUpdateToAllDevices)
- 菜单角标管理 (updateMenuBadge)
- WebSocket BADGE_UPDATE 消息构建和推送

**集成点**:
- MessageStorageService 在保存消息后调用 pushBadgeUpdate
- ConversationService 在清空未读数后调用 pushBadgeUpdate

**核心接口** (已实现):

```java
public interface ImBadgeService {
    
    /**
     * 获取用户的角标数据
     */
    ImBadgeRespVO getUserBadgeData(Long userId);
    
    /**
     * 推送角标更新
     */
    void pushBadgeUpdate(Long userId);
    
    /**
     * 推送角标更新到所有设备
     */
    void pushBadgeUpdateToAllDevices(Long userId);
    
    /**
     * 计算总未读数
     */
    Integer calculateTotalUnread(Long userId);
    
    /**
     * 获取会话角标列表
     */
    List<ConversationBadge> getConversationBadges(Long userId);
    
    /**
     * 获取菜单角标列表
     */
    List<MenuBadge> getMenuBadges(Long userId);
    
    /**
     * 更新菜单角标
     */
    void updateMenuBadge(Long userId, String menuId, Integer count);
}
```

**使用示例**:

```java
// 在 MessageStorageServiceImpl 中集成
@Resource
private ImBadgeService badgeService;

@Override
public void saveMessage(ImMessage message) {
    // ... 保存消息逻辑
    
    // 推送角标更新
    if (header.getReceiverId() > 0) {
        badgeService.pushBadgeUpdate(header.getReceiverId());
    } else if (header.getGroupId() > 0) {
        List<Long> memberIds = groupService.getGroupMemberIds(header.getGroupId());
        for (Long memberId : memberIds) {
            if (!memberId.equals(header.getSenderId())) {
                badgeService.pushBadgeUpdate(memberId);
            }
        }
    }
}
``` String menuId, Integer count);
}
```

### 3. WebSocket 中间件 SPI 实现

#### 3.1 MessageStorageService 实现

**位置**: `shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/service/im/impl/MessageStorageServiceImpl.java`

**实现要点**:

```java
@Service
public class MessageStorageServiceImpl implements MessageStorageService {
    
    @Resource
    private ImMessageService messageService;
    
    @Resource
    private ImConversationService conversationService;
    
    @Resource
    private ImBadgeService badgeService;
    
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void saveMessage(ImMessage message) {
        MessageHeader header = message.getHeader();
        
        // 1. 转换为 DO 对象
        ImMessageDO messageDO = convertToDO(message);
        
        // 2. 保存到数据库
        messageService.saveMessage(messageDO);
        
        // 3. 更新会话
        if (header.getReceiverId() > 0) {
            // 单聊: 更新发送者和接收者的会话
            conversationService.updateLastMessage(header.getReceiverId(), messageDO);
            conversationService.incrementUnreadCount(header.getReceiverId(), header.getReceiverId());
        } else if (header.getGroupId() > 0) {
            // 群聊: 更新所有群成员的会话
            List<Long> memberIds = groupService.getGroupMemberIds(header.getGroupId());
            for (Long memberId : memberIds) {
                if (!memberId.equals(header.getSenderId())) {
                    conversationService.updateLastMessage(memberId, messageDO);
                    conversationService.incrementUnreadCount(memberId, memberId);
                }
            }
        }
        
        // 4. 推送角标更新 (集成 im-badge-notifications spec 的 ImBadgeService)
        if (header.getReceiverId() > 0) {
            badgeService.pushBadgeUpdate(header.getReceiverId());
        } else if (header.getGroupId() > 0) {
            List<Long> memberIds = groupService.getGroupMemberIds(header.getGroupId());
            for (Long memberId : memberIds) {
                if (!memberId.equals(header.getSenderId())) {
                    badgeService.pushBadgeUpdate(memberId);
                }
            }
        }
    }
    
    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long saveMessageWithId(ImMessage message) {
        saveMessage(message);
        return message.getHeader().getMessageId();
    }
    
    private ImMessageDO convertToDO(ImMessage message) {
        MessageHeader header = message.getHeader();
        
        return ImMessageDO.builder()
            .messageId(header.getMessageId())
            .messageType(mapProtobufTypeToDbType(header.getMessageType()))
            .senderId(header.getSenderId())
            .receiverId(header.getReceiverId())
            .groupId(header.getGroupId())
            .content(parseMessageContent(message))
            .extra(header.getExtra())
            .status(0)  // 未读
            .sequence(header.getSequence())
            .tenantId(header.getTenantId())
            .build();
    }
    
    /**
     * 将 Protobuf 消息类型映射到数据库类型
     */
    private Integer mapProtobufTypeToDbType(MessageType protobufType) {
        switch (protobufType) {
            case TEXT: return 1;
            case IMAGE: return 2;
            case VOICE: return 3;
            case VIDEO: return 4;
            case FILE: return 5;
            case LOCATION: return 6;
            default: return 1;
        }
    }
}
```

#### 3.2 AuthService 实现

**位置**: `shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/service/im/impl/AuthServiceImpl.java`

**实现要点**:

```java
@Service
public class AuthServiceImpl implements AuthService {
    
    @Resource
    private OAuth2TokenApi oauth2TokenApi;
    
    @Override
    public LoginBase validateToken(String accessToken) {
        try {
            // 1. 验证 token
            OAuth2AccessTokenCheckRespDTO tokenInfo = 
                oauth2TokenApi.checkAccessToken(accessToken);
            
            if (tokenInfo == null) {
                return null;
            }
            
            // 2. 检查是否过期
            if (tokenInfo.getExpiresTime().isBefore(LocalDateTime.now())) {
                return null;
            }
            
            // 3. 构建登录用户信息
            return buildLoginUser(tokenInfo);
            
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
    
    private LoginBase buildLoginUser(OAuth2AccessTokenCheckRespDTO tokenInfo) {
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

#### 3.3 MessageCacheService 实现

**位置**: `shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/service/im/impl/MessageCacheServiceImpl.java`

**实现要点**:

```java
@Service
public class MessageCacheServiceImpl implements MessageCacheService {
    
    @Resource
    private RedisTemplate<String, Object> redisTemplate;
    
    private static final String UNREAD_COUNT_KEY = "im:unread:";
    private static final String USER_INFO_KEY = "im:user:";
    private static final String CONVERSATION_KEY = "im:conversation:";
    
    @Override
    public void cacheUnreadCount(Long userId, long count) {
        String key = UNREAD_COUNT_KEY + userId;
        redisTemplate.opsForValue().set(key, count, 24, TimeUnit.HOURS);
    }
    
    @Override
    public Long getCachedUnreadCount(Long userId) {
        String key = UNREAD_COUNT_KEY + userId;
        Object value = redisTemplate.opsForValue().get(key);
        return value != null ? Long.parseLong(value.toString()) : null;
    }
    
    @Override
    public long incrementUnreadCount(Long userId, long delta) {
        String key = UNREAD_COUNT_KEY + userId;
        Long result = redisTemplate.opsForValue().increment(key, delta);
        redisTemplate.expire(key, 24, TimeUnit.HOURS);
        return result != null ? result : 0;
    }
    
    /**
     * 缓存用户信息
     */
    public void cacheUserInfo(Long userId, UserInfo userInfo) {
        String key = USER_INFO_KEY + userId;
        redisTemplate.opsForValue().set(key, userInfo, 1, TimeUnit.HOURS);
    }
    
    /**
     * 获取缓存的用户信息
     */
    public UserInfo getCachedUserInfo(Long userId) {
        String key = USER_INFO_KEY + userId;
        return (UserInfo) redisTemplate.opsForValue().get(key);
    }
}
```

#### 3.4 OfflinePushService 实现

**位置**: `shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/service/im/impl/OfflinePushServiceImpl.java`

**实现要点**:

```java
@Service
public class OfflinePushServiceImpl implements OfflinePushService {
    
    @Resource
    private JpushClient jpushClient;  // 极光推送客户端
    
    @Override
    public boolean pushOfflineMessage(Long userId, ImMessageDO message) {
        try {
            // 1. 查询用户的推送设置
            UserPushSetting setting = getUserPushSetting(userId);
            if (setting == null || !setting.getEnabled()) {
                return false;
            }
            
            // 2. 检查免打扰设置
            if (isInMuteTime(setting)) {
                return false;
            }
            
            // 3. 构建推送内容
            PushNotification notification = buildNotification(message, setting);
            
            // 4. 调用推送服务
            jpushClient.push(userId, notification);
            
            return true;
        } catch (Exception e) {
            log.error("[OfflinePush] 推送失败: userId={}, messageId={}", 
                userId, message.getId(), e);
            return false;
        }
    }
    
    @Override
    public boolean pushUnreadCount(Long userId, long count) {
        try {
            // 推送角标数到移动端
            jpushClient.pushBadge(userId, (int) count);
            return true;
        } catch (Exception e) {
            log.error("[OfflinePush] 推送角标失败: userId={}, count={}", 
                userId, count, e);
            return false;
        }
    }
    
    private PushNotification buildNotification(ImMessageDO message, UserPushSetting setting) {
        PushNotification notification = new PushNotification();
        
        // 设置标题
        notification.setTitle(getSenderName(message.getSenderId()));
        
        // 设置内容
        if (setting.getShowPreview()) {
            notification.setContent(getMessagePreview(message));
        } else {
            notification.setContent("您收到一条新消息");
        }
        
        // 设置跳转参数
        notification.setExtras(Map.of(
            "conversationId", message.getConversationId(),
            "messageId", message.getId()
        ));
        
        return notification;
    }
}
```


## 数据模型

### 现有数据库表结构

**重要**: 以下数据库表已在 `sql/mysql/1.0/im/ddl_im_tables.sql` 中定义，无需重新创建:

1. **im_message** (消息表) - 已存在
   - 存储所有聊天消息(单聊/群聊)
   - 支持多种消息类型(1-文本 2-图片 3-语音 4-视频 5-文件 6-位置 7-表情包 8-自定义贴纸 10-系统消息)
   - 包含消息状态、撤回信息、引用消息等字段
   - 已建立必要的索引(会话、发送者、接收者、群组、租户)

2. **im_conversation** (会话表) - 已存在
   - 存储用户的会话列表(单聊/群聊)
   - 支持置顶、免打扰、未读数管理
   - 包含最后消息信息和草稿内容
   - 唯一索引支持逻辑删除后重新创建会话

3. **im_group** (群组表) - 已存在
   - 存储群组基本信息
   - 支持群公告、全员禁言、成员邀请设置
   - 包含群主、成员数量、最大成员数量等字段

4. **im_group_member** (群成员表) - 已存在
   - 存储群组成员关系
   - 支持角色管理(群主、管理员、普通成员)
   - 支持群昵称、禁言管理
   - 唯一索引支持逻辑删除后重新加入

5. **im_message_read** (消息已读表) - 已存在
   - 存储群聊消息的已读状态
   - 单聊通过 im_message.status 字段判断

6. **im_group_invite** (群邀请码表) - 已存在
   - 支持群二维码邀请功能
   - 支持有效期和使用次数限制

7. **im_group_file** (群文件关联表) - 已存在
   - 存储群组与文件的关联关系
   - 关联 infra_file 表存储实际文件
   - 支持文件夹管理、收藏、下载统计

8. **im_group_folder** (群文件夹表) - 已存在
   - 支持群文件的文件夹管理
   - 支持父子文件夹层级结构

**需要新增的表**:
- im_call_record (通话记录表) - 需要创建
- im_notification (通知表) - 需要创建

### 1. 数据库表设计

#### 1.1 消息表 (im_message) - 已存在

**参考**: `sql/mysql/1.0/im/ddl_im_tables.sql`

**表结构说明**:
```sql
-- 已存在的表结构，无需重新创建
-- 关键字段:
-- - id: 主键ID
-- - conversation_id: 会话ID
-- - sender_id: 发送者ID
-- - receiver_id: 接收者ID(单聊)
-- - group_id: 群ID(群聊)
-- - message_type: 消息类型(1-6)
-- - content: 消息内容(TEXT)
-- - extra: 扩展信息(JSON)
-- - status: 消息状态(1-6)
-- - quote_message_id: 引用消息ID
-- - send_time: 发送时间
-- - recall_time: 撤回时间
-- - recall_by: 撤回人ID
```

**使用方式**:
- 直接使用现有表结构
- 消息类型映射: Protobuf 100-106 → DB 1-6
- 扩展字段使用 extra (JSON) 存储额外信息

#### 1.2 会话表 (im_conversation) - 已存在

**参考**: `sql/mysql/1.0/im/ddl_im_tables.sql`

**表结构说明**:
```sql
-- 已存在的表结构，无需重新创建
-- 关键字段:
-- - id: 会话ID
-- - user_id: 用户ID
-- - target_id: 目标ID
-- - conversation_type: 会话类型(1-单聊 2-群聊)
-- - unread_count: 未读消息数
-- - last_message_id: 最后一条消息ID
-- - last_message_content: 最后一条消息内容
-- - last_message_time: 最后一条消息时间
-- - is_pinned: 是否置顶
-- - no_disturb: 是否免打扰
-- - deleted_by_user: 用户是否删除会话
```

**使用方式**:
- 直接使用现有表结构
- 注意字段名: no_disturb (不是 is_muted)
- 注意字段名: deleted_by_user (不是 deleted)

#### 1.3 群组表 (im_group) - 已存在

**参考**: `sql/mysql/1.0/im/ddl_im_tables.sql`

**表结构说明**:
```sql
-- 已存在的表结构，无需重新创建
-- 关键字段:
-- - id: 群ID
-- - name: 群名称
-- - avatar: 群头像
-- - owner_id: 群主ID
-- - member_count: 成员数量
-- - max_member_count: 最大成员数量
-- - notice: 群公告
-- - notice_pinned: 群公告是否置顶
-- - mute_all: 是否全员禁言
-- - allow_member_invite: 是否允许成员邀请
-- - need_approval: 加群是否需要审批
```

**使用方式**:
- 直接使用现有表结构
- 注意字段名: name (不是 group_name)
- 注意字段名: notice (不是 announcement)

#### 1.4 群成员表 (im_group_member) - 已存在

**参考**: `sql/mysql/1.0/im/ddl_im_tables.sql`

**表结构说明**:
```sql
-- 已存在的表结构，无需重新创建
-- 关键字段:
-- - id: 成员ID
-- - group_id: 群ID
-- - user_id: 用户ID
-- - role: 角色(1-群主 2-管理员 3-普通成员)
-- - nickname: 群昵称
-- - join_time: 加入时间
-- - mute_end_time: 禁言结束时间
```

**使用方式**:
- 直接使用现有表结构
- 注意角色值: 1-群主, 2-管理员, 3-普通成员

#### 1.5 消息已读表 (im_message_read) - 已存在

**参考**: `sql/mysql/1.0/im/ddl_im_tables.sql`

**表结构说明**:
```sql
-- 已存在的表结构，无需重新创建
-- 仅用于群聊消息已读回执
-- 单聊通过 im_message.status 字段判断
```

#### 1.6 群文件表 (im_group_file, im_group_folder) - 已存在

**参考**: `sql/mysql/1.0/im/ddl_im_tables.sql`

**表结构说明**:
```sql
-- 已存在的表结构，群文件功能已部分实现
-- im_group_file: 存储群组与文件的关联关系
-- im_group_folder: 支持文件夹管理
-- 关联 infra_file 表存储实际文件
```

**使用方式**:
- 群文件上传: 调用 AppImGroupFileController.uploadFile()
- 群文件列表: 调用 AppImGroupFileController.getFileList()
- 群文件删除: 调用 AppImGroupFileController.deleteFile()
- 下载统计: 调用 AppImGroupFileController.downloadFile()

#### 1.7 通话记录表 (im_call_record) - 需要创建

```sql
CREATE TABLE im_message (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
    message_id BIGINT NOT NULL COMMENT '消息ID(雪花算法)',
    message_type TINYINT NOT NULL COMMENT '消息类型(1-文本 2-图片 3-语音 4-视频 5-文件 6-位置)',
    sender_id BIGINT NOT NULL COMMENT '发送者ID',
    receiver_id BIGINT DEFAULT NULL COMMENT '接收者ID(单聊)',
    group_id BIGINT DEFAULT NULL COMMENT '群组ID(群聊)',
    conversation_id BIGINT NOT NULL COMMENT '会话ID',
    content TEXT NOT NULL COMMENT '消息内容(JSON格式)',
    quote_message_id BIGINT DEFAULT NULL COMMENT '引用的消息ID',
    at_user_ids VARCHAR(500) DEFAULT NULL COMMENT '@的用户ID列表(逗号分隔)',
    status TINYINT DEFAULT 0 COMMENT '状态(0-未读 1-已读 2-已撤回)',
    sequence BIGINT NOT NULL COMMENT '消息序列号',
    extra VARCHAR(1000) DEFAULT NULL COMMENT '扩展字段(JSON)',
    tenant_id BIGINT NOT NULL COMMENT '租户ID',
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted BIT(1) NOT NULL DEFAULT 0 COMMENT '是否删除',
    
    UNIQUE KEY uk_message_id (message_id),
    KEY idx_conversation_id (conversation_id, sequence),
    KEY idx_sender_id (sender_id, create_time),
    KEY idx_receiver_id (receiver_id, create_time),
    KEY idx_group_id (group_id, create_time),
    KEY idx_tenant_id (tenant_id, create_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='IM消息表';
```

#### 1.2 会话表 (im_conversation)

```sql
CREATE TABLE im_conversation (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    conversation_type TINYINT NOT NULL COMMENT '会话类型(1-单聊 2-群聊)',
    target_id BIGINT NOT NULL COMMENT '目标ID(单聊为对方ID,群聊为群组ID)',
    last_message_id BIGINT DEFAULT NULL COMMENT '最后一条消息ID',
    last_message_content VARCHAR(500) DEFAULT NULL COMMENT '最后一条消息内容',
    last_message_time DATETIME DEFAULT NULL COMMENT '最后一条消息时间',
    unread_count INT DEFAULT 0 COMMENT '未读消息数',
    is_pinned BIT(1) DEFAULT 0 COMMENT '是否置顶',
    is_muted BIT(1) DEFAULT 0 COMMENT '是否免打扰',
    draft_content VARCHAR(1000) DEFAULT NULL COMMENT '草稿内容',
    tags VARCHAR(200) DEFAULT NULL COMMENT '标签(逗号分隔)',
    tenant_id BIGINT NOT NULL COMMENT '租户ID',
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted BIT(1) NOT NULL DEFAULT 0 COMMENT '是否删除',
    
    UNIQUE KEY uk_user_target (user_id, conversation_type, target_id),
    KEY idx_user_id (user_id, last_message_time),
    KEY idx_tenant_id (tenant_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='IM会话表';
```

#### 1.3 群组表 (im_group)

```sql
CREATE TABLE im_group (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
    group_name VARCHAR(100) NOT NULL COMMENT '群名称',
    group_avatar VARCHAR(500) DEFAULT NULL COMMENT '群头像URL',
    owner_id BIGINT NOT NULL COMMENT '群主ID',
    member_count INT DEFAULT 0 COMMENT '群成员数量',
    max_member_count INT DEFAULT 500 COMMENT '最大成员数量',
    is_all_muted BIT(1) DEFAULT 0 COMMENT '是否全员禁言',
    announcement TEXT DEFAULT NULL COMMENT '群公告',
    announcement_time DATETIME DEFAULT NULL COMMENT '公告发布时间',
    tenant_id BIGINT NOT NULL COMMENT '租户ID',
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted BIT(1) NOT NULL DEFAULT 0 COMMENT '是否删除',
    
    KEY idx_owner_id (owner_id),
    KEY idx_tenant_id (tenant_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='IM群组表';
```

#### 1.4 群成员表 (im_group_member)

```sql
CREATE TABLE im_group_member (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
    group_id BIGINT NOT NULL COMMENT '群组ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    member_role TINYINT DEFAULT 0 COMMENT '成员角色(0-普通成员 1-管理员 2-群主)',
    member_nickname VARCHAR(100) DEFAULT NULL COMMENT '群昵称',
    is_muted BIT(1) DEFAULT 0 COMMENT '是否被禁言',
    mute_end_time DATETIME DEFAULT NULL COMMENT '禁言结束时间',
    join_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '加入时间',
    tenant_id BIGINT NOT NULL COMMENT '租户ID',
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted BIT(1) NOT NULL DEFAULT 0 COMMENT '是否删除',
    
    UNIQUE KEY uk_group_user (group_id, user_id),
    KEY idx_user_id (user_id),
    KEY idx_tenant_id (tenant_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='IM群成员表';
```

#### 1.5 消息已读表 (im_message_read)

```sql
CREATE TABLE im_message_read (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
    message_id BIGINT NOT NULL COMMENT '消息ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    read_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '阅读时间',
    tenant_id BIGINT NOT NULL COMMENT '租户ID',
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    
    UNIQUE KEY uk_message_user (message_id, user_id),
    KEY idx_user_id (user_id, read_time),
    KEY idx_tenant_id (tenant_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='IM消息已读表';
```

#### 1.7 通话记录表 (im_call_record) - 需要创建

**说明**: 此表需要新建，用于存储语音/视频通话记录

```sql
CREATE TABLE im_call_record (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
    call_id VARCHAR(64) NOT NULL COMMENT '通话ID',
    call_type TINYINT NOT NULL COMMENT '通话类型(1-语音 2-视频)',
    caller_id BIGINT NOT NULL COMMENT '呼叫方ID',
    callee_id BIGINT NOT NULL COMMENT '接听方ID',
    call_status TINYINT NOT NULL COMMENT '通话状态(1-呼叫中 2-通话中 3-已挂断 4-已拒绝 5-未接听 6-忙线)',
    start_time DATETIME DEFAULT NULL COMMENT '开始时间',
    end_time DATETIME DEFAULT NULL COMMENT '结束时间',
    duration INT DEFAULT 0 COMMENT '通话时长(秒)',
    tenant_id BIGINT NOT NULL COMMENT '租户ID',
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    
    UNIQUE KEY uk_call_id (call_id),
    KEY idx_caller_id (caller_id, create_time),
    KEY idx_callee_id (callee_id, create_time),
    KEY idx_tenant_id (tenant_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='IM通话记录表';
```

#### 1.8 通知表 (im_notification) - 需要创建

**说明**: 此表需要新建，用于存储系统通知、自定义通知等

```sql
CREATE TABLE im_call_record (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
    call_id VARCHAR(64) NOT NULL COMMENT '通话ID',
    call_type TINYINT NOT NULL COMMENT '通话类型(1-语音 2-视频)',
    caller_id BIGINT NOT NULL COMMENT '呼叫方ID',
    callee_id BIGINT NOT NULL COMMENT '接听方ID',
    call_status TINYINT NOT NULL COMMENT '通话状态(1-呼叫中 2-通话中 3-已挂断 4-已拒绝 5-未接听 6-忙线)',
    start_time DATETIME DEFAULT NULL COMMENT '开始时间',
    end_time DATETIME DEFAULT NULL COMMENT '结束时间',
    duration INT DEFAULT 0 COMMENT '通话时长(秒)',
    tenant_id BIGINT NOT NULL COMMENT '租户ID',
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    
    UNIQUE KEY uk_call_id (call_id),
    KEY idx_caller_id (caller_id, create_time),
    KEY idx_callee_id (callee_id, create_time),
    KEY idx_tenant_id (tenant_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='IM通话记录表';
```

#### 1.8 通知表 (im_notification) - 需要创建

**说明**: 此表需要新建，用于存储系统通知、自定义通知等

```sql
CREATE TABLE im_notification (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    notify_type VARCHAR(50) NOT NULL COMMENT '通知类型(SYSTEM/WORKFLOW/TODO/CUSTOM)',
    title VARCHAR(200) NOT NULL COMMENT '通知标题',
    content TEXT NOT NULL COMMENT '通知内容',
    extra VARCHAR(2000) DEFAULT NULL COMMENT '扩展数据(JSON)',
    is_read BIT(1) DEFAULT 0 COMMENT '是否已读',
    read_time DATETIME DEFAULT NULL COMMENT '阅读时间',
    expire_time DATETIME DEFAULT NULL COMMENT '过期时间',
    tenant_id BIGINT NOT NULL COMMENT '租户ID',
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted BIT(1) NOT NULL DEFAULT 0 COMMENT '是否删除',
    
    KEY idx_user_id (user_id, create_time),
    KEY idx_tenant_id (tenant_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='IM通知表';
```

### 现有文件上传基础设施

**重要**: 文件上传功能已完整实现，无需重新开发:

1. **后端上传 API** - 已存在
   - 接口: `POST /app-api/infra/file/upload`
   - 控制器: `AppFileController.java`
   - 支持所有文件类型上传
   - 自动处理文件存储到 OSS
   - 返回文件 URL 和元数据

2. **前端上传工具** - 已存在
   - 文件: `utils/upload.uts`
   - 提供统一的上传接口
   - 支持图片、视频、文件上传
   - 支持上传进度回调
   - 支持文件大小验证
   - 兼容 Android、iOS、Web 三端

3. **群文件管理** - 已部分实现
   - 控制器: `AppImGroupFileController.java`
   - 服务: `ImGroupFileService`
   - 支持群文件上传、列表查询、删除、下载统计
   - 文件存储在 infra_file 表，关联关系存储在 im_group_file 表

**使用方式**:
```typescript
// 前端上传图片
import { chooseAndUploadImage } from '@/utils/upload.uts'

const result = await chooseAndUploadImage(1, {
  directory: 'im/image',
  onProgress: (progress) => {
    console.log('上传进度:', progress)
  }
})

// 获取图片 URL
const imageUrl = result[0].data.url
```

### 1. 数据库表设计 (补充说明)

```sql
CREATE TABLE im_notification (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    notify_type VARCHAR(50) NOT NULL COMMENT '通知类型(SYSTEM/WORKFLOW/TODO/CUSTOM)',
    title VARCHAR(200) NOT NULL COMMENT '通知标题',
    content TEXT NOT NULL COMMENT '通知内容',
    extra VARCHAR(2000) DEFAULT NULL COMMENT '扩展数据(JSON)',
    is_read BIT(1) DEFAULT 0 COMMENT '是否已读',
    read_time DATETIME DEFAULT NULL COMMENT '阅读时间',
    expire_time DATETIME DEFAULT NULL COMMENT '过期时间',
    tenant_id BIGINT NOT NULL COMMENT '租户ID',
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted BIT(1) NOT NULL DEFAULT 0 COMMENT '是否删除',
    
    KEY idx_user_id (user_id, create_time),
    KEY idx_tenant_id (tenant_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='IM通知表';
```

### 2. 前端数据模型

#### 2.1 MessageItem (消息项)

```typescript
type MessageItem = {
  id: number                    // 数据库ID
  messageId: number             // 消息ID(雪花算法)
  senderId: number              // 发送者ID
  receiverId: number | null     // 接收者ID(单聊)
  groupId: number | null        // 群组ID(群聊)
  conversationId: number        // 会话ID
  type: string                  // 消息类型('text'|'image'|'voice'|'video'|'file'|'location')
  content: string               // 消息内容
  quoteMessageId: number | null // 引用的消息ID
  quoteContent: string | null   // 引用的消息内容摘要
  atUserIds: Array<number>      // @的用户ID列表
  isSelf: boolean               // 是否自己发送
  time: string                  // 显示时间
  timestamp: number             // 时间戳
  showTime: boolean             // 是否显示时间
  avatarText: string            // 头像文本
  avatarBg: string              // 头像背景色
  senderName: string            // 发送者名称
  status: string                // 消息状态('sending'|'sent'|'delivered'|'read'|'failed')
  
  // 媒体消息字段
  url?: string                  // 媒体URL
  thumbnailUrl?: string         // 缩略图URL
  width?: number                // 宽度
  height?: number               // 高度
  size?: number                 // 文件大小
  duration?: number             // 时长(语音/视频)
  fileName?: string             // 文件名
  fileType?: string             // 文件类型
  
  // 位置消息字段
  latitude?: number             // 纬度
  longitude?: number            // 经度
  address?: string              // 地址描述
}
```

#### 2.2 ConversationItem (会话项)

```typescript
type ConversationItem = {
  id: number                    // 会话ID
  conversationType: number      // 会话类型(1-单聊 2-群聊)
  targetId: number              // 目标ID
  targetName: string            // 目标名称
  targetAvatar: string          // 目标头像
  lastMessage: string           // 最后一条消息
  lastMessageTime: string       // 最后消息时间
  lastMessageTimestamp: number  // 最后消息时间戳
  unreadCount: number           // 未读数
  isPinned: boolean             // 是否置顶
  isMuted: boolean              // 是否免打扰
  draftContent: string          // 草稿内容
  tags: Array<string>           // 标签列表
  atMe: boolean                 // 是否有人@我
}
```

#### 2.3 GroupInfo (群组信息)

```typescript
type GroupInfo = {
  id: number                    // 群组ID
  groupName: string             // 群名称
  groupAvatar: string           // 群头像
  ownerId: number               // 群主ID
  memberCount: number           // 成员数量
  maxMemberCount: number        // 最大成员数量
  isAllMuted: boolean           // 是否全员禁言
  announcement: string          // 群公告
  announcementTime: string      // 公告时间
  myRole: number                // 我的角色(0-普通 1-管理员 2-群主)
  myNickname: string            // 我的群昵称
  isMuted: boolean              // 我是否被禁言
}
```

#### 2.4 GroupMember (群成员)

```typescript
type GroupMember = {
  id: number                    // 成员ID
  groupId: number               // 群组ID
  userId: number                // 用户ID
  userName: string              // 用户名称
  userAvatar: string            // 用户头像
  memberRole: number            // 成员角色(0-普通 1-管理员 2-群主)
  memberNickname: string        // 群昵称
  isMuted: boolean              // 是否被禁言
  muteEndTime: string | null    // 禁言结束时间
  joinTime: string              // 加入时间
}
```

#### 2.5 CallRecord (通话记录)

```typescript
type CallRecord = {
  id: number                    // 记录ID
  callId: string                // 通话ID
  callType: string              // 通话类型('voice'|'video')
  callerId: number              // 呼叫方ID
  callerName: string            // 呼叫方名称
  calleeId: number              // 接听方ID
  calleeName: string            // 接听方名称
  callStatus: string            // 通话状态('calling'|'connected'|'ended'|'rejected'|'missed'|'busy')
  startTime: string             // 开始时间
  endTime: string | null        // 结束时间
  duration: number              // 通话时长(秒)
  isSelf: boolean               // 是否自己发起
}
```

#### 2.6 NotificationItem (通知项)

```typescript
type NotificationItem = {
  id: number                    // 通知ID
  notifyType: string            // 通知类型('SYSTEM'|'WORKFLOW'|'TODO'|'CUSTOM')
  title: string                 // 通知标题
  content: string               // 通知内容
  icon: string                  // 通知图标
  extra: any                    // 扩展数据
  isRead: boolean               // 是否已读
  readTime: string | null       // 阅读时间
  expireTime: string | null     // 过期时间
  createTime: string            // 创建时间
  
  // 操作按钮
  actions?: Array<{
    label: string
    action: string
    params: any
  }>
}
```

### 3. Protobuf 消息定义

#### 3.1 扩展消息类型

在现有 `im_message.proto` 基础上扩展:

```protobuf
// 引用回复消息
message QuoteReplyMessage {
  int64 quoteMessageId = 1;     // 被引用的消息ID
  string quoteContent = 2;      // 被引用的消息内容摘要
  int64 quoteSenderId = 3;      // 被引用消息的发送者ID
  string quoteSenderName = 4;   // 被引用消息的发送者名称
  string content = 5;           // 回复内容
}

// 正在输入消息
message TypingMessage {
  int64 userId = 1;             // 用户ID
  bool isTyping = 2;            // 是否正在输入
}

// 角标更新消息
message BadgeUpdateMessage {
  int32 unreadCount = 1;        // 总未读数
  repeated ConversationBadge conversationBadges = 2;  // 会话角标列表
  repeated MenuBadge menuBadges = 3;  // 菜单角标列表
}

message ConversationBadge {
  int64 conversationId = 1;     // 会话ID
  int32 unreadCount = 2;        // 未读数
}

message MenuBadge {
  string menuId = 1;            // 菜单ID
  int32 badgeCount = 2;         // 角标数量
}

// 通话信令消息
message CallSignalMessage {
  string callId = 1;            // 通话ID
  string callType = 2;          // 通话类型('VOICE'|'VIDEO')
  string action = 3;            // 信令动作('INVITE'|'ACCEPT'|'REJECT'|'HANGUP'|'BUSY')
  int64 callerId = 4;           // 呼叫方ID
  int64 calleeId = 5;           // 接听方ID
  string roomId = 6;            // 房间ID
  string reason = 7;            // 原因(拒绝/挂断原因)
  string sdp = 8;               // SDP信息(WebRTC)
  string candidate = 9;         // ICE候选(WebRTC)
}

// 系统通知消息
message SystemNotifyMessage {
  string title = 1;             // 通知标题
  string content = 2;           // 通知内容
  string type = 3;              // 通知类型
  string extra = 4;             // 扩展数据(JSON)
}


```

### 4. API 接口设计

#### 4.1 消息相关接口

**发送消息**:
```
POST /app-api/system/im/message/send
Request: {
  messageType: number,
  receiverId?: number,
  groupId?: number,
  content: string,
  extra?: string
}
Response: {
  code: number,
  data: {
    messageId: number,
    sequence: number,
    timestamp: number
  }
}
```

**查询消息列表**:
```
GET /app-api/system/im/message/list
Params: {
  conversationId: number,
  lastMessageId?: number,
  pageSize: number
}
Response: {
  code: number,
  data: {
    list: Array<MessageVO>,
    hasMore: boolean
  }
}
```

**撤回消息**:
```
PUT /app-api/system/im/message/recall/{id}
Response: {
  code: number,
  message: string
}
```

**搜索消息**:
```
GET /app-api/system/im/message/search
Params: {
  keyword: string,
  conversationId?: number,
  messageType?: number,
  pageNo: number,
  pageSize: number
}
Response: {
  code: number,
  data: {
    list: Array<MessageVO>,
    total: number
  }
}
```

#### 4.2 会话相关接口

**获取会话列表**:
```
GET /app-api/system/im/conversation/list
Response: {
  code: number,
  data: Array<ConversationVO>
}
```

**清空未读数**:
```
PUT /app-api/system/im/conversation/clear-unread/{id}
Response: {
  code: number,
  message: string
}
```

**置顶会话**:
```
PUT /app-api/system/im/conversation/pin/{id}
Request: {
  isPinned: boolean
}
Response: {
  code: number,
  message: string
}
```

**设置免打扰**:
```
PUT /app-api/system/im/conversation/mute/{id}
Request: {
  isMuted: boolean
}
Response: {
  code: number,
  message: string
}
```

#### 4.3 群组相关接口

**创建群组**:
```
POST /app-api/system/im/group/create
Request: {
  groupName: string,
  groupAvatar?: string,
  memberIds: Array<number>
}
Response: {
  code: number,
  data: {
    groupId: number
  }
}
```

**获取群组信息**:
```
GET /app-api/system/im/group/get/{id}
Response: {
  code: number,
  data: GroupVO
}
```

**添加群成员**:
```
POST /app-api/system/im/group/add-members
Request: {
  groupId: number,
  userIds: Array<number>
}
Response: {
  code: number,
  message: string
}
```

**移除群成员**:
```
POST /app-api/system/im/group/remove-members
Request: {
  groupId: number,
  userIds: Array<number>
}
Response: {
  code: number,
  message: string
}
```

**禁言成员**:
```
POST /app-api/system/im/group/mute-member
Request: {
  groupId: number,
  userId: number,
  duration: number  // 禁言时长(秒)
}
Response: {
  code: number,
  message: string
}
```

#### 4.4 通话相关接口

**发起通话**:
```
POST /app-api/system/im/call/initiate
Request: {
  calleeId: number,
  callType: string  // 'voice' | 'video'
}
Response: {
  code: number,
  data: {
    callId: string,
    roomId: string
  }
}
```

**保存通话记录**:
```
POST /app-api/system/im/call/save-record
Request: {
  callId: string,
  callStatus: string,
  startTime?: string,
  endTime?: string,
  duration: number
}
Response: {
  code: number,
  message: string
}
```

**获取通话记录**:
```
GET /app-api/system/im/call/records
Params: {
  pageSize: number
}
Response: {
  code: number,
  data: Array<CallRecordVO>
}
```

#### 4.5 角标相关接口

**获取角标数据**:
```
GET /app-api/system/im/badge/get
Response: {
  code: number,
  data: {
    totalUnread: number,
    conversationBadges: Array<{conversationId: number, unreadCount: number}>,
    menuBadges: Array<{menuId: string, badgeCount: number}>
  }
}
```


### 5. 工具函数设计

#### 5.1 消息类型转换

```typescript
/**
 * 将数据库类型转换为字符串类型
 */
function mapDbTypeToString(dbType: number): string {
  const typeMap = {
    1: 'text',
    2: 'image',
    3: 'voice',
    4: 'video',
    5: 'file',
    6: 'location'
  }
  return typeMap[dbType] || 'text'
}

/**
 * 将 Protobuf 类型转换为字符串类型
 */
function mapProtobufTypeToString(protobufType: number): string {
  const typeMap = {
    100: 'text',
    101: 'image',
    102: 'voice',
    103: 'video',
    104: 'file',
    105: 'location',
    106: 'custom'
  }
  return typeMap[protobufType] || 'text'
}

/**
 * 智能类型转换 (支持两种格式)
 */
function getMessageTypeString(messageType: number): string {
  if (messageType >= 100) {
    return mapProtobufTypeToString(messageType)
  } else {
    return mapDbTypeToString(messageType)
  }
}
```

#### 5.2 消息内容解析

```typescript
/**
 * 解析消息内容
 */
function parseMessageContent(messageType: number, content: any): string {
  const typeStr = getMessageTypeString(messageType)
  
  // 如果 content 是字符串，尝试解析为 JSON
  if (typeof content === 'string') {
    try {
      content = JSON.parse(content)
    } catch (e) {
      // 解析失败，直接返回字符串
      return content
    }
  }
  
  // 根据消息类型提取内容
  switch (typeStr) {
    case 'text':
      return content.content || content
    case 'image':
      return content.url || content
    case 'voice':
      return content.url || content
    case 'video':
      return content.url || content
    case 'file':
      return content.url || content
    case 'location':
      return content.address || content
    default:
      return content.toString()
  }
}
```

#### 5.3 时间格式化

```typescript
/**
 * 格式化消息时间
 */
function formatMessageTime(timestamp: number): string {
  const now = Date.now()
  const diff = now - timestamp
  const date = new Date(timestamp)
  
  // 刚刚 (1分钟内)
  if (diff < 60 * 1000) {
    return '刚刚'
  }
  
  // 今天 (显示时:分)
  if (isSameDay(date, new Date())) {
    return formatTime(date, 'HH:mm')
  }
  
  // 昨天
  if (isYesterday(date)) {
    return '昨天 ' + formatTime(date, 'HH:mm')
  }
  
  // 本周 (显示星期)
  if (isSameWeek(date, new Date())) {
    return getWeekday(date) + ' ' + formatTime(date, 'HH:mm')
  }
  
  // 更早 (显示日期)
  return formatTime(date, 'YYYY-MM-DD HH:mm')
}

/**
 * 判断是否需要显示时间
 */
function shouldShowTime(currentTimestamp: number, previousTimestamp: number): boolean {
  // 相邻消息时间间隔超过5分钟则显示时间
  return (currentTimestamp - previousTimestamp) > 5 * 60 * 1000
}
```

#### 5.4 头像生成

```typescript
/**
 * 生成头像文本
 */
function getAvatarText(name: string): string {
  if (!name || name.length === 0) {
    return '?'
  }
  
  // 中文名取最后两个字
  if (/[\u4e00-\u9fa5]/.test(name)) {
    return name.slice(-2)
  }
  
  // 英文名取首字母
  const words = name.split(' ')
  if (words.length >= 2) {
    return (words[0][0] + words[1][0]).toUpperCase()
  }
  
  return name.slice(0, 2).toUpperCase()
}

/**
 * 生成头像背景色
 */
function getUserAvatarColor(userId: number): string {
  const colors = [
    '#FF6B6B', '#4ECDC4', '#45B7D1', '#FFA07A',
    '#98D8C8', '#F7DC6F', '#BB8FCE', '#85C1E2',
    '#F8B739', '#52B788', '#E76F51', '#2A9D8F'
  ]
  
  const index = userId % colors.length
  return colors[index]
}
```

#### 5.5 消息 ID 生成

```typescript
/**
 * 生成消息 ID (雪花算法)
 */
function generateMessageId(): number {
  // 简化版雪花算法
  // 实际应该从服务器获取或使用完整的雪花算法实现
  const timestamp = Date.now()
  const random = Math.floor(Math.random() * 1000)
  return timestamp * 1000 + random
}

/**
 * 生成序列号
 */
function generateSequence(): number {
  // 从服务器获取递增的序列号
  // 保证全局有序
  return Date.now()
}
```

### 6. 缓存策略设计

#### 6.1 用户信息缓存

```typescript
class UserInfoCache {
  private cache: Map<number, UserInfo>
  private maxSize: number = 1000
  private accessOrder: Array<number>
  
  /**
   * 获取用户信息
   */
  public async getUserInfo(userId: number): Promise<UserInfo> {
    // 1. 检查缓存
    if (this.cache.has(userId)) {
      this.updateAccessOrder(userId)
      return this.cache.get(userId)!
    }
    
    // 2. 从服务器获取
    const userInfo = await fetchUserInfo(userId)
    
    // 3. 添加到缓存
    this.set(userId, userInfo)
    
    return userInfo
  }
  
  /**
   * 设置缓存
   */
  private set(userId: number, userInfo: UserInfo): void {
    // LRU 淘汰策略
    if (this.cache.size >= this.maxSize) {
      const oldestUserId = this.accessOrder.shift()!
      this.cache.delete(oldestUserId)
    }
    
    this.cache.set(userId, userInfo)
    this.accessOrder.push(userId)
  }
  
  /**
   * 更新访问顺序
   */
  private updateAccessOrder(userId: number): void {
    const index = this.accessOrder.indexOf(userId)
    if (index > -1) {
      this.accessOrder.splice(index, 1)
      this.accessOrder.push(userId)
    }
  }
  
  /**
   * 使缓存失效
   */
  public invalidate(userId: number): void {
    this.cache.delete(userId)
    const index = this.accessOrder.indexOf(userId)
    if (index > -1) {
      this.accessOrder.splice(index, 1)
    }
  }
}
```

#### 6.2 消息缓存

```typescript
class MessageCache {
  private cache: Map<number, MessageItem>
  private conversationMessages: Map<number, Array<number>>
  
  /**
   * 缓存消息
   */
  public cacheMessage(message: MessageItem): void {
    this.cache.set(message.messageId, message)
    
    // 添加到会话消息列表
    const conversationId = message.conversationId
    if (!this.conversationMessages.has(conversationId)) {
      this.conversationMessages.set(conversationId, [])
    }
    this.conversationMessages.get(conversationId)!.push(message.messageId)
  }
  
  /**
   * 获取缓存的消息
   */
  public getMessage(messageId: number): MessageItem | null {
    return this.cache.get(messageId) || null
  }
  
  /**
   * 获取会话的缓存消息
   */
  public getConversationMessages(conversationId: number): Array<MessageItem> {
    const messageIds = this.conversationMessages.get(conversationId) || []
    return messageIds
      .map(id => this.cache.get(id))
      .filter(msg => msg != null) as Array<MessageItem>
  }
  
  /**
   * 清空会话缓存
   */
  public clearConversationCache(conversationId: number): void {
    const messageIds = this.conversationMessages.get(conversationId) || []
    messageIds.forEach(id => this.cache.delete(id))
    this.conversationMessages.delete(conversationId)
  }
}
```

### 7. 性能优化设计

#### 7.1 虚拟滚动实现

```typescript
class VirtualScroller {
  private itemHeight: number = 80  // 每项高度
  private visibleCount: number = 10  // 可见项数量
  private bufferCount: number = 5   // 缓冲项数量
  private scrollTop: number = 0
  
  /**
   * 计算可见范围
   */
  public getVisibleRange(totalCount: number): {start: number, end: number} {
    const start = Math.max(0, Math.floor(this.scrollTop / this.itemHeight) - this.bufferCount)
    const end = Math.min(totalCount, start + this.visibleCount + this.bufferCount * 2)
    
    return {start, end}
  }
  
  /**
   * 更新滚动位置
   */
  public updateScrollTop(scrollTop: number): void {
    this.scrollTop = scrollTop
  }
  
  /**
   * 计算总高度
   */
  public getTotalHeight(totalCount: number): number {
    return totalCount * this.itemHeight
  }
  
  /**
   * 计算偏移量
   */
  public getOffset(start: number): number {
    return start * this.itemHeight
  }
}
```

#### 7.2 消息批量加载

```typescript
class MessageLoader {
  private pageSize: number = 20
  private loading: boolean = false
  private hasMore: boolean = true
  
  /**
   * 加载更多消息
   */
  public async loadMore(conversationId: number, lastMessageId: number): Promise<Array<MessageItem>> {
    if (this.loading || !this.hasMore) {
      return []
    }
    
    this.loading = true
    
    try {
      const response = await getMessageList({
        conversationId,
        lastMessageId,
        pageSize: this.pageSize
      })
      
      this.hasMore = response.data.hasMore
      return response.data.list
      
    } finally {
      this.loading = false
    }
  }
  
  /**
   * 预加载下一页
   */
  public async preloadNext(conversationId: number, lastMessageId: number): Promise<void> {
    if (!this.hasMore) {
      return
    }
    
    // 后台静默加载
    const messages = await this.loadMore(conversationId, lastMessageId)
    
    // 缓存到内存
    messages.forEach(msg => messageCache.cacheMessage(msg))
  }
}
```

#### 7.3 图片懒加载

```typescript
class ImageLazyLoader {
  private observer: IntersectionObserver
  private loadingImages: Set<string>
  
  constructor() {
    this.loadingImages = new Set()
    
    // 创建 IntersectionObserver
    this.observer = new IntersectionObserver(
      (entries) => {
        entries.forEach(entry => {
          if (entry.isIntersecting) {
            const img = entry.target as HTMLImageElement
            const src = img.dataset.src
            if (src && !this.loadingImages.has(src)) {
              this.loadImage(img, src)
            }
          }
        })
      },
      {
        rootMargin: '50px'  // 提前50px开始加载
      }
    )
  }
  
  /**
   * 观察图片元素
   */
  public observe(img: HTMLImageElement): void {
    this.observer.observe(img)
  }
  
  /**
   * 加载图片
   */
  private async loadImage(img: HTMLImageElement, src: string): Promise<void> {
    this.loadingImages.add(src)
    
    try {
      // 预加载图片
      const image = new Image()
      image.src = src
      await image.decode()
      
      // 设置图片源
      img.src = src
      img.classList.add('loaded')
      
    } catch (e) {
      console.error('[ImageLazyLoader] 加载失败:', src, e)
      img.classList.add('error')
      
    } finally {
      this.loadingImages.delete(src)
    }
  }
}
```

#### 7.4 防抖和节流

```typescript
/**
 * 防抖函数
 */
function debounce<T extends (...args: any[]) => any>(
  func: T,
  wait: number
): (...args: Parameters<T>) => void {
  let timeout: number | null = null
  
  return function(...args: Parameters<T>) {
    if (timeout !== null) {
      clearTimeout(timeout)
    }
    
    timeout = setTimeout(() => {
      func(...args)
      timeout = null
    }, wait)
  }
}

/**
 * 节流函数
 */
function throttle<T extends (...args: any[]) => any>(
  func: T,
  wait: number
): (...args: Parameters<T>) => void {
  let lastTime = 0
  
  return function(...args: Parameters<T>) {
    const now = Date.now()
    
    if (now - lastTime >= wait) {
      func(...args)
      lastTime = now
    }
  }
}
```

### 8. 消息处理器设计

#### 8.1 文本消息处理器

```java
@Component
public class TextMessageProcessor implements MessageProcessor {
    
    @Resource
    private MessageStorageService storageService;
    
    @Resource
    private NettyMessageSender messageSender;
    
    @Override
    public void process(NettySession session, ImMessage message) {
        MessageHeader header = message.getHeader();
        
        // 1. 解析文本消息
        TextMessage textMessage = TextMessage.parseFrom(message.getBody());
        
        // 2. 敏感词过滤
        String filteredContent = filterSensitiveWords(textMessage.getContent());
        
        // 3. 构建新消息
        TextMessage newTextMessage = TextMessage.newBuilder()
            .setContent(filteredContent)
            .addAllAtUserIds(textMessage.getAtUserIdsList())
            .build();
        
        ImMessage newMessage = ImMessage.newBuilder()
            .setHeader(header)
            .setBody(ByteString.copyFrom(newTextMessage.toByteArray()))
            .build();
        
        // 4. 保存消息
        storageService.saveMessage(newMessage);
        
        // 5. 转发消息
        if (header.getReceiverId() > 0) {
            // 单聊
            messageSender.sendToUser(header.getReceiverId(), newMessage);
        } else if (header.getGroupId() > 0) {
            // 群聊
            messageSender.sendToGroup(header.getGroupId(), newMessage);
        }
        
        // 6. 返回发送确认
        sendAck(session, header.getMessageId());
    }
    
    @Override
    public MessageType supportedType() {
        return MessageType.TEXT;
    }
    
    private String filterSensitiveWords(String content) {
        // 敏感词过滤逻辑
        return content;
    }
}
```

#### 8.2 已读回执处理器

```java
@Component
public class ReadReceiptProcessor implements MessageProcessor {
    
    @Resource
    private ImMessageService messageService;
    
    @Resource
    private NettyMessageSender messageSender;
    
    @Override
    public void process(NettySession session, ImMessage message) {
        MessageHeader header = message.getHeader();
        
        // 1. 解析已读回执
        ReadReceiptMessage receipt = ReadReceiptMessage.parseFrom(message.getBody());
        
        // 2. 批量更新消息状态
        messageService.batchUpdateMessageStatus(
            receipt.getMessageIdsList(),
            1  // 已读
        );
        
        // 3. 查询消息的发送者
        List<Long> senderIds = messageService.getSenderIds(receipt.getMessageIdsList());
        
        // 4. 推送已读回执到发送者
        for (Long senderId : senderIds) {
            messageSender.sendToUser(senderId, message);
        }
    }
    
    @Override
    public MessageType supportedType() {
        return MessageType.READ_RECEIPT;
    }
}
```

#### 8.3 消息撤回处理器

```java
@Component
public class RecallMessageProcessor implements MessageProcessor {
    
    @Resource
    private ImMessageService messageService;
    
    @Resource
    private NettyMessageSender messageSender;
    
    @Override
    public void process(NettySession session, ImMessage message) {
        MessageHeader header = message.getHeader();
        
        // 1. 解析撤回消息
        RecallMessage recall = RecallMessage.parseFrom(message.getBody());
        
        // 2. 撤回消息
        messageService.recallMessage(header.getSenderId(), recall.getMessageId());
        
        // 3. 查询原消息
        ImMessageDO originalMessage = messageService.getById(recall.getMessageId());
        
        // 4. 通知接收者
        if (originalMessage.getReceiverId() != null) {
            // 单聊
            messageSender.sendToUser(originalMessage.getReceiverId(), message);
        } else if (originalMessage.getGroupId() != null) {
            // 群聊
            messageSender.sendToGroup(originalMessage.getGroupId(), message);
        }
    }
    
    @Override
    public MessageType supportedType() {
        return MessageType.RECALL;
    }
}
```

#### 8.4 正在输入处理器

```java
@Component
public class TypingMessageProcessor implements MessageProcessor {
    
    @Resource
    private NettyMessageSender messageSender;
    
    @Override
    public void process(NettySession session, ImMessage message) {
        MessageHeader header = message.getHeader();
        
        // 1. 解析正在输入消息
        TypingMessage typing = TypingMessage.parseFrom(message.getBody());
        
        // 2. 转发到目标用户
        if (header.getReceiverId() > 0) {
            messageSender.sendToUser(header.getReceiverId(), message);
        }
        
        // 注意: 正在输入消息不需要存储
    }
    
    @Override
    public MessageType supportedType() {
        return MessageType.TYPING;
    }
}
```

#### 8.5 角标更新处理器

```java
@Component
public class BadgeUpdateProcessor implements MessageProcessor {
    
    @Resource
    private NettyMessageSender messageSender;
    
    @Override
    public void process(NettySession session, ImMessage message) {
        // 角标更新消息由服务器主动推送
        // 客户端不会发送此类型消息
        // 此处理器仅用于转发
        
        MessageHeader header = message.getHeader();
        
        if (header.getReceiverId() > 0) {
            messageSender.sendToUser(header.getReceiverId(), message);
        }
    }
    
    @Override
    public MessageType supportedType() {
        return MessageType.BADGE_UPDATE;
    }
}
```

### 9. 断线重连设计

#### 9.1 重连策略

```typescript
class ReconnectStrategy {
  private maxRetries: number = 10
  private retryCount: number = 0
  private retryDelays: Array<number> = [1000, 2000, 4000, 8000, 16000, 30000]
  private reconnecting: boolean = false
  
  /**
   * 执行重连
   */
  public async reconnect(connectFunc: () => Promise<void>): Promise<boolean> {
    if (this.reconnecting) {
      return false
    }
    
    this.reconnecting = true
    
    while (this.retryCount < this.maxRetries) {
      try {
        // 等待重连延迟
        const delay = this.getRetryDelay()
        await sleep(delay)
        
        // 尝试连接
        await connectFunc()
        
        // 连接成功，重置计数
        this.retryCount = 0
        this.reconnecting = false
        return true
        
      } catch (e) {
        this.retryCount++
        console.error(`[Reconnect] 重连失败 (${this.retryCount}/${this.maxRetries})`, e)
      }
    }
    
    // 超过最大重试次数
    this.reconnecting = false
    return false
  }
  
  /**
   * 获取重连延迟
   */
  private getRetryDelay(): number {
    const index = Math.min(this.retryCount, this.retryDelays.length - 1)
    return this.retryDelays[index]
  }
  
  /**
   * 重置重连状态
   */
  public reset(): void {
    this.retryCount = 0
    this.reconnecting = false
  }
}
```

#### 9.2 消息发送队列

```typescript
class MessageSendQueue {
  private queue: Array<QueuedMessage>
  private processing: boolean = false
  
  /**
   * 添加消息到队列
   */
  public enqueue(message: ImMessage, callback: (success: boolean) => void): void {
    this.queue.push({
      message,
      callback,
      retryCount: 0,
      maxRetries: 3
    })
    
    // 触发处理
    this.processQueue()
  }
  
  /**
   * 处理队列
   */
  private async processQueue(): Promise<void> {
    if (this.processing || this.queue.length === 0) {
      return
    }
    
    this.processing = true
    
    while (this.queue.length > 0) {
      const item = this.queue[0]
      
      try {
        // 发送消息
        await websocket.send(item.message)
        
        // 发送成功，移除队列
        this.queue.shift()
        item.callback(true)
        
      } catch (e) {
        item.retryCount++
        
        if (item.retryCount >= item.maxRetries) {
          // 超过重试次数，标记失败
          this.queue.shift()
          item.callback(false)
        } else {
          // 等待后重试
          await sleep(1000 * item.retryCount)
        }
      }
    }
    
    this.processing = false
  }
}

type QueuedMessage = {
  message: ImMessage
  callback: (success: boolean) => void
  retryCount: number
  maxRetries: number
}
```


### 10. 文件上传设计

**重要**: 文件上传功能已完整实现，本节说明如何集成现有服务。

#### 10.1 现有文件上传服务

**后端 API** (已实现):
- 接口: `POST /app-api/infra/file/upload`
- 控制器: `AppFileController.java`
- 参数: MultipartFile file, String directory (可选)
- 返回: { code, msg, data: { url, path, name, size, type } }

**前端工具** (已实现):
- 文件: `utils/upload.uts`
- 方法:
  - `uploadFile(filePath, config)`: 通用上传方法
  - `chooseAndUploadImage(count, config)`: 选择并上传图片
  - `chooseAndUploadVideo(config)`: 选择并上传视频
  - `chooseAndUploadFile(accept, config)`: 选择并上传文件
- 支持上传进度回调
- 支持文件大小验证
- 兼容 Android、iOS、Web 三端

**群文件管理** (已部分实现):
- 控制器: `AppImGroupFileController.java`
- 接口:
  - `POST /system/im/group/file/upload`: 上传群文件
  - `GET /system/im/group/file/list`: 获取群文件列表
  - `DELETE /system/im/group/file/delete`: 删除群文件
  - `POST /system/im/group/file/download`: 记录下载次数

#### 10.2 集成到消息发送流程

#### 10.2 集成到消息发送流程

**图片消息发送**:

```typescript
import { chooseAndUploadImage } from '@/utils/upload.uts'

async function sendImageMessage(targetId: number, isGroup: boolean): Promise<void> {
  try {
    // 1. 使用现有工具选择并上传图片
    const results = await chooseAndUploadImage(1, {
      directory: 'im/image',
      maxSize: 10 * 1024 * 1024,  // 10MB
      onProgress: (progress) => {
        // 显示上传进度
        showUploadProgress(progress)
      }
    })
    
    const uploadResult = results[0]
    
    // 2. 构建图片消息
    const imageMessage = {
      url: uploadResult.data.url,
      width: 0,  // 需要从图片获取
      height: 0,
      size: uploadResult.data.size
    }
    
    // 3. 发送消息
    await messageService.sendImageMessage(
      isGroup ? null : targetId,
      isGroup ? targetId : null,
      imageMessage.url,
      imageMessage.width,
      imageMessage.height,
      imageMessage.size
    )
    
  } catch (e) {
    console.error('[SendImage] 发送失败:', e)
    showToast('图片发送失败')
  }
}
```

**视频消息发送**:

```typescript
import { chooseAndUploadVideo } from '@/utils/upload.uts'

async function sendVideoMessage(targetId: number, isGroup: boolean): Promise<void> {
  try {
    // 1. 使用现有工具选择并上传视频
    const result = await chooseAndUploadVideo({
      directory: 'im/video',
      maxSize: 100 * 1024 * 1024,  // 100MB
      onProgress: (progress) => {
        showUploadProgress(progress)
      }
    })
    
    // 2. 构建视频消息
    const videoMessage = {
      url: result.data.url,
      coverUrl: '',  // 需要生成视频封面
      duration: 0,   // 需要从视频获取
      width: 0,
      height: 0
    }
    
    // 3. 发送消息
    await messageService.sendVideoMessage(
      isGroup ? null : targetId,
      isGroup ? targetId : null,
      videoMessage.url,
      videoMessage.coverUrl,
      videoMessage.duration,
      videoMessage.width,
      videoMessage.height
    )
    
  } catch (e) {
    console.error('[SendVideo] 发送失败:', e)
    showToast('视频发送失败')
  }
}
```

**文件消息发送**:

```typescript
import { chooseAndUploadFile } from '@/utils/upload.uts'

async function sendFileMessage(targetId: number, isGroup: boolean): Promise<void> {
  try {
    // 1. 使用现有工具选择并上传文件
    const result = await chooseAndUploadFile('*/*', {
      directory: 'im/file',
      maxSize: 100 * 1024 * 1024,  // 100MB
      onProgress: (progress) => {
        showUploadProgress(progress)
      }
    })
    
    // 2. 构建文件消息
    const fileMessage = {
      url: result.data.url,
      fileName: result.data.name,
      fileSize: result.data.size,
      fileType: result.data.type
    }
    
    // 3. 发送消息
    await messageService.sendFileMessage(
      isGroup ? null : targetId,
      isGroup ? targetId : null,
      fileMessage.url,
      fileMessage.fileName,
      fileMessage.fileSize,
      fileMessage.fileType
    )
    
  } catch (e) {
    console.error('[SendFile] 发送失败:', e)
    showToast('文件发送失败')
  }
}
```

#### 10.3 群文件管理集成

**上传群文件**:

```typescript
// 方式1: 使用群文件专用接口 (推荐用于群文件管理页面)
async function uploadGroupFile(groupId: number, file: File): Promise<void> {
  const formData = new FormData()
  formData.append('groupId', groupId.toString())
  formData.append('file', file)
  
  const response = await request.post('/system/im/group/file/upload', formData)
  // 返回群文件信息，包含文件ID、URL等
}

// 方式2: 使用通用上传接口 (用于消息发送)
async function uploadFileForMessage(file: File): Promise<string> {
  const result = await uploadFile(file.path, {
    directory: 'im/file'
  })
  return result.data.url
}
```

**查询群文件列表**:

```typescript
async function getGroupFiles(groupId: number, folderId: number = 0): Promise<Array<GroupFile>> {
  const response = await request.get('/system/im/group/file/list', {
    params: {
      groupId,
      folderId,
      pageNo: 1,
      pageSize: 20
    }
  })
  return response.data.list
}
```

#### 10.4 文件上传优化 (可选扩展)

**注意**: 基础文件上传已实现，以下为可选的高级功能:

**大文件分片上传** (如需支持超大文件):
- 使用 AppFileController 的 presigned-url 接口
- 前端直接上传到 OSS
- 完成后调用 create 接口记录文件

**断点续传** (如需支持):
- 保存上传进度到本地
- 使用 OSS 的分片上传 API
- 从中断位置继续上传

### 11. 消息去重设计
        return false;
    }
    
    /**
     * 检查并处理消息
     */
    public boolean checkAndProcess(ImMessage message, Runnable processor) {
        Long messageId = message.getHeader().getMessageId();
        
        if (isDuplicate(messageId)) {
            log.debug("[MessageDedup] 重复消息: {}", messageId);
            return false;
        }
        
        // 处理消息
        processor.run();
        return true;
    }
}
```

### 12. 消息顺序保证设计

#### 12.1 序列号生成

```java
@Component
public class SequenceGenerator {
    
    @Resource
    private RedisTemplate<String, Object> redisTemplate;
    
    private static final String SEQUENCE_KEY = "im:sequence:";
    
    /**
     * 生成序列号
     */
    public Long generateSequence(Long conversationId) {
        String key = SEQUENCE_KEY + conversationId;
        return redisTemplate.opsForValue().increment(key);
    }
    
    /**
     * 获取当前序列号
     */
    public Long getCurrentSequence(Long conversationId) {
        String key = SEQUENCE_KEY + conversationId;
        Object value = redisTemplate.opsForValue().get(key);
        return value != null ? Long.parseLong(value.toString()) : 0L;
    }
}
```

#### 12.2 消息排序和补发

```typescript
class MessageSequencer {
  private expectedSequence: Map<number, number>  // conversationId -> 期望的下一个序列号
  private pendingMessages: Map<number, Array<MessageItem>>  // 等待插入的消息
  
  /**
   * 处理接收到的消息
   */
  public processMessage(message: MessageItem): Array<MessageItem> {
    const conversationId = message.conversationId
    const sequence = message.sequence
    
    // 初始化期望序列号
    if (!this.expectedSequence.has(conversationId)) {
      this.expectedSequence.set(conversationId, sequence)
    }
    
    const expected = this.expectedSequence.get(conversationId)!
    
    // 消息按序到达
    if (sequence === expected) {
      const result = [message]
      this.expectedSequence.set(conversationId, expected + 1)
      
      // 检查是否有等待的消息可以插入
      const pending = this.checkPendingMessages(conversationId)
      result.push(...pending)
      
      return result
    }
    
    // 消息乱序到达
    if (sequence > expected) {
      // 缓存消息，等待前面的消息
      this.addPendingMessage(conversationId, message)
      
      // 请求补发缺失的消息
      this.requestMissingMessages(conversationId, expected, sequence - 1)
      
      return []
    }
    
    // 重复消息，忽略
    return []
  }
  
  /**
   * 检查等待的消息
   */
  private checkPendingMessages(conversationId: number): Array<MessageItem> {
    const result: Array<MessageItem> = []
    const pending = this.pendingMessages.get(conversationId) || []
    
    let expected = this.expectedSequence.get(conversationId)!
    
    // 按序列号排序
    pending.sort((a, b) => a.sequence - b.sequence)
    
    // 提取连续的消息
    while (pending.length > 0 && pending[0].sequence === expected) {
      const msg = pending.shift()!
      result.push(msg)
      expected++
    }
    
    this.expectedSequence.set(conversationId, expected)
    
    return result
  }
  
  /**
   * 请求补发缺失的消息
   */
  private async requestMissingMessages(
    conversationId: number,
    startSequence: number,
    endSequence: number
  ): Promise<void> {
    try {
      const response = await getMissingMessages({
        conversationId,
        startSequence,
        endSequence
      })
      
      // 处理补发的消息
      response.data.forEach(msg => {
        this.processMessage(msg)
      })
      
    } catch (e) {
      console.error('[MessageSequencer] 补发消息失败', e)
    }
  }
}
```

### 13. 多端同步设计

#### 13.1 同步消息类型

```typescript
enum SyncMessageType {
  MESSAGE_SENT = 'message_sent',          // 消息已发送
  MESSAGE_READ = 'message_read',          // 消息已读
  CONVERSATION_DELETED = 'conversation_deleted',  // 会话已删除
  CONVERSATION_PINNED = 'conversation_pinned',    // 会话已置顶
  CONVERSATION_MUTED = 'conversation_muted',      // 会话已免打扰
  BADGE_UPDATED = 'badge_updated'         // 角标已更新
}
```

#### 13.2 同步处理

```java
@Component
public class MultiDeviceSyncService {
    
    @Resource
    private NettyMessageSender messageSender;
    
    /**
     * 同步消息已读状态
     */
    public void syncMessageRead(Long userId, List<Long> messageIds) {
        // 构建已读回执消息
        ReadReceiptMessage receipt = ReadReceiptMessage.newBuilder()
            .addAllMessageIds(messageIds)
            .build();
        
        MessageHeader header = MessageHeader.newBuilder()
            .setMessageType(MessageType.READ_RECEIPT)
            .setTimestamp(System.currentTimeMillis())
            .build();
        
        ImMessage message = ImMessage.newBuilder()
            .setHeader(header)
            .setBody(ByteString.copyFrom(receipt.toByteArray()))
            .build();
        
        // 推送到用户的所有设备
        messageSender.sendToUser(userId, message);
    }
    
    /**
     * 同步会话操作
     */
    public void syncConversationOperation(
        Long userId,
        Long conversationId,
        String operation,
        Object data
    ) {
        // 构建同步消息
        Map<String, Object> syncData = new HashMap<>();
        syncData.put("operation", operation);
        syncData.put("conversationId", conversationId);
        syncData.put("data", data);
        
        // 推送到用户的所有设备
        messageSender.sendToUser(userId, MessageType.CUSTOM, syncData);
    }
}
```


## 正确性属性

属性是系统所有有效执行中应该保持为真的特征或行为——本质上是关于系统应该做什么的正式陈述。属性作为人类可读规范和机器可验证正确性保证之间的桥梁。

### 属性反思

在编写属性之前，我对 prework 分析进行了反思，识别并消除了冗余：

**合并的属性**:
- 1.1 和 2.1 (单聊和群聊消息发送) → 合并为"消息发送通用性"
- 6.2 和 78.1 (撤回时间限制) → 重复，只保留一个
- 33.1 和 33.2 (缓存功能和缓存命中) → 合并为"缓存一致性"
- 19.1 和 30.1 (多端消息同步和角标同步) → 合并为"多端同步一致性"

**消除的冗余**:
- 1.5 被 4.2 包含 (状态更新)
- 5.1 被 5.2 包含 (已读标记和回执)

经过反思，我将编写精简且不重复的属性集合。

### 核心消息属性

#### 属性1: 消息发送完整性

*对于任何*有效的消息内容和目标(单聊或群聊)，当用户发送消息时，系统应通过 WebSocket 发送包含完整消息头和消息体的 ImMessage

**验证: 需求 1.1, 2.1**

#### 属性2: 消息存储持久性

*对于任何*通过 WebSocket 接收的消息，Message_Service 应将消息存储到数据库，并且后续查询应能检索到该消息

**验证: 需求 1.2**

#### 属性3: 在线消息实时推送

*对于任何*在线用户的所有设备，当该用户收到新消息时，系统应通过 WebSocket 推送消息到所有在线设备

**验证: 需求 1.3, 2.3**

#### 属性4: 离线消息标记

*对于任何*离线用户，当向该用户发送消息时，Message_Service 应将消息标记为离线消息

**验证: 需求 1.4**

#### 属性5: 消息状态转换正确性

*对于任何*消息，其状态转换应遵循: 发送中 → 已发送 → 已送达 → 已读，且不应出现逆向转换

**验证: 需求 4.1, 4.2, 4.3, 4.4**

#### 属性6: 消息发送失败处理

*对于任何*发送失败的消息，系统应更新状态为"发送失败"并保留消息以供重试

**验证: 需求 1.6, 4.5**

#### 属性7: 多种消息类型支持

*对于任何*有效的消息类型(文本、图片、语音、视频、文件、位置)，系统应正确解析、存储和显示该类型的消息

**验证: 需求 3.1, 3.2, 3.3, 3.4, 3.5, 3.6**

#### 属性8: 已读回执双向性

*对于任何*被标记为已读的消息，系统应发送已读回执到发送者，且发送者应能查询到该消息的已读状态

**验证: 需求 5.1, 5.2, 5.3**

#### 属性9: 消息撤回时间限制

*对于任何*消息，当且仅当消息发送时间在2分钟内时，系统应允许撤回操作

**验证: 需求 6.2, 6.3**

#### 属性10: 消息撤回通知

*对于任何*被撤回的消息，系统应将消息状态更新为"已撤回"，并通过 WebSocket 通知所有接收者

**验证: 需求 6.4, 6.5**

#### 属性11: 引用回复完整性

*对于任何*引用回复消息，消息应包含被引用消息的 ID、内容摘要和发送者信息

**验证: 需求 8.3, 8.4**

#### 属性12: @提醒用户列表

*对于任何*包含@提醒的群聊消息，消息应包含被@用户的 ID 列表，且列表中的所有用户都应是群成员

**验证: 需求 9.3, 9.4**

#### 属性13: 正在输入状态时效性

*对于任何*用户，当用户开始输入时应发送"正在输入"状态，当停止输入超过3秒或发送消息时应发送"停止输入"状态

**验证: 需求 10.1, 10.2, 10.5**

#### 属性14: 消息搜索结果相关性

*对于任何*搜索关键词，返回的所有消息应包含该关键词，且结果应按时间倒序排列

**验证: 需求 11.1, 11.2**

#### 属性15: 会话最后消息一致性

*对于任何*会话，当收到新消息时，会话的最后消息和时间应更新为该消息，且会话应移动到列表顶部(除非置顶)

**验证: 需求 12.1, 12.2**

#### 属性16: 群组创建完整性

*对于任何*新创建的群组，系统应为所有指定的群成员创建群聊会话，且群成员列表应包含所有指定成员

**验证: 需求 13.1, 13.2**

#### 属性17: 消息分页加载一致性

*对于任何*会话，每次加载历史消息应返回指定数量的消息，且消息应按时间顺序排列不重复

**验证: 需求 15.1, 15.2**

#### 属性18: 离线消息拉取完整性

*对于任何*用户，当用户从离线状态上线时，系统应拉取离线期间的所有消息，且消息顺序应与发送顺序一致

**验证: 需求 17.1, 17.2**

#### 属性19: 多端消息同步一致性

*对于任何*用户的多个在线设备，当在设备A执行操作(发送消息、阅读消息、删除会话等)时，设备B应实时收到同步更新

**验证: 需求 19.1, 19.2, 19.3, 19.4, 19.5, 19.6**

#### 属性20: 设备类型互踢规则

*对于任何*用户，当在同类型设备登录时，旧设备应被踢下线，当在不同类型设备登录时，所有设备应保持在线

**验证: 需求 20.1, 20.2**

#### 属性21: 通话信令传递

*对于任何*通话操作(发起、接听、拒绝、挂断)，系统应通过 WebSocket 发送对应的信令消息到目标用户

**验证: 需求 21.1, 21.2, 21.3, 21.4, 21.5, 22.1, 22.2, 22.3, 22.4, 22.5**

#### 属性22: 通话记录完整性

*对于任何*结束的通话，系统应保存包含通话类型、时长、开始时间、结束时间的完整记录

**验证: 需求 23.1, 23.2**

#### 属性23: 角标数量准确性

*对于任何*会话，会话的未读数应等于该会话中状态为"未读"的消息数量

**验证: 需求 28.1**

#### 属性24: 角标格式化规则

*对于任何*未读数，当未读数≤99时应显示具体数字，当未读数>99时应显示"99+"

**验证: 需求 28.2, 28.3**

#### 属性25: 角标多端同步

*对于任何*用户的多个设备，当在设备A改变未读数时，设备B应通过 WebSocket 收到角标更新消息

**验证: 需求 30.1, 30.2, 30.3**

#### 属性26: 虚拟滚动渲染范围

*对于任何*消息列表，虚拟滚动应只渲染可见区域及缓冲区的消息，渲染数量应远小于总消息数

**验证: 需求 31.1, 31.2**

#### 属性27: 缓存一致性

*对于任何*用户信息，首次查询应从服务器获取并缓存，后续查询应使用缓存数据，直到缓存失效

**验证: 需求 33.1, 33.2, 67.1**

#### 属性28: 断线重连指数退避

*对于任何*连接失败，重连延迟应遵循指数退避策略(1s, 2s, 4s, 8s, 16s, 30s)，且重连次数应有上限

**验证: 需求 36.2, 36.4**

#### 属性29: 消息重试幂等性

*对于任何*发送失败的消息，重试时应使用相同的消息 ID，确保服务器端去重

**验证: 需求 37.3, 39.4**

#### 属性30: 消息格式校验

*对于任何*接收到的消息，系统应校验必需字段的存在性，缺失字段应使用默认值

**验证: 需求 38.1, 38.2**

#### 属性31: 消息去重幂等性

*对于任何*消息 ID，系统应只处理一次，重复接收的消息应被忽略

**验证: 需求 39.1, 39.2**

#### 属性32: 消息序列号有序性

*对于任何*会话的消息列表，消息应按 sequence 升序排列，且 sequence 应严格递增

**验证: 需求 40.1, 40.2, 40.4**

#### 属性33: 文件上传返回 URL

*对于任何*通过现有 upload.uts 上传的文件，系统应返回可访问的 URL，且该 URL 应能成功访问文件

**验证: 需求 41.1, 41.3**

**注意**: 此属性验证现有 upload.uts 工具的正确性，无需重新实现上传功能

#### 属性34: 大文件分片上传 (可选)

*对于任何*大于10MB的文件，如果实现分片上传功能，系统应将文件分片上传，且所有分片上传成功后应合并为完整文件

**验证: 需求 42.1**

**注意**: 此为可选扩展功能，基础上传已通过 upload.uts 实现

#### 属性35: 断点续传状态保存 (可选)

*对于任何*中断的文件上传，如果实现断点续传功能，系统应保存已上传的分片信息，恢复时应从中断位置继续

**验证: 需求 42.2, 42.3**

**注意**: 此为可选扩展功能，基础上传已通过 upload.uts 实现

#### 属性36: 敏感词过滤替换

*对于任何*包含敏感词的消息，系统应将敏感词替换为星号，且替换后的消息不应包含原敏感词

**验证: 需求 44.1, 44.2**

#### 属性37: 消息频率限制

*对于任何*用户，当发送频率超过每秒10条时，系统应拒绝发送并返回"发送过于频繁"错误

**验证: 需求 45.1, 45.2**

#### 属性38: 会话置顶排序

*对于任何*会话列表，置顶会话应始终在列表顶部，且置顶会话之间按最后消息时间倒序排列

**验证: 需求 46.2, 46.3**

#### 属性39: 草稿往返一致性

*对于任何*会话的草稿内容，保存后重新进入会话应恢复相同的草稿内容

**验证: 需求 47.1, 47.2**

#### 属性40: 群成员操作权限

*对于任何*群组，只有群主和管理员应能执行管理操作(添加/移除成员、禁言等)，普通成员应被拒绝

**验证: 需求 51.1, 51.2, 51.6, 52.1**

#### 属性41: 禁言限制有效性

*对于任何*被禁言的群成员，该成员发送消息的尝试应被拒绝，且应返回"您已被禁言"错误

**验证: 需求 52.2**

#### 属性42: 消息长度限制

*对于任何*文本消息，当内容长度超过5000字符时，系统应拒绝发送并返回长度限制错误

**验证: 需求 57.1, 57.2**

#### 属性43: 本地存储往返一致性

*对于任何*接收到的消息，保存到本地数据库后查询应返回相同的消息内容

**验证: 需求 58.1, 58.2**

#### 属性44: 消息确认机制

*对于任何*发送的消息，系统应等待服务器的 ACK 确认，未收到确认的消息应标记为"发送中"状态

**验证: 需求 69.1, 88.1**

#### 属性45: 分布式会话共享

*对于任何*用户会话，在任意服务器节点查询应返回相同的会话状态

**验证: 需求 70.1, 70.2**

#### 属性46: 协议自适应选择

*对于任何*客户端连接，系统应根据客户端类型自动选择协议(Web 使用 JSON，移动端使用 Protobuf)

**验证: 需求 71.1, 71.2**

#### 属性47: 在线状态广播

*对于任何*用户的好友，当该用户上线或离线时，所有好友应收到在线状态变更通知

**验证: 需求 73.1, 73.2**

#### 属性48: 免打扰设置持久性

*对于任何*会话的免打扰设置，保存后查询应返回相同的设置状态

**验证: 需求 75.1**

#### 属性49: 心跳保活时效性

*对于任何*WebSocket 连接，系统应每30秒发送心跳，且60秒内未收到心跳应关闭连接

**验证: 需求 85.1, 85.3**

#### 属性50: 消息队列顺序性

*对于任何*添加到发送队列的消息，系统应按添加顺序发送，且队列中的消息不应丢失

**验证: 需求 87.1, 87.2, 87.4**

#### 属性51: 租户数据隔离

*对于任何*租户的用户，查询消息或会话时应只返回该租户的数据，不应返回其他租户的数据

**验证: 需求 90.1, 90.3, 90.4**

### 边界和特殊情况属性

#### 属性52: 空消息拒绝

*对于任何*空字符串或纯空格的文本消息，系统应拒绝发送

**验证: 需求 38.1**

#### 属性53: 消息 ID 唯一性

*对于任何*生成的消息 ID，应全局唯一且不重复

**验证: 需求 39.3**

#### 属性54: 序列号连续性检测

*对于任何*会话，当检测到序列号跳跃时，系统应请求服务器补发缺失的消息

**验证: 需求 40.5**

#### 属性55: 文件大小限制

*对于任何*文件上传，当文件大小超过100MB时，系统应拒绝上传并返回大小限制错误

**验证: 需求 41.1**

#### 属性56: 消息类型转换一致性

*对于任何*消息类型编号(REST API 的1-6或 WebSocket 的100-106)，类型转换函数应返回正确的字符串类型

**验证: 需求 71.1, 71.2**

#### 属性57: 群成员列表一致性

*对于任何*群组，添加成员后群成员列表应包含新成员，移除成员后群成员列表不应包含该成员

**验证: 需求 51.1, 51.2**

#### 属性58: 禁言时长自动解除

*对于任何*有时长限制的禁言，当禁言时长到期时，系统应自动解除禁言状态

**验证: 需求 52.3**


## 错误处理

### 1. 网络错误处理

#### 1.1 WebSocket 连接失败

**场景**: WebSocket 连接建立失败或连接中断

**处理策略**:
- 立即尝试重新连接
- 使用指数退避策略 (1s, 2s, 4s, 8s, 16s, 30s)
- 最多重试10次
- 显示"网络连接失败"提示
- 提供手动重试按钮
- 保存未发送的消息到队列

**代码示例**:
```typescript
async function handleConnectionError(error: Error): Promise<void> {
  console.error('[WebSocket] 连接失败:', error)
  
  // 显示错误提示
  showToast('网络连接失败，正在重试...')
  
  // 触发重连
  const success = await reconnectStrategy.reconnect(() => websocket.connect())
  
  if (!success) {
    showToast('网络连接失败，请检查网络后手动重试')
  }
}
```

#### 1.2 HTTP 请求失败

**场景**: REST API 请求失败(超时、网络错误、服务器错误)

**处理策略**:
- 自动重试3次
- 显示错误提示
- 提供手动重试按钮
- 使用缓存数据降级
- 记录错误日志

**代码示例**:
```typescript
async function handleApiError(error: Error, retryFunc: () => Promise<any>): Promise<any> {
  console.error('[API] 请求失败:', error)
  
  // 尝试重试
  for (let i = 0; i < 3; i++) {
    try {
      await sleep(1000 * (i + 1))
      return await retryFunc()
    } catch (e) {
      console.error(`[API] 重试失败 (${i + 1}/3)`, e)
    }
  }
  
  // 重试失败，使用缓存或显示错误
  showToast('加载失败，请稍后重试')
  throw error
}
```

### 2. 数据错误处理

#### 2.1 消息格式错误

**场景**: 接收到格式不正确的消息(字段缺失、类型错误)

**处理策略**:
- 使用默认值填充缺失字段
- 记录警告日志
- 继续处理消息不中断
- 上报异常到监控系统

**代码示例**:
```typescript
function parseMessage(data: any): MessageItem {
  try {
    return {
      id: data.id || 0,
      messageId: data.messageId || 0,
      senderId: data.senderId || 0,
      receiverId: data.receiverId || null,
      groupId: data.groupId || null,
      type: data.type || 'text',
      content: data.content || '',
      isSelf: data.isSelf || false,
      timestamp: data.timestamp || Date.now(),
      status: data.status || 'sent',
      // ... 其他字段使用默认值
    }
  } catch (e) {
    console.error('[MessageParser] 解析失败:', e, data)
    // 返回最小可用的消息对象
    return createDefaultMessage()
  }
}
```

#### 2.2 JSON 解析失败

**场景**: JSON.parse() 抛出异常

**处理策略**:
- 捕获异常不中断程序
- 返回原始字符串作为后备
- 记录解析错误和原始数据
- 显示消息但标记为"格式错误"

**代码示例**:
```typescript
function safeJsonParse(jsonStr: string, fallback: any = null): any {
  try {
    return JSON.parse(jsonStr)
  } catch (e) {
    console.error('[JSON] 解析失败:', e, jsonStr)
    return fallback
  }
}
```

#### 2.3 数据库操作失败

**场景**: 数据库插入、更新、查询失败

**处理策略**:
- 回滚事务保证数据一致性
- 返回明确的错误信息
- 记录详细错误日志
- 对于查询失败，使用缓存降级
- 对于写入失败，重试或提示用户

**代码示例**:
```java
@Transactional(rollbackFor = Exception.class)
public void saveMessage(ImMessageDO message) {
    try {
        messageMapper.insert(message);
        conversationService.updateLastMessage(message);
    } catch (Exception e) {
        log.error("[MessageService] 保存消息失败: messageId={}", message.getMessageId(), e);
        throw new ServiceException("消息保存失败，请重试");
    }
}
```

### 3. 业务错误处理

#### 3.1 权限不足

**场景**: 用户尝试执行无权限的操作(如普通成员发布群公告)

**处理策略**:
- 拒绝操作
- 返回明确的权限错误
- 显示"权限不足"提示
- 记录权限违规日志

**代码示例**:
```java
public void publishAnnouncement(Long groupId, String content, Long operatorId) {
    // 检查权限
    ImGroupMemberDO member = groupMemberMapper.selectByGroupIdAndUserId(groupId, operatorId);
    if (member == null || member.getMemberRole() == 0) {
        throw new ServiceException("权限不足，只有群主和管理员可以发布公告");
    }
    
    // 执行操作
    // ...
}
```

#### 3.2 消息撤回超时

**场景**: 用户尝试撤回超过2分钟的消息

**处理策略**:
- 拒绝撤回操作
- 返回"超过2分钟无法撤回"错误
- 显示错误提示
- 不影响其他功能

**代码示例**:
```java
public void recallMessage(Long userId, Long messageId) {
    ImMessageDO message = messageMapper.selectById(messageId);
    
    // 检查权限
    if (!message.getSenderId().equals(userId)) {
        throw new ServiceException("无权撤回该消息");
    }
    
    // 检查时间
    if (message.getCreateTime().plusMinutes(2).isBefore(LocalDateTime.now())) {
        throw new ServiceException("超过2分钟，无法撤回");
    }
    
    // 执行撤回
    // ...
}
```

#### 3.3 群组不存在

**场景**: 用户尝试操作不存在的群组

**处理策略**:
- 返回"群组不存在"错误
- 显示错误提示
- 从本地删除该会话
- 刷新会话列表

**代码示例**:
```java
public ImGroupRespVO getGroup(Long groupId) {
    ImGroupDO group = groupMapper.selectById(groupId);
    if (group == null || group.getDeleted()) {
        throw new ServiceException("群组不存在或已解散");
    }
    return convertToVO(group);
}
```

### 4. 性能错误处理

#### 4.1 内存溢出

**场景**: 消息列表过大导致内存不足

**处理策略**:
- 使用虚拟滚动限制渲染数量
- 定期清理不可见消息
- 限制缓存大小使用 LRU 淘汰
- 监控内存使用率
- 超过阈值时主动释放内存

**代码示例**:
```typescript
class MemoryMonitor {
  private maxMemoryMB: number = 200
  
  public checkMemory(): void {
    const memoryUsage = getMemoryUsage()
    
    if (memoryUsage > this.maxMemoryMB) {
      console.warn('[Memory] 内存使用过高:', memoryUsage, 'MB')
      
      // 清理缓存
      messageCache.clear()
      userInfoCache.clear()
      
      // 触发垃圾回收
      if (global.gc) {
        global.gc()
      }
    }
  }
}
```

#### 4.2 消息加载超时

**场景**: 消息加载时间过长

**处理策略**:
- 设置30秒超时
- 超时后取消请求
- 显示"加载超时"提示
- 提供重试按钮
- 使用本地缓存降级

**代码示例**:
```typescript
async function loadMessagesWithTimeout(conversationId: number): Promise<Array<MessageItem>> {
  const timeoutPromise = new Promise((_, reject) => {
    setTimeout(() => reject(new Error('加载超时')), 30000)
  })
  
  try {
    return await Promise.race([
      getMessageList(conversationId),
      timeoutPromise
    ])
  } catch (e) {
    console.error('[MessageLoader] 加载超时:', e)
    showToast('加载超时，请重试')
    
    // 使用本地缓存
    return messageCache.getConversationMessages(conversationId)
  }
}
```

### 5. 并发错误处理

#### 5.1 消息并发冲突

**场景**: 多个设备同时操作同一消息(如同时撤回)

**处理策略**:
- 使用乐观锁(版本号)
- 第一个操作成功，后续操作返回"已被处理"
- 同步最新状态到所有设备
- 不影响其他消息操作

**代码示例**:
```java
@Transactional(rollbackFor = Exception.class)
public void recallMessage(Long userId, Long messageId) {
    // 使用乐观锁
    ImMessageDO message = messageMapper.selectById(messageId);
    
    if (message.getStatus() == 2) {
        throw new ServiceException("消息已被撤回");
    }
    
    // 更新状态(带版本号)
    int updated = messageMapper.updateStatusWithVersion(
        messageId,
        2,  // 已撤回
        message.getVersion()
    );
    
    if (updated == 0) {
        throw new ServiceException("消息已被其他设备撤回");
    }
}
```

#### 5.2 会话并发更新

**场景**: 多个设备同时更新会话设置

**处理策略**:
- 使用 Redis 分布式锁
- 最后一次更新生效
- 同步最新状态到所有设备
- 记录冲突日志

**代码示例**:
```java
public void updateConversation(Long conversationId, Long userId, ConversationUpdateReqVO reqVO) {
    String lockKey = "im:conversation:lock:" + conversationId;
    
    try {
        // 获取分布式锁
        boolean locked = redisLock.tryLock(lockKey, 5, TimeUnit.SECONDS);
        if (!locked) {
            throw new ServiceException("操作过于频繁，请稍后重试");
        }
        
        // 更新会话
        conversationMapper.updateById(conversationId, reqVO);
        
        // 同步到所有设备
        syncService.syncConversationUpdate(userId, conversationId, reqVO);
        
    } finally {
        redisLock.unlock(lockKey);
    }
}
```

### 6. 第三方服务错误处理

#### 6.1 OSS 上传失败

**场景**: 文件上传到 OSS 失败

**处理策略**:
- 自动重试3次
- 重试失败后提示用户
- 保存上传失败的文件信息
- 提供稍后重试功能
- 记录失败日志

**代码示例**:
```typescript
async function uploadToOSS(file: File): Promise<string> {
  let lastError: Error | null = null
  
  for (let i = 0; i < 3; i++) {
    try {
      return await ossClient.upload(file)
    } catch (e) {
      lastError = e as Error
      console.error(`[OSS] 上传失败 (${i + 1}/3):`, e)
      await sleep(1000 * (i + 1))
    }
  }
  
  // 重试失败
  showToast('文件上传失败，请稍后重试')
  throw lastError
}
```

#### 6.2 推送服务失败

**场景**: 离线推送发送失败

**处理策略**:
- 记录失败日志
- 不影响消息存储
- 后台重试推送
- 用户上线后通过 WebSocket 补推
- 监控推送成功率

**代码示例**:
```java
@Override
public boolean pushOfflineMessage(Long userId, ImMessageDO message) {
    try {
        jpushClient.push(userId, buildNotification(message));
        return true;
    } catch (Exception e) {
        log.error("[OfflinePush] 推送失败: userId={}, messageId={}", 
            userId, message.getId(), e);
        
        // 记录失败，但不影响消息存储
        // 用户上线后会通过 WebSocket 接收消息
        return false;
    }
}
```

### 7. 数据一致性错误处理

#### 7.1 消息序列号跳跃

**场景**: 接收到的消息序列号不连续

**处理策略**:
- 缓存乱序消息
- 请求服务器补发缺失消息
- 按序列号重新排序
- 超时后放弃等待，显示现有消息
- 记录序列号异常日志

**代码示例**:
```typescript
function handleSequenceGap(conversationId: number, expected: number, received: number): void {
  console.warn('[Sequence] 序列号跳跃:', {conversationId, expected, received})
  
  // 请求补发
  requestMissingMessages(conversationId, expected, received - 1)
  
  // 设置超时
  setTimeout(() => {
    // 超时后放弃等待，显示现有消息
    console.warn('[Sequence] 补发超时，放弃等待')
    messageSequencer.forceFlush(conversationId)
  }, 5000)
}
```

#### 7.2 未读数不一致

**场景**: 客户端和服务器的未读数不一致

**处理策略**:
- 定期从服务器同步未读数
- 用户进入会话时强制同步
- 提供手动同步功能
- 以服务器数据为准
- 记录不一致日志

**代码示例**:
```typescript
async function syncUnreadCount(conversationId: number): Promise<void> {
  try {
    const response = await getConversationDetail(conversationId)
    const serverUnread = response.data.unreadCount
    const localUnread = conversationService.getUnreadCount(conversationId)
    
    if (serverUnread !== localUnread) {
      console.warn('[UnreadSync] 未读数不一致:', {conversationId, serverUnread, localUnread})
      
      // 以服务器数据为准
      conversationService.setUnreadCount(conversationId, serverUnread)
      badgeService.syncFromServer()
    }
  } catch (e) {
    console.error('[UnreadSync] 同步失败:', e)
  }
}
```

### 8. 用户操作错误处理

#### 8.1 发送空消息

**场景**: 用户尝试发送空字符串或纯空格消息

**处理策略**:
- 客户端验证拒绝发送
- 显示"不能发送空消息"提示
- 保持输入框内容
- 不发送到服务器

**代码示例**:
```typescript
function validateMessageContent(content: string): boolean {
  const trimmed = content.trim()
  
  if (trimmed.length === 0) {
    showToast('不能发送空消息')
    return false
  }
  
  if (trimmed.length > 5000) {
    showToast('消息长度不能超过5000字符')
    return false
  }
  
  return true
}
```

#### 8.2 重复操作

**场景**: 用户快速重复点击发送按钮

**处理策略**:
- 使用防抖机制
- 禁用按钮直到操作完成
- 忽略重复请求
- 显示"正在发送"状态

**代码示例**:
```typescript
const sendMessage = debounce(async (content: string) => {
  if (sending.value) {
    return
  }
  
  sending.value = true
  
  try {
    await messageService.sendTextMessage(targetId, content)
  } finally {
    sending.value = false
  }
}, 300)
```

### 9. 系统错误处理

#### 9.1 服务器宕机

**场景**: 服务器宕机或不可用

**处理策略**:
- 自动切换到其他服务器节点
- 使用负载均衡器的健康检查
- 显示"服务暂时不可用"提示
- 保存未发送的消息
- 服务恢复后自动重连

**代码示例**:
```typescript
async function handleServerDown(): Promise<void> {
  console.error('[Server] 服务器不可用')
  
  // 尝试切换到备用服务器
  const backupServers = getBackupServers()
  
  for (const server of backupServers) {
    try {
      await websocket.connect(server)
      console.log('[Server] 切换到备用服务器:', server)
      return
    } catch (e) {
      console.error('[Server] 备用服务器连接失败:', server, e)
    }
  }
  
  // 所有服务器都不可用
  showToast('服务暂时不可用，请稍后重试')
}
```

#### 9.2 Redis 不可用

**场景**: Redis 缓存服务不可用

**处理策略**:
- 降级到直接查询数据库
- 记录 Redis 错误日志
- 触发告警通知运维
- 不影响核心功能
- Redis 恢复后自动恢复缓存

**代码示例**:
```java
public UserInfo getUserInfo(Long userId) {
    try {
        // 尝试从 Redis 获取
        UserInfo cached = (UserInfo) redisTemplate.opsForValue().get("user:" + userId);
        if (cached != null) {
            return cached;
        }
    } catch (Exception e) {
        log.error("[Cache] Redis 不可用，降级到数据库查询", e);
    }
    
    // 从数据库查询
    UserInfo userInfo = userMapper.selectById(userId);
    
    try {
        // 尝试缓存
        redisTemplate.opsForValue().set("user:" + userId, userInfo, 1, TimeUnit.HOURS);
    } catch (Exception e) {
        log.error("[Cache] Redis 缓存失败", e);
    }
    
    return userInfo;
}
```

### 10. 错误恢复策略

#### 10.1 自动恢复

**适用场景**:
- 网络临时中断
- 服务器临时不可用
- 缓存服务临时故障

**恢复策略**:
- 自动重试
- 指数退避
- 降级处理
- 后台恢复

#### 10.2 手动恢复

**适用场景**:
- 长时间网络故障
- 数据不一致
- 权限问题
- 配置错误

**恢复策略**:
- 显示明确的错误信息
- 提供手动重试按钮
- 提供刷新/同步功能
- 引导用户解决问题

#### 10.3 降级处理

**降级优先级**:
1. 核心功能优先 (消息发送接收)
2. 使用缓存数据
3. 禁用非核心功能
4. 显示简化界面
5. 记录降级日志

## 测试策略

### 双重测试方法

本系统需要单元测试和基于属性的测试相结合:

**单元测试**: 关注特定示例、边界情况和错误条件
- 测试特定的消息类型转换
- 测试特定的时间格式化
- 测试特定的权限检查
- 测试特定的错误场景
- 测试组件集成点

**属性测试**: 验证所有输入的通用属性
- 使用随机消息数据测试消息处理
- 使用随机用户数据测试缓存一致性
- 使用随机序列号测试消息排序
- 使用随机会话数据测试会话管理
- 使用随机群组数据测试群组功能

### 测试工具和框架

**后端测试**:
- JUnit 5: 单元测试框架
- Mockito: Mock 框架
- jqwik: 基于属性的测试库 (Java)
- Spring Boot Test: 集成测试
- Testcontainers: 数据库测试

**前端测试**:
- Vitest: 单元测试框架
- fast-check: 基于属性的测试库 (TypeScript)
- @vue/test-utils: Vue 组件测试
- MSW: API Mock

### 基于属性的测试配置

**配置要求**:
- 每个属性测试最少100次迭代
- 每个测试标记为: **Feature: im-complete-message-system, Property {number}: {property_text}**
- 使用适当的生成器生成测试数据
- 测试失败时记录反例

**测试组织**:

后端:
```
src/test/java/
  com/shengyu/module/system/service/im/
    unit/
      ImMessageServiceTest.java
      ImConversationServiceTest.java
      ImGroupServiceTest.java
    property/
      MessageProcessingPropertyTest.java
      ConversationManagementPropertyTest.java
      GroupManagementPropertyTest.java
```

前端:
```
tests/
  unit/
    message-service.test.ts
    conversation-service.test.ts
    badge-service.test.ts
  property/
    message-processing.property.test.ts
    cache-consistency.property.test.ts
    message-ordering.property.test.ts
```

### 测试覆盖率目标

- 单元测试覆盖率: 核心代码的80%+
- 属性测试覆盖率: 所有已识别的属性(58个属性)
- 集成测试覆盖率: 所有面向用户的关键流程
- 边界情况覆盖率: 所有错误处理场景

### 性能测试

**测试场景**:
1. 单机50w并发连接测试
2. 消息吞吐量测试 (10w+ msg/s)
3. 消息延迟测试 (局域网<100ms, 广域网<500ms)
4. 大群组消息广播测试 (500人群)
5. 长时间稳定性测试 (7x24小时)

**测试工具**:
- JMeter: 压力测试
- Gatling: 性能测试
- Prometheus + Grafana: 监控

### 集成测试

**测试流程**:
1. 用户登录和认证
2. 发送单聊消息
3. 发送群聊消息
4. 消息撤回和转发
5. 已读回执
6. 多端同步
7. 离线消息拉取
8. 语音/视频通话信令
9. 系统通知推送
10. 角标实时更新

**测试环境**:
- 开发环境: 单机部署
- 测试环境: 3节点集群
- 预发环境: 生产级配置
- 生产环境: 灰度发布

