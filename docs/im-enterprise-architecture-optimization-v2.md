# 企业级 IM 全链路优化方案（对标企业微信/飞书）

> 版本：v7.0（新增弱网/断网场景企业级 UX 设计，对标微信）
> 创建时间：2026-06-15
> 最后更新：2026-06-15
> 目标：50w 并发 + 等保三级合规 + 国密算法支持
> 范围：后端 Netty + Spring Boot + 移动端 Flutter + 数据库
> 审查范围：后端 8 个核心文件（完整源码逐行审查） + Flutter 客户端 6 个核心文件（完整源码逐行审查）

---

## 一、架构现状评估

### 1.1 整体架构

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter Client (Mobile/Web)               │
│  ┌──────────┐ ┌──────────────┐ ┌──────────────┐ ┌───────────┐ │
│  │WebSocket │ │  HTTP Rest   │ │  Upload Dio  │ │  Local DB │ │
│  │ Client   │ │  Controllers │ │  (Files)     │ │  (Cache)  │ │
│  └────┬─────┘ └──────┬───────┘ └──────┬───────┘ └───────────┘ │
│       │              │                │                        │
├───────┼──────────────┼────────────────┼────────────────────────┤
│       │              │                │                        │
│  ┌────▼─────┐ ┌──────▼───────┐ ┌──────▼───────┐               │
│  │ Netty    │ │ Spring MVC   │ │ File Server  │               │
│  │ WS:9000  │ │ HTTP:48080   │ │ OSS/Local    │               │
│  │ (Proto)  │ │ (REST API)   │ │              │               │
│  └────┬─────┘ └──────┬───────┘ └──────┬───────┘               │
│       │              │                │                        │
│  ┌────▼──────────────▼────────────────▼───────┐               │
│  │            Service Layer                    │               │
│  │  ImMessageService / ImConversationService   │               │
│  │  ImGroupService / ImBadgeService            │               │
│  │  ImPresenceService / ImReadReceiptService   │               │
│  └──────────────────┬─────────────────────────┘               │
│                     │                                         │
│  ┌──────────────────▼─────────────────────────┐               │
│  │         MySQL + Redis (Presence/限流)       │               │
│  └────────────────────────────────────────────┘               │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 已完成优化（前序迭代 + 源码确认）

| 序号 | 优化项 | 状态 | 源码确认 |
|------|--------|------|----------|
| 1 | AndroidManifest 网络权限补全 | ✅ | 已确认 |
| 2 | Netty LoggingHandler 移除 | ✅ | 已确认 |
| 3 | JSON 消息最大长度限制（256KB） | ✅ | 已确认 |
| 4 | N+1 查询消除（群成员批量查询） | ✅ | 已确认 |
| 5 | SQL 层未读数聚合 | ✅ | 已确认 |
| 6 | 数据库索引优化 | ✅ | 已确认 |
| 7 | 会话增量同步游标机制 | ✅ | 已确认 |
| 8 | Presence 服务（Redis 在线状态） | ✅ | 已确认 |
| 9 | 消息限流（Redis INCR 1s 窗口） | ✅ | 已确认 |
| 10 | 群禁言/全员禁言校验 | ✅ | `validateGroupSendPermission` |
| 11 | 语音文件归属校验 | ✅ | `validateVoiceMessageOwnership` |
| 12 | @提及校验 + @all 权限控制 | ✅ | `validateGroupMentions` |
| 13 | 消息幂等（DuplicateKeyException） | ✅ | `saveMessageWithId` 第 482-492 行 |
| 14 | 会话软删除 + 复活 | ✅ | `ensureChatUser` 第 1078-1112 行 |
| 15 | 会话预览 13 种消息类型 | ✅ | `buildConversationPreview` 第 970-1046 行 |
| 16 | 背压控制（sendToUser） | ✅ | `NettyMessageSender` 第 153/176/257/270 行 |
| 17 | 多设备推送 | ✅ | `sendToUser` 遍历 `getSessionsByUserId` |
| 18 | Token 撤销联动 | ✅ | `revokeByAccessToken` 第 256-312 行 |
| 19 | 角标服务（Flutter StateNotifier） | ✅ | `badge_service.dart` 完整实现 |
| 20 | 会话同步游标机制 | ✅ | Flutter `ConversationSyncCoordinator` |

### 1.3 架构亮点（基于源码深度审查 v4.0 修正）

| 亮点 | 文件 | 源码行号 | 说明 |
|------|------|----------|------|
| **双协议兼容** | `NettyChannelInitializer.java` | - | 同时支持 JSON WebSocket + Protobuf Binary，`codec` 属性协商 |
| **严格模式** | `AuthHandler.java` | - | PROBE → AUTH → 业务，未完成握手不允许业务请求 |
| **微信模式多端登录** | [NettySessionManager](file:///Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/session/NettySessionManager.java) | 全文 | 同账号同设备互踢，不同设备在线（6 维索引） |
| **群消息扇出** | [SystemMessageStorageServiceImpl](file:///Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/service/im/spi/SystemMessageStorageServiceImpl.java#L730-L967) | L730-967 | 群聊遍历成员逐推，携带 cursorVersion 避免查库 |
| **@ 提及处理** | [SystemMessageStorageServiceImpl](file:///Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/service/im/spi/SystemMessageStorageServiceImpl.java#L150-L213) | L150-213 | 完整的 @ 校验、@all 权限控制 |
| **异步会话更新** | [SystemMessageStorageServiceImpl](file:///Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/service/im/spi/SystemMessageStorageServiceImpl.java#L729) | L729 | `@Async("imTaskExecutor")` 不阻塞 Netty 线程 |
| **消息幂等** | [SystemMessageStorageServiceImpl](file:///Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/service/im/spi/SystemMessageStorageServiceImpl.java#L482-L492) | L482-492 | DuplicateKeyException 捕获，防止重投导致重复 |
| **语音消息校验** | [SystemMessageStorageServiceImpl](file:///Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/service/im/spi/SystemMessageStorageServiceImpl.java#L558-L619) | L558-619 | 文件归属、格式、时长(1s-60s)、大小(10MB)全方位校验 |
| **群禁言控制** | [SystemMessageStorageServiceImpl](file:///Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/service/im/spi/SystemMessageStorageServiceImpl.java#L215-L240) | L215-240 | 全员禁言 + 个人禁言 + 角色豁免 |
| **游标版本机制** | `ImCursorVersionService` | - | 每消息分配 cursorVersion，支持增量同步 gap 检测 |
| **角标推送** | `ImBadgeServiceImpl` | - | 增量角标 + WebSocket 推送 |
| **Presence 服务** | `ImPresenceServiceImpl` | - | Redis Hash 按设备类型存储在线状态，30 天 TTL |
| **消息限流** | [SystemMessageRateLimitServiceImpl](file:///Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/service/im/spi/SystemMessageRateLimitServiceImpl.java) | 全文 | Redis INCR + 1s TTL，10 msg/s，异常时允许通过 |
| **会话软删除** | [SystemMessageStorageServiceImpl](file:///Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/service/im/spi/SystemMessageStorageServiceImpl.java#L1078-L1112) | L1078-1112 | 删除的会话可复活（reviveSoftDeleted） |
| **会话摘要** | [SystemMessageStorageServiceImpl](file:///Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/service/im/spi/SystemMessageStorageServiceImpl.java#L970-L1046) | L970-1046 | 13 种消息类型分别处理预览文案 |
| **已读回执** | `markMessagesRead` | L244-270 | 批量标记 + 过滤不属于当前用户的消息 |
| **鉴权租约监控** | [NettyAuthLeaseMonitor](file:///Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/session/NettyAuthLeaseMonitor.java) | 全文 | 定时扫描 Session 租约，僵尸连接清理 + 续期建议 |
| **i18n 支持** | [NettyAuthLeaseMonitor](file:///Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/session/NettyAuthLeaseMonitor.java#L208-L227) | L208-227 | 租约提示支持 zh-CN/en 国际化 |
| **消息去重** | `chat_realtime_binding.dart` | L26 | `MessageDeduplicator(maxSize: 1000)` 防重复渲染 |
| **角标服务** | [badge_service.dart](file:///Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/features/im/badge/badge_service.dart) | 全文 | StateNotifier + 防抖 300ms + 节流 1s + 数据版本控制 + 24h TTL |
| **批量消息节流** | [chat_realtime_binding.dart](file:///Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/features/im/chat/presentation/providers/chat_realtime_binding.dart#L643-L783) | L643-783 | 50ms 批量窗口 + 去重 + 自动已读回执 |
| **WebSocket 重连补偿** | [chat_realtime_binding.dart](file:///Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/features/im/chat/presentation/providers/chat_realtime_binding.dart#L225-L239) | L225-239 | `authSucceeded` 后拉取离线消息，防止丢失 |
| **消息发送失败通知** | [chat_realtime_binding.dart](file:///Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/features/im/chat/presentation/providers/chat_realtime_binding.dart#L382-L429) | L382-429 | 群不存在/非群成员等错误码自动跳转 |

### 1.4 50w 并发容量评估

| 维度 | 当前实现 | 50w 需求 | 差距 |
|------|----------|----------|------|
| **连接管理** | 单机 ConcurrentHashMap | 分布式集群 + Redis Session 中心 | 🔴 大 |
| **群消息扇出** | 遍历成员逐推（写扩散） | 读扩散模型 | 🟡 中 |
| **消息存储** | 同步 INSERT + 异步会话更新 | 批量写入 + 分表 | 🟡 中 |
| **心跳处理** | Netty IdleStateHandler | O(N) 遍历，50w 需时间轮 | 🟡 中 |
| **会话快照** | 每条消息逐成员 UPDATE | Redis 中间缓存合并 | 🟡 中 |
| **数据库连接池** | 默认 Hikari | 需 500+ | 🟢 可配置 |
| **消息限流** | Redis INCR（1s 窗口） | 需滑动窗口（Token Bucket） | 🟢 可升级 |
| **内存使用** | 每连接 ~50KB | 50w×50KB≈25GB | 🟡 需调优 |

---

## 二、加密与传输协议方案（对标企业微信/飞书）

### 2.1 企业微信/飞书安全架构对比

| 安全维度 | 企业微信 | 飞书 | 本项目现状 | 推荐方案 |
|----------|----------|------|------------|----------|
| **传输加密** | TLS 1.2+ | TLS 1.3 | ws:// 明文 | wss:// + TLS 1.3 |
| **应用层加密** | 自研协议 | Protobuf | JSON 明文 + Protobuf 子协议 | Protobuf + SM4 |
| **端到端加密** | 密聊场景 | 密聊场景 | 无 | 可选 E2EE（密聊） |
| **国密算法** | SM2/SM3/SM4 | 无 | 无 | SM2/SM3/SM4 可插拔 |
| **Token 机制** | JWT + 刷新 | OAuth2 | 自定义 Token | JWT + 短租约 |
| **消息签名** | 是 | 是 | 无 | HMAC-SM3 |
| **审计合规** | 等保三级 | 等保三级 | 无 | 等保三级全套 |

### 2.2 推荐传输协议方案

#### 方案 A：Protobuf 二进制帧（推荐 ⭐⭐⭐⭐⭐）

**对标飞书架构，性能最优**

```
┌──────────────────────────────────────────────────────┐
│                  WebSocket Frame                     │
│  ┌────────────┐ ┌──────────────┐ ┌────────────────┐ │
│  │  Header    │ │  Payload     │ │  Signature     │ │
│  │  (4 bytes) │ │  (Protobuf)  │ │  (HMAC-SM3 32B)│ │
│  └────────────┘ └──────────────┘ └────────────────┘ │
│                                                      │
│  Header: [Version(1)][Type(1)][Length(2)]            │
│  Payload: Protobuf 序列化消息体                       │
│  Signature: HMAC-SM3(Header + Payload + SessionKey) │
└──────────────────────────────────────────────────────┘
```

**优势：**
- 体积减少 60-80%（相比 JSON）
- 序列化/反序列化速度快 5-10 倍
- 天然支持字段版本兼容
- 带宽成本大幅降低（50w 并发时尤其明显）

**实施路径：**
1. Phase 1：保持 JSON 兼容，新增 Protobuf 子协议协商（当前已支持 `codec` 协商，Flutter 端切换 Binary WebSocket）
2. Phase 2：Flutter 端优先切换 Protobuf（移动端带宽敏感）
3. Phase 3：Web 端通过 WebSocket BinaryType 支持
4. Phase 4：全量切换，JSON 作为降级兼容

#### 方案 B：国密 TLS + JSON（等保三级快速达标 ⭐⭐⭐⭐）

**适合快速过等保，改造成本最低**

```
传输层：wss:// + 国密 TLS（TLCP）
  ├── 签名证书：SM2
  ├── 加密证书：SM2
  └── 密钥交换：ECDHE-SM2

应用层：JSON + SM4-CBC 加密 payload
  ├── 消息体 AES 替换为 SM4
  ├── 签名 SHA-256 替换为 SM3
  └── 密钥协商 RSA 替换为 SM2
```

### 2.3 最终推荐方案（分阶段）

```
Phase 1（等保三级快速达标，2 周）
  ├── 启用 wss://（TLS 1.2+）
  ├── 消息签名（SM3-HMAC）
  └── Token 加密传输（SM2）

Phase 2（性能优化，3 周）
  ├── Flutter 端切换 Protobuf Binary（已支持 codec 协商）
  ├── 服务端完善 Protobuf 出站（已支持 ws-protobuf-outbound）
  └── 全量切换，JSON 作为降级兼容

Phase 3（密聊功能，2 周）
  ├── 端到端加密（E2EE，可选）
  ├── SM4-GCM 消息体加密
  └── 密钥轮换机制

Phase 4（全面合规，持续）
  ├── 等保三级审计日志
  ├── 数据出境合规
  └── 渗透测试 + 安全加固
```

---

## 三、P0 级优化项（50w 并发核心瓶颈）

### 3.1 群消息扇出模型优化（🔴 50w 并发核心瓶颈）

**当前实现精确链路（源码确认）：**

消息入口 [TextMessageProcessor.process](file:///Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/processor/impl/TextMessageProcessor.java#L47-L187)（第 47-187 行）：
1. 解析文本消息 → 敏感词过滤 → 调用 `saveMessageWithResult()`
2. 第 145-168 行：单聊通过 `sendToUser` 转发给接收者
3. **第 169-174 行：群聊仅打 debug 日志，不做任何推送**（"TODO: 查询群成员列表并转发"）

实际群消息扇出由 [SystemMessageStorageServiceImpl.updateChatUserAsync](file:///Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/service/im/spi/SystemMessageStorageServiceImpl.java#L730-L967)（`@Async("imTaskExecutor")`）完成：
- 第 776-794 行：遍历群成员，对每个成员执行 `updateLastMessageAndIncrementUnread`
- 第 795-812 行：发送者侧 `upsertAfterMessageForSender`
- 第 813-834 行：接收者侧 `upsertAfterMessage` + @mention 检测
- 第 844-862 行：非发送者触发 `pushIncrementalBadgeUpdate` + `sendToUserWithExtra` 实时推送

**核心问题（源码确认）：**
1. **群消息在 TextMessageProcessor 中不做扇出**（L169-174 仅 TODO），完全依赖异步的 `updateChatUserAsync` 遍历推送
2. `updateChatUserAsync` 是 **同步遍历**（`for (Long memberId : memberIds)`），1000 人群 = 1000 × (1 UPDATE + 1 UPSERT + 1 推送) = 3000+ 操作
3. 每个成员的 `ensureChatUser()` 会触发 SELECT，如果不存在则 INSERT（虽然 catch DuplicateKeyException）
4. **没有区分群规模**——100 人群和 5000 人群走完全相同的遍历逻辑

### 3.2 消息存储批量写入

**当前实现审查（源码确认）：**

`saveMessageWithId()` 是同步 `@Transactional` 方法（[第 446-509 行](file:///Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/service/im/spi/SystemMessageStorageServiceImpl.java#L446-L509)）：
- 第 460 行：`chatMapper.nextSequence(chatId)` 获取序列号（每次调用一次 SELECT + UPDATE）
- 第 482 行：`chatMessageMapper.insert(messageDO)` 单条 INSERT
- 第 495 行：`updateChatUserAsync` 异步处理会话更新

群场景下每条消息调用一次 `saveMessageWithResult()`（由 `TextMessageProcessor` 第 116 行触发），不存在批量优化。

**优化方案：**
```java
// MessageStorageService 新增批量接口
public interface MessageStorageService {
    // 现有
    void saveMessage(ImMessage message);
    MessageSaveResult saveMessageWithResult(ImMessage message);
    Long saveMessageWithId(ImMessage message);
    
    // 新增：批量写入（适用于写扩散场景）
    List<Long> batchSaveMessages(List<ImMessage> messages);
}

// 实现：使用 MyBatis batch executor
@Override
public List<Long> batchSaveMessages(List<ImMessage> messages) {
    if (messages == null || messages.isEmpty()) return Collections.emptyList();
    
    // MyBatis Batch Executor 模式
    try (SqlSession session = sqlSessionFactory.openSession(ExecutorType.BATCH, false)) {
        ImChatMessageMapper mapper = session.getMapper(ImChatMessageMapper.class);
        for (ImMessage msg : messages) {
            mapper.insert(buildDO(msg));
        }
        session.commit();
    }
    
    return messages.stream().map(m -> m.getHeader().getMessageId()).collect(Collectors.toList());
}
```

### 3.3 NettySessionManager 竞态条件修复（精确行号定位）

**当前实现审查（源码逐行确认）：**

[NettySessionManager.addSession](file:///Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/session/NettySessionManager.java#L128-L188)（第 128-188 行）的实际执行流程：

```java
// 第 136-138 行：重复认证时先清理旧 session
if (channelId != null && channelSessionMap.containsKey(channelId)) {
    removeSession(session.getChannel());
}

// 第 144-154 行：检查同设备类型互踢
String userDeviceKey = buildUserDeviceKey(userId, deviceType);
String oldChannelId = userDeviceChannelMap.get(userDeviceKey);
if (oldChannelId != null && !oldChannelId.equals(channelId)) {
    NettySession oldSession = channelSessionMap.get(oldChannelId);
    if (oldSession != null && oldSession.isActive()) {
        kickOffDevice(oldSession, session);  // 第 152 行
    }
}

// 第 157 行：保存新映射
userDeviceChannelMap.put(userDeviceKey, channelId);
```

**竞态分析（v6.0 精确定位）：**

关键发现：`kickOffDevice`（第 317-371 行）内部执行顺序：
1. L334：`removeSession(ch)` — **先移除会话索引**
2. L336-365：`writeAndFlush` 发送 KICKED 消息
3. L367：`ch.close()` — 关闭连接

而 `removeSession`（第 193-248 行）在第 219 行执行：
```java
userDeviceChannelMap.remove(userDeviceKey);  // L219: 无条件 remove
```

**实际竞态场景：**
- 线程 1（A 设备登录）：L152 `kickOffDevice(oldSession=A)` → 进入 `removeSession(channelA)` → L219 `userDeviceChannelMap.remove("1:3")` → 返回 addSession → L157 `put("1:3", "channelA")`
- 线程 2（B 设备登录，同类型）：L146 `get("1:3")` 可能拿到 channelA 或 null（取决于线程 1 执行到哪）
- 如果线程 2 在线程 1 的 L157 之后、但在 L219 之前读取，`oldChannelId` = "channelB"，然后 `kickOffDevice(B)` 又会 remove 掉 B 的映射

**根因：`removeSession` 的 L219 无条件 remove，不校验当前值是否等于被移除的 channelId**

**修复方案：**
```java
// 方案 1：removeSession 中增加保护（推荐）
// 仅当 map 中的值等于被移除的 channelId 时才 remove
String userDeviceKey = buildUserDeviceKey(userId, deviceType);
userDeviceChannelMap.compute(userDeviceKey, (key, current) ->
    current != null && current.equals(channelId) ? null : current);

// 方案 2：addSession 中先占位再踢
String existingChannelId = userDeviceChannelMap.putIfAbsent(userDeviceKey, channelId);
if (existingChannelId != null && !existingChannelId.equals(channelId)) {
    kickOffDevice(channelSessionMap.get(existingChannelId), session);
    // 再次确保新映射存在（因为 kickOffDevice → removeSession 可能误删）
    userDeviceChannelMap.put(userDeviceKey, channelId);
}
```

### 3.4 会话快照优化（🔴 大群场景核心瓶颈，精确行号定位）

**当前实现审查（源码逐行确认）：**

`updateChatUserAsync`（[第 730-968 行](file:///Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/service/im/spi/SystemMessageStorageServiceImpl.java#L730-L968)）对每个群成员执行以下操作：

1. [ensureChatUser](file:///Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/service/im/spi/SystemMessageStorageServiceImpl.java#L1078-L1112)（L1078-1112）：SELECT → 不存在则 INSERT → catch DuplicateKeyException 重试
2. `chatUserMapper.updateLastMessageAndIncrementUnread`（L783-793）：UPDATE `im_chat_user`
3. `cursorVersionService.allocateNextCursorVersion`（L795）：分配游标版本
4. `conversationUserStateMapper.upsertAfterMessage` / `upsertAfterMessageForSender`（L798-834）：UPSERT `im_conversation_user_state`
5. `chatUserMapper.markReadToSequence`（L838-843）：UPDATE 推进已读水位
6. `imBadgeService.pushIncrementalBadgeUpdate`（L845）：Redis + WebSocket 角标推送
7. `nettyMessageSender.sendToUserWithExtra`（L847-862）：WebSocket 实时推送

单聊链路（L865-962）对发送者和接收者各执行类似操作。

**精确计算（500 人群）：**
- 500 次 SELECT（ensureChatUser）
- 500 次 UPDATE（im_chat_user 未读数）
- 500 次 UPSERT（im_conversation_user_state）
- 500 次 UPDATE（markReadToSequence，发送者侧额外 +1）
- 500 次 Redis INCR（角标推送）
- 500 次 WebSocket 推送（sendToUserWithExtra）
- **总计：3000+ DB 操作 + 1000+ 网络操作，全部在单个 @Async 线程中同步执行**

**优化方案：Redis 中间缓存 + 批量合并**
```java
// 1. 会话更新先走 Redis，定时批量合并到 MySQL
@Service
public class ConversationSnapshotService {
    
    // 每条消息更新时先写 Redis
    public void updateSnapshotAsync(Long chatId, Long userId, JsonWebSocketMessage message) {
        String key = "im:snapshot:" + userId + ":" + chatId;
        redisTemplate.opsForHash().putAll(key, Map.of(
            "lastMessageId", message.getId(),
            "lastMessageSequence", message.getSequence(),
            "lastMessageType", message.getMessageType(),
            "lastMessageTime", message.getSendTime()
        ));
        redisTemplate.expire(key, 24, TimeUnit.HOURS);
        
        // 标记 dirty
        redisTemplate.opsForSet().add("im:snapshot:dirty", String.valueOf(userId + ":" + chatId));
    }
    
    // 定时合并（每 3 秒）
    @Scheduled(fixedDelay = 3000)
    public void mergeDirtySnapshots() {
        Set<String> dirtyKeys = redisTemplate.opsForSet().pop("im:snapshot:dirty", 200);
        if (dirtyKeys == null) return;
        
        for (String key : dirtyKeys) {
            // 批量 UPDATE MySQL
        }
    }
}
```

---

## 四、P1 级优化项（架构完善）

### 4.1 消息处理器未知类型告警

**当前实现审查（源码确认）：**

[MessageProcessorFactory](file:///Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/processor/MessageProcessorFactory.java) 的 `getProcessor()`（第 33-35 行）：
```java
public MessageProcessor getProcessor(MessageType messageType) {
    return processorMap.get(messageType);  // 找不到返回 null
}
```

未注册的消息类型返回 null，调用方需要处理 null 情况。缺少：
1. 未知消息类型的日志告警
2. 空处理器兜底（NOOP_PROCESSOR）
3. 监控指标上报

**优化方案：**
```java
public MessageProcessor getProcessor(String messageType) {
    MessageProcessor processor = processorMap.get(messageType);
    if (processor == null) {
        log.error("[MessageProcessorFactory] UNKNOWN message type: {}, message will be DROPPED!", messageType);
        return NOOP_PROCESSOR; // 空处理器
    }
    return processor;
}

private static final MessageProcessor NOOP_PROCESSOR = new MessageProcessor() {
    @Override
    public void process(ChannelHandlerContext ctx, ImMessage message) {
        log.warn("[NOOP_PROCESSOR] Dropped message type: {}", 
                message.getHeader().getMessageType());
    }
    @Override
    public String getSupportedMessageType() { return "noop"; }
};
```

### 4.2 心跳机制优化

**当前实现审查（源码确认）：**

Flutter 端配置 [app_config.dart](file:///Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/app/config/app_config.dart#L56-L60)（第 56-60 行）：
```dart
static const Duration socketHeartbeatInterval = Duration(seconds: 25);  // 当前 25s
static const Duration socketHeartbeatTimeout = Duration(seconds: 10);
static const Duration socketAuthTimeout = Duration(seconds: 8);
```

心跳间隔 25s 偏短，对标企业微信/飞书建议调整为 30s。移动端心跳过频会加速耗电。

**优化方案：服务端主动发心跳**
```java
@Override
protected void channelIdle(ChannelHandlerContext ctx, IdleStateEvent evt) {
    switch (evt.state()) {
        case READER_IDLE:
            // 客户端长时间未发消息，发心跳探测
            if (session != null && session.isAuthenticated()) {
                channel.writeAndFlush(createServerHeartbeat());
            }
            if (noHeartbeatCount.incrementAndGet() >= maxNoHeartbeatCount) {
                ctx.close();
            }
            break;
            
        case WRITER_IDLE:
            // 服务端长时间未发消息，主动发心跳保活
            channel.writeAndFlush(createServerHeartbeat());
            break;
            
        case ALL_IDLE:
            ctx.close();
            break;
    }
}
```

Flutter 端心跳间隔建议调整为 30s（当前 25s，对标企业微信/飞书）：
```dart
// app_config.dart
static const Duration socketHeartbeatInterval = Duration(seconds: 30);
static const Duration socketHeartbeatTimeout = Duration(seconds: 90);
```

### 4.3 sendToTenant / broadcast / sendToDevice 背压补全（精确行号定位）

**当前实现审查（源码逐行确认）：**

[NettyMessageSender](file:///Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/sender/NettyMessageSender.java)：

- `sendToUser()`（第 106-201 行）：✅ 已有 `isWritable()` 检查（L153 WebSocket, L176 Protobuf）
- `sendToUserWithFullInfo()`（第 216-290 行）：✅ 已有 `isWritable()` 检查（L257 WebSocket, L270 Protobuf）
- **`sendToTenant()`（第 318-350 行）**：❌ **缺少 `isWritable()` 检查**（L340 WebSocket, L342 Protobuf 直接 writeAndFlush）
- **`broadcast()`（第 358-377 行）**：❌ **缺少 `isWritable()` 检查**（L370 直接 writeAndFlush）
- **`sendToDevice()`（第 387-404 行）**：❌ **缺少 `isWritable()` 检查**（L396 直接 writeAndFlush）

**优化方案：**
```java
// sendToTenant 增强（第 331-343 行修改）
for (NettySession session : sessions) {
    if (!session.isActive()) continue;
    Channel channel = session.getChannel();
    if (channel == null || !channel.isWritable()) continue;  // 新增背压
    boolean ws = isWebSocketChannel(channel);
    if (ws) {
        channel.writeAndFlush(new TextWebSocketFrame(jsonPayload));
    } else {
        channel.writeAndFlush(protobufMessage);
    }
    successCount++;
}

// broadcast 增强（第 368-372 行修改）
for (NettySession session : sessions) {
    if (session.isActive()) {
        Channel channel = session.getChannel();
        if (channel == null || !channel.isWritable()) continue;  // 新增背压
        channel.writeAndFlush(message);
        successCount++;
    }
}

// sendToDevice 增强（第 391-396 行修改）
if (deviceId.equals(session.getDeviceId()) && session.isActive()) {
    Channel channel = session.getChannel();
    if (channel == null || !channel.isWritable()) return;  // 新增背压
    TenantUtils.execute(tenantId, () -> {
        channel.writeAndFlush(message);
    });
}
```

### 4.4 踢人消息延迟关闭（精确行号定位）

**当前实现审查（源码逐行确认）：**

[NettySessionManager.kickOffDevice](file:///Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/session/NettySessionManager.java#L317-L371)（第 317-371 行）：
- L334：`removeSession(ch)` — 先移除会话索引
- L336-365：`writeAndFlush` 发送 KICKED 消息（JSON TextWebSocketFrame 或 Protobuf ImMessage）
- L367：`ch.close()` — 立即关闭连接

`writeAndFlush` 是 Netty 异步操作，返回 `ChannelFuture`。`close()` 紧随其后同步调用，在 Netty 事件循环中这两个操作被放入同一个任务队列，但 `close()` 可能在 `writeAndFlush` 完成前执行，导致客户端来不及处理 KICKED 通知。

**优化方案：延迟 500ms 关闭**
```java
ch.writeAndFlush(notification)
    .addListener((ChannelFutureListener) future -> {
        future.channel().eventLoop().schedule(
            () -> future.channel().close(),
            500, TimeUnit.MILLISECONDS
        );
    });
```

### 4.5 Flutter `_serial` 链无限增长修复（精确行号定位）

**当前实现审查（源码逐行确认）：**

[SocketSessionCoordinator](file:///Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/core/websocket/socket_session_coordinator.dart#L20-L60)（第 20-60 行）：
```dart
Future<void> _serial = Future<void>.value();  // 第 24 行

void onSessionChanged(AuthSession? previous, AuthSession next) {
    _serial = _serial.then((_) => _syncSession(previous, next));  // 第 27 行
}
```

**问题分析（v6.0 修正）：**
- `authSessionProvider` 使用 `listen(..., fireImmediately: true)`（L13-17），首次初始化即触发一次
- 每次 token 刷新、登录/登出、断线重连都会触发 `onSessionChanged`
- `_syncSession` 内部可能调用 `connect()` → `auth()` → `reauth()`，每个操作耗时 200-800ms
- **链上未捕获异常**：如果 `_syncSession` 抛出异常（如 auth timeout），异常会传播到 `_serial` 链的下一层，导致后续所有任务跳过执行
- **无限增长**：`Future.then` 链永远不会缩短，即使所有任务已完成，链上每个 Future 对象仍保留在内存中

**修复方案：限制链长度 + 异常隔离**
```dart
int _chainLength = 0;

Future<void> _enqueue(FutureOr<void> Function() task) async {
    _serial = _serial.then((_) async {
        try {
            await task();
        } catch (e, st) {
            debugPrint('[SocketSessionCoordinator] task error: $e');
        }
    }).catchError((Object e) {
        debugPrint('[SocketSessionCoordinator] catchError: $e');
    });
    
    if (_chainLength++ > 100) {
        await _serial;
        _serial = Future.value();
        _chainLength = 0;
    }
}

void onSessionChanged(AuthSession? previous, AuthSession next) {
    _enqueue(() => _syncSession(previous, next));
}
```

### 4.6 Flutter `chat_realtime_binding` 内存泄漏修复（精确行号定位）

**当前实现审查（源码逐行确认）：**

[chat_realtime_binding.dart](file:///Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/features/im/chat/presentation/providers/chat_realtime_binding.dart#L26-L50)（第 26-50 行）：
```dart
final _messageDeduplicator = MessageDeduplicator(maxSize: 1000);  // L26: 全局 LRU

final Map<String, Timer> _singleChatPresenceRefreshTimers = <String, Timer>{};  // L28
final Map<String, List<Map<String, dynamic>>> _messageBatchBuffers = <String, List<Map<String, dynamic>>>{};  // L31
final Map<String, Timer> _messageBatchTimers = <String, Timer>{};  // L32
```

**分析结论（v6.0 修正）：**
- `_messageBatchBuffers` / `_messageBatchTimers` 在 `onDispose` 中已清理（L46-47）：
  ```dart
  _messageBatchBuffers.remove(chatId);         // L46: 只 remove 不 cancel
  _messageBatchTimers.remove(chatId)?.cancel(); // L47: cancel 正确
  ```
- `_singleChatPresenceRefreshTimers` 在 `onDispose` 中已清理（L44）：`?.cancel()` 正确
- `_messageDeduplicator` 有 `maxSize: 1000` 限制，`clearByChatId` 在 dispose 时调用（L49），可控
- **⚠️ 但 `_flushMessageBatch` 中 `_messageBatchTimers.remove(chatId)`（L686）在 Timer 已触发后再次 remove 是安全的**，因为 Timer 在 L678 创建，L680 触发后自动失效
- **⚠️ 真正的问题：`_messageBatchBuffers.remove(chatId)`（L687）在 `_flushMessageBatch` 被调用时执行**，但如果在 dispose 前 Timer 已触发（L680 → `_flushMessageBatch`），dispose 中的 L46 remove 会返回 null（已被 L687 remove），所以 **无明显泄漏**
- **⚠️ 但全局 Map 在高频率切换聊天窗口时可能积累大量空 entry**：`_enqueueMessageForBatch`（L663）使用 `putIfAbsent` 创建 entry，如果消息到达后 50ms 内用户切走（dispose），Timer 触发后 L687 remove，此时无泄漏。**但如果 Timer 触发前 dispose**，L46 remove buffer，L680 Timer 触发时 buffer 已被 remove，`_flushMessageBatch` 中 L687 再次 remove 返回 null，消息丢失但无泄漏。

**评价：现有代码无明显内存泄漏，但缺乏对极端场景的防御性处理。**

**建议增强：**
```dart
// 1. dispose 中先 cancel Timer，再 remove buffer，避免竞态
ref.onDispose(() {
    subscription.cancel();
    _singleChatPresenceRefreshTimers.remove(chatId)?.cancel();
    _messageBatchTimers.remove(chatId)?.cancel();  // 先 cancel
    _messageBatchBuffers.remove(chatId);           // 再 remove
    _messageDeduplicator.clearByChatId(chatId);
});
```

---

### 4.7 弱网/断网场景用户体验优化（对标微信，企业级完善） 🔴 核心需求

**需求背景：**
当网络断了或弱网接口不足以请求时，页面不应出现错误代码的情况，而应类似微信的友好提示。这是对标企业微信/飞书的核心用户体验要求。

**微信设计调研结果：**

| 场景 | 微信策略 | 说明 |
|------|----------|------|
| **消息列表断网** | Notice bar 通告栏（顶部持续提示） | 一直存在，点击跳转网络解决方案页面 |
| **聊天发送消息失败** | 消息旁显示红色感叹号 + 重试按钮 | 用户点击可重新发送 |
| **有缓存的页面** | 不立即提示，仅在请求新数据时 Toast | 已有缓存内容可正常浏览 |
| **无缓存的页面** | 整页提示 + 刷新按钮 | 如联系人列表、群列表等 |
| **网络切换（WiFi→流量）** | 弹窗确认 | 防止用户误消耗流量（视频/语音场景） |
| **通话/音视频场景** | 轻量提示"当前网络不佳" | 不弹窗、不抢占焦点，仅安静告知 |

**核心设计原则：**
1. **缓存优先**：有本地缓存时不立即提示，降低用户焦虑
2. **不打断操作**：网络异常提示不能干扰用户正常浏览缓存内容
3. **持续性提示**：IM 场景需要持续反馈网络状态（区别于非即时通讯 App）
4. **重试机制**：发送失败的消息必须有重试按钮
5. **防抖判定**：网络状态判定采用时间窗口 + 连续恶化（2~5s 持续异常才判定），避免短暂抖动频繁提示
6. **解决方案引导**：不只是告知异常，还要提供解决路径

#### 4.7.1 Flutter 客户端网络状态监控架构

**新增核心组件：**

```dart
/// 网络状态监控服务
class NetworkMonitorService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<NetworkStatus> _statusController = 
      StreamController<NetworkStatus>.broadcast();
  
  NetworkStatus _currentStatus = NetworkStatus.unknown;
  
  /// 当前网络状态
  NetworkStatus get currentStatus => _currentStatus;
  
  /// 网络状态流
  Stream<NetworkStatus> get statusStream => _statusController.stream;
  
  /// 是否处于可用网络
  bool get isNetworkAvailable => 
      _currentStatus == NetworkStatus.wifi || 
      _currentStatus == NetworkStatus.mobile;
  
  /// 是否处于弱网（通过 ping 延迟判定）
  bool get isWeakNetwork => _pingDelayMs > 500;
  
  /// 网络状态枚举
  enum NetworkStatus {
    unknown,    // 未知
    wifi,       // WiFi
    mobile,     // 移动数据
    none,       // 无网络
  }
  
  /// 初始化监控
  void init() {
    _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
    _checkCurrentStatus();
    
    // 定时网络质量探测（每 30s）
    Timer.periodic(Duration(seconds: 30), (_) => _probeNetworkQuality());
  }
  
  /// 连通性变化
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final result = results.first;
    switch (result) {
      case ConnectivityResult.wifi:
        _updateStatus(NetworkStatus.wifi);
        break;
      case ConnectivityResult.mobile:
        _updateStatus(NetworkStatus.mobile);
        break;
      case ConnectivityResult.none:
        _updateStatus(NetworkStatus.none);
        break;
      default:
        _updateStatus(NetworkStatus.unknown);
    }
  }
  
  /// 网络质量探测（ping 延迟）
  int _pingDelayMs = 0;
  Future<void> _probeNetworkQuality() async {
    final sw = Stopwatch()..start();
    try {
      await InternetAddress('ping.shengyu-im.com').timeout(Duration(seconds: 3));
      sw.stop();
      _pingDelayMs = sw.elapsedMilliseconds;
    } catch (e) {
      _pingDelayMs = 9999; // ping 失败
    }
  }
  
  /// 更新状态（带防抖）
  int _statusChangeCount = 0;
  DateTime? _lastStatusChangeTime;
  
  void _updateStatus(NetworkStatus newStatus) {
    if (newStatus == _currentStatus) return;
    
    final now = DateTime.now();
    if (_lastStatusChangeTime != null && 
        now.difference(_lastStatusChangeTime!).inSeconds < 3) {
      _statusChangeCount++;
      if (_statusChangeCount < 3) return; // 3s 内变化 3 次才判定
    } else {
      _statusChangeCount = 0;
    }
    
    _lastStatusChangeTime = now;
    _currentStatus = newStatus;
    _statusController.add(newStatus);
  }
}
```

#### 4.7.2 UI 提示组件设计

**Notice Bar 网络异常提示条：**

```dart
/// 网络异常 Notice Bar
class NetworkStatusNoticeBar extends StatelessWidget {
  final NetworkStatus status;
  final VoidCallback? onTap;
  
  const NetworkStatusNoticeBar({
    Key? key,
    required this.status,
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (status == NetworkStatus.wifi || status == NetworkStatus.mobile) {
      return const SizedBox.shrink(); // 网络正常不显示
    }
    
    return GestureDetector(
      onTap: onTap ?? () => _showNetworkSettings(context),
      child: Container(
        height: 32,
        color: const Color(0xFFFFF3CD), // 浅黄色警告背景
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.signal_wifi_off, size: 16, color: Color(0xFF856404)),
            SizedBox(width: 6),
            Text(
              status == NetworkStatus.none 
                ? '网络连接已断开，点击前往设置' 
                : '当前网络不稳定，消息可能无法及时接收',
              style: TextStyle(fontSize: 12, color: Color(0xFF856404)),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showNetworkSettings(BuildContext context) {
    // 跳转到系统网络设置（Android/iOS）
  }
}
```

**消息发送失败重试组件：**

```dart
/// 消息发送状态指示器
class MessageSendStatusIndicator extends StatelessWidget {
  final MessageSendStatus status;
  final VoidCallback? onRetry;
  
  const MessageSendStatusIndicator({
    Key? key,
    required this.status,
    this.onRetry,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MessageSendStatus.sending:
        return SizedBox(
          width: 12, height: 12,
          child: CircularProgressIndicator(strokeWidth: 1.5),
        );
      case MessageSendStatus.failed:
        return GestureDetector(
          onTap: onRetry,
          child: Icon(Icons.error_outline, color: Colors.red, size: 16),
        );
      case MessageSendStatus.sent:
      case MessageSendStatus.delivered:
      case MessageSendStatus.read:
        return const SizedBox.shrink();
    }
  }
}
```

#### 4.7.3 WebSocket 断网处理流程

```
WebSocket 断连 → ImSocketClient 检测到断连
  ↓
NetworkMonitorService 判定网络状态
  ↓
┌───────────────────────────────────────────────────────┐
│  NetworkStatus.none（完全断网）                         │
│  ├── 显示 Notice Bar："网络连接已断开，点击前往设置"     │
│  ├── 发送中的消息标记为 failed                           │
│  ├── 禁止新消息发送（本地缓存，待网络恢复后重发）         │
│  └── 启动重连（指数退避，最多 10 次）                    │
├───────────────────────────────────────────────────────┤
│  NetworkStatus.wifi/mobile 但 ping 延迟 > 500ms（弱网）│
│  ├── 显示 Notice Bar："当前网络不稳定"                  │
│  ├── 心跳超时延长至 120s（默认 90s）                    │
│  ├── 消息发送超时延长至 30s（默认 8s）                  │
│  └── 启动重连                                          │
└───────────────────────────────────────────────────────┘
  ↓
网络恢复 → NetworkMonitorService 检测到恢复
  ↓
┌───────────────────────────────────────────────────────┐
│  隐藏 Notice Bar                                      │
│  ├── 自动重连 WebSocket                                │
│  ├── 重发本地缓存的失败消息                             │
│  ├── 拉取离线消息（ConversationSyncCoordinator）       │
│  └── 刷新角标数据                                     │
└───────────────────────────────────────────────────────┘
```

#### 4.7.4 HTTP 接口弱网处理

**Dio 拦截器增强：**

```dart
/// 弱网友好的 Dio 拦截器
class WeakNetworkInterceptor extends Interceptor {
  final NetworkMonitorService networkMonitor;
  
  WeakNetworkInterceptor(this.networkMonitor);
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      
      if (!networkMonitor.isNetworkAvailable) {
        // 无网络：返回友好的本地错误
        handler.reject(DioException(
          requestOptions: err.requestOptions,
          type: DioExceptionType.unknown,
          error: '网络连接已断开，请检查网络设置',
        ));
      } else if (networkMonitor.isWeakNetwork) {
        // 弱网：增加重试
        if (err.requestOptions.extra['retryCount'] == null ||
            err.requestOptions.extra['retryCount'] < 2) {
          err.requestOptions.extra['retryCount'] = 
              (err.requestOptions.extra['retryCount'] ?? 0) + 1;
          handler.resolve(
            Dio.getInstance().fetch(err.requestOptions)
          );
        } else {
          handler.reject(DioException(
            requestOptions: err.requestOptions,
            type: DioExceptionType.unknown,
            error: '当前网络不稳定，请稍后重试',
          ));
        }
      } else {
        // 网络正常但请求失败：原始错误
        handler.next(err);
      }
    } else {
      handler.next(err);
    }
  }
}
```

#### 4.7.5 实施清单

| 组件 | 说明 | 优先级 |
|------|------|--------|
| `NetworkMonitorService` | 网络状态监控 + 防抖判定 | P1 |
| `NetworkStatusNoticeBar` | Notice Bar 提示条 | P1 |
| `MessageSendStatusIndicator` | 消息发送状态指示器 | P1 |
| `WeakNetworkInterceptor` | Dio 弱网拦截器 | P1 |
| 消息本地缓存队列 | 断网时消息本地缓存，网络恢复后重发 | P1 |
| WebSocket 重连 UI 绑定 | 重连状态与 UI 联动 | P1 |
| 网络切换弹窗（WiFi→流量） | 音视频场景弹窗确认 | P2 |

---

### 4.8 NettyAuthLeaseMonitor getAllSessions 性能问题（精确行号定位）

**当前实现审查（源码逐行确认）：**

[NettyAuthLeaseMonitor.scanOnce](file:///Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/session/NettyAuthLeaseMonitor.java#L65-L136)（第 65-136 行）：
```java
List<NettySession> sessions = sessionManager.getAllSessions();  // 第 67 行
// ...
for (NettySession session : sessions) {  // 第 77 行：O(N) 遍历
```

[NettySessionManager.getAllSessions](file:///Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/session/NettySessionManager.java#L519-L521)（第 519-521 行）：
```java
public List<NettySession> getAllSessions() {
    return new ArrayList<>(channelSessionMap.values());  // 复制全部 Session
}
```

**问题分析（v6.0 精确计算）：**
- `getAllSessions()` 每次调用都会复制整个 `channelSessionMap`（O(N) 内存分配 + GC 压力）
- 50w 并发时 = 50w 个 Session 对象 × 每次扫描 = 每次约 50-100MB 临时对象
- 扫描频率由 `nettyProperties.getAuthLeaseMonitorIntervalSeconds()` 控制（通常 30-60s）
- 每次扫描都遍历全部连接，包括未认证的僵尸连接（无意义的 CPU 消耗）

**优化方案：**
1. 将租约到期时间索引化，使用 `TreeMap<expireTime, channelId>` 替代全量遍历
2. 仅扫描即将到期或已到期的连接（O(log N) 而非 O(N)）
3. 僵尸连接由 Netty `IdleStateHandler` 自动清理，无需租约扫描器处理

---

## 五、多端登录互踢机制审计（微信模式）

### 5.1 架构设计评审

**当前实现策略（对标微信）：**
```
同一账号 + 同设备类型 → 互踢（后登录踢前登录）
同一账号 + 不同设备类型 → 允许同时在线
```

**设备类型枚举：**
| deviceType | 名称 | 说明 |
|------------|------|------|
| 1 | Web | 浏览器端 |
| 2 | iOS | iPhone/iPad |
| 3 | Android | 安卓手机/平板 |
| 4 | 小程序 | 微信小程序等 |

**6 维索引设计：**
```java
1. channelSessionMap       // channelId → Session（主索引）
2. userChannelMap          // userId → Set<channelId>（多设备查询）
3. userDeviceChannelMap    // userId:deviceType → channelId（互踢核心）
4. accessTokenChannelMap   // accessToken → channelId（Token 撤销）
5. userDeviceIdChannelMap  // userId:deviceType:deviceId → channelId（设备精确操作）
6. tenantChannelMap        // tenantId → Set<channelId>（租户维度查询）
```

### 5.2 已实现亮点 ✅

| 亮点 | 说明 | 对标企业微信 |
|------|------|-------------|
| ✅ PROBE 协议协商 | 连接后先协商 codec/subprotocol | 飞书类似设计 |
| ✅ 严格模式 | 未完成 PROBE 不允许 AUTH_REQ | 企业级协议控制 |
| ✅ Token 撤销联动 | `revokeByAccessToken` 实时失效 | 安全合规要求 |
| ✅ 踢人通知 | KICKED 消息携带踢人时间、设备信息 | 微信体验一致 |
| ✅ 租约续期 | `lastBizActiveTime` 控制会话租约 | 安全租约机制 |
| ✅ 多索引设计 | 支持多维度查询和精确撤销 | 完善 |
| ✅ 生命周期监听 | `NettySessionLifecycleListener` 扩展点 | 架构合理 |
| ✅ i18n 支持 | 认证成功/失败消息国际化 | 国际化能力 |
| ✅ 双协议支持 | JSON + Protobuf 认证 | 面向未来 |

### 5.3 待完善功能

| 功能 | 企业微信 | 本项目 | 优先级 |
|------|----------|--------|--------|
| 手机+平板同时在线 | ✅ | ✅ | - |
| 手机+Web 同时在线 | ✅ | ✅ | - |
| 同设备类型互踢 | ✅ | ✅ | - |
| 踢人通知 | ✅ | ✅ | - |
| **登录设备管理** | ✅ | ❌ | P1 |
| **在线状态查询** | ✅ | ❌ | P1 |
| **远程踢出设备** | ✅ | ❌ | P1 |
| **登录事件审计** | ✅ | ❌ | P1 |
| **登录二次验证** | ✅ | ❌ | P2 |
| **登录IP限制** | ✅ | ❌ | P2 |
| **异常登录告警** | ✅ | ❌ | P2 |

### 5.4 建议新增接口

```java
// 1. 登录设备管理
@GetMapping("/login-devices")
CommonResult<List<LoginDeviceRespVO>> getLoginDevices();

// 2. 踢出指定设备
@PostMapping("/kick-device")
CommonResult<Boolean> kickDevice(@RequestParam("deviceType") Integer deviceType);

// 3. 在线状态查询
@GetMapping("/online-status")
CommonResult<List<UserOnlineStatusRespVO>> getOnlineStatus(
    @RequestParam("userIds") List<Long> userIds);
```

### 5.5 多端消息同步

**当前实现已完善：**

[NettyMessageSender.sendToUser](file:///Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/sender/NettyMessageSender.java#L106-L201) 遍历用户所有在线设备发送消息：
```java
List<NettySession> sessions = sessionManager.getSessionsByUserId(userId);
for (NettySession session : sessions) {
    if (session.isActive()) {
        channel.writeAndFlush(...);
    }
}
```

消息推送链路已完整：存储 → 逐设备推送 → 角标更新 → cursorVersion 携带。

---

## 六、移动端 API 接口审计

### 6.1 AppImMessageController

| 接口 | 审查结果 | 说明 |
|------|----------|------|
| `POST /send` | ⚠️ | HTTP 发送消息与 WebSocket 双通道，建议 WebSocket 为主 |
| `GET /window` | ✅ | 消息窗口查询，已覆盖 `idx_chat_seq` 索引 |
| `GET /pull` | ✅ | 增量拉取，游标逻辑完善 |
| `PUT /mark-read` | ⚠️ | 批量标记建议异步处理 |
| `POST /forward` | ⚠️ | 转发逐条 INSERT，建议批量写入 |

### 6.2 AppImConversationController

| 接口 | 审查结果 | 说明 |
|------|----------|------|
| `GET /list` | ✅ | 最大 pageSize 200，已有限制 |
| `GET /sync` | ✅ | 增量同步游标，核心接口设计合理 |
| `PUT /mark-read-seq` | ✅ | 已读后推送角标，异步处理 |

### 6.3 AppImGroupController

| 接口 | 审查结果 | 说明 |
|------|----------|------|
| `POST /member/add` | ⚠️ | 批量加人后需推送系统消息 |
| `DELETE /member/remove` | ⚠️ | 移除后需更新群缓存 |
| `GET /member/list` | ⚠️ | 群成员列表，建议加 Redis 缓存 |

### 6.4 已完善的服务

| 服务 | 文件 | 状态 |
|------|------|------|
| **消息限流** | `SystemMessageRateLimitServiceImpl` | ✅ Redis INCR + 1s TTL |
| **在线状态** | `ImPresenceServiceImpl` | ✅ Redis Hash + 30天 TTL |
| **角标服务** | `ImBadgeServiceImpl` | ✅ 增量角标 + WebSocket 推送 |
| **已读回执** | `ImReadReceiptServiceImpl` | ✅ |
| **搜索限流** | `ImSearchRateLimitService` | ✅ |
| **会话同步限流** | `ImConversationSyncRateLimitService` | ✅ |
| **语音文件校验** | `VoiceFileOwnershipValidator` | ✅ 完整校验 |

---

## 七、数据库架构优化

### 7.1 消息表分表策略

**问题：** `im_chat_message` 单表数据量快速增长。

**方案：按月份分表**
```sql
-- 分表策略：im_chat_message_YYYYMM
-- 3 个月内：在线表（活跃查询）
-- 3-12 个月：归档表（只读）
-- 12 个月以上：冷存储（OSS）
```

### 7.2 数据库索引优化（基于源码高频查询路径精确分析）

```sql
-- 1. 群消息拉取优化（读扩散场景）
-- 源码依据：消息窗口查询使用 chat_id + sequence 范围扫描
ALTER TABLE im_chat_message 
  ADD INDEX idx_group_chat_seq (tenant_id, group_id, chat_id, sequence DESC);

-- 2. 会话增量同步优化（游标查询高频）
-- 源码依据：ConversationSyncCoordinator 使用 cursor_version 做增量同步
ALTER TABLE im_conversation_user_state 
  ADD INDEX idx_user_cursor_version (tenant_id, user_id, cursor_version DESC);

-- 3. 群成员缓存优化（用于大群推送）
-- 源码依据：updateChatUserAsync L777 getGroupMemberIds 需要遍历全部成员
ALTER TABLE im_group_member 
  ADD INDEX idx_group_user_active (group_id, user_id, deleted);

-- 4. 会话用户查询优化（ensureChatUser 高频查询）
-- 源码依据：ensureChatUser L1079 selectByUserIdAndChatId，L1083 selectAnyByUserIdAndChatId
ALTER TABLE im_chat_user 
  ADD INDEX idx_user_chat_deleted (user_id, chat_id, deleted_by_user);

-- 5. 消息幂等查询优化（DuplicateKeyException 重试场景）
-- 源码依据：saveMessageWithId L486 selectById 重试查询
-- 如果 id 使用雪花算法，PRIMARY KEY 已覆盖，无需额外索引
```

### 7.3 数据库表结构变更建议

```sql
-- 1. im_chat_user 表增加软删除标记索引（已有 deleted_by_user 字段但无索引）
ALTER TABLE im_chat_user 
  ADD INDEX idx_chat_user_soft_delete (user_id, chat_id, deleted_by_user);

-- 2. im_conversation_user_state 表增加 cursor_version 索引（增量同步核心字段）
ALTER TABLE im_conversation_user_state 
  ADD INDEX idx_conv_cursor_version (tenant_id, user_id, cursor_version);

-- 3. im_group_member 表增加角色+静音状态索引（群发送权限校验高频查询）
-- 源码依据：validateGroupSendPermission L225 selectByGroupIdAndUserId
ALTER TABLE im_group_member 
  ADD INDEX idx_group_user_role_mute (group_id, user_id, role, mute_end_time);
```

### 7.4 Redis 缓存架构（已部分实现）

| 缓存项 | Key | 当前状态 |
|--------|-----|----------|
| 在线用户索引 | `im:presence:user:{userId}` Hash | ✅ 已实现 |
| 消息限流 | `system:im:rate:limit:{userId}` | ✅ 已实现 |
| 角标数据 | `im:badge:{userId}` | ❌ 未实现 |
| 群成员缓存 | `im:group:members:{groupId}` Set | ❌ 未实现 |
| 会话快照 | `im:snapshot:{userId}:{chatId}` | ❌ 未实现 |
| 游标版本 | 内存 Map | ❌ 建议 Redis 化 |

---

## 八、Flutter 客户端审查（v4.0 源码确认）

### 8.1 角标服务（✅ 优秀）

[BadgeService](file:///Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/features/im/badge/badge_service.dart) 实现亮点（第 1-460 行）：
- StateNotifier + Riverpod 状态管理
- 防抖通知（300ms，L366-376）
- 节流持久化（1s，L380-388）
- 数据版本控制（`_dataVersion = '1.0'`，L412-415 版本不匹配自动清除）
- 数据过期检查（24h TTL，L420-423）
- 会话角标上限（1000，L345-352）
- 增量更新支持（`applyIncrementalPayload`，L225-260）
- 有效角标计算（`effectiveMessagesTabBadgeProvider`，L449-460，扣除活跃对话）

### 8.2 会话同步（✅ 优秀）

`ConversationSyncCoordinator` 实现亮点：
- 游标版本增量同步
- 失败降级全量拉取
- 游标规范化处理

### 8.3 聊天实时绑定（✅ 良好，少量优化空间）

[chat_realtime_binding.dart](file:///Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/features/im/chat/presentation/providers/chat_realtime_binding.dart) 实现亮点：
- 消息去重器（`MessageDeduplicator(maxSize: 1000)`，L26）
- 50ms 批量节流窗口（`_enqueueMessageForBatch`，L643-682）
- 自动已读回执（L761-782）
- WebSocket 重连补偿拉取（L225-239）
- 群解散/退群状态过滤（`_isGroupLeftStatus`，L65-66, L303-307）
- 消息发送失败通知 + 自动跳转（L382-429）
- 撤回消息的 reedit 支持（L126-203, L516-567）

### 8.4 Flutter 客户端全链路分析（v5.0 新增）

#### 8.4.1 WebSocket 连接管理架构

**核心组件（已实现）：**

| 文件 | 职责 | 源码位置 |
|------|------|----------|
| `im_socket_client.dart` | 核心 WebSocket 客户端：连接/认证/心跳/重连 | 全文 |
| `socket_session_coordinator.dart` | 监听 `AuthSession` 变化，自动协调连接/断开/重认证 | 全文 |
| `socket_message_dispatcher.dart` | 事件分发中心（broadcast Stream） | 全文 |
| `socket_inbound_mapper.dart` | 将收到的 `SocketEnvelope` 映射为 `ImSocketEvent` | 全文 |
| `socket_outbound_sender.dart` | 封装业务消息发送（文本、已读回执、输入中） | 全文 |
| `socket_auth_payload_builder.dart` | 构建认证/探测/心跳的发送包 | 全文 |

**连接生命周期设计：**

```
AuthSession 变化 → SocketSessionCoordinator 监听
  ├── 未认证 → disconnect()
  ├── 新登录 → connect() + auth()
  ├── Token 变化 → reauth()
  └── 已断连 → connect() + auth()
```

**心跳机制（[im_socket_client.dart](file:///Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/core/websocket/im_socket_client.dart#L522-L532) 第 522-532 行）：**

```dart
void _startHeartbeat() {
    _clearHeartbeatTimers();
    _heartbeatTimer = Timer.periodic(AppConfig.socketHeartbeatInterval, (_) {
        _sendEnvelope(_authPayloadBuilder.buildHeartbeatEnvelope());
        _heartbeatTimeoutTimer?.cancel();
        _heartbeatTimeoutTimer = Timer(
            AppConfig.socketHeartbeatTimeout,
            notifyHeartbeatTimeout,
        );
    });
}
```

- 心跳间隔: 25s（`socketHeartbeatInterval`，[app_config.dart](file:///Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/app/config/app_config.dart#L56) L56）
- 心跳超时: 10s（`socketHeartbeatTimeout`，L57）
- 收到任何服务端消息会重置心跳超时计时器（第 301 行 `_clearHeartbeatTimeout`）
- 心跳超时 → `reconnectWaiting` → 指数退避重连（2s ~ 30s，最多 10 次，第 496-503 行 `_nextReconnectDelay`）

**重连机制（第 447-493 行 `_scheduleReconnect`）：**
- L466-469：重连次数超过 `socketMaxReconnectAttempts` (10) 后，直接设置 `disconnected` 状态
- L472-474：dispatch `reconnecting` 事件，但 **无任何 UI 提示用户网络异常**
- L481-487：先 `connect()` 再 `auth(session)`，auth 失败被 catch 吃掉，不触发重补偿

**认证机制（第 129-151 行 `auth`）：**
- L139：先发送 PROBE（探测）
- L146：再发送 AUTH_REQ（认证请求）
- L147：`await _awaitAuthResult()` 等待认证结果，超时为 `socketAuthTimeout` (8s)
- **PROBE → AUTH 之间无等待，两个消息连续发送，可能因网络延迟导致服务端乱序处理**

**评价**: 架构设计合理，分层清晰，事件驱动模型完整。但存在以下不足：
1. 重连失败无 UI 反馈
2. 心跳超时 10s 过短（建议 90s）
3. PROBE 和 AUTH 之间缺少 ack 确认

#### 8.4.2 消息收发完整链路

**消息发送链路（用户点击 → 服务端接收）：**

```
用户点击发送
  ↓
chat_page.dart: onSend 回调
  ↓
chat_controller.dart: sendText()
  ├── 1. 创建乐观消息: _optimisticMessageFactory.createText()  [状态: sending]
  ├── 2. 加入时间线: _timelineController.appendSingleMessage() [立即显示]
  ├── 3. 更新会话列表: _patchConversationForMessage()          [立即更新预览]
  └── 4. 异步提交: _submitTextMessage()
        ├── _sendMessageUseCase (HTTP 发送)  ← ⚠️ 使用 HTTP 而非 WebSocket
        ├── 成功: markSentByClientMessageId() [状态: sent]
        └── 失败: markFailedByClientMessageId() [状态: failed]
```

**消息接收链路（服务端推送 → UI 渲染）：**

```
WebSocket 帧 → ImSocketClient._handleInboundFrame()
  ↓
handleInboundRaw() → handleInboundJson()
  ↓
SocketInboundMapper.map() → ImSocketEvent
  ↓
SocketMessageDispatcher.dispatch()
  ↓
chat_realtime_binding.dart: _handleChatSocketEvent()
  ↓
_enqueueMessageForBatch() → 50ms 批量缓冲
  ↓
_flushMessageBatch() → TimelineController.appendMessagesBatch()
  ↓
UI rebuild (Riverpod state update)
```

**双层批量节流设计：**

| 层级 | 位置 | 窗口 | 说明 |
|------|------|------|------|
| 第一层 | `chat_realtime_binding.dart` L643-682 | 50ms | `_enqueueMessageForBatch` 收集消息到 `_messageBatchBuffers` |
| 第二层 | `chat_timeline_controller.dart` L67-85 | 50ms | `appendMessagesBatch` 收集到 `_pendingMessages` |

**⚠️ 问题：双层 50ms 缓冲导致实际延迟可能达到 100ms**。第一层节流 50ms 后调用 `appendMessagesBatch`，第二层再节流 50ms 才真正渲染。

**三层去重机制：**

1. **全局 LRU 去重器** (`message_deduplicator.dart` L24-37)：基于 `messageId > clientMessageId > sequence` 优先级去重，使用 `LinkedHashMap`，超出 maxSize(1000) 淘汰最早条目
2. **chat_realtime_binding 去重** (L651-660)：对方消息去重，自己消息加入缓存但不过滤
3. **Timeline Controller 内部去重** (L100-112)：`_flushPendingMessages` 中使用 Map 按 dedupKey 去重

#### 8.4.3 小米手机真机环境问题分析 🔴

**问题 1: mDNS 域名解析不稳定（高优先级）**

文件: `app_config.dart` 第 25、30 行
```dart
static const String apiBaseUrl = 'http://MacBook-Pro-3.local:48080/app-api';
static const String socketUrl = 'ws://MacBook-Pro-3.local:9000/ws';
```

**问题**: `.local` 域名依赖 mDNS/Bonjour 协议，在部分小米手机上默认未启用或解析不稳定。即使在同一 WiFi 下，小米 HyperOS/MIUI 可能对 mDNS 有限制。
**症状**: WebSocket 连接偶发性失败、断连后无法重连
**修复**: 真机调试时使用 IP 地址，生产环境使用正式域名或 IP 配置化

---

**问题 2: 缺少后台保活机制（高优先级）**

**缺失配置**:
- `AndroidManifest.xml` 中未声明前台服务权限
- 未申请电池优化白名单（`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`）
- 未使用 `workmanager` 或 `android_alarm_manager` 做后台心跳

**小米特有问题**:
- MIUI/HyperOS 有激进的后台进程管理，App 切后台后可能被完全杀死网络
- 自启动管理：小米默认禁止第三方 App 自启动，后台进程会被清理
- 省电策略："超级省电" 或 "极致省电" 模式下网络会被完全切断
- 锁屏后断网：部分小米机型锁屏 1~3 分钟后会切断后台 App 的网络连接

**症状**: App 切后台或锁屏后，WebSocket 断开且不恢复

---

**问题 3: 生命周期处理不完整（中优先级）**

**问题**:
- 仅监听了 `resumed` 状态，**未处理 `paused`/`inactive`/`hidden` 状态下的 WebSocket 状态**
- 进入后台时没有主动暂停心跳或标记连接状态
- 多个页面各自注册 `WidgetsBindingObserver`，**未统一在 App 级别处理生命周期**
- `_handleResumeFromBackground` 中只检查了 `state != connected` 才重连，但 `connected` 状态可能是"假连接"（TCP 连接存在但已被服务端断开）

**建议**: 在 App 级别统一处理生命周期，进入后台时关闭 WebSocket 连接，回前台时重新建立

---

**问题 4: 心跳间隔与后台策略冲突（中优先级）**

心跳间隔 25s + 超时 10s = 35s 才发现断连。小米系统在锁屏后可能 60~120s 就切断后台 App 的网络。如果锁屏 60s 后网络被切断，心跳在 25s 时发送失败，但 35s 后才检测到断连。

**建议**: 检测到应用进入后台时，缩短心跳间隔或主动断连

---

**问题 5: 重连失败无 UI 提示（中优先级）**

文件: `im_socket_client.dart` 第 447-493 行

重连次数达到 `socketMaxReconnectAttempts` (10 次) 后，直接设置为 `disconnected` 状态，**但没有任何 UI 提示用户网络异常**。用户可能以为消息已发送，实际已断连且不再尝试重连。

---

**问题 6: 消息发送使用 HTTP 而非 WebSocket（中优先级）**

`_submitTextMessage` 使用 `_sendMessageUseCase`（HTTP 发送），而非通过 WebSocket 发送。这意味着：
- 发送消息需要额外建立 HTTP 连接
- 与 WebSocket 实时通道分离，增加延迟
- 在高并发场景下增加服务器 HTTP 负载

**建议**: 消息发送优先使用 WebSocket，HTTP 作为降级备用

---

**问题 7: 会话更新重复调用（低优先级）**

`chat_controller.dart` 中：
- `sendText` 第 112 行调用了 `_patchConversationForMessage`
- `_submitTextMessage` 第 222-223 行又重复调用了一次 `upsertLocalMessage`

导致**会话列表被更新两次**。

### 8.5 Flutter 客户端待优化项汇总

| 问题 | 文件 | 源码位置 | 建议 | 优先级 |
|------|------|----------|------|--------|
| `_serial` 链无限增长 | [socket_session_coordinator.dart](file:///Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/core/websocket/socket_session_coordinator.dart#L24-L28) | L24-28 | 限制链长度 | P1 |
| mDNS 域名不稳定 | `app_config.dart` L25, L30 | 全文 | IP 或域名配置化 | P0 |
| 缺少后台保活 | `AndroidManifest.xml` | 全文 | 前台服务 + 电池白名单 | P0 |
| 生命周期分散 | 多个页面 | 全文 | App 级别统一管理 | P1 |
| 重连失败无 UI | `im_socket_client.dart` | L466-469 | 显示网络异常横幅 | P1 |
| 双层 50ms 缓冲延迟 | `chat_realtime_binding.dart` + `chat_timeline_controller.dart` | L643-701 | 合并为单层 50ms | P2 |
| 心跳间隔偏短 | `app_config.dart` L56 | L56 | 25s → 30s | P2 |
| Timer 残留风险 | `chat_realtime_binding.dart` L686 | L686 | `?.cancel()` | P2 |
| `_syncThrottleTimestamps` 泄漏 | `conversation_realtime_binding.dart` L42 | 全文 | 定期清理或限制大小 | P2 |
| `_localConversationUpdateTimes` 泄漏 | `conversation_realtime_binding.dart` L47 | 全文 | 定期清理或限制大小 | P2 |
| 消息发送使用 HTTP | `chat_controller.dart` L222 | 全文 | WebSocket 优先 | P2 |
| 会话更新重复 | `chat_controller.dart` L112, L223 | 全文 | 去除重复调用 | P3 |

---

## 九、监控与可观测性

### 9.1 核心监控指标

| 指标 | 告警阈值 | 采集方式 |
|------|----------|----------|
| WebSocket 连接数 | > 40w | Netty 指标 |
| 消息处理延迟 | P99 > 100ms | Micrometer |
| 消息丢失率 | > 0.01% | 业务埋点 |
| DB 连接池使用率 | > 80% | HikariCP |
| GC 暂停时间 | > 500ms | JMX |
| 内存使用 | > 85% | JMX |
| Flutter 客户端重连率 | > 5%/h | 客户端埋点 |
| Flutter WebSocket 断连率 | > 2%/h | 客户端埋点 |
| 消息发送 HTTP→WS 切换率 | 目标 100% WS | 客户端埋点 |

---

## 十、等保三级合规清单

| 要求 | 当前状态 | 达标方案 |
|------|----------|----------|
| 传输加密（TLS） | ws:// | 启用 wss:// |
| 身份鉴别 | Token | JWT + 双因素（可选） |
| 访问控制 | 有 | 增强权限校验 |
| 安全审计 | 无 | 全链路审计日志 |
| 入侵防范 | 限流有 | WAF + 限流完善 |
| 数据完整性 | 无 | 消息签名（SM3） |
| 数据保密性 | 无 | 消息加密（SM4） |

---

## 十一、实施计划（v5.0 修正）

### Phase 1：P0 级核心优化（2 周）

| 任务 | 文件 | 优先级 | 源码确认 |
|------|------|--------|----------|
| 群消息扇出混合模型 | [SystemMessageStorageServiceImpl](file:///Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/service/im/spi/SystemMessageStorageServiceImpl.java#L730-L968) | P0 | ✅ L776-864 遍历群成员 |
| 消息存储批量写入 | `MessageStorageService` + Mapper | P0 | ✅ `saveMessageWithId` 单条 INSERT |
| SessionManager 竞态修复 | [NettySessionManager](file:///Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/session/NettySessionManager.java#L128-L188) | P0 | ✅ L152-157 竞态窗口 |
| sendToTenant/broadcast 背压 | [NettyMessageSender](file:///Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/sender/NettyMessageSender.java#L318-L404) | P0 | ✅ L340/370/396 缺 isWritable |
| 未知消息类型告警 | [MessageProcessorFactory](file:///Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/processor/MessageProcessorFactory.java#L33-L35) | P0 | ✅ 返回 null 无告警 |
| 踢人消息延迟关闭 | [NettySessionManager](file:///Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/session/NettySessionManager.java#L317-L371) | P0 | ✅ L367 立即 close |
| wss:// 启用 | Netty 配置 | P0 | - |
| Flutter mDNS 替换 | `app_config.dart` | P0 | ✅ L25/L30 `.local` 域名 |
| Flutter 后台保活 | `AndroidManifest.xml` | P0 | ✅ 缺失前台服务配置 |

### Phase 2：P1 级架构完善（2 周）

| 任务 | 文件 | 优先级 | 源码确认 |
|------|------|--------|----------|
| 弱网/断网网络状态监控 | 新增 `NetworkMonitorService` | P1 | 对标微信 Notice Bar 设计 |
| 网络异常 UI 提示组件 | 新增 `NetworkStatusNoticeBar` | P1 | 对标微信持续提示策略 |
| 消息发送状态指示器 | 新增 `MessageSendStatusIndicator` | P1 | 对标微信重试按钮 |
| Dio 弱网拦截器 | 新增 `WeakNetworkInterceptor` | P1 | 弱网自动重试 2 次 |
| 消息本地缓存队列 | 新增 `MessageCacheQueue` | P1 | 断网消息缓存，网络恢复重发 |
| WebSocket 重连 UI 绑定 | `im_socket_client.dart` + UI | P1 | ✅ L466-469 无提示 |
| Flutter Protobuf Binary | `im_socket_client.dart` | P1 | ✅ 已支持 codec 协商 |
| 会话快照 Redis 缓存 | 新增服务 | P1 | ✅ `updateChatUserAsync` 每次全量 DB 操作 |
| 心跳机制双向优化 | `HeartbeatHandler` + [Flutter](file:///Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/app/config/app_config.dart#L56) | P1 | ✅ 心跳 25s 偏短 |
| Redis 缓存架构完善 | 多处 | P1 | ✅ 群成员/角标/快照未缓存 |
| Flutter _serial 链修复 | [socket_session_coordinator.dart](file:///Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/core/websocket/socket_session_coordinator.dart#L24-L28) | P1 | ✅ L24-28 无限增长 |
| NettyAuthLeaseMonitor 索引化 | [NettyAuthLeaseMonitor](file:///Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/session/NettyAuthLeaseMonitor.java#L65-L136) | P1 | ✅ O(N) 全量遍历 |
| 登录设备管理 API | 新增接口 | P1 | - |
| 在线状态查询 API | 新增接口 | P1 | - |
| Flutter 生命周期统一管理 | App 级别 Provider | P1 | ✅ 多页面分散注册 |
| Flutter 全局 Map 泄漏修复 | `conversation_realtime_binding.dart` | P1 | ✅ L42/L47 无清理 |

### Phase 3：P2 级优化 + 等保三级合规（2 周）

| 任务 | 说明 | 优先级 |
|------|------|--------|
| 双层缓冲合并 | 50ms+50ms → 单层 50ms | P2 |
| 消息发送切换 WebSocket | HTTP → WebSocket 优先 | P2 |
| 心跳间隔调整 | 25s → 30s | P2 |
| 会话更新去重 | 去除重复 upsertLocalMessage | P3 |
| 国密 TLS 证书 | SM2 证书替换 | P1 |
| 消息签名（SM3） | HMAC-SM3 | P1 |
| 审计日志系统 | 全链路审计 | P1 |
| 监控指标集成 | Prometheus + Grafana + Flutter 客户端埋点 | P2 |

---

## 附录：架构演进路线图

```
当前架构 ─────────────────────────────────────────────────▶ 目标架构

单节点 Netty                                    分布式 Netty 集群
    │                                                │
    ├── 本地 SessionMap          ──▶                 ├── Redis Session 中心
    ├── 写扩散（500人群1500次操作）──▶               ├── 混合扩散 + 读扩散
    ├── 同步消息存储             ──▶                 ├── 批量写入 + 分表
    ├── JSON 协议               ──▶                 ├── Protobuf 二进制协议
    ├── ws:// 明文              ──▶                 ├── wss:// + 国密
    ├── 无消息签名              ──▶                 ├── SM3-HMAC 签名
    ├── 无监控                  ──▶                 ├── Prometheus + Grafana
    └── 无审计                  ──▶                 └── 全链路审计日志
```

---

## 对标参考

| 特性 | 企业微信 | 飞书 | 本项目 | 差距 |
|------|----------|------|--------|------|
| 最大并发 | 100w+ | 50w+ | 1-2w（单机） | 🔴 集群化 |
| 消息延迟 | < 100ms | < 200ms | < 100ms | ✅ |
| 单群上限 | 10000 人 | 5000 人 | 5000 人 | ✅ |
| 消息存储 | 分库分表 | 分库分表 | 单表 | 🟡 分表 |
| 加密方式 | 自研协议 | Protobuf | JSON + Proto | 🟡 国密 |
| 多端登录 | 同类型互踢 | 同类型互踢 | 同类型互踢 | ✅ |
| 在线状态 | ✅ | ✅ | ✅ | ✅ |
| 已读回执 | ✅ | ✅ | ✅ | ✅ |
| 消息撤回 | ✅ | ✅ | ✅ | ✅ |
| 角标推送 | ✅ | ✅ | ✅ | ✅ |
| 消息限流 | ✅ | ✅ | ✅ | ✅ |
| 弱网体验 | ✅ 防抖+Notice Bar+重试 | ✅ 网络质量提示 | ❌ 无 | 🔴 核心需求 |
| 断网缓存 | ✅ 本地消息队列 | ✅ 草稿自动保存 | ❌ 无 | 🔴 核心需求 |
| 网络切换提示 | ✅ WiFi→流量弹窗 | ✅ WiFi→流量弹窗 | ❌ 无 | 🔴 核心需求 |
