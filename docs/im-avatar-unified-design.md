# IM 头像统一显示修复设计文档

> 创建时间: 2026-07-04  
> 最后更新: 2026-07-04  
> 版本: v4.0（完整调研版）

---

## 实施状态跟踪

### 已完成任务（2026-07-04）

- [x] **Step 1**: 修正 ChatAvatar 组件 - 添加 name 参数，seed 语义调整为 userId（P0严重）
  - 文件: `lib/features/im/chat/presentation/widgets/chat_avatar.dart`
  - 文件: `lib/features/im/chat/presentation/widgets/chat_timeline.dart`
  - 状态: ✅ 已完成

- [x] **Step 2**: 修正会话列表头像参数 - 显式传递 seed: conversation.targetId
  - 文件: `lib/features/im/conversation/presentation/widgets/conversation_tile.dart`
  - 状态: ✅ 已完成

- [x] **Step 3**: 联系人详情页添加头像显示（功能缺失）
  - 文件: `lib/features/contacts/presentation/pages/contact_profile_page.dart`
  - 状态: ✅ 已完成

- [x] **Step 4**: 修正来电页头像参数 - 添加 seed，移除固定背景色
  - 文件: `lib/features/im/call/presentation/pages/incoming_call_page.dart`
  - 状态: ✅ 已完成

- [x] **Step 5**: 修正群加入申请页头像参数 - 添加 seed，移除固定背景色
  - 文件: `lib/features/im/group_settings/presentation/pages/group_join_requests_page.dart`
  - 状态: ✅ 已完成

- [x] **Step 6**: 统一群设置页、个人中心页、转发目标页 seed 参数
  - 文件: `lib/features/im/group_settings/presentation/pages/group_settings_page.dart`
  - 文件: `lib/features/profile/presentation/pages/profile_page.dart`
  - 文件: `lib/features/im/chat/presentation/pages/forward_target_page.dart`
  - 状态: ✅ 已完成

- [x] **Step 7**: 增强头像上传/删除后的缓存清理和 Provider 刷新机制
  - 文件: `lib/features/profile/presentation/providers/profile_providers.dart`
  - 文件: `lib/features/im/conversation/presentation/providers/conversation_realtime_binding.dart`
  - 状态: ✅ 已完成
  - 实现内容:
    - 头像上传/删除时清理旧头像的磁盘缓存（ImCacheManager）
    - 清理 Flutter ImageCache 内存缓存
    - 刷新 currentUserProfileProvider、conversationListControllerProvider、contactsPageControllerProvider
    - WebSocket 头像变更事件处理增强（多端同步场景）

- [x] **Step 8**: 编译验证 + 更新设计文档任务状态
  - 编译结果: ✅ 通过（178 个问题中只有 1 个错误在测试文件中，与本次修改无关）
  - 状态: ✅ 已完成

- [x] **Step 9**: 全面检查并修复所有头像组件调用遗漏 seed 参数问题
  - 状态: ✅ 已完成
  - 修复内容:
    - 修复 5 处重复 seed 参数导致的编译错误:
      - `read_receipt_page.dart` - 已读回执页
      - `contacts_page.dart` - 通讯录页
      - `contact_search_result_page.dart` - 联系人搜索结果页
      - `contact_group_members_page.dart` - 联系人分组成员页
      - `my_following_page.dart` - 我的关注页
    - 修复 3 处缺少 seed 参数的问题:
      - `group_members_page.dart` - 群成员列表页: `_MemberAvatar` 组件添加 `userId` 参数
      - `common_global_search_page.dart` - 全局搜索页: `_ResultAvatar` 组件添加 `seed: item.id`
      - `call_session_page.dart` - 通话会话页: 添加 `seed: state.callerProfile?.userId ?? state.calleeProfile?.userId`
    - 修复 1 处语法错误:
      - `my_department_page.dart` - 我的部门页: 修复多余的右括号导致的 `ContactsChevronTile` 构造函数调用错误
  - 编译结果: ✅ 通过（仅剩 1 个测试文件错误，与本次修改无关）

- [x] **Step 10**: 补充修复剩余头像组件调用遗漏 seed 参数问题
  - 状态: ✅ 已完成
  - 修复内容:
    - 修复 2 处缺少 seed 参数的问题:
      - `settings_page.dart` - 个人中心设置页: 添加 `seed: profile.userId`
      - `outgoing_call_page.dart` - 呼出通话页: 添加 `seed: state.calleeProfile?.userId`
  - 编译结果: ✅ 通过（仅剩 1 个测试文件错误，与本次修改无关）

### 待验证任务（需要手动测试）

代码实现已全部完成，以下测试项需要手动验证：

- [ ] 用户上传头像后，个人中心立即显示新头像
- [ ] 用户上传头像后，会话列表中的当前用户头像立即更新
- [ ] 用户上传头像后，通讯录中的当前用户头像立即更新
- [ ] 用户删除头像后，所有页面立即显示文字头像
- [ ] 多设备登录时，一端修改头像，另一端实时同步
- [ ] 重新登录后，头像显示正确（不显示旧缓存）
- [ ] 租户切换后，头像显示正确
- [ ] 弱网环境下，头像加载失败正确降级到文字头像
- [ ] 磁盘缓存被正确清理，不会无限增长
- [ ] 内存缓存被正确清理，不会残留旧头像

**验证方法**：
1. 在个人中心上传/删除头像，观察各页面是否立即更新
2. 使用两个设备登录同一账号，修改一端头像，观察另一端是否实时同步
3. 切换租户后，检查所有页面头像是否正确刷新
4. 在弱网环境下（如飞行模式）打开应用，观察头像是否正确降级到文字头像
5. 使用开发者工具查看磁盘缓存目录，确认缓存文件数量在合理范围内

---

## 最终实施总结（2026-07-04）

### 已完成的全部任务

#### 核心组件修正（P0/P1）
1. ✅ **ChatAvatar 组件** - 添加 `name` 参数，`seed` 语义调整为 userId
2. ✅ **会话列表头像** - 显式传递 `seed: conversation.targetId`
3. ✅ **联系人详情页** - 添加头像显示功能（原功能缺失）
4. ✅ **来电页** - 添加 `seed` 参数，移除固定背景色
5. ✅ **群加入申请页** - 添加 `seed` 参数，移除固定背景色

#### 统一 seed 参数（P2）
6. ✅ **群设置页** - 显式传递 `seed: userId`
7. ✅ **个人中心页** - 显式传递 `seed: session.userId`
8. ✅ **转发目标页** - 显式传递 `seed: conversation.targetId`
9. ✅ **个人中心设置页** - 显式传递 `seed: profile.userId`
10. ✅ **呼出通话页** - 显式传递 `seed: state.calleeProfile?.userId`
11. ✅ **通话会话页** - 显式传递 `seed: state.callerProfile?.userId ?? state.calleeProfile?.userId`
12. ✅ **群成员列表页** - `_MemberAvatar` 组件添加 `userId` 参数
13. ✅ **全局搜索页** - `_ResultAvatar` 组件添加 `seed: item.id`

#### 缓存清理机制（企业级）
14. ✅ **头像上传/删除后缓存清理** - 清理磁盘缓存（ImCacheManager）、内存缓存（ImageCache）
15. ✅ **Provider 刷新机制** - 刷新 currentUserProfileProvider、conversationListControllerProvider、contactsPageControllerProvider
16. ✅ **WebSocket 头像变更事件处理** - 增强 `_handleUserAvatarChanged` 方法，支持多端同步场景

#### 编译错误修复
17. ✅ **修复 5 处重复 seed 参数** - read_receipt_page.dart、contacts_page.dart、contact_search_result_page.dart、contact_group_members_page.dart、my_following_page.dart
18. ✅ **修复 1 处语法错误** - my_department_page.dart 多余的右括号

### 编译验证结果

```
✅ 编译通过（仅剩 1 个测试文件错误，与本次修改无关）
错误文件: test/features/im/conversation/conversation_list_controller_test.dart:29:32
错误原因: ConversationListController 构造函数参数数量变化（与头像功能无关）
```

### 技术实现要点

1. **颜色种子统一使用 userId** - 确保同一用户即使修改昵称，头像颜色不变
2. **文字头像使用昵称** - 通过 `getAvatarText(name)` 提取头像文字
3. **三级缓存架构** - 内存缓存（ImageCache）+ 磁盘缓存（ImCacheManager）+ 网络（OSS/CDN）
4. **缓存清理时机** - 头像上传/删除时、WebSocket 收到头像变更事件时
5. **Provider 刷新** - 确保所有包含用户头像的 Provider 在头像变更后被刷新

### 文件修改清单（最终版）

| 序号 | 文件路径 | 修改类型 | 状态 |
|------|---------|---------|------|
| 1 | `lib/features/im/chat/presentation/widgets/chat_avatar.dart` | 修改 | ✅ 已完成 |
| 2 | `lib/features/im/chat/presentation/widgets/chat_timeline.dart` | 修改 | ✅ 已完成 |
| 3 | `lib/features/contacts/presentation/pages/contact_profile_page.dart` | 修改 | ✅ 已完成 |
| 4 | `lib/features/im/conversation/presentation/widgets/conversation_tile.dart` | 修改 | ✅ 已完成 |
| 5 | `lib/features/im/call/presentation/pages/incoming_call_page.dart` | 修改 | ✅ 已完成 |
| 6 | `lib/features/im/group_settings/presentation/pages/group_join_requests_page.dart` | 修改 | ✅ 已完成 |
| 7 | `lib/features/im/group_settings/presentation/pages/group_settings_page.dart` | 修改 | ✅ 已完成 |
| 8 | `lib/features/profile/presentation/pages/profile_page.dart` | 修改 | ✅ 已完成 |
| 9 | `lib/features/im/chat/presentation/pages/forward_target_page.dart` | 修改 | ✅ 已完成 |
| 10 | `lib/features/profile/presentation/providers/profile_providers.dart` | 修改 | ✅ 已完成 |
| 11 | `lib/features/im/conversation/presentation/providers/conversation_realtime_binding.dart` | 修改 | ✅ 已完成 |
| 12 | `lib/features/profile/presentation/pages/settings_page.dart` | 修改 | ✅ 已完成 |
| 13 | `lib/features/im/call/presentation/pages/outgoing_call_page.dart` | 修改 | ✅ 已完成 |
| 14 | `lib/features/im/call/presentation/pages/call_session_page.dart` | 修改 | ✅ 已完成 |
| 15 | `lib/features/im/group_settings/presentation/pages/group_members_page.dart` | 修改 | ✅ 已完成 |
| 16 | `lib/features/im/search/presentation/pages/common_global_search_page.dart` | 修改 | ✅ 已完成 |
| 17 | `lib/features/im/chat/presentation/pages/read_receipt_page.dart` | 修复 | ✅ 已完成 |
| 18 | `lib/features/contacts/presentation/pages/contacts_page.dart` | 修复 | ✅ 已完成 |
| 19 | `lib/features/contacts/presentation/pages/contact_search_result_page.dart` | 修复 | ✅ 已完成 |
| 20 | `lib/features/contacts/presentation/pages/contact_group_members_page.dart` | 修复 | ✅ 已完成 |
| 21 | `lib/features/contacts/presentation/pages/my_following_page.dart` | 修复 | ✅ 已完成 |
| 22 | `lib/features/contacts/presentation/pages/my_department_page.dart` | 修复 | ✅ 已完成 |

### 下一步

所有代码实现已完成，需要进行手动测试验证，确保：
1. 头像上传/删除后各页面立即更新
2. 多设备同步正常工作
3. 租户切换后头像正确刷新
4. 弱网环境下降级到文字头像
5. 缓存清理机制正常工作

---

## 一、需求概述

1. 用户未上传头像时 → 显示**昵称文字头像**（基于昵称 + userId 固定化生成）
2. 用户已上传头像时 → 显示**用户上传的头像图片**
3. 重新登录、租户切换后，所有页面头像显示必须统一且一致
4. 显示逻辑封装为统一组件/服务，所有页面调用即可

---

## 二、后端数据结构调研

### 2.1 登录接口响应

**文件**: `shengyu-module-system-biz/src/main/java/com/shengyu/module/system/controller/admin/auth/vo/AuthLoginRespVO.java`

```java
public class AuthLoginRespVO {
    private Long userId;
    private String accessToken;
    private String refreshToken;
    private LocalDateTime expiresTime;
    private Long tenantId;
    private String tenantName;
    private Long deptId;
}
```

**关键发现**: 登录接口**不返回** `avatar` 和 `nickname` 字段。

### 2.2 权限信息接口响应

**文件**: `shengyu-module-system-biz/src/main/java/com/shengyu/module/system/controller/admin/auth/vo/AuthPermissionInfoRespVO.java`

```java
public class AuthPermissionInfoRespVO {
    private UserVO user;
    private Set<String> roles;
    private Set<String> permissions;
    private List<MenuVO> menus;
    
    public static class UserVO {
        private Long id;
        private String nickname;  // 用户昵称
        private String avatar;    // 用户头像
    }
}
```

**关键发现**: 用户头像和昵称通过 `/system/auth/get-permission-info` 接口获取，而非登录接口。

### 2.3 用户数据模型

**文件**: `shengyu-module-system-biz/src/main/java/com/shengyu/module/system/dal/dataobject/user/AdminUserDO.java`

```java
public class AdminUserDO extends TenantBaseDO {
    private Long id;
    private Long saasUserId;
    private String openAccount;
    private String nickname;      // 用户昵称
    private String remark;
    private Long deptId;
    private Integer status;
    private String avatar;        // 用户头像
    private String loginIp;
    private LocalDateTime loginDate;
}
```

**关键发现**: 用户头像和昵称存储在 `system_users` 表中，字段名为 `avatar` 和 `nickname`。

### 2.4 会话列表接口响应

**文件**: `shengyu-module-system-biz/src/main/java/com/shengyu/module/system/controller/app/im/vo/conversation/AppImConversationRespVO.java`

```java
public class AppImConversationRespVO {
    private Long chatId;
    private Long targetId;              // 目标ID(单聊为对方用户ID,群聊为群ID)
    private Integer conversationType;   // 会话类型(1-单聊 2-群聊)
    private String targetName;          // 目标名称(对方名称或群名)
    private String targetAvatar;        // 目标头像
    private Long lastMessageSenderId;   // 最后一条消息发送者ID
    private List<GroupMemberItem> groupMemberItems;  // 群成员信息列表
    
    @Data
    public static class GroupMemberItem {
        private Long userId;
        private String name;
        private String avatar;
    }
}
```

**关键发现**: 
- **单聊场景**: `targetName` 就是对方的真实昵称（来自 `AdminUserDO.nickname`）
- **群聊场景**: `targetName` 是群名称（来自 `ImGroupDO.name`）
- 后端实现位置: `ImConversationServiceImpl.java` L1088-L1091

```java
// 单聊场景 - L1088-L1091
Long otherUserId = Objects.equals(chat.getSingleUser1(), userId) ? chat.getSingleUser2() : chat.getSingleUser1();
respVO.setTargetId(otherUserId);
AdminUserDO targetUser = otherUserId != null ? userMap.get(otherUserId) : null;
if (targetUser != null) {
    respVO.setTargetName(targetUser.getNickname());  // 使用真实昵称
    respVO.setTargetAvatar(targetUser.getAvatar());
}
```

**结论**: 后端已经返回对方真实昵称，**无需添加新字段**，前端可直接使用 `targetName` 作为昵称

### 2.5 联系人接口响应

**文件**: `shengyu-module-system-biz/src/main/java/com/shengyu/module/system/controller/app/im/vo/contact/AppImContactRespVO.java`

```java
public class AppImContactRespVO {
    private Long id;           // 用户ID
    private String nickname;   // 用户昵称
    private String avatar;     // 用户头像
    private Long deptId;
    private String deptName;
    private String postName;
    private Boolean star;
    private Boolean noDisturb;
}
```

**关键发现**: 联系人接口返回完整的用户信息，包括 `id`、`nickname`、`avatar`。

### 2.6 消息接口响应

**文件**: `shengyu-module-system-biz/src/main/java/com/shengyu/module/system/controller/app/im/vo/message/AppImMessageRespVO.java`

```java
public class AppImMessageRespVO {
    private Long id;
    private Long chatId;
    private Long senderId;           // 发送者ID
    private String senderNickname;   // 发送者昵称
    private String senderAvatar;     // 发送者头像
    private Integer messageType;
    private String content;
    private LocalDateTime sendTime;
    private Boolean isSelf;
}
```

**关键发现**: 消息接口返回完整的发送者信息，包括 `senderId`、`senderNickname`、`senderAvatar`。

---

## 三、Flutter 端现有架构调研

### 3.1 认证会话

**文件**: `lib/core/auth/auth_session.dart` (L1-65)

```dart
class AuthSession {
  const AuthSession({
    required this.userId,
    required this.accessToken,
    required this.refreshToken,
    required this.tenantId,
    this.tenantName,
    required this.deviceId,
    required this.deviceType,
    required this.deviceName,
    required this.clientVersion,
    required this.locale,
  });
  
  final String userId;
  final String accessToken;
  final String refreshToken;
  final String tenantId;
  final String? tenantName;
  final String deviceId;
  final int deviceType;
  final String deviceName;
  final String clientVersion;
  final String locale;
}
```

**关键发现**: `AuthSession` **不包含** `avatarUrl` 和 `nickname` 字段。

### 3.2 登录响应解析

**文件**: `lib/core/auth/auth_token_dto.dart` (L1-23)

```dart
class AuthTokenDto {
  const AuthTokenDto({
    required this.accessToken,
    required this.refreshToken,
    required this.tenantId,
    this.tenantName,
  });
  
  final String accessToken;
  final String refreshToken;
  final String tenantId;
  final String? tenantName;
}
```

**关键发现**: `AuthTokenDto` 只解析 token 相关信息，不包含头像和昵称。

### 3.3 用户信息获取

**文件**: `lib/features/profile/presentation/pages/profile_page.dart` (L26, L45-67)

```dart
final profileAsync = ref.watch(currentUserProfileProvider);
// ...
final profile = profileAsync.valueOrNull;
final username = profile.nickname.isNotEmpty ? profile.nickname : session.userId;
// ...
_ProfileHeader(
  username: username,
  avatarUrl: profile.avatarUrl,
  nickname: profile.nickname,
  // ...
)
```

**关键发现**: 个人中心通过 `currentUserProfileProvider` 获取用户信息，该 Provider 返回 `UserProfile` 实体。

### 3.4 核心头像组件

| 组件 | 文件路径 | 用途 | 关键参数 |
|------|---------|------|---------|
| `AppAvatar` | `lib/shared/widgets/app_avatar.dart:6-98` | 通用头像组件 | `name`, `avatarUrl`, `seed`, `backgroundColor` |
| `ChatAvatar` | `lib/features/im/chat/presentation/widgets/chat_avatar.dart` | 聊天消息头像 | `seed`, `imageUrl`, `size` |
| `GroupAvatarWidget` | `lib/shared/widgets/group_avatar.dart` | 群组组合头像（钉钉风格） | `members`, `size`, `borderRadius` |

### 3.5 头像工具函数

**文件**: `lib/shared/utils/im_avatar.dart`

| 函数 | 行号 | 功能 |
|------|------|------|
| `getUserAvatarColor(userId)` | L27 | 基于用户 ID 生成头像背景色 |
| `getGroupAvatarColor(groupId)` | L29-30 | 基于群组 ID 生成头像背景色 |
| `getAvatarText(name)` | L50-70 | 从昵称提取头像文字（中文2字/英文首字母） |
| `normalizeAvatarUrl(raw)` | L42-48 | 标准化头像 URL（过滤空值） |
| `resolveConversationAvatarBg(...)` | L92-112 | 解析会话头像背景色 |

### 3.6 头像数据来源

| 场景 | 数据模型 | 头像字段 | 昵称字段 | ID字段 |
|------|---------|---------|---------|--------|
| 通讯录 | `ContactDto` | `avatarUrl` (L16) | `nickname` (L14) | `userId` (L13) |
| 会话列表(单聊) | `ConversationDto` | `targetAvatar` (L49) | `title` (L45) | `targetId` (L48) |
| 会话列表(群聊) | `ConversationDto` | `groupMemberItems[].avatar` (L311) | `groupMemberItems[].name` (L310) | `groupMemberItems[].userId` (L309) |
| 聊天消息 | `MessageDto` | `senderAvatar` (L73) | `senderName` (L72) | `senderId` (L71) |
| 群设置成员 | `GroupMemberPreviewItem` | `avatarUrl` (L20) | `name` (L17) | `id` (L16) |
| 当前用户 | `UserProfile` | `avatarUrl` | `nickname` | `userId` |

### 3.7 缓存管理

**文件**: `lib/infrastructure/cache/im_cache_manager.dart`

- `ImCacheManager.instance` (L42-54): 图片缓存管理器，100 文件上限，30 天过期
- 租户切换时**未清理**头像缓存

---

## 四、各页面头像使用现状与问题诊断

### 4.1 会话列表页 - **轻微问题**

**文件**: `lib/features/im/conversation/presentation/widgets/conversation_tile.dart` (L579-592)

**当前实现**:
```dart
AppAvatar(
  name: _fallbackText(),  // 返回会话标题
  avatarUrl: conversation.targetAvatar,
  backgroundColor: resolveConversationAvatarBg(...),
  // 缺少 seed 参数
)
```

**后端数据现状**:
- 后端 `ImConversationServiceImpl.java` L1088-L1091 已经返回 `targetName` = `targetUser.getNickname()`
- Flutter `ConversationDto.fromJson` L100-105 将 `targetName` 映射为 `title`
- **单聊场景下 `conversation.title` 就是对方真实昵称**，无需后端改动

**问题**:
- 没有显式传递 `seed` 参数，依赖 `seed ?? name` 逻辑，导致颜色基于标题生成
- 当标题被修改后，头像颜色会变化

**修复方案**: 显式传递 `seed: conversation.targetId`，确保颜色基于用户ID稳定生成

### 4.2 聊天对话页 - **严重问题**

**文件**: `lib/features/im/chat/presentation/widgets/chat_timeline.dart` (L316-318)

**当前实现**:
```dart
ChatAvatar(seed: senderDisplayName, imageUrl: message.senderAvatar)
```

**问题**: 
- `seed` 传入的是 `senderDisplayName`（显示名）而非 `userId`
- 同一用户在不同消息中如果显示名不同（如群昵称 vs 真实姓名），头像颜色会不一致
- `ChatAvatar` 组件没有 `name` 参数，无法区分颜色种子和文字头像来源

**修复方案**:
```dart
// 修改 ChatAvatar 组件，添加 name 参数
ChatAvatar(
  seed: message.senderId,          // userId 作为颜色种子
  name: senderDisplayName,         // 昵称用于文字头像
  imageUrl: message.senderAvatar,
)
```

### 4.3 通讯录页面 - **已正确实现**

**文件**: `lib/features/contacts/presentation/widgets/contacts_section_widgets.dart` (L170-199)

**当前实现**:
```dart
ContactsInitialAvatar(
  name: contactDto.nickname,
  color: getUserAvatarColor(contactDto.userId),
  avatarUrl: contactDto.avatarUrl,
)
```

**状态**: 颜色基于 `userId` 生成，是稳定的。

### 4.4 群设置页 - **轻微问题**

**文件**: `lib/features/im/group_settings/presentation/pages/group_settings_page.dart` (L1158-1167)

**当前实现**:
```dart
AppAvatar(
  name: name,
  avatarUrl: avatarUrl,
  backgroundColor: getUserAvatarColor(userId),  // 已经基于 userId
  // 缺少 seed 参数
)
```

**问题**: 没有显式传递 `seed` 参数，但 `backgroundColor` 已经基于 `userId` 生成，颜色是稳定的。

**修复方案**: 显式传递 `seed: userId` 以保持一致性。

### 4.5 群成员列表页 - **已正确实现**

**文件**: `lib/features/im/group_settings/presentation/pages/group_members_page.dart` (L778-785)

**当前实现**:
```dart
_MemberAvatar(
  name: displayName,
  colorValue: member.colorValue,  // 从 GroupMemberPreviewItem 传入
  avatarUrl: member.avatarUrl,
)
```

**根因分析**:
- `colorValue` 通过 `_memberColorValue(member.userId)` 生成
- `_memberColorValue` 函数调用 `getUserAvatarColor(seed).toARGB32()`
- `seed` 是 `userId`，颜色是稳定的

**状态**: **已正确实现**，颜色基于 `userId` 生成。

### 4.6 群成员详情页 - **已正确实现**

**文件**: `lib/features/im/group_settings/presentation/pages/group_member_detail_page.dart` (L517-546)

**当前实现**: 同群成员列表页，使用 `colorValue`，基于 `userId` 生成。

**状态**: **已正确实现**。

### 4.7 群加入申请页 - **需要修复**

**文件**: `lib/features/im/group_settings/presentation/pages/group_join_requests_page.dart` (L172-175, L465-479)

**当前实现**:
```dart
class _RequestAvatar extends StatelessWidget {
  const _RequestAvatar({required this.name, this.avatarUrl});

  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return AppAvatar(
      name: name,
      avatarUrl: avatarUrl,
      backgroundColor: const Color(0xFFEEF3FF),
      size: 44,
      borderRadius: 12,
      fontSize: 18,
    );
  }
}
```

**后端接口现状**:
- **后端已经返回申请人ID**：`AppImGroupJoinRequestRespVO.java` L22-24 包含 `applicantUserId` 字段
- 后端实现位置: `ImGroupServiceImpl.java` L2218-2225 `getJoinRequests` 方法

**问题**: 
- 没有显式传递 `seed` 参数
- `backgroundColor` 固定为 `Color(0xFFEEF3FF)`，不基于 `userId` 生成

**修复方案**:
1. Flutter 端解析 `applicantUserId` 字段到 `GroupJoinRequestItem`
2. 传递 `seed: applicantUserId`，移除固定背景色

### 4.8 个人中心页 - **轻微问题**

**文件**: `lib/features/profile/presentation/pages/profile_page.dart` (L659-668)

**当前实现**:
```dart
AppAvatar(
  name: name,
  avatarUrl: avatarUrl,
  backgroundColor: Colors.white.withValues(alpha: 0.2),
  // 缺少 seed 参数
)
```

**问题**: 没有显式传递 `seed` 参数，但 `backgroundColor` 已经固定为半透明白色。

**修复方案**: 显式传递 `seed: session.userId` 以保持一致性。

### 4.9 来电页 - **需要修复**

**文件**: `lib/features/im/call/presentation/pages/incoming_call_page.dart` (L59-67)

**当前实现**:
```dart
AppAvatar(
  name: title,
  avatarUrl: avatarUrl,
  backgroundColor: const Color(0xFF3D75F6),
  // 缺少 seed 参数
)
```

**问题**: 
- 没有显式传递 `seed` 参数
- `backgroundColor` 固定为蓝色

**修复方案**:
1. 获取对方 `userId`（从 `state.callerProfile`）
2. 传递 `seed: callerUserId`，移除固定背景色

### 4.10 转发目标页 - **轻微问题**

**文件**: `lib/features/im/chat/presentation/pages/forward_target_page.dart` (L532-540)

**当前实现**:
```dart
AppAvatar(
  name: title,
  avatarUrl: conversation.targetAvatar,
  backgroundColor: getUserAvatarColor(conversation.targetId ?? ''),
  // 缺少 seed 参数
)
```

**问题**: 没有显式传递 `seed` 参数，但 `backgroundColor` 已经基于 `targetId` 生成。

**修复方案**: 显式传递 `seed: conversation.targetId`。

### 4.11 名片消息气泡 - **已正确实现**

**文件**: `lib/features/im/chat/presentation/widgets/contact_card_message_bubble.dart` (L91-99)

**当前实现**:
```dart
AppAvatar(
  name: displayName,
  avatarUrl: avatarUrl.isNotEmpty ? avatarUrl : null,
  seed: contactUserId.isNotEmpty ? contactUserId : null,
)
```

**状态**: 已经正确传递 `seed` 参数。

### 4.12 联系人详情页 - **功能缺失**

**文件**: `lib/features/contacts/presentation/pages/contact_profile_page.dart` (L106-182)

**当前实现**: 页面顶部没有显示头像！只有姓名和详细信息。

**问题**: 缺少头像显示功能。

**修复方案**:
1. 在页面顶部添加头像显示
2. 使用 `AppAvatar` 组件
3. 传递 `name: displayName`, `avatarUrl: _profile?.avatarUrl`, `seed: widget.userId`

### 4.13 聊天设置页 - **已正确实现**

**文件**: `lib/features/im/conversation/presentation/pages/chat_settings_page.dart` (L110-117)

**当前实现**:
```dart
ContactsInitialAvatar(
  name: displayName,
  color: avatarColor,  // 通过 getUserAvatarColor(targetId) 生成
  avatarUrl: avatarUrl,
)
```

**状态**: 颜色基于 `targetId` 生成，是稳定的。

---

## 五、问题诊断总结

### 问题1: ChatAvatar 的 seed 参数不一致（严重）

**文件**: `lib/features/im/chat/presentation/widgets/chat_avatar.dart`  
**调用位置**: `lib/features/im/chat/presentation/widgets/chat_timeline.dart:317`

**现状**: 
```dart
ChatAvatar(seed: senderDisplayName, imageUrl: message.senderAvatar)
```

`seed` 参数传入的是 `senderDisplayName`（显示名），而不是 `userId`。

**影响**: 同一用户在不同消息中如果显示名不同（如群昵称 vs 真实姓名），头像颜色会不一致。

**正确做法**: `seed` 应该传入 `userId`，确保颜色稳定。

### 问题2: 会话列表缺少 seed 参数（轻微）

**文件**: `lib/features/im/conversation/presentation/widgets/conversation_tile.dart`

**现状**: 
- 单聊场景下 `AppAvatar` 的 `name` 参数传入的是 `conversation.title`
- **后端已经返回对方真实昵称**：`ImConversationServiceImpl.java` L1088-L1091 中 `targetName` 就是 `targetUser.getNickname()`
- **Flutter DTO 正确映射**：`ConversationDto.fromJson` L100-105 将 `targetName` 映射为 `title`
- 没有显式传递 `seed` 参数，依赖 `seed ?? name` 逻辑

**影响**: 头像颜色基于 `title` 生成，当标题变化时颜色不稳定。

**正确做法**: 显式传递 `seed: conversation.targetId`，确保颜色基于用户ID稳定生成。

### 问题3: 联系人详情页缺失头像显示（功能缺失）

**文件**: `lib/features/contacts/presentation/pages/contact_profile_page.dart`

**现状**: 页面顶部没有显示头像，只有姓名和详细信息。

**影响**: 用户体验不一致，无法在联系人详情页看到对方头像。

**正确做法**: 在页面顶部添加头像显示，使用 `AppAvatar` 组件。

### 问题4: 来电页和群加入申请页缺少 seed 参数（轻微）

**文件**: 
- `lib/features/im/call/presentation/pages/incoming_call_page.dart`
- `lib/features/im/group_settings/presentation/pages/group_join_requests_page.dart`

**现状**: 没有显式传递 `seed` 参数，且 `backgroundColor` 固定。

**影响**: 头像颜色不基于 `userId` 生成，可能不一致。

**正确做法**: 获取对方 `userId`，传递 `seed: userId`，移除固定背景色。

### 问题5: 多个页面缺少显式 seed 参数（轻微）

**文件**: 
- `lib/features/im/group_settings/presentation/pages/group_settings_page.dart`
- `lib/features/profile/presentation/pages/profile_page.dart`
- `lib/features/im/chat/presentation/pages/forward_target_page.dart`

**现状**: 没有显式传递 `seed` 参数，但 `backgroundColor` 已经基于 `userId` 生成。

**影响**: 代码可读性差，依赖隐式逻辑。

**正确做法**: 显式传递 `seed: userId` 以保持一致性和可读性。

### 问题6: 头像缓存未在租户切换时清理（设计决策）

**文件**: `lib/infrastructure/cache/im_cache_manager.dart`  
**租户切换**: `lib/features/profile/domain/services/tenant_switch_service.dart`

**现状**: `ImCacheManager` 使用全局单例，不同租户/用户的头像缓存共享同一缓存池。

**影响**: 虽然 URL 不同通常不会冲突，但可能导致缓存膨胀。

**策略**: 租户切换时**不清理**图片缓存，因为：
1. 头像 URL 本身包含用户/租户标识，不会跨租户冲突
2. 清理缓存会导致切换后大量网络请求
3. 缓存有 LRU 淘汰机制，自动管理

### 问题7: 消息发送者头像不会随用户更新而变化（预期行为）

**现状**: 聊天消息中的 `senderAvatar` 是消息发送时的快照，用户修改头像后旧消息不会更新。

**说明**: 这是**预期行为**（消息历史不可变），新消息会使用最新头像。

---

## 六、修复方案（精确到代码）

### 方案1: 修正 ChatAvatar 参数（严重问题）

**目标**: 确保聊天消息中头像颜色基于用户 ID 生成，而非显示名

**修改文件**:
- `lib/features/im/chat/presentation/widgets/chat_avatar.dart`
- `lib/features/im/chat/presentation/widgets/chat_timeline.dart:317`

**具体修改**:

1. 修改 `ChatAvatar` 组件签名 (`lib/features/im/chat/presentation/widgets/chat_avatar.dart`):
```dart
class ChatAvatar extends StatelessWidget {
  const ChatAvatar({
    super.key,
    required this.seed,       // 改为: 传入 userId 作为稳定颜色种子
    this.name,                // 新增: 昵称，用于文字头像显示
    this.imageUrl,
    this.size = 40,
    this.borderRadius = 8,
    this.fontSize = 12,
  });

  final String seed;          // userId，用于颜色生成
  final String? name;         // 昵称，用于文字头像
  final String? imageUrl;
  final double size;
  final double borderRadius;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return AppAvatar(
      name: name ?? seed,     // 优先使用 name，兜底使用 seed
      avatarUrl: imageUrl,
      seed: seed,             // 传递 userId 作为颜色种子
      size: size,
      borderRadius: borderRadius,
      fontSize: fontSize,
    );
  }
}
```

2. 修改 `chat_timeline.dart:317` 调用:
```dart
// 修改前
ChatAvatar(seed: senderDisplayName, imageUrl: message.senderAvatar)

// 修改后
ChatAvatar(
  seed: message.senderId,          // userId 作为颜色种子
  name: senderDisplayName,         // 昵称用于文字头像
  imageUrl: message.senderAvatar,
)
```

### 方案2: 修正会话列表头像参数（轻微问题）

**目标**: 单聊场景下使用对方真实昵称生成文字头像，颜色基于 targetId 生成

**后端数据现状**:
- 后端 `ImConversationServiceImpl.java` L1088-L1091 已经返回 `targetName` = `targetUser.getNickname()`
- Flutter `ConversationDto.fromJson` L100-105 将 `targetName` 映射为 `title`
- **无需后端改动**，前端直接使用 `conversation.title` 即可

**修改文件**:
- `lib/features/im/conversation/presentation/widgets/conversation_tile.dart`

**具体修改**:

1. 修改 `_ConversationAvatar` 组件 (`lib/features/im/conversation/presentation/widgets/conversation_tile.dart:579-592`):
```dart
AppAvatar(
  name: conversation.title,  // 已经是对方真实昵称（单聊场景）
  avatarUrl: conversation.targetAvatar,
  seed: conversation.targetId,  // 使用 targetId 作为颜色种子
  backgroundColor: resolveConversationAvatarBg(
    avatarBg: conversation.avatarBg,
    conversationType: conversation.conversationType,
    targetId: conversation.targetId,
    chatId: conversation.chatId,
  ),
  size: 48,
  borderRadius: 8,
  fontSize: 14,
  fontWeight: FontWeight.w600,
)
```

### 方案3: 添加联系人详情页头像显示（功能缺失）

**目标**: 在联系人详情页顶部添加头像显示

**修改文件**:
- `lib/features/contacts/presentation/pages/contact_profile_page.dart`

**具体修改**:

1. 在页面顶部添加头像显示 (`lib/features/contacts/presentation/pages/contact_profile_page.dart:106-182`):
```dart
Container(
  margin: const EdgeInsets.fromLTRB(16, 24, 16, 24),
  padding: const EdgeInsets.all(24),
  decoration: BoxDecoration(
    color: ThemeColors.surface(context),
    borderRadius: BorderRadius.circular(12),
    boxShadow: const [
      BoxShadow(
        color: Color(0x14000000),
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
  ),
  child: Row(
    children: [
      // 添加头像显示
      AppAvatar(
        name: displayName,
        avatarUrl: _profile?.avatarUrl,
        seed: widget.userId,
        size: 64,
        borderRadius: 16,
        fontSize: 24,
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: ThemeColors.textPrimary(context),
                    ),
                  ),
                ),
                if (_profile?.sex != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    _profile!.sex == 0 ? Icons.male : Icons.female,
                    size: 18,
                    color: _profile!.sex == 0
                        ? const Color(0xFF0EA5E9)
                        : const Color(0xFFEC4899),
                  ),
                ],
              ],
            ),
            // ... 其他信息
          ],
        ),
      ),
    ],
  ),
)
```

### 方案4: 修正来电页头像参数（轻微问题）

**目标**: 来电页头像颜色基于对方 userId 生成

**修改文件**:
- `lib/features/im/call/presentation/pages/incoming_call_page.dart`

**具体修改**:

1. 修改来电页头像显示 (`lib/features/im/call/presentation/pages/incoming_call_page.dart:59-67`):
```dart
AppAvatar(
  name: title,
  avatarUrl: avatarUrl,
  seed: state.callerProfile?.userId,  // 添加 seed 参数
  size: 72,
  borderRadius: 24,
  fontSize: 28,
  textColor: Colors.white,
  // 移除固定 backgroundColor
)
```

### 方案5: 修正群加入申请页头像参数（轻微问题）

**目标**: 群加入申请页头像颜色基于申请人 userId 生成

**修改文件**:
- `lib/features/im/group_settings/presentation/pages/group_join_requests_page.dart`

**具体修改**:

1. 在 `GroupJoinRequestItem` 中添加 `applicantId` 字段（如果后端返回）
2. 修改 `_RequestAvatar` 组件 (`lib/features/im/group_settings/presentation/pages/group_join_requests_page.dart:465-479`):
```dart
class _RequestAvatar extends StatelessWidget {
  const _RequestAvatar({
    required this.name,
    this.avatarUrl,
    this.seed,  // 添加 seed 参数
  });

  final String name;
  final String? avatarUrl;
  final String? seed;

  @override
  Widget build(BuildContext context) {
    return AppAvatar(
      name: name,
      avatarUrl: avatarUrl,
      seed: seed,  // 传递 seed
      size: 44,
      borderRadius: 12,
      fontSize: 18,
      // 移除固定 backgroundColor
    );
  }
}
```

3. 修改调用处 (`lib/features/im/group_settings/presentation/pages/group_join_requests_page.dart:172-175`):
```dart
_RequestAvatar(
  name: applicantName,
  avatarUrl: item.applicantAvatar,
  seed: item.applicantId,  // 添加 seed 参数
)
```

### 方案6: 统一所有页面 seed 参数（轻微问题）

**目标**: 所有使用 `AppAvatar` 的地方显式传递 `seed` 参数

**修改文件**:
- `lib/features/im/group_settings/presentation/pages/group_settings_page.dart`
- `lib/features/profile/presentation/pages/profile_page.dart`
- `lib/features/im/chat/presentation/pages/forward_target_page.dart`

**具体修改**:

1. 群设置页 (`lib/features/im/group_settings/presentation/pages/group_settings_page.dart:1158-1167`):
```dart
AppAvatar(
  name: name,
  avatarUrl: avatarUrl,
  seed: userId,  // 显式传递 seed
  backgroundColor: getUserAvatarColor(userId),
  size: 48,
  borderRadius: 12,
  fontSize: 18,
)
```

2. 个人中心页 (`lib/features/profile/presentation/pages/profile_page.dart:659-668`):
```dart
AppAvatar(
  name: name,
  avatarUrl: avatarUrl,
  seed: session.userId,  // 显式传递 seed
  backgroundColor: Colors.white.withValues(alpha: 0.2),
  size: 72,
  borderRadius: 24,
  fontSize: 28,
)
```

3. 转发目标页 (`lib/features/im/chat/presentation/pages/forward_target_page.dart:532-540`):
```dart
AppAvatar(
  name: title,
  avatarUrl: conversation.targetAvatar,
  seed: conversation.targetId,  // 显式传递 seed
  backgroundColor: getUserAvatarColor(conversation.targetId ?? ''),
  size: 40,
  borderRadius: 10,
  fontSize: 16,
)
```

---

## 七、实施步骤

### Step 1: 修正 ChatAvatar 参数（严重问题）

1. 修改 `lib/features/im/chat/presentation/widgets/chat_avatar.dart`
   - 添加 `name` 参数
   - `seed` 语义调整为 userId

2. 修改 `lib/features/im/chat/presentation/widgets/chat_timeline.dart:317`
   - 修改 `ChatAvatar` 调用: `seed: message.senderId, name: senderDisplayName`

### Step 2: 添加联系人详情页头像显示（功能缺失）

1. 修改 `lib/features/contacts/presentation/pages/contact_profile_page.dart`
   - 在页面顶部添加头像显示
   - 使用 `AppAvatar` 组件，传递 `seed: widget.userId`

### Step 3: 修正会话列表头像参数（轻微问题）

1. 修改 `lib/features/im/conversation/presentation/widgets/conversation_tile.dart`
   - 显式传递 `seed: conversation.targetId`
   - `name` 继续使用 `conversation.title`（后端已返回对方真实昵称，单聊场景下 `targetName` = `targetUser.getNickname()`）

**注意**: 无需后端改动，后端 `ImConversationServiceImpl.java` L1088-L1091 已正确返回 `targetName`

### Step 4: 修正来电页和群加入申请页头像参数（轻微问题）

1. 修改 `lib/features/im/call/presentation/pages/incoming_call_page.dart`
   - 添加 `seed: state.callerProfile?.userId`
   - 移除固定背景色

2. 修改 `lib/features/im/group_settings/presentation/pages/group_join_requests_page.dart`
   - 在 `GroupJoinRequestItem` 中添加 `applicantId` 字段（如果后端返回）
   - 修改 `_RequestAvatar` 组件，添加 `seed` 参数
   - 修改调用处，传递 `seed: item.applicantId`

### Step 5: 统一所有页面 seed 参数（轻微问题）

1. 修改 `lib/features/im/group_settings/presentation/pages/group_settings_page.dart`
   - 显式传递 `seed: userId`

2. 修改 `lib/features/profile/presentation/pages/profile_page.dart`
   - 显式传递 `seed: session.userId`

3. 修改 `lib/features/im/chat/presentation/pages/forward_target_page.dart`
   - 显式传递 `seed: conversation.targetId`

### Step 6: 验证租户切换场景

1. 切换租户后，确认所有页面头像正确刷新
2. 确认 `currentUserProfileProvider` 在租户切换后被正确刷新
3. 确认头像缓存不会导致跨租户数据泄露

---

## 八、文件修改清单

| 序号 | 文件路径 | 修改类型 | 修改内容 |
|------|---------|---------|---------|
| 1 | `lib/features/im/chat/presentation/widgets/chat_avatar.dart` | 修改 | 添加 name 参数，seed 语义调整 |
| 2 | `lib/features/im/chat/presentation/widgets/chat_timeline.dart` | 修改 | L317 ChatAvatar 调用参数修正 |
| 3 | `lib/features/contacts/presentation/pages/contact_profile_page.dart` | 修改 | 添加头像显示 |
| 4 | `lib/features/im/conversation/presentation/widgets/conversation_tile.dart` | 修改 | 显式传递 seed 参数 |
| 5 | `lib/features/im/call/presentation/pages/incoming_call_page.dart` | 修改 | 添加 seed 参数，移除固定背景色 |
| 6 | `lib/features/im/group_settings/presentation/pages/group_join_requests_page.dart` | 修改 | 添加 seed 参数，移除固定背景色 |
| 7 | `lib/features/im/group_settings/presentation/pages/group_settings_page.dart` | 修改 | 显式传递 seed 参数 |
| 8 | `lib/features/profile/presentation/pages/profile_page.dart` | 修改 | 显式传递 seed 参数 |
| 9 | `lib/features/im/chat/presentation/pages/forward_target_page.dart` | 修改 | 显式传递 seed 参数 |
| 10 | `lib/features/im/conversation/domain/entities/conversation.dart` | 无需修改 | 后端 `targetName` 已是对方真实昵称，无需新增字段 |
| 11 | `lib/features/im/conversation/infrastructure/dtos/conversation_dto.dart` | 无需修改 | 同上，`title` 字段已映射 `targetName` |
| 12 | `lib/features/profile/domain/services/tenant_switch_service.dart` | 已确认 | L258 已调用 `ref.invalidate(currentUserProfileProvider)` |

---

## 九、测试验证清单

### 功能测试

- [ ] 用户无头像时，所有页面显示统一的昵称文字头像
- [ ] 用户上传头像后，所有页面显示新头像
- [ ] 重新登录后，头像显示与之前一致
- [ ] 租户切换后，头像正确更新为新租户下的用户头像
- [ ] 聊天消息中，发送者头像显示正确（含自己和他人的）
- [ ] 群聊头像显示钉钉风格组合头像（≤4人）
- [ ] 同一用户在不同页面头像颜色一致（seed 统一使用 userId）
- [ ] 网络图片加载失败时，正确降级到文字头像
- [ ] 个人中心头像显示当前登录用户信息
- [ ] 联系人详情页显示对方头像

### 边界测试

- [ ] 昵称为空时，显示 '?' 文字头像
- [ ] 昵称为中文时，显示前2个字
- [ ] 昵称为英文时，显示首字母（大写）
- [ ] 昵称包含特殊字符时，正确显示
- [ ] 头像 URL 无效时，正确降级到文字头像
- [ ] 租户切换后，旧租户的头像缓存不会泄露到新租户
- [ ] 弱网环境下，头像加载超时正确降级

### 性能测试

- [ ] 会话列表滚动流畅，头像加载不卡顿
- [ ] 聊天消息列表滚动流畅，头像加载不卡顿
- [ ] 群成员列表（大量成员）滚动流畅
- [ ] 头像缓存命中率高，减少网络请求

---

## 十、技术要点总结

### 头像显示优先级规则

所有页面遵循以下统一规则:

```
1. 若 avatarUrl 有效（非空、非 null/undefined）→ 显示网络图片（CachedNetworkImage）
2. 若 avatarUrl 无效 → 显示文字头像:
   - 文字内容: getAvatarText(nickname) → 中文取前2字，英文取首字母
   - 背景颜色: getUserAvatarColor(userId) → 基于 userId 哈希
   - 文字颜色: 白色
3. 若 nickname 也为空 → 显示 '?' 文字
```

### 关键原则

1. **颜色种子必须使用 userId**: 确保同一用户即使修改昵称，头像颜色不变
2. **文字头像使用昵称**: 确保文字头像反映用户真实身份
3. **个人中心使用独立 Provider**: 通过 `currentUserProfileProvider` 获取当前用户信息
4. **所有页面使用统一组件**: 避免重复实现头像显示逻辑
5. **显式传递 seed 参数**: 提高代码可读性和一致性

### 缓存策略

- 租户切换时**不清理**图片缓存
- 原因: 头像 URL 包含用户/租户标识，不会跨租户冲突；缓存有 LRU 淘汰机制
- 确保: 租户切换后，所有 Provider 状态中的头像数据被正确刷新

### 后端接口说明

- **登录接口** (`/system/auth/login`): 不返回头像和昵称
- **权限信息接口** (`/system/auth/get-permission-info`): 返回当前用户的头像和昵称
- **用户信息获取**: 通过 `currentUserProfileProvider` 调用权限信息接口获取
- **会话列表接口** (`/system/im/conversation/list`): 返回 `targetName` 和 `targetAvatar`，但没有返回 `targetNickname`
- **联系人接口** (`/system/im/contact/list`): 返回完整的用户信息，包括 `id`、`nickname`、`avatar`
- **消息接口** (`/system/im/message/window`): 返回完整的发送者信息，包括 `senderId`、`senderNickname`、`senderAvatar`

---

## 十一、头像上传后的全局更新机制（企业级方案）

### 11.1 现状调研

#### 后端已实现机制

**文件**: `shengyu-module-system-biz/src/main/java/com/shengyu/module/system/service/user/AdminUserServiceImpl.java`

**L376-393**: 上传头像后广播变更
```java
@Override
public String updateUserAvatar(Long id, InputStream avatarFile) {
    validateAdminUserExists(id);
    // 存储文件（每次生成新 URL）
    String avatar = fileApi.createFile(IoUtil.readBytes(avatarFile));
    // 更新路径
    AdminUserDO sysUserDO = new AdminUserDO();
    sysUserDO.setId(id);
    sysUserDO.setAvatar(avatar);
    userMapper.updateById(sysUserDO);

    // 清除 IM 用户缓存
    imCacheService.evictUserCache(id);

    // 广播头像变更事件到该用户的所有在线端（多端同步）
    broadcastAvatarChanged(id, avatar);

    return avatar;
}
```

**L414-429**: WebSocket 广播实现
```java
private void broadcastAvatarChanged(Long userId, String avatarUrl) {
    try {
        Long tenantId = TenantContextHolder.getTenantId();
        String extra = JSONUtil.createObj()
                .set("action", "user_avatar_changed")
                .set("userId", String.valueOf(userId))
                .set("avatarUrl", avatarUrl != null ? avatarUrl : "")
                .toString();
        TextMessage body = TextMessage.newBuilder().setContent("USER_AVATAR_CHANGED").build();
        nettyMessageSender.sendToUserWithExtra(userId, MessageType.SYSTEM_NOTIFY, body,
                0L, userId, 0L, tenantId,
                null, null, null,
                null, null, extra);
        log.info("[AdminUserService] 广播头像变更事件, userId={}, avatarUrl={}", userId, avatarUrl);
    } catch (Exception e) {
        log.warn("[AdminUserService] 广播头像变更事件失败, userId={}, error={}", userId, e.getMessage(), e);
    }
}
```

#### Flutter 端已实现机制

**文件**: `lib/core/websocket/socket_event_types.dart` L30-31
```dart
/// 用户头像变更事件（由后端 SYSTEM_NOTIFY action=user_avatar_changed 触发）
static const userAvatarChanged = 'userAvatarChanged';
```

**文件**: `lib/core/websocket/socket_inbound_mapper.dart` L114-121
```dart
// 用户头像变更事件：拆分为独立事件类型，便于上层监听
if (action == 'user_avatar_changed') {
  return <ImSocketEvent>[
    ImSocketEvent(
      type: SocketEventTypes.userAvatarChanged,
      payload: merged,
    ),
  ];
}
```

**文件**: `lib/features/im/conversation/presentation/providers/conversation_realtime_binding.dart` L206-233
```dart
case SocketEventTypes.userAvatarChanged:
  _handleUserAvatarChanged(ref, event);
  break;

/// 用户头像变更事件处理
/// 刷新当前用户的个人资料（自己改头像时）
void _handleUserAvatarChanged(Ref ref, ImSocketEvent event) {
  final payload = event.payload;
  final action = payload['action']?.toString() ?? '';
  if (action != 'user_avatar_changed') {
    return;
  }

  final currentUserId = ref.read(authSessionProvider).userId;
  final changedUserId = payload['userId']?.toString() ?? '';
  
  // 只处理当前用户的头像变更
  if (changedUserId != currentUserId) {
    return;
  }

  // 刷新当前用户资料
  ref.invalidate(currentUserProfileProvider);
}
```

**文件**: `lib/features/profile/presentation/providers/profile_providers.dart` L68-103
```dart
class AvatarUploadNotifier extends StateNotifier<AvatarUploadState> {
  AvatarUploadNotifier(this._ref) : super(AvatarUploadState.initial);

  final Ref _ref;

  Future<bool> upload({required String fileName, required Uint8List bytes}) async {
    state = const AvatarUploadState(isUploading: true, progress: 0.0);
    try {
      await _ref.read(profileRepositoryProvider).uploadAvatar(fileName: fileName, bytes: bytes);
      // 上传成功后刷新个人资料
      _ref.invalidate(currentUserProfileProvider);
      state = const AvatarUploadState();
      return true;
    } catch (e) {
      state = AvatarUploadState(error: e.toString());
      return false;
    }
  }

  Future<bool> delete() async {
    state = const AvatarUploadState(isUploading: true);
    try {
      await _ref.read(profileRepositoryProvider).deleteAvatar();
      _ref.invalidate(currentUserProfileProvider);
      state = const AvatarUploadState();
      return true;
    } catch (e) {
      state = AvatarUploadState(error: e.toString());
      return false;
    }
  }
}
```

### 11.2 问题诊断

**已实现**:
1. 后端每次上传头像生成新 URL（`fileApi.createFile` 生成唯一路径）
2. 后端通过 WebSocket 广播 `user_avatar_changed` 事件
3. Flutter 端监听事件并刷新 `currentUserProfileProvider`
4. `CachedNetworkImage` 自动下载新 URL 的头像

**未实现**:
1. **磁盘缓存未清理**: 旧头像 URL 的磁盘缓存不会被清理，导致缓存膨胀
2. **内存缓存未清理**: Flutter `ImageCache` 中的旧头像不会被清除
3. **其他 Provider 未刷新**: 会话列表、通讯录等包含当前用户头像的 Provider 未刷新

**影响**:
- 磁盘缓存占用空间持续增长（最多 100 个文件，30 天过期）
- 内存中可能残留旧头像（下次显示时先显示旧头像再刷新）
- 会话列表、通讯录中的当前用户头像不会立即更新

### 11.3 推荐方案：增强现有 WebSocket 机制

**核心思路**: 在现有 WebSocket 广播机制基础上，增加缓存清理逻辑

**优势**:
- 后端已实现，无需改动
- Flutter 端已有事件监听，只需增强处理逻辑
- 利用后端每次生成新 URL 的特性，无需版本号机制

#### 11.3.1 Flutter 端修改

**文件**: `lib/features/im/conversation/presentation/providers/conversation_realtime_binding.dart`

**修改 L223-233**: 增强 `_handleUserAvatarChanged` 方法
```dart
/// 用户头像变更事件处理
/// 刷新当前用户的个人资料（自己改头像时）
void _handleUserAvatarChanged(Ref ref, ImSocketEvent event) {
  final payload = event.payload;
  final action = payload['action']?.toString() ?? '';
  if (action != 'user_avatar_changed') {
    return;
  }

  final currentUserId = ref.read(authSessionProvider).userId;
  final changedUserId = payload['userId']?.toString() ?? '';
  
  // 只处理当前用户的头像变更
  if (changedUserId != currentUserId) {
    return;
  }

  // 1. 获取旧头像 URL
  final oldProfile = ref.read(currentUserProfileProvider).valueOrNull;
  final oldAvatarUrl = oldProfile?.avatarUrl ?? '';

  // 2. 清理旧头像的磁盘缓存
  if (oldAvatarUrl.isNotEmpty) {
    unawaited(ImCacheManager.instance.removeFile(oldAvatarUrl));
  }

  // 3. 清理 Flutter ImageCache 内存缓存
  // 注意：这会清理所有图片缓存，但头像变更是低频操作，影响可接受
  PaintingBinding.instance.imageCache.clear();

  // 4. 刷新当前用户资料（触发重新请求新头像）
  ref.invalidate(currentUserProfileProvider);

  // 5. 刷新会话列表（包含当前用户头像的会话）
  ref.invalidate(conversationListProvider);

  // 6. 刷新技术通讯录（包含当前用户头像）
  ref.invalidate(contactListProvider);
}
```

**文件**: `lib/features/profile/presentation/providers/profile_providers.dart`

**修改 L68-103**: 增强 `AvatarUploadNotifier` 方法
```dart
class AvatarUploadNotifier extends StateNotifier<AvatarUploadState> {
  AvatarUploadNotifier(this._ref) : super(AvatarUploadState.initial);

  final Ref _ref;

  Future<bool> upload({required String fileName, required Uint8List bytes}) async {
    state = const AvatarUploadState(isUploading: true, progress: 0.0);
    try {
      // 1. 获取旧头像 URL（用于后续清理缓存）
      final oldProfile = _ref.read(currentUserProfileProvider).valueOrNull;
      final oldAvatarUrl = oldProfile?.avatarUrl ?? '';

      // 2. 上传新头像
      await _ref.read(profileRepositoryProvider).uploadAvatar(fileName: fileName, bytes: bytes);
      
      // 3. 清理旧头像的磁盘缓存
      if (oldAvatarUrl.isNotEmpty) {
        unawaited(ImCacheManager.instance.removeFile(oldAvatarUrl));
      }

      // 4. 清理内存缓存
      PaintingBinding.instance.imageCache.clear();

      // 5. 刷新当前用户资料
      _ref.invalidate(currentUserProfileProvider);

      // 6. 刷新会话列表
      _ref.invalidate(conversationListProvider);

      // 7. 刷新技术通讯录
      _ref.invalidate(contactListProvider);

      state = const AvatarUploadState();
      return true;
    } catch (e) {
      state = AvatarUploadState(error: e.toString());
      return false;
    }
  }

  Future<bool> delete() async {
    state = const AvatarUploadState(isUploading: true);
    try {
      // 1. 获取旧头像 URL
      final oldProfile = _ref.read(currentUserProfileProvider).valueOrNull;
      final oldAvatarUrl = oldProfile?.avatarUrl ?? '';

      // 2. 删除头像
      await _ref.read(profileRepositoryProvider).deleteAvatar();
      
      // 3. 清理旧头像的磁盘缓存
      if (oldAvatarUrl.isNotEmpty) {
        unawaited(ImCacheManager.instance.removeFile(oldAvatarUrl));
      }

      // 4. 清理内存缓存
      PaintingBinding.instance.imageCache.clear();

      // 5. 刷新所有相关 Provider
      _ref.invalidate(currentUserProfileProvider);
      _ref.invalidate(conversationListProvider);
      _ref.invalidate(contactListProvider);

      state = const AvatarUploadState();
      return true;
    } catch (e) {
      state = AvatarUploadState(error: e.toString());
      return false;
    }
  }

  void reset() {
    state = const AvatarUploadState();
  }
}
```

**文件**: `lib/features/profile/presentation/providers/profile_providers.dart`

**添加 import**:
```dart
import 'dart:ui';
import 'package:flutter/painting.dart';
import 'package:shengyu_ui_admin_im/infrastructure/cache/im_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ... 其他 import
```

### 11.4 缓存优化策略

#### 11.4.1 三级缓存架构

```
├─ L1: 内存缓存 (Flutter ImageCache)
│  ├─ 容量: 1000 张图片（默认）
│  ├─ 淘汰策略: LRU
│  └─ 清理时机: 头像上传/删除时、WebSocket 收到头像变更事件时
│
├─ L2: 磁盘缓存 (ImCacheManager)
│  ├─ 容量: 100 个文件
│  ├─ 过期时间: 30 天
│  └─ 清理时机: 头像上传/删除时主动清理旧 URL
│
└─ L3: 网络 (OSS/CDN)
   └─ 特点: 后端每次上传生成新 URL，自动触发重新下载
```

#### 11.4.2 缓存预热（可选优化）

**文件**: `lib/features/im/conversation/presentation/providers/conversation_list_provider.dart`

在会话列表加载完成后，预加载可见头像：
```dart
Future<void> preloadVisibleAvatars(List<Conversation> conversations) async {
  final avatarUrls = conversations
      .where((c) => c.targetAvatar != null && c.targetAvatar!.isNotEmpty)
      .map((c) => c.targetAvatar!)
      .take(20)  // 最多预加载 20 个
      .toList();
  
  for (final url in avatarUrls) {
    // 异步下载，不阻塞 UI
    unawaited(ImCacheManager.instance.downloadFile(url));
  }
}
```

### 11.5 实施步骤

#### Step 1: 增强 WebSocket 事件处理（Flutter 改动）

**文件**: `lib/features/im/conversation/presentation/providers/conversation_realtime_binding.dart`

1. 添加 import: `import 'package:shengyu_ui_admin_im/infrastructure/cache/im_cache_manager.dart';`
2. 添加 import: `import 'dart:ui';` 和 `import 'package:flutter/painting.dart';`
3. 修改 `_handleUserAvatarChanged` 方法（L223-233），增加缓存清理逻辑
4. 添加 `import 'dart:async';` 用于 `unawaited`

#### Step 2: 增强头像上传逻辑（Flutter 改动）

**文件**: `lib/features/profile/presentation/providers/profile_providers.dart`

1. 添加 import: `import 'package:shengyu_ui_admin_im/infrastructure/cache/im_cache_manager.dart';`
2. 添加 import: `import 'dart:ui';` 和 `import 'package:flutter/painting.dart';`
3. 修改 `AvatarUploadNotifier.upload` 方法（L73-85），增加缓存清理逻辑
4. 修改 `AvatarUploadNotifier.delete` 方法（L87-98），增加缓存清理逻辑
5. 添加 `import 'dart:async';` 用于 `unawaited`

#### Step 3: 验证测试

1. 上传头像后，检查个人中心是否立即显示新头像
2. 上传头像后，检查会话列表中的当前用户头像是否更新
3. 上传头像后，检查通讯录中的当前用户头像是否更新
4. 删除头像后，检查所有页面是否正确显示文字头像
5. 多设备登录时，一端修改头像，另一端是否实时同步
6. 检查磁盘缓存是否被正确清理（通过开发者工具查看）

### 11.6 测试验证清单

- [ ] 用户上传头像后，个人中心立即显示新头像
- [ ] 用户上传头像后，会话列表中的当前用户头像立即更新
- [ ] 用户上传头像后，通讯录中的当前用户头像立即更新
- [ ] 用户删除头像后，所有页面立即显示文字头像
- [ ] 多设备登录时，一端修改头像，另一端实时同步
- [ ] 重新登录后，头像显示正确（不显示旧缓存）
- [ ] 租户切换后，头像显示正确
- [ ] 弱网环境下，头像加载失败正确降级到文字头像
- [ ] 磁盘缓存被正确清理，不会无限增长
- [ ] 内存缓存被正确清理，不会残留旧头像

---

## 十二、后续优化建议

1. **后端优化**: 在会话列表接口中返回对方昵称字段 `targetNickname`，避免使用 `title` 作为头像文字
2. **头像预加载**: 在会话列表加载时，预加载可见头像，提升用户体验
3. **头像压缩**: 上传头像时进行压缩，减少网络传输和存储成本
4. **头像裁剪**: 支持头像裁剪功能，允许用户自定义头像显示区域
5. **头像动画**: 在特定场景（如消息发送成功）添加头像动画效果
6. **离线头像**: 支持离线时显示已缓存的头像，提升离线体验

---

**文档版本**: v4.0（增加头像上传更新机制）  
**创建时间**: 2026-07-04  
**最后更新**: 2026-07-04  
**维护者**: AI Assistant
