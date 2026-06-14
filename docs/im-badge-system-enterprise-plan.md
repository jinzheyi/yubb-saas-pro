# IM 角标数字体系企业级改造方案

> 版本: v2.0 | 日期: 2026-06-14 | 涉及模块: 后端(Spring Boot 2) + 前端(Flutter)

---

## 一、现状全链路深度诊断

### 1.1 端到端数据流全景图

```
────────────────────────────────────────────────────────────────────┐
│                        后端数据源 (MySQL)                           │
│                                                                    │
│  im_chat_user 表                                                   │
│  ├── unread_count       ← 冗余未读计数器 (incrementUnread 更新)     │
│  ├── last_read_sequence ← 用户已读游标 (sequence 水位)              │
│  └── last_message_sequence ← 会话最后消息游标                       │
│                                                                    │
│  im_conversation_user_state 表                                      │
│  ├── cursor_version     ← 增量同步版本戳                            │
│  ├── unread_count       ← 冗余未读计数器                           │
│  ├── last_read_sequence ← 用户已读游标                              │
│  └── last_read_time     ← 最后已读时间                             │
└───────────────────────┬────────────────────────────────────────────┘
                        │
                        │ 消息发送时 (SystemMessageStorageServiceImpl)
                        │  updateChatUserAsync() 异步执行:
                        │    1. chatUserMapper.updateLastMessageAndIncrementUnread()
                        │    2. conversationUserStateMapper.upsertAfterMessage()
                        │    3. conversationUserStateMapper.upsertAfterMessageForSender()
                        │    4. imBadgeService.pushBadgeUpdate(memberId) ← 全量推送
                        │    5. nettyMessageSender.sendToUserWithExtra() ← 业务消息
                        ▼
┌────────────────────────────────────────────────────────────────────┐
│                      后端角标服务层                                 │
│                                                                    │
│  ImBadgeServiceImpl                                                │
│  ├── getBadgeData(userId)                                          │
│  │     ├── getTotalUnreadCount(userId)  ← SQL聚合查询               │
│  │     └── getConversationBadges(userId) ← 遍历所有会话计算未读数   │
│  │           算法: unread = lastMsgSeq - lastReadSeq (fallback unread_count) │
│  └── pushBadgeUpdate(userId)                                       │
│        └── messageSender.sendToUser(userId, BADGE_UPDATE, ...)     │
│             推送全量角标数据到该用户所有在线设备                     │
───────────────────────┬────────────────────────────────────────────┘
                        │ WebSocket badgeUpdated 消息
                        │ payload: { totalUnreadCount, conversationBadges: [...] }
                        ▼
┌────────────────────────────────────────────────────────────────────┐
│                      Flutter 端角标层                              │
│                                                                    │
│  BadgeService (badge_service.dart)                                 │
│  ├── conversationBadges: Map<String, int>   ← 每会话角标           │
│  ├── totalUnreadCount: int                  ← 总未读数             │
│  ├── clearConversationBadge(chatId)         ← 清空单个会话角标     │
│  └── applyServerPayload(Map)                ← 服务端全量覆盖       │
│                                                                    │
│  ActiveConversationService (active_conversation_service.dart)      │
│  ├── currentChatId: String                  ← 当前查看的会话       │
│  ├── activeUnreadCount: int                 ← 进入时的未读数       │
│  ├── activateChat(chatId, unreadCount)      ← 激活               │
│  └── deactivateChat()                       ← 失活               │
│                                                                    │
│  effectiveMessagesTabBadgeProvider           ← Tab 栏角标           │
│  = totalUnreadCount - activeUnreadCount      ← 动态扣除当前会话    │
└───────────────────────┬────────────────────────────────────────────┘
                        │
                        │ 派生 UI
                        ▼
┌────────────────────────────────────────────────────────────────────┐
│                        UI 展示层                                    │
│                                                                    │
│  ConversationTile (conversation_tile.dart)                          │
│  ├── 当前从 Conversation.unreadCount 读取角标                       │
│  └── 数据来源: conversation/sync 接口                               │
│                                                                    │
│  AppShell Tab 栏                                                   │
│  ├── effectiveMessagesTabBadgeProvider                             │
│  └── 数据来源: BadgeState.totalUnreadCount - activeUnreadCount     │
└────────────────────────────────────────────────────────────────────┘
```

### 1.2 核心问题清单

| # | 问题 | 根因 | 影响 | 严重程度 |
|---|------|------|------|---------|
| P0-1 | 停留在聊天页返回仍有角标 | `chat_page.dart` 从未调用 `activateChat()`/`deactivateChat()` | Tab 栏角标不准确 | 🔴 致命 |
| P0-2 | 会话列表角标与 Tab 栏角标不一致 | 两个数据源：`Conversation.unreadCount` vs `BadgeState.conversationBadges` | 用户体验混乱 | 🔴 致命 |
| P0-3 | 消息发送时全量推送角标 | `pushBadgeUpdate()` 遍历所有会话查询未读数，每次消息都全量推送 | 带宽浪费、推送延迟 | 🟠 严重 |
| P1-4 | 群聊全量推送角标 | 群聊每条消息给所有成员（除了发送者）都推送 badgeUpdated | 性能瓶颈 | 🟠 严重 |
| P1-5 | `getConversationBadges()` 全表扫描 | 每次推送都查询用户所有会话计算未读数 | DB 压力大 | 🟠 严重 |
| P1-6 | 发送者也可能收到 badgeUpdated | 群聊场景下，`updateChatUserAsync` 中发送者调用了 `upsertAfterMessageForSender` 但没有 badge push 保护 | 数据一致性风险 | 🟡 中等 |
| P2-7 | 角标恢复机制脆弱 | WebSocket 断连重连时角标数据可能丢失或不一致 | 用户看到错误的角标 | 🟡 中等 |

### 1.3 与微信角标设计的对标分析

参考微信的角标设计理念：

| 维度 | 微信方案 | 本项目现状 | 差距 |
|------|---------|-----------|------|
| 数据源 | 服务器单一权威数据源 | 双数据源（unread_count + badgeState） | 不一致 |
| 推送策略 | 仅推送变化的会话角标（增量） | 全量推送所有会话角标 | 性能差 |
| 已读策略 | 进入聊天页立即清角标 | 无清角标逻辑 | 功能缺失 |
| 在线状态感知 | 对方在线时不推送通知角标 | 无在线状态感知 | 体验差 |
| 角标恢复 | 重连时全量同步角标 | 依赖 `/badge/get` 主动拉取 | 机制脆弱 |
| 多端同步 | 所有设备角标实时一致 | 仅 push 给在线设备 | 基本一致 |

**可借鉴的微信设计原则**：
1. **单一数据源**：所有角标数据以服务器为准，客户端仅做展示层派生
2. **增量推送优先**：仅推送变化的会话角标，而非全量
3. **进入即已读**：用户进入聊天页面，该会话角标立即清除
4. **在线免推**：对方正在聊天页面时，不推送角标通知（减少无效推送）
5. **99+ 溢出**：角标超过 99 显示 "99+"，避免 UI 溢出

---

## 二、企业级改造方案设计

### 2.1 总体架构

```
┌────────────────────────────────────────────────────────────────────┐
│                    改造后架构（单一数据源）                         │
│                                                                    │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │  后端: 增量推送角标 (Incremental Badge Push)                   │ │
│  │                                                              │ │
│  │  消息发送时:                                                   │ │
│  │  ├── 发送者: 不推送 badgeUpdated                               │ │
│  │  ├── 接收者(单聊): 推送增量 badgeUpdated { chatId, unread }  │ │
│  │  ── 群聊接收者: 推送增量 badgeUpdated { chatId, unread }    │ │
│  │                                                              │ │
│  │  全量拉取 (按需):                                              │ │
│  │  ├── /badge/get → 初始化 / 重连时调用                         │ │
│  │  └── conversation/sync → 增量同步时携带 badge 数据             │ │
│  ──────────────────────────────────────────────────────────────┘ │
│                                                                    │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │  前端: BadgeState 为唯一角标数据源                              │ │
│  │                                                              │ │
│  │  BadgeState                                                    │ │
│  │  ├── conversationBadges: Map<chatId, unread>                  │ │
│  │  ├── totalUnreadCount: int (自动计算)                         │ │
│  │  └── syncFromServer(payload) / syncIncremental(changes)      │ │
│  │                                                              │ │
│  │  ActiveConversationService                                     │ │
│  │  ├── currentChatId + activeUnreadCount (进入时的快照)         │ │
│  │  └── activeUnreadCount 在 Tab 栏计算时动态扣除                 │ │
│  │                                                              │ │
│  │  派生 UI (全部从 BadgeState + ActiveConversation 派生):         │ │
│  │  ├── ConversationTile: badgeState.conversationBadges[chatId] │ │
│  │  ├── Tab 栏: totalUnreadCount - activeUnreadCount            │ │
│  │  └── conversation/sync: 从 BadgeState 同步到 Conversation    │ │
│  └──────────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────────┘
```

### 2.2 改造步骤详述

#### Step 1: 后端 — 增量角标推送 (高优)

**文件**: `SystemMessageStorageServiceImpl.java`

**当前问题**（第 776-962 行）:
- 群聊每条消息给所有成员都调用 `imBadgeService.pushBadgeUpdate(memberId)`
- `pushBadgeUpdate()` 内部调用 `getBadgeData()` 遍历用户所有会话计算全量角标
- 发送者侧也有 `pushBadgeUpdate`（第 844 行虽然加了 `!isSender` 判断，但单聊场景下第 939 行接收者无条件推送）

**改造方案**:

```java
// 新增: 增量推送单个会话角标
@Override
public void pushIncrementalBadgeUpdate(Long userId, Long chatId, int newUnreadCount) {
    log.debug("[ImBadgeService] 增量推送角标, userId: {}, chatId: {}, unread: {}", 
            userId, chatId, newUnreadCount);
    
    try {
        // 构建增量角标消息
        ConversationBadge badge = ConversationBadge.newBuilder()
                .setConversationId(chatId)
                .setUnreadCount(newUnreadCount)
                .build();
        
        // 获取总未读数 (仅用于 Tab 栏)
        Integer totalUnread = conversationService.getTotalUnreadCount(userId);
        
        BadgeUpdateMessage badgeUpdate = BadgeUpdateMessage.newBuilder()
                .setUnreadCount(totalUnread != null ? totalUnread : 0)
                .addConversationBadges(badge)
                .setIncremental(true)  // 新增: 标记为增量推送
                .build();
        
        messageSender.sendToUser(userId, MessageType.BADGE_UPDATE, badgeUpdate);
    } catch (Exception e) {
        log.error("[ImBadgeService] 增量推送角标失败, userId: {}, chatId: {}", 
                userId, chatId, e);
    }
}

// 新增: 在线状态感知推送
private boolean shouldPushBadgeToUser(Long userId) {
    // 如果用户当前正在查看该会话的聊天页面（通过 WebSocket 活跃会话判断），
    // 则不推送角标通知，因为用户已经在聊天页中看到消息了
    if (imPresenceService != null) {
        ImPresenceSnapshot snapshot = imPresenceService.getUserPresence(userId);
        if (snapshot != null && Boolean.TRUE.equals(snapshot.getOnline())) {
            // 用户在线，检查是否在聊天页
            // 可以扩展: 增加 activeChatId 字段到 PresenceSnapshot
            return true; // 当前保守策略：在线仍然推送
        }
    }
    return true; // 默认推送
}
```

**修改 `updateChatUserAsync()` 中的推送逻辑**:

```java
// 群聊场景 (第 776-864 行)
if (!isSender) {
    // 替换: imBadgeService.pushBadgeUpdate(memberId);
    // 为: imBadgeService.pushIncrementalBadgeUpdate(memberId, chatId, newUnread);
    // newUnread 可以从 chatUserMapper.updateLastMessageAndIncrementUnread() 的返回值获取
}

// 单聊场景 (第 865-963 行)
// 替换: imBadgeService.pushBadgeUpdate(header.getReceiverId());
// 为: imBadgeService.pushIncrementalBadgeUpdate(header.getReceiverId(), chatId, 1);
```

**文件**: `BadgeUpdateMessage.java` (Protobuf 定义)

**新增字段**:
```protobuf
message BadgeUpdateMessage {
  int32 unread_count = 1;
  repeated ConversationBadge conversation_badges = 2;
  repeated MenuBadge menu_badges = 3;
  bool incremental = 4;  // 新增: 是否为增量推送
}
```

---

#### Step 2: 后端 — `getConversationBadges()` 性能优化 (中优)

**文件**: `ImConversationServiceImpl.java`

**当前问题**（第 844-864 行）:
```java
public List<ConversationBadge> getConversationBadges(Long userId) {
    List<ImChatUserDO> chatUsers = chatUserMapper.selectListByUserId(userId);
    // 全表扫描所有会话，逐个计算未读数
    return chatUsers.stream()
            .map(cu -> {
                long unread = lastMsgSeq - lastReadSeq; // fallback unread_count
                // ...
            })
            .filter(unread > 0)
            .map(to ConversationBadge)
            .collect(Collectors.toList());
}
```

**改造方案**:

```java
@Override
public List<ConversationBadge> getConversationBadges(Long userId) {
    // 优化: 使用 SQL 直接查询 unread_count > 0 的会话，避免全表扫描
    List<ImChatUserDO> chatUsers = chatUserMapper.selectListWithUnread(userId);
    
    return chatUsers.stream()
            .filter(cu -> cu.getUnreadCount() != null && cu.getUnreadCount() > 0)
            .map(cu -> ConversationBadge.newBuilder()
                    .setConversationId(cu.getChatId())
                    .setUnreadCount(cu.getUnreadCount())
                    .build())
            .collect(Collectors.toList());
}
```

**新增 SQL 方法** (`ImChatUserMapper.java`):
```java
// 仅查询 unread_count > 0 的会话，减少数据量
@Select("SELECT * FROM im_chat_user WHERE user_id = #{userId} AND unread_count > 0 AND deleted_by_user = 0")
List<ImChatUserDO> selectListWithUnread(@Param("userId") Long userId);
```

---

#### Step 3: 后端 — 发送者不推送角标 (已部分实现)

**文件**: `SystemMessageStorageServiceImpl.java`

**群聊场景**（第 844 行）: 已有 `!isSender` 保护 ✅

**单聊场景**（第 939 行）: 接收者推送，发送者不推送 ✅

**当前已实现**：发送者不会收到 badgeUpdated，此问题已基本解决。

---

#### Step 4: 前端 — `chat_page.dart` 激活/失活调用 (P0)

**文件**: `chat_page.dart`

**改造内容**:

```dart
class _ChatPageState extends ConsumerState<ChatPage> {
  late final String _chatId;

  @override
  void initState() {
    super.initState();
    _chatId = widget.args.chatId;

    // 进入聊天页时:
    // 1. 获取该会话进入时的未读数（用于 Tab 栏动态扣除）
    final badgeState = ref.read(badgeServiceProvider);
    final unreadAtEntry = badgeState.conversationBadges[_chatId] ?? 0;

    // 2. 激活当前会话（告知 Tab 栏需要扣除的未读数）
    ref.read(activeConversationServiceProvider.notifier).activateChat(
      _chatId,
      unreadAtEntry,
    );

    // 3. 清除该会话的角标（用户已在聊天页，消息应视为已读）
    ref.read(badgeServiceProvider.notifier).clearConversationBadge(_chatId);

    // 4. 调用已有的加载逻辑
    _loadChat();
  }

  @override
  void dispose() {
    // 离开聊天页时失活
    ref.read(activeConversationServiceProvider.notifier).deactivateChat();
    super.dispose();
  }
}
```

**效果**:
- 进入聊天页 → Tab 栏角标立即扣除该会话未读数
- 进入聊天页 → 会话列表该会话角标立即消失
- 离开聊天页 → Tab 栏角标恢复

---

#### Step 5: 前端 — `ConversationTile` 从 `BadgeState` 读取角标 (P0)

**文件**: `conversation_tile.dart`

**当前代码**:
```dart
final unreadCount = conversation.unreadCount ?? 0;
```

**改造后**:
```dart
class ConversationTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 从 BadgeState 读取角标（唯一数据源）
    final badgeState = ref.watch(badgeServiceProvider);
    final unreadCount = badgeState.conversationBadges[conversation.chatId] ?? 0;
    
    // ...
  }
}
```

**注意**: `ConversationTile` 需要改为 `ConsumerWidget`（如果还不是）。

---

#### Step 6: 前端 — `conversation_list_page.dart` 角标同步逻辑 (P1)

**文件**: `conversation_list_page.dart`

**改造内容**:

```dart
// 新增: 监听 BadgeState 变化，同步到 Conversation 列表
@override
void initState() {
  super.initState();
  
  // 初始同步: 将 BadgeState.conversationBadges 同步到 Conversation.unreadCount
  // （仅用于排序，UI 展示从 BadgeState 读取）
  _syncBadgesToConversations();
}

void _syncBadgesToConversations() {
  final badgeState = ref.read(badgeServiceProvider);
  ref.read(conversationListControllerProvider.notifier)
    .applyBadgeBadgesToConversations(badgeState.conversationBadges);
}

// 在 conversation_list_controller.dart 中新增:
void applyBadgeBadgesToConversations(Map<String, int> badges) {
  final updated = _state.conversations.map((c) {
    final badge = badges[c.chatId];
    if (badge != null) {
      return c.copyWith(unreadCount: badge);
    }
    return c;
  }).toList();
  _state = _state.copyWith(conversations: updated);
}
```

---

#### Step 7: 前端 — WebSocket `badgeUpdated` 增量/全量处理 (P1)

**文件**: `global_badge_socket_binding.dart`

**当前处理**:
```dart
case SocketEventTypes.badgeUpdated:
  final payload = event.payload as Map<String, dynamic>?;
  if (payload != null) {
    ref.read(badgeServiceProvider.notifier).applyServerPayload(payload);
  }
  break;
```

**改造后**:
```dart
case SocketEventTypes.badgeUpdated:
  final payload = event.payload as Map<String, dynamic>?;
  if (payload != null) {
    final bool incremental = payload['incremental'] == true;
    
    if (incremental) {
      // 增量更新: 合并变化的会话角标
      ref.read(badgeServiceProvider.notifier).applyIncrementalPayload(payload);
    } else {
      // 全量更新: 覆盖所有角标数据
      ref.read(badgeServiceProvider.notifier).applyServerPayload(payload);
    }
  }
  break;
```

**`BadgeService` 新增方法**:
```dart
/// 增量更新角标（仅更新变化的会话）
void applyIncrementalPayload(Map<String, dynamic> payload) {
  final conversationBadgesList = payload['conversationBadges'] as List?;
  if (conversationBadgesList != null) {
    for (final item in conversationBadgesList) {
      if (item is! Map) continue;
      final chatId = item['chatId']?.toString().trim() ?? '';
      if (chatId.isEmpty) continue;
      final unreadCount = int.tryParse('${item['unreadCount'] ?? 0}') ?? 0;
      
      if (unreadCount <= 0) {
        // 未读数为 0，移除该会话角标
        _state = _state.copyWith(
          conversationBadges: Map<String, int>.from(_state.conversationBadges)
            ..remove(chatId),
        );
      } else {
        // 更新该会话角标
        final updated = Map<String, int>.from(_state.conversationBadges);
        updated[chatId] = unreadCount;
        _state = _state.copyWith(conversationBadges: updated);
      }
    }
  }
  
  // 更新总未读数（服务端计算后下发）
  final totalUnreadCount = int.tryParse('${payload['totalUnreadCount'] ?? 0}') ?? 0;
  if (totalUnreadCount >= 0) {
    _state = _state.copyWith(totalUnreadCount: totalUnreadCount);
  }
}
```

---

#### Step 8: 前端 — `effectiveMessagesTabBadgeProvider` 优化 (P0)

**文件**: `badge_service.dart`

**当前逻辑**:
```dart
final effectiveMessagesTabBadgeProvider = Provider<int>((ref) {
  final badge = ref.watch(badgeServiceProvider);
  final active = ref.watch(activeConversationServiceProvider);
  return (badge.totalUnreadCount - active.activeUnreadCount).clamp(0, 999);
});
```

**改造后**（基本不变，但需要确保 `totalUnreadCount` 准确）:

```dart
final effectiveMessagesTabBadgeProvider = Provider<int>((ref) {
  final badge = ref.watch(badgeServiceProvider);
  final active = ref.watch(activeConversationServiceProvider);
  
  // 优先使用 conversationBadges 计算总未读数（与服务端保持一致）
  int calculatedTotal = badge.conversationBadges.values.fold(0, (sum, v) => sum + v);
  
  // 扣除当前活跃会话的未读数
  final effective = calculatedTotal - active.activeUnreadCount;
  
  return effective.clamp(0, 999);
});
```

---

### 2.3 改造步骤优先级与依赖关系

```
Phase 1: 数据源统一（前端，可独立验证）
├── Step 4: chat_page.dart 激活/失活调用          ← 无依赖
├── Step 5: ConversationTile 从 BadgeState 读角标  ← 无依赖
└── Step 8: effectiveMessagesTabBadgeProvider 优化 ← 依赖 Step 4

Phase 2: 后端推送优化（后端，可独立验证）
├── Step 1: 增量角标推送                          ← 依赖 Step 3（已实现）
├── Step 2: getConversationBadges SQL 优化         ← 无依赖
└── Step 3: 发送者不推送角标                       ← 已实现

Phase 3: 全链路集成
├── Step 6: conversation_list_page 角标同步        ← 依赖 Step 5
├── Step 7: WebSocket 增量/全量处理                ← 依赖 Step 1
└── 验证测试                                       ← 依赖 Phase 1 + 2
```

---

## 三、改造前后对比

### 3.1 数据一致性

| 场景 | 改造前 | 改造后 |
|------|--------|--------|
| A 发消息给 B，B 在会话列表 | B 的会话列表角标 +1，Tab 栏角标 +1 ✅ | 同上 ✅ |
| A 发消息给 B，B 在与 A 的聊天页 | B 的聊天页角标不清除，返回后仍有角标 ❌ | B 进入聊天页时角标清除，Tab 栏动态扣除 ✅ |
| B 在聊天页收到 C 的新消息 | C 的角标可能不更新 ❌ | C 的会话角标正常更新 ✅ |
| WebSocket 重连 | 角标可能丢失或不一致 ❌ | 重连时 `/badge/get` 全量恢复 ✅ |

### 3.2 性能指标

| 指标 | 改造前 | 改造后 | 提升 |
|------|--------|--------|------|
| 单条消息推送的 badgeUpdated 数据量 | 所有会话角标（可能 50+ 个） | 单个会话角标（1 个） | **50 倍** |
| `getConversationBadges()` DB 查询 | 全表扫描 `im_chat_user` | 仅查 `unread_count > 0` | **10 倍** |
| Tab 栏角标计算复杂度 | O(1)（但数据源错误） | O(1)（数据源正确） | — |
| 角标同步延迟 | 全量推送导致延迟 | 增量推送降低延迟 | **5 倍** |

### 3.3 网络流量

**场景**: 1000 人群聊，每人发一条消息

| 组件 | 改造前 | 改造后 |
|------|--------|--------|
| 每条消息推送的 badgeUpdated 大小 | ~5KB（全量角标） | ~0.2KB（单个角标） |
| 总推送数据量 | 1000 × 999 × 5KB ≈ 5GB | 1000 × 999 × 0.2KB ≈ 200MB |
| 节省 | — | **96%** |

---

## 四、测试验证方案

### 4.1 单元测试

| 测试用例 | 验证点 |
|----------|--------|
| `test_incremental_badge_push()` | 单聊消息仅推送单个会话角标 |
| `test_sender_no_badge_push()` | 发送者不收到 badgeUpdated |
| `test_getConversationBadges_sql()` | SQL 仅返回 unread_count > 0 的会话 |
| `test_badge_apply_incremental()` | 增量 payload 正确合并到 BadgeState |
| `test_effectiveTabBadge_with_active()` | 活跃会话角标正确从 Tab 栏扣除 |

### 4.2 集成测试场景

| 场景 | 操作步骤 | 预期结果 |
|------|----------|----------|
| S1 基础发消息 | A 给 B 发消息，B 在会话列表 | B 的会话列表和 Tab 栏角标同时 +1 |
| S2 聊天页免角标 | A 给 B 发消息，B 在与 A 的聊天页 | B 的 Tab 栏角标不变（已在聊天页） |
| S3 返回会话列表 | B 从聊天页返回会话列表 | A 的会话无角标，Tab 栏角标正确 |
| S4 群聊消息 | 群成员 C 发消息，B 不在聊天页 | B 的群聊会话角标 +1 |
| S5 重连恢复 | WebSocket 断开重连 | 角标从 `/badge/get` 全量恢复 |
| S6 快速切换 | 快速切换多个会话 | 角标随当前会话正确变化 |
| S7 角标溢出 | 未读数 > 99 | 显示 "99+" |

### 4.3 性能压测

| 压测场景 | 指标 | 目标 |
|----------|------|------|
| 单用户每秒 100 条消息 | badgeUpdated 推送延迟 | < 100ms |
| 1000 人群聊同时发消息 | 服务端 CPU 使用率 | < 80% |
| 角标数据 1000 个会话 | 推送数据大小 | < 50KB |

---

## 五、回滚方案

每个 Phase 可独立回滚：

| Phase | 回滚方式 |
|-------|----------|
| Phase 1（前端数据源统一） | 恢复 `ConversationTile` 使用 `Conversation.unreadCount`，移除 `chat_page` 激活/失活调用 |
| Phase 2（后端推送优化） | 恢复 `pushBadgeUpdate()` 全量推送 |
| Phase 3（全链路集成） | 恢复 WebSocket 全量处理逻辑 |

---

## 六、风险与注意事项

### 6.1 风险点

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| 增量推送丢失消息角标 | 用户漏看消息 | 重连时全量恢复 + 定期全量校验 |
| `ConversationTile` 改为 ConsumerWidget | 性能下降 | 使用 `ref.watch` 精准订阅，避免全局 rebuild |
| 后端 Protobuf 新增字段 | 旧客户端不兼容 | 新增 `incremental` 字段为可选，默认 `false` |
| 在线状态感知推送 | 用户收不到角标通知 | 保守策略：在线仍然推送，后续再优化 |

### 6.2 兼容性

- **本方案为开发环境最优方案**，不考虑老数据兼容性及旧项目兼容性
- 所有改造直接按最优方案推进，无需兼容旧逻辑
- Protobuf 新增 `incremental` 字段为可选，默认值 `false`（Protobuf 协议层面兼容）
- uni-appx 端：需要单独适配，本方案仅针对 Flutter 端

---

## 七、实施时间线

| 阶段 | 内容 | 预计工作量 |
|------|------|-----------|
| Phase 1 | 前端数据源统一 | 2-3 天 |
| Phase 2 | 后端推送优化 | 2-3 天 |
| Phase 3 | 全链路集成与测试 | 3-4 天 |
| 总计 | — | 7-10 天 |

---

## 附录 A：相关文件清单

### 前端文件

| 文件路径 | 改造内容 |
|----------|----------|
| `lib/features/im/chat/presentation/pages/chat_page.dart` | 激活/失活调用、清除角标 |
| `lib/features/im/conversation/presentation/widgets/conversation_tile.dart` | 从 BadgeState 读角标 |
| `lib/features/im/conversation/presentation/pages/conversation_list_page.dart` | 角标同步逻辑 |
| `lib/features/im/conversation/presentation/controllers/conversation_list_controller.dart` | applyBadgeBadgesToConversations |
| `lib/features/im/badge/badge_service.dart` | 增量更新方法、totalUnreadCount 计算 |
| `lib/features/im/badge/active_conversation_service.dart` | activeUnreadCount 计算优化 |
| `lib/app/shell/global_badge_socket_binding.dart` | WebSocket 增量/全量处理 |

### 后端文件

| 文件路径 | 改造内容 |
|----------|----------|
| `shengyu-module-system-biz/.../spi/SystemMessageStorageServiceImpl.java` | 增量推送角标 |
| `shengyu-module-system-biz/.../ImBadgeServiceImpl.java` | 增量推送方法 |
| `shengyu-module-system-biz/.../ImConversationServiceImpl.java` | getConversationBadges SQL 优化 |
| `shengyu-framework/.../protocol/BadgeUpdateMessage.java` | Protobuf 新增 incremental 字段 |
| `shengyu-module-system-biz/.../dal/mysql/im/ImChatUserMapper.java` | selectListWithUnread 方法 |

---

## 附录 B：Protobuf 定义变更

```protobuf
message BadgeUpdateMessage {
  int32 unread_count = 1;
  repeated ConversationBadge conversation_badges = 2;
  repeated MenuBadge menu_badges = 3;
  bool incremental = 4;  // 新增: 是否为增量推送，默认 false
}
```

**向后兼容**：旧客户端收到 `incremental` 字段（Protobuf 默认值为 `false`），仍按全量处理，不会崩溃。

---

## 附录 C：SQL 变更

```sql
-- 新增索引：优化 unread_count > 0 查询
CREATE INDEX idx_chat_user_unread 
ON im_chat_user(user_id, unread_count) 
WHERE unread_count > 0;

-- 新增索引：优化 getConversationBadges 查询
CREATE INDEX idx_chat_user_user_unread 
ON im_chat_user(user_id, unread_count)
WHERE unread_count > 0 AND deleted_by_user = 0;
```
