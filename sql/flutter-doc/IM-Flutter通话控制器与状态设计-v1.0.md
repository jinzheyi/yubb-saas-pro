# IM Flutter 通话控制器与状态设计 v1.0

> 文档日期：2026-04-29  
> 文档定位：Flutter 音视频通话模块的 Controller、State、UseCase、协调器详细设计  

---

## 1. 目标

把音视频通话模块收敛成可直接实现的控制器体系，避免后续编码时把业务状态、媒体状态、页面状态混在一起。

本文件与 `IM-Flutter音视频通话企业级设计-v1.0.md` 配套使用。

---

## 2. 设计原则

1. 页面只消费 `CallState`
2. 业务状态与媒体状态分离
3. WebRTC 原始对象不进入页面层
4. 所有通话动作必须通过 `CallController`
5. 页面恢复必须可以仅靠 `callSessionId` 与 `call.state-sync` 完成

---

## 3. 模块角色

### 3.1 `CallController`

负责：

- 通话主状态编排
- 页面动作入口
- 业务事件收敛
- 与 `CallCoordinator` 协同

### 3.2 `CallMediaController`

负责：

- 本地媒体流创建与销毁
- 远端媒体流订阅与解绑
- 静音、摄像头、扬声器、切前后摄
- 首帧与重连状态上报

### 3.3 `CallCoordinator`

负责：

- 页面进入策略
- 多页面与悬浮态切换
- 前后台恢复
- 路由跳转与恢复

### 3.4 `ActiveCallRegistry`

负责：

- 当前活动通话唯一性
- 悬浮态会话引用
- 防重复进入

---

## 4. 状态对象拆分

### 4.1 `CallState`

建议字段：

- `callSessionId`
- `chatId`
- `callType`
- `entryMode`
- `businessStatus`
- `endReason`
- `pageStatus`
- `isIncoming`
- `isOutgoing`
- `hasAccepted`
- `hasConnected`
- `isMinimized`
- `showPermissionBanner`
- `showReconnectingBanner`
- `elapsedSeconds`
- `callerProfile`
- `calleeProfile`
- `acceptedDeviceId`
- `errorMessage`
- `mediaState`

### 4.2 `CallMediaState`

建议字段：

- `microphoneEnabled`
- `cameraEnabled`
- `speakerEnabled`
- `frontCamera`
- `localTrackReady`
- `remoteTrackReady`
- `localVideoFirstFrameReady`
- `remoteVideoFirstFrameReady`
- `isPublishing`
- `isSubscribing`
- `networkQualityLevel`
- `rtcConnectionStatus`
- `localRendererAttached`
- `remoteRendererAttached`

### 4.3 `CallPageStatus`

建议枚举：

- `initial`
- `loading`
- `ringing`
- `accepting`
- `connecting`
- `connected`
- `reconnecting`
- `minimized`
- `ending`
- `ended`
- `failed`

### 4.4 `RtcConnectionStatus`

建议枚举：

- `idle`
- `preparing`
- `joining`
- `publishing`
- `subscribing`
- `connected`
- `reconnecting`
- `disconnected`
- `failed`

---

## 5. `CallController` 详细职责

### 5.1 初始化职责

- 读取 `CallLaunchArgs`
- 查询本地活动通话
- 启动 `SyncActiveCallStateUseCase`
- 订阅 socket call 事件
- 根据进入模式构造首屏状态

### 5.2 用户动作职责

- `startOutgoing()`
- `accept()`
- `reject()`
- `cancel()`
- `hangup()`
- `toggleMute()`
- `toggleSpeaker()`
- `toggleCamera()`
- `switchCamera()`
- `minimize()`
- `restore()`
- `retryReconnect()`

### 5.3 外部事件职责

- `onInviteReceived()`
- `onAccepted()`
- `onRejected()`
- `onBusy()`
- `onCancelled()`
- `onEnded()`
- `onTimeout()`
- `onStateSync()`
- `onDeviceTerminated()`
- `onMediaTokenIssued()`

### 5.4 生命周期职责

- 页面进入
- 页面恢复
- 页面销毁
- 前后台切换
- 登录态失效

---

## 6. `CallMediaController` 详细职责

### 6.1 本地媒体准备

- 申请权限
- 构建 audio constraints
- 构建 video constraints
- 创建本地流
- 绑定本地 renderer

### 6.2 RTC 会话职责

- 初始化 Janus session
- attach publisher
- attach subscriber
- publish local tracks
- subscribe remote tracks
- 处理 trickle / reconnect / detach

### 6.3 本地控制职责

- mute / unmute
- camera on / off
- switch camera
- speaker route
- stop local tracks
- release renderer

### 6.4 状态上报职责

- 本地首帧
- 远端首帧
- connection connected
- connection reconnecting
- connection failed

---

## 7. 协调器设计

### 7.1 `CallCoordinator`

建议动作：

- `openIncomingCall()`
- `openOutgoingCall()`
- `openCallSession()`
- `showMiniOverlay()`
- `hideMiniOverlay()`
- `restoreFromMiniOverlay()`
- `resumeFromStateSync()`
- `closeCallFlow()`

### 7.2 `CallPermissionCoordinator`

建议动作：

- `checkAudioPermission()`
- `checkVideoPermission()`
- `requestAudioPermission()`
- `requestVideoPermission()`
- `buildPermissionFailureReason()`

---

## 8. UseCase 详细定义

### 8.1 `CreateCallInviteUseCase`

输入：

- `chatId`
- `calleeUserId`
- `callType`

输出：

- `CallSession`
- 初始业务状态 `outgoing`

### 8.2 `AcceptCallUseCase`

输入：

- `callSessionId`

输出：

- 已接听业务状态
- RTC token / room 参数

### 8.3 `RejectCallUseCase`

输入：

- `callSessionId`
- `reason`

输出：

- 结束状态

### 8.4 `CancelCallUseCase`

输入：

- `callSessionId`

输出：

- `cancelled_by_caller`

### 8.5 `HangupCallUseCase`

输入：

- `callSessionId`

输出：

- 结束后的业务状态

### 8.6 `ReconnectCallUseCase`

输入：

- `callSessionId`
- `rtcRoomId`

输出：

- 恢复的媒体会话参数

### 8.7 `SyncActiveCallStateUseCase`

输入：

- `callSessionId`

输出：

- 最新 `CallSession`
- 当前业务状态
- 需要恢复的页面模式

---

## 9. Provider 建议

### 9.1 主 provider

- `callControllerProvider`
- `callMediaControllerProvider`
- `activeCallRegistryProvider`
- `callRepositoryProvider`
- `rtcGatewayClientProvider`

### 9.2 派生 provider

- `activeCallStateProvider`
- `callElapsedSecondsProvider`
- `isCallConnectedProvider`
- `isCallVideoEnabledProvider`
- `isCallReconnectingProvider`

---

## 10. 状态迁移约束

1. `idle -> outgoing -> connecting -> connected -> ended`
2. `idle -> incoming -> accepting -> connecting -> connected -> ended`
3. `incoming` 可直接到 `ended`
4. `outgoing` 可直接到 `ended`
5. `connected -> reconnecting -> connected`
6. `reconnecting` 超时后进入 `ended`

---

## 11. 页面与状态映射

### 11.1 `IncomingCallPage`

消费：

- `callerProfile`
- `callType`
- `pageStatus`
- `showPermissionBanner`

动作：

- `accept`
- `reject`

### 11.2 `OutgoingCallPage`

消费：

- `calleeProfile`
- `callType`
- `pageStatus`
- `errorMessage`

动作：

- `cancel`

### 11.3 `CallSessionPage`

消费：

- `mediaState`
- `elapsedSeconds`
- `showReconnectingBanner`
- `isMinimized`
- `endReason`

动作：

- `hangup`
- `toggleMute`
- `toggleSpeaker`
- `toggleCamera`
- `switchCamera`
- `minimize`
- `retryReconnect`

---

## 12. 失败处理约束

### 12.1 权限失败

- 不进入媒体连接
- 直接进入 `ended` 或 `failed`
- 明确 `permission_denied`

### 12.2 媒体连接失败

- 先进入 `reconnecting`
- 超窗后再进入 `ended`

### 12.3 业务态冲突

- 以服务端 `call.state-sync` 修正本地状态

### 12.4 多端抢接

- 本端收到 `call.device-terminated` 后立即退出可交互态

---

## 13. 实现禁令

1. 不在页面直接创建 `MediaStream`
2. 不在页面直接调用 Janus 协议
3. 不在页面用零散 bool 拼通话状态机
4. 不允许多个 controller 同时修改业务最终态

