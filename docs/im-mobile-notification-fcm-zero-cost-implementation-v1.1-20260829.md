# IM 多端消息通知与 FCM 零成本实施任务书 v1.1

> 日期：2026-08-29  
> 状态：经源码复核后待实施  
> 适用范围：同一 Flutter 工程的 Android → iOS → Web；以 Android 为 P0、iOS 为 P1、Web 为 P2，三端共用协议与后端设备注册模型。  
> 实施原则：先实现无需外部推送 SDK 的“后台未杀进程”通知；再接入免费 FCM。**不接入极光、个推、腾讯云推送或小米/OPPO/vivo/华为厂商通道，不引入其付费聚合服务。**

---

## 1. 结论与交付边界

### 1.1 必须区分的状态、平台与承诺

| 状态 | Android | iOS | Web | 送达承诺 |
|---|---|---|
| 前台 | WebSocket / FCM `onMessage` + 本地通知或应用内横幅 | 同左 | WebSocket / FCM foreground 回调 + 应用内横幅 | 可控；当前会话不重复提示 |
| 后台、进程或浏览器页仍存活 | WebSocket + `flutter_local_notifications` | WebSocket + 本地通知（系统允许时） | WebSocket；页面后台后不承诺持续连接 | 最佳努力，不能代替离线推送 |
| App/浏览器已终止、锁屏、Doze 或 socket 已断 | FCM；仅 GMS 设备可作为正式免费通道 | FCM 经 APNs；需 Apple Developer 的签名与 APNs 凭据 | FCM Web Push；需 HTTPS、Service Worker、VAPID 与浏览器授权 | 以平台系统实际投递为准；通知点击后一律服务端同步 |

微信式“被系统/厂商清理后仍必达”依赖 OEM 通道或商业聚合服务，不属于本轮。FCM 是免费正式通道，但不能替代小米、OPPO、vivo、华为等 ROM 的厂商通道覆盖。

### 1.2 本轮必须交付

1. 普通 IM 消息的通知栏提醒、点击直达会话、未读数聚合、前台免打扰，以及不同业务类型的统一展示契约。
2. 应用在后台但未杀进程时，不依赖 FCM 也能由 WebSocket 展示本地通知。
3. Android、iOS、Web FCM token 注册、刷新、注销和服务端按**设备/浏览器实例**投递；按 P0→P2 分期启用。
4. FCM 收到消息后只做最小通知/同步，不把聊天正文、access token、refresh token、LiveKit token 放进 payload。
5. 现有 `CallPushService` 离线来电从 `NOT_CONFIGURED` 变为 FCM 可投递；客户端收到后先查询通话状态，再调用既有 `NativeCallUiGateway`。iOS 语音/视频呼叫在 P1 只做普通通知与状态校验，**不把 FCM 当作 CallKit/PushKit 来电唤醒的替代品**。
6. 可观测性：每次注册、发送、失败、点击和补偿同步都具备 `tenantId`、`userId`、`deviceId`、`provider`、`eventId`/`callId` 日志字段；严禁记录 token 正文。

### 1.3 明确不做

- 不以 WebSocket、WakeLock、忽略电池优化或无限前台服务伪造“离线必达”。
- 不为了通知常驻一个 `dataSync` 前台服务。当前 Android 15 对该类型已有时长和后台启动限制，且用户会看到常驻通知。
- 不接入任何厂商 Push SDK、聚合 Push SDK、付费 SaaS 推送服务。
- 不把普通消息正文或通话媒体凭证写入 Firebase、Redis 日志、通知 click intent 或 FCM payload。
- 不改变现有 LiveKit 媒体和业务状态机；FCM 只负责唤醒、提示和驱动状态校验。

---

## 2. 当前工程事实与问题定位

### 2.1 Flutter 当前能力（源码复核）

| 位置 | 当前状态 | 本轮处理 |
|---|---|---|
| `pubspec.yaml` | 已有 `flutter_local_notifications`、`flutter_callkit_incoming`；无 Firebase 依赖 | 新增 Firebase 依赖；复用本地通知依赖 |
| `android/app/src/main/AndroidManifest.xml` | 已声明 `POST_NOTIFICATIONS`、前台服务和全屏来电权限；未声明真实前台 Service | 保留权限；由 Firebase Android 插件合并 FCM 配置；不新增常驻 Service。文件注释“前台服务保活 WebSocket”与当前实际能力不符，不据此设计可靠性 |
| `ios/Runner/Info.plist`、`ios/Runner/AppDelegate.swift` | 已有 `remote-notification`、`voip` 背景模式及屏幕常亮通道；没有 `GoogleService-Info.plist`、Push Notifications capability、APS entitlement、Firebase 初始化 | P1 新增 Firebase/APS 配置；保留现有 CallKit 相关背景声明，不承诺以普通 FCM 完成 VoIP 来电 |
| `web/index.html` | 已有 Flutter bootstrap 与 PWA manifest 引用；没有 Firebase Web 配置、`firebase-messaging-sw.js` 或通知权限交互 | P2 通过 HTTPS + Service Worker + VAPID 接 FCM；不能从 `file://`、HTTP 或无浏览器授权环境验收 |
| `lib/main.dart` | 初始化生命周期、网络监控和 Riverpod | 初始化 Firebase、注册后台 FCM handler 和全局通知绑定 |
| `lib/core/lifecycle/app_lifecycle_manager.dart` | 后台只把 socket 标记 stale，回前台重连 | 作为“后台未杀进程”判断来源；不得将其视为离线可靠方案 |
| `lib/core/websocket/socket_event_types.dart` | 已有 `messageReceived`、`systemNotify`、`conversationHint` | 新增全局通知绑定订阅这些事件 |
| `lib/features/im/chat/presentation/providers/chat_realtime_binding.dart` | 当前聊天页的消息实时处理，且注释已说明后台断开会丢失 `messageReceived` | 不在此页面级 binding 发通知，避免页面导航导致遗漏/重复；复用 `activeConversationServiceProvider` 判断当前会话 |
| `lib/features/im/call/infrastructure/native_call_ui_gateway.dart` | 已能展示 Android 全屏来电和未接来电通知 | FCM 通话 data payload 校验成功后调用它 |

### 2.2 后端当前能力（源码复核）

| 位置 | 当前状态 | 缺口 |
|---|---|---|
| `shengyu-framework/.../OfflinePushService.java` | `pushOfflineMessage()`、`pushSystemNotify()` 仅返回 `boolean`，`bindPushToken()` 仅有 userId/deviceType/token | 当前 key 只按 `userId + deviceType`，会覆盖同类型多设备；接口缺 `tenantId/deviceId/provider/结果明细`，不能由 FCM 实现直接满足企业级多端投递 |
| `OfflinePushServiceImpl.java` | 普通消息仅记录日志并模拟成功；通话明确返回 `NOT_CONFIGURED` | 没有实际 FCM HTTP v1 投递 |
| `CallPushService.java` | 在线先走 WebSocket；离线来电会调用 `OfflinePushService.pushCallInvite()`；目前 `pushData()` 会复制 `callerName/callerAvatar/callSessionId` | 必须先收紧为最小 `callId/eventVersion/tenantId` 契约，再接入 FCM；不应把 `callSessionId`、展示资料或媒体凭证放进离线 data |
| `CallEventPublisher` 与 outbox | 已有通话事件版本与重试语义 | 仅 `RETRYABLE_FAILURE` 可重试，其他 FCM 明确失败必须收敛 |

---

## 3. 总体架构

```text
普通消息
服务端消息持久化/会话未读更新
  ├─ 在线 WebSocket -> Flutter GlobalImNotificationBinding
  │                    └─ ImLocalNotificationService.showMessage()
  └─ 离线或无有效 socket -> FcmOfflinePushService
                           └─ Android 系统通知 / Flutter background handler

通话邀请
CallEventPublisher -> CallPushService
  ├─ 在线 WebSocket -> LiveKitCallInvitationBinding
  └─ 离线 FCM 高优先级 data push
       -> FcmBackgroundHandler
       -> GET /system/im/call/active 或 /state
       -> NativeCallUiGateway.showIncoming()

通知点击
ImNotificationRouter -> AuthSession 已登录？
  ├─ 是：Conversation HTTP 同步并解析会话类型 -> goNamed(RouteNames.chat, extra: ChatEntryArgs.latest(...))
  └─ 否：保存 pending deep link -> 登录完成后消费一次
```

### 3.1 三端分期与不混淆的职责

| 阶段 | 目标端 | 本阶段真正交付 | 不能承诺/不得借用 |
|---|---|---|---|
| P0-A | Android | 已登录、未杀进程时 WebSocket 驱动本地通知；通知点击先同步会话，再 `goNamed(RouteNames.chat, extra: ChatEntryArgs.latest(...))` | 不以 `WAKE_LOCK`、电池优化白名单或常驻服务承诺离线必达 |
| P0-B/C/D | Android | FCM token、后端设备登记、FCM HTTP v1 普通消息与离线通话状态唤醒 | 非 GMS ROM 的可靠离线通知；强制停止后必须先手动打开过 App |
| P1 | iOS | 同一业务 event、APNs 经 FCM 的消息通知、角标、点击路由 | FCM data push 不能替代 PushKit/CallKit 的实时来电；本轮不接入付费或 VoIP 通话推送改造 |
| P2 | Web | HTTPS 下 FCM Web Push、Service Worker 通知、点击聚焦/打开指定 URL | 标签页 websocket 在浏览器后台持续在线；非 HTTPS、隐私模式、未授权浏览器的离线提醒 |

**共享原则：**WebSocket 只用于在线实时事件；本地通知只负责已存活进程的呈现；FCM/APNs/Web Push 只提供离线提示与唤醒机会；消息、未读、通话状态都以 HTTP/现有同步接口为权威来源。

### 3.2 事件去重和权威来源

- `eventId` 是通知幂等键；普通消息使用 `messageId`，通话使用 `callId + eventVersion`。
- 通知不是业务事实来源。收到后或点击后都必须调用已有会话/消息同步、`GET /system/im/call/active` 或 `GET /system/im/call/state` 通话状态接口校验。
- 同一消息可能同时通过 WebSocket、FCM 和恢复同步到达；只允许第一次创建通知，其余更新同一 notification id 或忽略。
- 当前正打开该 `chatId` 且 `AppLifecycleManager.isResumed == true` 时，不显示普通消息通知；仍正常更新会话与角标。

### 3.3 Payload 规范（服务端到设备，非显示数据）

所有 payload 均为字符串键值对，FCM data 总大小严格控制在 4KB 以下。

```json
{
  "v": "1",
  "kind": "im_message",
  "eventId": "messageId",
  "recipientUserId": "当前登录用户 ID",
  "tenantId": "123",
  "chatId": "456",
  "messageId": "789",
  "sentAt": "1760000000000"
}
```

通话 payload：

```json
{
  "v": "1",
  "kind": "call_invite",
  "eventId": "callId:version",
  "tenantId": "123",
  "callId": "uuid",
  "eventVersion": "7",
  "sentAt": "1760000000000"
}
```

禁止字段：`accessToken`、`refreshToken`、`LiveKit token`、`serverUrl`、`callSessionId`、消息正文、手机号、群成员清单、未脱敏头像 URL。`recipientUserId` 只用于本地账号作用域校验，服务端仍必须从认证上下文确定真实接收人。

### 3.4 通知栏 UI 设计规范（所有端共享语义，平台各自渲染）

服务端 payload 不携带业务显示正文。客户端在已获得本地会话/消息摘要且用户启用预览时渲染；否则固定使用隐私文案。Android 由 `flutter_local_notifications` 的 channel/group/summary 渲染，iOS 使用 APNs alert + badge（富图片不属于本轮），Web 使用 Service Worker `showNotification()`。任何显示字段均不能成为路由或权限依据。

| 业务事件 | 标题（允许预览） | 正文（允许预览） | 隐私/锁屏关闭预览 | 聚合与动作 | 优先级 |
|---|---|---|---|---|---|
| 单聊文字/图片/文件/语音 | 对方昵称 | 文本摘要；非文本显示“[图片] / [文件] / [语音]” | “圣钰 IM：你收到一条新消息” | 按 `chatId` 聚合；点击打开聊天；Android 可设“标为已读”仅在有安全 API 后启用 | 默认 |
| 群聊普通消息 | 群名称 | “发送者：摘要” | “圣钰 IM：群聊有新消息” | 同一群 30 秒聚合；不要逐条展开刷屏 | 默认 |
| @我 / @所有人 | 群名称 | “发送者 @你：摘要” | “圣钰 IM：你有一条重要群消息” | 独立 `im_mentions` channel/category；不能被普通群聚合覆盖 | 高 |
| 系统业务通知 | 业务名称 | 服务端白名单的短标题，不含敏感字段 | “圣钰 IM：你有一条系统通知” | 独立 notification id；点击到已验证业务详情 | 默认 |
| 离线来电 | `caller` 或“来电提醒” | “语音通话/视频通话邀请” | “圣钰 IM：来电提醒” | Android 仅由 `NativeCallUiGateway` 维护来电 UI；普通消息不得覆盖。iOS P1 显示普通通知，不能伪造 CallKit；Web P2 显示普通通知 | 最高但受系统限制 |
| 未读汇总 | “圣钰 IM” | “你有 N 条未读消息” | 同左 | 仅在多个 chat 并发时作为 Android group summary / iOS/Web 兜底；点击会话列表 | 低于 @我/来电 |

UI 不变量：标题/正文最多一行摘要；同一 `eventId` 只提示一次；应用前台并正在查看同一 `chatId` 时不弹系统通知；账号退出、被踢或切租户时取消该账号的所有 notification id、group summary、pending click。

---

## 4. Flutter 精确实施清单

### 4.1 依赖与原生配置

修改 `shengyu-ui/shengyu-ui-admin-flutter/pubspec.yaml`：

```yaml
dependencies:
  firebase_core: <由 flutter pub add 锁定的兼容版本>
  firebase_messaging: <由 flutter pub add 锁定的兼容版本>
```

执行（由实施分支实际生成并评审差异，不手写旧版 Gradle/Pod 版本号）：

```bash
cd shengyu-ui/shengyu-ui-admin-flutter
/Users/zsy/app/flutter/bin/flutter pub add firebase_core firebase_messaging
dart pub global activate flutterfire_cli
flutterfire configure
```

平台配置清单：

- Android：`google-services.json` 只放 `android/app/`；在 `android/settings.gradle.kts` 声明 Google Services plugin，在 `android/app/build.gradle.kts` 应用该 plugin。当前工程使用 Kotlin DSL、AGP 8.11.1，必须让 FlutterFire 生成结果与该结构兼容。
- iOS：新增 `ios/Runner/GoogleService-Info.plist`（非私钥）、Xcode 的 Push Notifications capability 和 `ios/Runner/Runner.entitlements` 的 `aps-environment`；上传 APNs Auth Key 至 Firebase 控制台。现有 `Info.plist` 的 `remote-notification` 仅允许后台通知回调，**不是**APNs 授权配置。
- Web：在 `web/` 新增 `firebase-messaging-sw.js`，并在 `web/index.html` 注册它；部署域名必须 HTTPS，Firebase 项目需生成 Web Push VAPID public key。公开 Firebase Web config/VAPID public key 可以随前端发布，service account 私钥、APNs `.p8` 私钥不得进入仓库。
- 三端：`firebase_options.dart` 由 FlutterFire 生成并纳入 Flutter 源码；不得将 service-account 私钥放进 Flutter 工程。
- 现有 `POST_NOTIFICATIONS` 权限保留；在首个有明确价值的时机（登录成功或首次进入会话页）请求，不得在 Splash 启动时弹窗。
- iOS/Web 同样不得在启动 splash 自动索取通知授权；先显示通知价值说明，再由用户操作触发请求。iOS 可评估 provisional authorization，但必须作为单独产品决策。

### 4.2 新增文件

| 文件 | 职责 |
|---|---|
| `lib/features/im/notification/domain/im_notification_event.dart` | `ImMessageNotificationEvent`、`ImCallNotificationEvent` 不可变模型和 payload 解析 |
| `lib/features/im/notification/infrastructure/im_local_notification_service.dart` | 初始化 channel、权限、普通消息展示、聚合、取消、点击 stream |
| `lib/features/im/notification/infrastructure/fcm_notification_gateway.dart` | `FirebaseMessaging` token、前台消息、token refresh、后台 handler 注册 |
| `lib/features/im/notification/application/push_device_registration_service.dart` | 在登录、token 刷新、登出时向服务端注册/注销设备 token |
| `lib/features/im/notification/presentation/providers/global_im_notification_binding.dart` | 唯一全局 WebSocket 订阅与本地通知决策 |
| `lib/features/im/notification/presentation/providers/im_notification_providers.dart` | Riverpod provider 装配 |
| `lib/features/im/notification/application/im_notification_router.dart` | 点击通知后的登录后 pending route、会话同步和导航 |
| `lib/features/im/notification/application/im_notification_presentation_policy.dart` | 根据事件、用户预览设置、平台、当前会话与聚合状态生成标题/正文/channel，不让 WebSocket 与 FCM 各写一套 UI 规则 |
| `lib/features/im/notification/infrastructure/im_notification_event_store.dart` | 使用现有 secure/local storage key 保存去重窗口、pending click 与账号作用域；后台 isolate 不读取 Riverpod UI 状态 |

新增原生/静态文件：

| 文件 | P 阶段 | 变更 |
|---|---|---|
| `android/settings.gradle.kts`、`android/app/build.gradle.kts` | P0 | Google Services plugin（由 FlutterFire 输出指导），保持 Kotlin DSL |
| `android/app/google-services.json` | P0 | Firebase Android 客户端配置，不提交私钥 |
| `ios/Runner/GoogleService-Info.plist` | P1 | Firebase iOS 客户端配置 |
| `ios/Runner/Runner.entitlements` | P1 | 新建 `aps-environment`；Xcode target 同时启用 Push Notifications |
| `ios/Runner/Info.plist`、`ios/Runner/AppDelegate.swift` | P1 | 必要的 Firebase/APNs 初始化；保留 Flutter implicit engine 注册与屏幕常亮通道 |
| `web/firebase-messaging-sw.js`、`web/index.html` | P2 | worker 初始化/通知点击与注册；不破坏当前 Flutter bootstrap 的 FontManifest 拦截逻辑 |

### 4.3 修改文件与方法级要求

#### `lib/main.dart`

在 `WidgetsFlutterBinding.ensureInitialized()` 后、`runApp()` 前：

1. `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`；仅在已完成 P0/P1/P2 对应配置的平台启用，避免未配置 Web/iOS 阻塞 Android 开发。
2. 注册顶级函数 `@pragma('vm:entry-point') Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message)`。
3. handler 只解析 payload、持久化 pending event 或展示最小通知；不初始化 Riverpod 页面状态，不连接 LiveKit，不执行长耗时 HTTP。Android background isolate 与 iOS/Web 的运行模型不同，统一通过 `ImNotificationEventStore` 交接。
4. `AppLifecycleManager`、`NetworkMonitorService` 的初始化顺序保持不变。

#### `lib/app/bootstrap/app_bootstrap.dart`

在根 `AppBootstrap.build()` 内 `ref.watch(globalBadgeSocketBindingProvider)` 附近新增：

```dart
ref.watch(globalImNotificationBindingProvider);
```

此 binding 不使用 `autoDispose`，原因同 `global_badge_socket_binding.dart`：页面路由切换不得中断通知。但它必须监听 `authSessionProvider`：匿名状态不订阅、不通知；userId/tenantId 变化时取消旧 scope、重建订阅，避免现有 `AppBootstrap` 在登录页也持续构建造成串号。

#### `lib/features/login/presentation/controllers/login_controller.dart`

在 `saveSession()` 与 `warmStart()` 成功后：

```dart
await ref.read(pushDeviceRegistrationServiceProvider).registerCurrentDevice();
```

失败仅记录脱敏日志，不应阻断登录。token 注册失败后由 `authSucceeded`、`onTokenRefresh` 或下次启动再次补偿。`AuthSessionController.restore()` 恢复旧登录态成功后也要触发一次登记，不能只覆盖密码登录。

#### `lib/core/auth/session_cleanup_service.dart`

`SessionCleanupService` 已在 `authSessionProvider` userId 变更时清理 scope；不要把 `Ref` 反向塞入 `AuthSessionController`。应在新增的全局通知 binding 监听到旧 session 后，先异步调用：

```dart
unawaited(ref.read(pushDeviceRegistrationServiceProvider).unregisterCurrentDevice());
```

登出接口失败不能阻止本地登出；服务端 token 仍有 TTL 和后续投递失效清理。显式登出、被踢、租户切换和覆盖式重新登录都必须取消本地通知与 pending click；`kicked_dialog.dart` 的直接 `clearSession()` 路径必须被该监听覆盖。

#### `global_im_notification_binding.dart`

订阅 `socketMessageDispatcherProvider.stream`，只处理：

- `SocketEventTypes.messageReceived`：转换为普通消息事件；通过当前活跃 chat 与 lifecycle 判断是否通知。
- `SocketEventTypes.systemNotify`：只识别允许白名单中的业务通知；不要把所有系统通知都弹出。
- `SocketEventTypes.sessionKicked`、`sessionLoggedOut`：取消所有本地通知并清理 pending event。

普通消息需同时读取 `activeConversationServiceProvider`、`AppLifecycleManager` 与本地去重 store；先由会话/消息控制器完成已知消息落库或取得安全摘要，再交 `ImNotificationPresentationPolicy`。不能在 `chat_realtime_binding.dart` 追加通知逻辑，否则同一事件可能被多聊天页面重复通知。

### 4.4 本地通知策略

`ImLocalNotificationService` 至少提供：

```dart
Future<void> initialize();
Future<bool> requestPermissionIfNeeded();
Future<void> showMessage(ImMessageNotificationEvent event);
Future<void> showCallFallback(ImCallNotificationEvent event);
Future<void> cancelForChat(String chatId);
Future<void> cancelAllForUserScope();
Stream<ImNotificationClick> get clicks;
```

Android channels：

| Channel | importance | 声音 | 用途 |
|---|---|---|---|
| `im_messages` | high | 默认短提示 | 普通消息，聚合后显示“你有 N 条新消息” |
| `im_mentions` | high | 默认短提示 | @我、强提醒，P0 可先共用 messages |
| `im_calls` | max | 由 `NativeCallUiGateway` 负责 | 不重复创建普通通知 |

通知标题和正文：

- 仅在本地已同步到可展示消息且用户允许消息预览时展示联系人/群名和摘要。
- 否则显示“圣钰科技 IM：你收到一条新消息”。
- 通知点击使用 `chatId`，先从本地/HTTP 会话记录取得 `conversationType/targetId/title`，再以 `ChatEntryArgs.latest(...)` 调用 `RouteNames.chat`；不能只导航 `RoutePaths.chat`（该路由会得到空 `ChatEntryArgs`），也不直接信任 payload 的显示文案。

### 4.5 FCM 前台、后台、点击流程

| FCM 回调 | 处理 |
|---|---|
| `FirebaseMessaging.onMessage` | 前台：转换为同一 `ImNotificationEvent`，复用本地通知/免打扰判定 |
| `FirebaseMessaging.onMessageOpenedApp` | 已登录立即交给 `ImNotificationRouter` |
| `FirebaseMessaging.instance.getInitialMessage()` | 冷启动时保存为 pending event，等待 auth bootstrap 完成后消费一次 |
| `FirebaseMessaging.onTokenRefresh` | 调用注册服务覆盖同一 `deviceId + provider=fcm` token |
| background handler | 最多做轻量本地持久化与本地通知；通话只保存 callId，前台/合规的回调路径再查状态 |

### 4.6 iOS 与 Web 的实施差异（不得按 Android 复制）

#### iOS（P1）

1. `flutter_local_notifications` 继续作为前台展示和已存活后台时的本地策略；APNs/FCM 的终止态显示使用最小 `notification` payload，由系统展示。
2. `FirebaseMessaging.onMessage` 前台通知默认不可见，必须在 `ImLocalNotificationService` 统一展示，或显式配置前台 presentation；二者只能选择一个，避免双通知。
3. 未读 badge 只使用本地权威未读状态；进入前台后由现有 `badgeService` HTTP/Socket 同步覆盖，不能相信 FCM payload 的计数。
4. 普通 data-only 静默推送不作为消息必达路径；iOS 可延迟、合并或不唤醒后台。普通离线消息用固定文案 notification + 最小 data，点击后同步。
5. 现有 `Info.plist` 的 `voip` 声明不代表可用普通 FCM 做来电。未来需要 iOS 锁屏实时来电须另立 PushKit + CallKit 合规设计；本任务不做。

#### Web（P2）

1. Web token 只在 HTTPS、浏览器支持 Push API 且用户授权后获取；`web/index.html` 必须在保留当前 FontManifest 拦截脚本的同时注册 worker。
2. `firebase-messaging-sw.js` 负责后台通知与 `notificationclick`：关闭通知、优先聚焦同源窗口，否则以固定同源 URL 打开 App。它不能调用 Dart/Riverpod；启动后由 `ImNotificationRouter` 二次校验 `eventId/chatId`。
3. Web 不存在 Android notification channel/full-screen intent 或 iOS badge API；只定义 `title/body/icon/tag` 等最小字段，实际外观交给浏览器和 OS。
4. 每个浏览器实例用独立 `installationId`/token 作为 `deviceId`；清除站点数据、换浏览器或撤销权限均视为新实例。

---

## 5. 后端精确实施清单

### 5.1 先修正框架接口，再实现设备 token 注册

`OfflinePushService` 位于 `shengyu-framework`，但普通消息接口没有 tenant、device、provider 和投递结果。不能把 FCM 多端循环、无效 token 删除或 Web/iOS 平台差异强行塞进其 `boolean pushOfflineMessage()`。

保留它作为向后兼容 facade，同时在 `shengyu-module-system-biz` 新增：

| 文件 | 职责 |
|---|---|
| `service/im/push/ImPushDispatcher.java` | 接收 tenant/user/业务事件，按注册设备投递并返回逐设备 `ImPushDispatchResult` |
| `service/im/push/ImPushDeviceRegistry.java` | 多端 token/浏览器实例登记、查询、失效回收 |
| `service/im/push/FcmV1Client.java` | FCM HTTP v1 单设备请求与错误归类；不承载业务文案 |
| `service/im/push/ImPushPayloadFactory.java` | 将 message/call/system 事件转成最小跨端 data 与每平台 notification 配置 |

`FcmOfflinePushService` 是兼容 Bean：老接口转换为 dispatcher 请求；`CallPushService` 改为调用 dispatcher 的专用 call 方法，获得明确可重试结果。这样既不破坏其它模块现有注入，也避免 call/普通消息绕过多端登记。

### 5.2 设备 token 注册模型

新增到 `shengyu-module-system-biz`：

| 文件 | 职责 |
|---|---|
| `controller/app/im/AppImPushDeviceController.java` | 注册、注销 token 的 App API |
| `controller/app/im/vo/push/AppImPushTokenRegisterReqVO.java` | `provider`、`token`、`deviceId`、`platform` 请求校验 |
| `service/im/push/ImPushDeviceRegistry.java` | 设备维度 token 存取与失效清理 |
| `service/im/push/RedisImPushDeviceRegistry.java` | Redis index/value 实现 |
| `service/im/push/FcmOfflinePushService.java` | `OfflinePushService` 兼容适配器 |
| `service/im/push/FcmAccessTokenProvider.java` | 用服务账号 OAuth2 获取并缓存 HTTP v1 bearer token |
| `config/FcmPushProperties.java` | `enabled`、`projectId`、凭据路径/secret 引用、超时、dryRun 配置 |

API：

```text
POST   /app-api/system/im/push/device-token
DELETE /app-api/system/im/push/device-token
```

注册请求：

```json
{
  "provider": "fcm",
  "token": "FCM registration token",
  "deviceId": "来自 AuthSession.deviceId；Web 为 browser installationId",
  "platform": "android | ios | web",
  "appVersion": "1.0.0"
}
```

服务端从登录用户上下文取得 `tenantId`、`userId`，不得相信请求体中的用户或租户。

### 5.3 Redis 数据结构

不要继续使用当前 `im:push:token:{userId}:{deviceType}` 单值 key。改为：

```text
im:push:device:{tenantId}:{userId}:{deviceId}:fcm -> JSON token metadata, TTL 35d
im:push:devices:{tenantId}:{userId}                -> Set(deviceId:provider), TTL 35d
```

metadata 最少字段：`token`、`platform`、`appVersion`、`permissionState`、`updatedAt`、`lastDeliveryAt`。`deviceId` 只允许 `[A-Za-z0-9._:-]` 且限长；日志永远只输出 token 的 hash 前 8 位。

投递返回 `UNREGISTERED`、`INVALID_ARGUMENT` 时必须删除对应 device token 和 index；网络超时/5xx 返回 `RETRYABLE_FAILURE`；用户关闭通知、无 token、配置关闭返回不可重试结果。

### 5.4 FCM 服务端实现方式

1. `FcmOfflinePushService` 放在业务模块，作为 `OfflinePushService` 兼容 Bean，并委托 `ImPushDispatcher`；不能直接以框架单 token key 发 FCM。
2. 使用 FCM HTTP v1 API；可使用 Google OAuth credential 库仅获取 server-to-server access token，不在移动端嵌入 service account。
3. service account JSON/Workload Identity credential 只由部署 secret 挂载：

```yaml
shengyu:
  im:
    push:
      fcm:
        enabled: true
        project-id: ${IM_PUSH_FCM_PROJECT_ID:}
        credential-file: ${IM_PUSH_FCM_CREDENTIAL_FILE:}
        connect-timeout-ms: 3000
        read-timeout-ms: 5000
        dry-run: false
```

4. `enabled=false` 或配置缺失时保持当前 `NOT_CONFIGURED` 行为，禁止假装发送成功。
5. 普通消息使用每平台最小 notification + data：Android channel 为 `im_messages/im_mentions`；iOS APNs alert + badge；Web notification 由 worker 呈现。高隐私模式仅使用固定 notification 文案，**不得把 data-only 当成三端可靠离线展示方案**。
6. 通话邀请在 Android 使用高优先级最小事件并先查状态；FCM 不包含 caller 详情、`callSessionId` 或 LiveKit Token。iOS/Web 只发普通“来电提醒”通知，点击查状态。

### 5.5 普通 IM 消息接入点

在 `SystemMessageStorageServiceImpl` 和其他普通消息写入成功的事务提交后路径中：

1. 保持原有 WebSocket 发送和会话未读/角标更新。
2. 通过 `NettySessionManager.getSessionsByUserId(receiverId)` 判断是否有可认证在线会话；该信号只能用于 push 降噪，不等于客户端一定可见。
3. 初版仅“无可用 session”时发布普通离线事件；后续后台状态上报成熟后再扩展。不要因某一 Web session 在线而压制同用户其它离线手机/浏览器的配置化提醒。
4. 不能在数据库事务内进行网络调用；`SystemMessageStorageServiceImpl` 是 MessageStorage SPI，不应直接同步请求 FCM。新增独立 `ImNotificationEventPublisher`，在事务提交后/outbox 消费时调用 `ImPushDispatcher`，不得复用通话 outbox 的状态机。

初版可只对“用户完全离线”调用 FCM；后续再增加客户端后台状态上报，避免在线但后台不可达时遗漏。

### 5.6 通话接入点

`CallPushService` 已正确在 `onlineSessionCount == 0` 且 invite 时调用 `pushCallInvite()`。本轮仅完成：

- 将 `CallPushService.pushData()` 收紧为 `kind`、`eventId`、`tenantId`、`callId`、`eventVersion`、`sentAt`，删除现有 `callSessionId/callerName/callerAvatar` 复制；
- `ImPushDispatcher.dispatchCallInvite()` 实际投递 FCM；
- 保持 `CallEventDeliveryResult` 和 outbox 重试语义；
- FCM 回执错误映射准确；
- 不修改 `CallEventPublisher`、LiveKit Token、REST 状态机和现有 30 秒超时。

---

## 6. 安全、隐私与可靠性门禁

1. Android 13+、iOS、Web 通知权限被拒绝时，服务端仍可保存 token（便于权限恢复后刷新），但记录 `permissionState=denied`，不把它当可见投递成功；Web token 获取失败时不做无效重试风暴。
2. FCM token 是设备标识符，按敏感数据处理；数据库、Redis dump、日志、Sentry 均脱敏。
3. 每个 payload 加 `v`，未知版本丢弃并上报受控日志。
4. 客户端事件时间超过 24 小时仅用于同步，不弹旧消息通知；通话则按服务端 `/active` 结果决定。
5. 同一 chat 的普通通知 30 秒内聚合；@我与通话不得被普通消息折叠覆盖。
6. 点击通知前必须验证当前登录 userId 与 pending event 的 user scope 相符；账号切换/被踢后清除 pending event。
7. FCM 不是消息可靠存储。任何通知丢失都由应用启动、socket reauth、会话增量同步恢复；Web worker 与 iOS/Android 后台 handler 都不直接写业务真相。

---

## 7. 测试与验收

### 7.1 Flutter 自动化

新增：

```text
test/features/im/notification/im_notification_payload_test.dart
test/features/im/notification/im_local_notification_service_test.dart
test/features/im/notification/global_im_notification_binding_test.dart
test/features/im/notification/im_notification_router_test.dart
```

覆盖：payload 缺字段/过期/重复、当前 chat 免打扰、群聊/@我/系统/来电 UI policy、账号与租户切换清理、FCM/WebSocket 同事件去重、点击路由、iOS/Web 平台分支不执行 Android channel 逻辑。

### 7.2 后端自动化

新增：

```text
.../service/im/push/FcmV1ClientTest.java
.../service/im/push/RedisImPushDeviceRegistryTest.java
.../service/im/push/ImPushPayloadFactoryTest.java
.../controller/app/im/AppImPushDeviceControllerTest.java
```

覆盖：多 Android/iOS/Web 实例不覆盖、租户隔离、token 刷新、无效 token 删除、配置缺失、4xx 永久失败、5xx/超时可重试、Android/iOS/Web payload 差异、call payload 不含 caller 展示资料/媒体 token。

### 7.3 真机验收矩阵

| 编号 | 操作 | 预期 |
|---|---|---|
| N1 | App 前台且未打开目标 chat，另一端发消息 | 角标/会话更新；按用户设置展示一次本地通知 |
| N2 | App 前台且正在目标 chat | 无通知栏重复提醒，消息立即出现 |
| N3 | Home 到后台，不杀进程，另一端发消息 | WebSocket 或 FCM 任一路触发一条通知；点击进入正确 chat |
| N4 | 强制停止 App 后发普通消息 | GMS Android 设备收到 FCM 通知；点击后登录态恢复并同步会话 |
| N5 | 锁屏/Doze 后发消息 | 不把未收到判定为代码故障；记录设备、GMS、权限、电池策略与 FCM 回执 |
| N6 | 强制停止后呼叫 | FCM 到达后先查 `/active`，有效才显示既有全屏来电；挂断后不可再接听 |
| N7 | 拒绝通知权限 | App 不崩溃；会话同步正常；服务端/客户端日志能识别拒绝状态 |
| N8 | 同账号两台 Android 注册 token | 两台均保留 token；分别可接收推送；注销一台不影响另一台 |
| N9 | iPhone 真机：允许通知、后台/终止状态收普通消息 | APNs 经 FCM 显示一次固定或授权预览文案；点击后先验证账号再进入聊天；模拟器不得作为 APNs 验收依据 |
| N10 | iPhone 真机：离线来电 | 仅收到普通“来电提醒”并查状态；不得错误宣称锁屏 CallKit 必达 |
| N11 | Chrome/Edge HTTPS：授权 Web 通知、关闭标签页后发消息 | worker 显示一次通知；点击聚焦或打开同源 App 并进入正确会话 |
| N12 | Web HTTP/无授权/清站点数据 | 不报错、不伪称已登记；重新授权后生成新的浏览器实例 token |

---

## 8. 实施顺序与提交边界

1. **P0-A Android 本地通知过渡版**：notification domain/service/policy/global binding、权限、点击路由、测试。无需 Firebase 凭据即可真机验收后台未杀进程场景。
2. **P0-B Android FCM 客户端**：Firebase Android 配置、token 生命周期、background handler、测试；不得提交服务端私钥。
3. **P0-C 后端基础**：先补 `ImPushDispatcher`/设备 registry/API/鉴权/测试，再让兼容 `OfflinePushService` 委托它。
4. **P0-D Android FCM 服务端与普通消息 outbox**：HTTP v1、secret、after-commit 投递、无效 token 回收、真实 GMS Android 验收。
5. **P0-E Android 通话离线提醒**：收紧 `CallPushService` payload 后接 dispatcher，真实设备验收状态校验与挂断竞态。
6. **P1 iOS**：APS entitlement/APNs key/Firebase 配置、同一 registry/payload、普通消息与点击验收；不展开 VoIP/CallKit 离线来电。
7. **P2 Web**：HTTPS/VAPID/service worker、浏览器实例登记、通知点击与多浏览器验收。
8. **发布门禁**：权限拒绝、隐私 payload、日志脱敏、断网/杀进程/多设备测试全部通过后，按平台开关逐一启用；不得用一个 `fcm.enabled` 同时放开未验收 iOS/Web。

每一步独立可回滚：关闭 `shengyu.im.push.fcm.enabled` 后，现有 WebSocket、通话和会话同步不受影响；禁止删除现有 `OfflinePushServiceImpl` 默认回退。

---

## 9. 外部前置条件

实施对应阶段前由项目方提供或授权创建：

1. Firebase 项目、Android `applicationId=com.shengyu.im.shengyu_ui_admin_im` 对应的 Android App、`google-services.json`；P1 再配置 iOS Bundle ID 与 `GoogleService-Info.plist`；P2 再配置 Web App。
2. 服务端使用的受限 service account 或 Workload Identity，按 secret 注入，不提交 Git。
3. Android 通知 icon、正式包名、隐私政策中“推送 token/通知用途”说明；P1 需要 Apple Developer 权限与 APNs Auth Key（Firebase 服务本身免费，但 Apple 开发者计划并非本项目可省略的外部前置）。
4. 一台有 Google Play Services 的 Android 真机、一台真 iPhone、一个 HTTPS 测试域名及 Chrome/Edge 浏览器用于分阶段验收。

若目标市场主要为中国非 GMS 设备，本轮完成后仍应明确向客户说明：FCM 是免费最佳努力通道；达到微信级别离线送达需要单独评估并接入厂商通道或聚合服务。

---

## 11. 外部配置获取与交付记录（实施授权补充）

本节用于记录 Firebase 外部依赖的获取方式；客户端配置可进入仓库，任何私钥、OAuth bearer token、APNs `.p8` 和服务账号 JSON 均不得进入仓库、日志或通知 payload。

| 配置项 | 获取方式 | 安全存放与接入位置 | 当前状态 |
|---|---|---|---|
| Firebase 项目与 Android App | 使用具备项目创建/编辑权限的 Google 账号登录 [Firebase Console](https://console.firebase.google.com/)，创建或选择项目后按包名 `com.shengyu.im.shengyu_ui_admin_im` 添加 Android App，下载 `google-services.json` | 仅客户端配置放入 `shengyu-ui/shengyu-ui-admin-flutter/android/app/google-services.json`；配合 Google Services Gradle plugin | 已完成：项目 `shengyu-im-fcm`、Android App 与 FCM HTTP v1 |
| iOS App 与 APNs | 在同一 Firebase 项目添加正式 Bundle ID；由 Apple Developer 管理员创建 APNs Auth Key 并上传 Firebase | `GoogleService-Info.plist` 放入 `ios/Runner/` 并加入 Runner target；APNs `.p8` 仅上传 Firebase，绝不提交 | Firebase iOS App 与 plist 已完成；P1 暂停，等待 Apple Developer Program（年费会员）与 APNs 配置 |
| Web App/VAPID | Firebase Console 添加 Web App，在 Cloud Messaging 生成 Web Push VAPID public key | Web config 与 VAPID public key 可发布；Service Worker 只使用公开配置 | 已完成：Web App、VAPID public key 和 worker 配置；仍需 HTTPS 域名验收 |
| 服务端 HTTP v1 身份 | 优先为运行环境配置 Workload Identity；无法使用时，由项目管理员创建受限 service account 并以部署 Secret 挂载 JSON | 使用 `IM_PUSH_FCM_CREDENTIAL_FILE` 指向只读挂载路径；不放入源码、Docker image 或 CI 日志 | 开发环境已完成；生产环境仍需独立 Secret/Workload Identity |

执行人获授权在已登录且有权限的 Firebase 项目中创建/下载上述**客户端**配置；在最终创建 Firebase 项目、生成 VAPID key 或创建 service account 等会产生持久账户凭据的动作前，必须由项目所有者在控制台确认。Firebase 项目与公开客户端配置已在 2026-08-29 完成；任何服务账号、APNs 私钥仍不通过浏览器、源码或日志传递。

### 11.1 开发环境凭据记录（2026-08-29）

- Firebase 项目：`shengyu-im-fcm`；Android applicationId：`com.shengyu.im.shengyu_ui_admin_im`。
- 开发机当前凭据文件为 `sql/shengyu-im-fcm-firebase-adminsdk-fbsvc.json`，并通过 `IM_PUSH_FCM_CREDENTIAL_FILE` 显式引用；该路径已加入 Git 忽略。实施代码不得读取、打印、复制或打包该文件。
- **生产环境禁止使用该开发机文件。** 部署时必须在目标 Secret Manager/Kubernetes Secret/受控只读卷中重新保存凭据，并设置 `IM_PUSH_FCM_CREDENTIAL_FILE` 为容器内挂载路径；推荐后续迁移为 Workload Identity，届时删除静态私钥。
- 轮换要求：泄露、人员权限变更或发布至生产前均应创建新 key、更新 Secret、滚动重启服务并在 Firebase/Google Cloud 控制台禁用旧 key。

### 11.2 iOS APNs 后续操作手册（P1 暂停记录）

**当前状态：**Firebase iOS App 已按 Bundle ID `com.shengyu.im.shengyuUiAdminIm` 创建，`ios/Runner/GoogleService-Info.plist` 已下载到工程。由于项目当前没有 Apple Developer Program 会员资格，无法创建 APNs Auth Key、启用正式签名的 Push Notifications capability 或进行 iPhone 真机 APNs 验收。本轮不得因此把 iOS FCM 标记为已启用。

获得 Apple Developer Program 的 Account Holder 或 Admin 权限后，按以下顺序恢复：

1. 登录 [Apple Developer Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/authkeys/list)，打开 **Keys**，点击 `+`。
2. 为密钥填写可识别名称（例如 `Shengyu FCM APNs`），勾选 **Apple Push Notification service (APNs)**；若控制台要求选择范围，优先选择 Team Scoped，并覆盖开发与生产环境。
3. 确认创建后立即下载一次 `.p8`；Apple 不会再次提供同一私钥下载。将其保存到团队受控密钥库，严禁提交 Git、发送聊天或放入 Flutter/服务器镜像。
4. 记录 Key ID 与 Team ID（可在 Apple Developer Membership 页面获取 Team ID）。这两个标识可提供给实施人员核对，但不得提供 `.p8` 内容。
5. 打开 Firebase Console → 项目设置 → **Cloud Messaging** → 对应 Apple App。在 **APNs authentication key** 下上传开发、生产密钥之一或两者：选择 `.p8`，填写 Key ID、Team ID，保存。可将同一把 APNs Auth Key 分别用于开发和生产；至少上传一项。
6. 在 Xcode 的 Runner target → Signing & Capabilities 添加 **Push Notifications**。实施分支须将 `GoogleService-Info.plist` 加入 Runner target，并创建/接入 `Runner.entitlements` 的 `aps-environment`；由签名配置决定 development 或 production，不能在源码中伪造生产 entitlement。
7. 在真实 iPhone（非模拟器）上允许通知，使用开发签名验证 FCM registration token、后台通知、通知点击与账号作用域校验；TestFlight/App Store 发布前再验证 production APNs。

权威参考：[Apple 私钥创建](https://developer.apple.com/help/account/keys/create-a-private-key)、[Firebase Apple 平台 FCM 配置](https://firebase.google.com/docs/cloud-messaging/ios/get-started)。

### 12. Android P0 人工验收准备（2026-08-29）

P0 的代码、Android Firebase 客户端配置和服务端 HTTP v1 实现完成后，按下面顺序进行首次真机验收。仅使用安装了 Google Play Services 的 Android 真机；中国大陆非 GMS ROM 不应作为 FCM 验收设备。

1. 启动本地服务前，在**启动服务的同一终端**设置 `IM_PUSH_FCM_ENABLED=true`、`IM_PUSH_FCM_CREDENTIAL_FILE=sql/shengyu-im-fcm-firebase-adminsdk-fbsvc.json`。可选设置 `IM_PUSH_FCM_DRY_RUN=true` 先只验证注册与服务端请求构造；真正接收通知必须设为 `false`。不得打印、复制或提交该 JSON 文件。
2. 使用 `application-local` 配置启动 `ShengyuServerApplication`，确认 Redis 与 IM 依赖服务可用；服务端只会在目标用户没有可认证 WebSocket session 时投递普通消息。观察日志时仅核对 `tenantId`、`userId`、`deviceId`、`eventId`、状态码，禁止查找或粘贴完整 token。
3. 构建并安装测试包：在 `shengyu-ui/shengyu-ui-admin-flutter` 运行 `flutter build apk --debug --dart-define=FCM_ENABLED=true`，安装 `build/app/outputs/flutter-apk/app-debug.apk`。首次通过登录页请求通知权限并选择允许；拒绝权限也是 N7 的有效测试路径。
4. 用账号 A 登录真机，账号 B 发送一条普通 IM 消息。先验证 N1/N2；随后按 Home 让 A 后台，再验证 N3。为验证 N4，强制停止 A 后再从 B 发消息，期望收到固定隐私文案通知，点击后由会话同步进入正确 chat。
5. 用同一账号 A 在第二台 GMS Android 设备登录并允许通知，重复 token 注册后验证 N8；只在其中一台退出登录，确认另一台仍能收到通知。再从 B 发起通话，验证 N6：客户端必须先校验 `/system/im/call/active`，已结束的通话不得显示或接听。

当前限制：iOS APNs P1 仍因 Apple Developer Program 前置条件暂停；Web P2 已有代码和公开 Firebase 配置，但必须先部署 HTTPS 域名后再进行 N11/N12。二者均不阻塞 Android P0 人工验收。

---

## 10. 调研依据（实施时以官方最新文档为准）

- [Firebase Cloud Messaging 定价：Cloud Messaging 无费用](https://firebase.google.com/pricing)
- [Firebase：Flutter 接收前台、后台和终止状态消息](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages)
- [Firebase：iOS/APNs 配置与 registration token 生命周期](https://firebase.google.com/docs/cloud-messaging/ios/get-started)
- [Firebase：Web FCM、HTTPS、VAPID 与 Service Worker 配置](https://firebase.google.com/docs/cloud-messaging/web/get-started)
- [Firebase：Android notification/data payload 行为与短时处理限制](https://firebase.google.com/docs/cloud-messaging/android/receive-messages)
- [Android：Doze/App Standby 对网络和 FCM 的限制](https://developer.android.com/training/monitoring-device-state/doze-standby)
- [Android：后台启动 Foreground Service 的限制及 FCM 高优先级例外](https://developer.android.com/develop/background-work/services/fgs/restrictions-bg-start)
- [Android：Android 13+ 通知运行时权限](https://developer.android.com/develop/ui/compose/notifications/notification-permission)
- [Huawei Push Kit：官方能力与支持平台](https://developer.huawei.com/consumer/en/hms/huawei-pushkit)（本轮不接入，仅作为后续厂商通道预留依据）
